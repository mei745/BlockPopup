#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ==========================================
// 核心配置：特征词库与白名单
// ==========================================

// 黑名单：包含这些关键词的弹窗将被拦截
static NSArray *kBlockKeywords = @[
    @"激活", @"授权", @"激活码", @"注册", @"正版", @"正版验证",
    @"注意", @"微密友", @"盗版", @"更新", @"卡密", @"到期",
    @"插件", @"license", @"activation", @"key", @"破解",
    @"警告", @"提示", @"试用", @"购买", @"续费", @"过期",
    @"捐赠", @"赞助", @"PayPal", @"Alipay", @"WeChat Pay",
    @"售后", @"请输入您的授权", @"朕知道了", @"2440841046"
];

// 白名单：即使包含黑名单关键词，但如果也包含白名单关键词，则放行
// 这可以有效防止误杀正常的系统或应用弹窗，例如“是否确认...”
static NSArray *kAllowKeywords = @[
    @"是否"
];

// ==========================================
// 工具函数：智能关键词匹配
// ==========================================
static BOOL ShouldBlockText(NSString *text) {
    if (!text || text.length == 0) return NO;
    
    NSString *lowerText = [text lowercaseString];
    
    // 1. 先检查白名单。如果命中白名单，直接放行（返回NO，表示不拦截）
    for (NSString *keyword in kAllowKeywords) {
        if ([lowerText containsString:[keyword lowercaseString]]) {
            return NO;
        }
    }
    
    // 2. 再检查黑名单。如果命中黑名单，则拦截（返回YES）
    for (NSString *keyword in kBlockKeywords) {
        if ([lowerText containsString:[keyword lowercaseString]]) {
            return YES;
        }
    }
    
    // 3. 都没命中，不拦截
    return NO;
}

// ==========================================
// 核心拦截：针对 UIAlertController (现代弹窗)
// ==========================================
%hook UIAlertController

// 1. 极致速度拦截：在初始化阶段直接杀掉
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle {
    // 检查标题或内容是否包含敏感词
    if (ShouldBlockText(title) || ShouldBlockText(message)) {
        NSLog(@"[BlockPopup] 🚫 极速拦截 (Init): %@", title ?: message);
        // 返回 nil，弹窗对象根本不会诞生
        return nil;
    }
    return %orig;
}

// 2. 补漏拦截：防止有些弹窗通过其他 init 方法创建
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    // 再次检查，如果漏网了，立刻强制关闭并从视图层级中移除
    if (ShouldBlockText(self.title) || ShouldBlockText(self.message)) {
        [self dismissViewControllerAnimated:NO completion:nil];
        [self.view removeFromSuperview];
    }
}

%end

// ==========================================
// 核心拦截：针对 UIAlertView (老式弹窗)
// ==========================================
%hook UIAlertView

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {
    if (ShouldBlockText(title) || ShouldBlockText(message)) {
        NSLog(@"[BlockPopup] 🚫 极速拦截 (Old Alert): %@", title ?: message);
        return nil;
    }
    return %orig;
}

- (void)show {
    if (ShouldBlockText(self.title) || ShouldBlockText(self.message)) {
        return; // 不调用 %orig，直接不显示
    }
    %orig;
}

%end

// ==========================================
// 终极防御：针对 UIWindow (独立悬浮窗/流氓遮罩)
// ==========================================
%hook UIWindow

- (void)makeKeyAndVisible {
    // 只有当窗口不是主窗口，且包含敏感特征时才拦截
    // 这里的判断逻辑比较保守，防止误杀系统键盘或正常界面
    BOOL isSuspicious = NO;

    // 检查窗口层级或类名特征 (可选，这里主要靠尺寸和可见性判断)
    if (self != [UIApplication sharedApplication].keyWindow && self != [UIApplication sharedApplication].delegate.window) {
         // 很多流氓插件会创建一个全屏但透明的 UIWindow 来锁死屏幕
         // 或者创建一个很小的窗口作为弹窗容器
         NSString *className = NSStringFromClass([self class]);
         if ([className containsString:@"Alert"] || [className containsString:@"Popup"] || [className containsString:@"Auth"]) {
             isSuspicious = YES;
         }
    }

    if (isSuspicious) {
        NSLog(@"[BlockPopup] 🚫 拦截可疑窗口: %@", NSStringFromClass([self class]));
        return; // 阻止窗口显示
    }

    %orig;
}

%end
