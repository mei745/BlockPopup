#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ==========================================
// 核心配置
// ==========================================

// 黑名单：包含这些词的弹窗会被杀掉
static NSArray *kBlockKeywords = @[
    @"激活", @"授权", @"激活码", @"注册", @"正版", @"正版验证", 
    @"注意", @"微密友", @"盗版", @"更新", @"卡密", @"到期", @"输入",
    @"插件", @"license", @"activation", @"key", @"破解", @"提醒",
    @"警告", @"提示", @"试用", @"购买", @"续费", @"过期", @"客服",
    @"捐赠", @"赞助", @"PayPal", @"Alipay", @"WeChat Pay", @"网址",
    @"售后", @"请输入您的授权", @"朕知道了", @"QQ", @"微信", @"2440841046"
];

// 白名单：如果包含这些词，即使是黑名单里的词也放行（防止误杀系统提示）
static NSArray *kAllowKeywords = @[
    @"是否", @"确定要", @"确认删除", @"退出登录", @"无法连接"
];

// ==========================================
// 工具函数
// ==========================================
static BOOL ShouldBlockText(NSString *text) {
    if (!text || text.length == 0) return NO;
    NSString *lowerText = [text lowercaseString];

    // 1. 先检查白名单（如果是正常的系统询问，直接放行）
    for (NSString *allowWord in kAllowKeywords) {
        if ([lowerText containsString:[allowWord lowercaseString]]) {
            return NO; // 放行
        }
    }

    // 2. 再检查黑名单
    for (NSString *blockWord in kBlockKeywords) {
        if ([lowerText containsString:[blockWord lowercaseString]]) {
            return YES; // 拦截
        }
    }
    return NO;
}

// ==========================================
// 拦截 UIAlertController (iOS 8+ 标准弹窗)
// ==========================================
%hook UIAlertController

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle {
    if (ShouldBlockText(title) || ShouldBlockText(message)) {
        NSLog(@"[BlockPopup] 🚫 拦截 Init: %@", title ?: message);
        return nil; // 直接返回空，弹窗连创建都不会创建
    }
    return %orig;
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    // 补漏：有些弹窗不是通过 initWithTitle 创建的
    if (ShouldBlockText(self.title) || ShouldBlockText(self.message)) {
        NSLog(@"[BlockPopup] 🚫 拦截 ViewWillAppear: %@", self.title ?: self.message);
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

%end

// ==========================================
// 拦截 UIAlertView (老旧弹窗，部分老插件还在用)
// ==========================================
%hook UIAlertView

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {
    if (ShouldBlockText(title) || ShouldBlockText(message)) {
        return nil;
    }
    return %orig;
}

- (void)show {
    if (ShouldBlockText(self.title) || ShouldBlockText(self.message)) {
        return; // 不调用 %orig，直接吞掉
    }
    %orig;
}

%end

// ==========================================
// 拦截 SCLAlertView (很多 iOS 插件喜欢用的第三方弹窗库)
// ==========================================
// 如果你的头文件 SCLAlertView.h 里有定义，这里可以直接引用，或者用 id 代替
%hook NSObject // 用 NSObject 兜底，防止类名不确定

- (instancetype)init {
    self = %orig;
    if (self) {
        NSString *className = NSStringFromClass([self class]);
        // 检测是否是 SCLAlertView 或其变体
        if ([className containsString:@"SCLAlert"] || [className containsString:@"AlertView"]) {
             // 尝试获取 title 属性 (KVC)
             NSString *title = [self valueForKey:@"title"];
             NSString *subTitle = [self valueForKey:@"subTitle"];

             if (ShouldBlockText(title) || ShouldBlockText(subTitle)) {
                 NSLog(@"[BlockPopup] 🚫 拦截第三方弹窗: %@", className);
                 // 对于这种复杂的自定义 View，最好的办法是把它隐藏或移除
                 // 但为了安全，我们尝试调用它的 hide 方法（如果存在）
                 if ([self respondsToSelector:@selector(hideView)]) {
                     [(id)self performSelector:@selector(hideView)];
                 }
             }
        }
    }
    return self;
}

%end

// ==========================================
// 拦截 UIWindow (针对全屏遮罩/流氓悬浮窗)
// ==========================================
%hook UIWindow

- (void)makeKeyAndVisible {
    // 简单的防御逻辑：如果不是主窗口，且类名很奇怪，就不让它显示
    BOOL isMain = (self == [UIApplication sharedApplication].keyWindow ||
                   self == [UIApplication sharedApplication].delegate.window);

    if (!isMain) {
        NSString *className = NSStringFromClass([self class]);
        // 这里的判断比较保守，避免误杀键盘或正常的 HUD
        if ([className containsString:@"Overlay"] ||
            [className containsString:@"Mask"] ||
            [className containsString:@"Auth"]) {
             NSLog(@"[BlockPopup] 🚫 拦截可疑窗口: %@", className);
             return;
        }
    }
    %orig;
}

%end
