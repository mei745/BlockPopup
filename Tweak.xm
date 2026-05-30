#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// 定义一个函数，用来判断字符串是否包含敏感词
static BOOL isSensitiveString(NSString *str) {
    if (!str) return NO;
    NSArray *keywords = @[@"激活", @"授权", @"注册", @"正版", @"购买", @"续费", @"试用", @"过期", @"License", @"Activation"];
    for (NSString *keyword in keywords) {
        if ([str containsString:keyword]) {
            return YES;
        }
    }
    return NO;
}

// ==========================================
// 核心拦截逻辑
// ==========================================

%hook SCLAlertView

// 拦截 show 方法：这是弹窗显示的最后一步
- (UIView *)show {
    // 获取弹窗的标题或内容，检查是否包含敏感词
    NSString *title = [self valueForKey:@"title"];
    NSString *subTitle = [self valueForKey:@"subTitle"];

    if (isSensitiveString(title) || isSensitiveString(subTitle)) {
        NSLog(@"[Tweak] 发现敏感弹窗，已拦截: %@", title);
        return nil; // 返回 nil，阻止弹窗显示
    }

    return %orig; // 如果不是敏感弹窗，放行
}

// 拦截 showSuccess / showError 等快捷方法
- (UIView *)showSuccess:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration {
    if (isSensitiveString(title) || isSensitiveString(subTitle)) return nil;
    return %orig;
}

- (UIView *)showError:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration {
    if (isSensitiveString(title) || isSensitiveString(subTitle)) return nil;
    return %orig;
}

- (UIView *)showNotice:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration {
    if (isSensitiveString(title) || isSensitiveString(subTitle)) return nil;
    return %orig;
}

- (UIView *)showWarning:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration {
    if (isSensitiveString(title) || isSensitiveString(subTitle)) return nil;
    return %orig;
}

- (UIView *)showInfo:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration {
    if (isSensitiveString(title) || isSensitiveString(subTitle)) return nil;
    return %orig;
}

- (UIView *)showEdit:(NSString *)title subTitle:(NSString *)subTitle closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration {
    if (isSensitiveString(title) || isSensitiveString(subTitle)) return nil;
    return %orig;
}

- (UIView *)showCustom:(NSString *)title subTitle:(NSString *)subTitle image:(UIImage *)image color:(UIColor *)color closeButtonTitle:(NSString *)closeButtonTitle duration:(NSTimeInterval)duration {
    if (isSensitiveString(title) || isSensitiveString(subTitle)) return nil;
    return %orig;
}

%end

// ==========================================
// 兜底拦截：防止漏网之鱼
// ==========================================

%hook UIWindow

// 拦截所有窗口的显示，但必须放过键盘和系统窗口
- (void)makeKeyAndVisible {
    NSString *windowClass = NSStringFromClass([self class]);

    // 【白名单】如果是键盘或系统窗口，直接放行
    if ([windowClass containsString:@"Keyboard"] ||
        [windowClass containsString:@"UITextEffects"] ||
        [windowClass containsString:@"UIRemote"] ||
        [windowClass isEqualToString:@"UIWindow"]) {
        %orig;
        return;
    }

    // 检查窗口内的视图是否包含 SCLAlertView
    BOOL hasSCLAlert = NO;
    for (UIView *view in self.subviews) {
        if ([NSStringFromClass([view class]) containsString:@"SCLAlertView"]) {
            hasSCLAlert = YES;
            break;
        }
    }

    if (hasSCLAlert) {
        NSLog(@"[Tweak] 发现 SCLAlertView 窗口，已拦截");
        self.hidden = YES; // 隐藏窗口
        self.alpha = 0;    // 透明化
        return;            // 不调用 %orig，彻底阻止显示
    }

    %orig; // 其他窗口正常显示
}

%end
