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
// 核心拦截1：针对 SCLAlertView (你文件列表里的自定义弹窗)
// ==========================================
%hook SCLAlertView

- (void)showTitle:(NSString *)title subTitle:(NSString *)subTitle style:(SCLAlertViewStyle)style {
    if (ContainsBlockKeyword(title) || ContainsBlockKeyword(subTitle)) {
        NSLog(@"[BlockPopup] 🚫 拦截 SCLAlertView: %@", title);
        return; // 直接不执行 show，弹窗就不会出来
    }
    %orig;
}

// 兼容其他 show 方法
- (void)showSuccess:(NSString *)title subTitle:(NSString *)subTitle {
    if (ContainsBlockKeyword(title)) return;
    %orig;
}
- (void)showError:(NSString *)title subTitle:(NSString *)subTitle {
    if (ContainsBlockKeyword(title)) return;
    %orig;
}
- (void)showNotice:(NSString *)title subTitle:(NSString *)subTitle {
    if (ContainsBlockKeyword(title)) return;
    %orig;
}
- (void)showWarning:(NSString *)title subTitle:(NSString *)subTitle {
    if (ContainsBlockKeyword(title)) return;
    %orig;
}
- (void)showInfo:(NSString *)title subTitle:(NSString *)subTitle {
    if (ContainsBlockKeyword(title)) return;
    %orig;
}
- (void)showEdit:(NSString *)title subTitle:(NSString *)subTitle {
    if (ContainsBlockKeyword(title)) return;
    %orig;
}
- (void)showWaiting:(NSString *)title subTitle:(NSString *)subTitle {
    if (ContainsBlockKeyword(title)) return;
    %orig;
}
- (void)showCustom:(NSString *)title subTitle:(NSString *)subTitle image:(UIImage *)image color:(UIColor *)color {
    if (ContainsBlockKeyword(title)) return;
    %orig;
}

%end

// ==========================================
// 核心拦截2：针对 UIView (暴力移除流氓遮罩层)
// ==========================================
%hook UIView

- (void)didMoveToWindow {
    %orig;

    // 如果这个 View 已经有了父视图（说明已经被加到界面上了）
    if (self.window) {
        NSString *className = NSStringFromClass([self class]);

        // 1. 排除法：如果是系统关键组件，绝对不碰
        if ([className containsString:@"UIKeyboard"] ||
            [className containsString:@"UITextEffects"] ||
            [className containsString:@"UIInputSet"] ||
            [className containsString:@"UILayoutContainer"] ||
            [className containsString:@"TabBar"] ||
            [className containsString:@"NavBar"]) {
            return;
        }

        // 2. 检查类名是否包含敏感特征
        BOOL isSuspiciousClass = ([className containsString:@"Alert"] ||
                                  [className containsString:@"Popup"] ||
                                  [className containsString:@"Auth"] ||
                                  [className containsString:@"Mask"] ||
                                  [className containsString:@"Overlay"] ||
                                  [className containsString:@"Lock"]);

        // 3. 检查内容文本
        BOOL hasBadText = NO;
        // 遍历子视图查找文本（防止文字在 Label 里）
        for (UIView *subview in self.subviews) {
            if ([subview respondsToSelector:@selector(text)]) {
                NSString *text = [subview performSelector:@selector(text)];
                if (ContainsBlockKeyword(text)) {
                    hasBadText = YES;
                    break;
                }
            }
            // 检查 UIButton 的 title
            if ([subview isKindOfClass:[UIButton class]]) {
                NSString *title = [(UIButton *)subview titleForState:UIControlStateNormal];
                if (ContainsBlockKeyword(title)) {
                    hasBadText = YES;
                    break;
                }
            }
        }

        // 4. 执行拦截
        if ((isSuspiciousClass || hasBadText) && self.window.windowLevel >= UIWindowLevelNormal) {
             // 再次确认标题或自身属性
             if (hasBadText || (isSuspiciousClass && self.frame.size.height < 500)) { // 简单的尺寸过滤，防止误杀全屏页面
                 NSLog(@"[BlockPopup] 🚫 强制移除流氓视图: %@", className);
                 [self removeFromSuperview];

                 // 解锁屏幕交互，防止卡死
                 self.window.userInteractionEnabled = YES;
                 [UIApplication sharedApplication].keyWindow.userInteractionEnabled = YES;
             }
        }
    }
}

%end

// ==========================================
// 核心拦截3：针对 UIWindow (修复键盘被杀的问题)
// ==========================================
%hook UIWindow

- (void)makeKeyAndVisible {
    NSString *className = NSStringFromClass([self class]);

    // 【白名单】：如果是键盘、输入法、或者正常的系统窗口，直接放行！
    if ([className containsString:@"Keyboard"] ||
        [className containsString:@"Input"] ||
        [className containsString:@"Remote"] ||
        [className containsString:@"UITextEffects"]) {
        %orig;
        return;
    }

    // 【黑名单】：检查是否是可疑的授权窗口
    // 这里的逻辑是：如果窗口类名很可疑，且不是主窗口，才拦截
    BOOL isSuspicious = NO;
    if ([className containsString:@"Alert"] ||
        [className containsString:@"Popup"] ||
        [className containsString:@"Auth"] ||
        [className containsString:@"License"]) {

        // 确保不是微信的主窗口或正常的导航窗口
        if (self != [UIApplication sharedApplication].delegate.window &&
            self != [UIApplication sharedApplication].keyWindow) {
            isSuspicious = YES;
        }
    }

    if (isSuspicious) {
        NSLog(@"[BlockPopup] 🚫 拦截可疑窗口显示: %@", className);
        // 这里不执行 %orig，窗口就不会显示
        // 同时尝试解锁主窗口
        [UIApplication sharedApplication].keyWindow.userInteractionEnabled = YES;
        return;
    }

    %orig;
}

%end
