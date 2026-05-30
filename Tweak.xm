#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ==========================================
// 核心配置：特征词库 (保持更新)
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
// 工具函数：关键词匹配 (高效版)
// ==========================================
static BOOL ContainsBlockKeyword(NSString *text) {
    if (!text || text.length == 0) return NO;
    // 使用 lowercaseString 忽略大小写
    NSString *lowerText = [text lowercaseString];
    for (NSString *keyword in kBlockKeywords) {
        if ([lowerText containsString:[keyword lowercaseString]]) {
            return YES;
        }
    }
    return NO;
}

// 辅助函数：检查视图层级中是否包含敏感词
static BOOL CheckViewHierarchy(UIView *view) {
    // 检查当前 View 的类名
    if (ContainsBlockKeyword(NSStringFromClass([view class]))) return YES;

    // 检查子 View
    for (UIView *subview in view.subviews) {
        if (CheckViewHierarchy(subview)) return YES;
    }
    return NO;
}

// ==========================================
// 策略一：拦截系统原生弹窗的“展示”动作
// ==========================================

%hook UIAlertController
- (void)viewWillAppear:(BOOL)animated {
    if (ContainsBlockKeyword(self.title) || ContainsBlockKeyword(self.message)) {
        NSLog(@"[BlockPopup] 🚫 拦截 UIAlertController: %@", self.title);
        [self dismissViewControllerAnimated:NO completion:nil]; // 立即消失
        return;
    }
    %orig;
}
%end

%hook UIAlertView
- (void)show {
    if (ContainsBlockKeyword(self.title) || ContainsBlockKeyword(self.message)) {
        NSLog(@"[BlockPopup] 🚫 拦截 UIAlertView: %@", self.title);
        return; // 直接不执行 show
    }
    %orig;
}
%end

// ==========================================
// 策略二：针对 UIViewController 的模态弹出
// ==========================================
%hook UIViewController
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    // 检查被弹出的控制器标题或类名
    if (ContainsBlockKeyword(viewControllerToPresent.title) ||
        ContainsBlockKeyword(NSStringFromClass([viewControllerToPresent class]))) {
        NSLog(@"[BlockPopup] 🚫 拦截 presentViewController");
        return; // 阻止弹出
    }
    %orig;
}
%end

// ==========================================
// 策略三：终极防御 - 拦截 addSubview (针对流氓自定义弹窗)
// ==========================================
%hook UIView

- (void)addSubview:(UIView *)view {
    // 1. 检查被添加的 View 是否包含敏感词（比如类名带有 Alert, Auth, License）
    BOOL isBadView = ContainsBlockKeyword(NSStringFromClass([view class]));

    // 2. 如果类名没命中，深入检查它的子视图（防止嵌套）
    if (!isBadView) {
        isBadView = CheckViewHierarchy(view);
    }

    // 3. 如果被判定为流氓弹窗
    if (isBadView) {
        NSLog(@"[BlockPopup] 🚫 拦截 addSubview: %@", NSStringFromClass([view class]));

        // 【关键】强制解锁屏幕交互！防止插件把背景锁死导致假死
        if ([self isKindOfClass:[UIWindow class]]) {
            self.userInteractionEnabled = YES;
        }
        return; // 拒绝添加这个 View
    }

    %orig;
}

%end

// ==========================================
// 策略四：防止 UIWindow 级别的遮罩
// ==========================================
%hook UIWindow
- (void)makeKeyAndVisible {
    // 简单的启发式判断：如果不是主窗口，且类名可疑
    NSString *className = NSStringFromClass([self class]);
    if (self != [UIApplication sharedApplication].delegate.window) {
         if ([className containsString:@"Alert"] ||
             [className containsString:@"Auth"] ||
             [className containsString:@"License"]) {
             NSLog(@"[BlockPopup] 🚫 拦截可疑 UIWindow: %@", className);
             return; // 不让它成为 KeyWindow
         }
    }
    %orig;
}
%end
