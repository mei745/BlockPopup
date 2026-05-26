#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ==========================================
// 核心配置：特征词库
// ==========================================
static NSArray *kBlockKeywords = @[
    @"激活", @"授权", @"激活码", @"注册", @"正版", @"正版验证",
    @"注意", @"微密友", @"盗版", @"更新", @"卡密",
    @"插件", @"license", @"activation", @"key", @"破解",
    @"警告", @"提示", @"试用", @"购买", @"续费", @"过期",
    @"捐赠", @"赞助", @"PayPal", @"Alipay", @"WeChat Pay",
    @"售后", @"请输入您的授权", @"朕知道了", @"2440841046"
];

// ==========================================
// 工具函数：关键词匹配
// ==========================================
static BOOL ContainsBlockKeyword(NSString *text) {
    if (!text || text.length == 0) return NO;
    NSString *lowerText = [text lowercaseString];
    for (NSString *keyword in kBlockKeywords) {
        if ([lowerText containsString:[keyword lowercaseString]]) {
            return YES;
        }
    }
    return NO;
}

// ==========================================
// 核心拦截：针对 UIAlertController (现代弹窗)
// ==========================================
%hook UIAlertController

// 1. 极致速度拦截：在初始化阶段直接杀掉
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle {
    // 检查标题或内容是否包含敏感词
    if (ContainsBlockKeyword(title) || ContainsBlockKeyword(message)) {
        NSLog(@"[BlockPopup] 🚫 极速拦截 (Init): %@", title ?: message);
        // 返回 nil，弹窗对象根本不会诞生
        return nil;
    }
    return %orig;
}

// 2. 补漏拦截：防止有些弹窗通过其他 init 方法创建
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    // 再次检查，如果漏网了，立刻强制关闭
    if (ContainsBlockKeyword(self.title) || ContainsBlockKeyword(self.message)) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

%end

// ==========================================
// 核心拦截：针对 UIAlertView (老式弹窗)
// ==========================================
%hook UIAlertView

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {
    if (ContainsBlockKeyword(title) || ContainsBlockKeyword(message)) {
        NSLog(@"[BlockPopup] 🚫 极速拦截 (Old Alert): %@", title ?: message);
        return nil;
    }
    return %orig;
}

- (void)show {
    if (ContainsBlockKeyword(self.title) || ContainsBlockKeyword(self.message)) {
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
