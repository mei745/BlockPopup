#import <UIKit/UIKit.h>
#import <SpringBoard/SpringBoard.h>
#import <CaptainHook/CaptainHook.h>

// 拦截所有 UIAlertController 弹窗
CHHook(UIAlertController, presentViewController:animated:completion:);

// 拦截 UIActionSheet 弹窗
CHHook(UIActionSheet, showInView:);

// 拦截自定义弹窗（检测可疑窗口）
CHHook(UIWindow, makeKeyAndVisible);

%hook UIAlertController

- (void)presentViewController:(UIViewController *)viewController 
                      animated:(BOOL)flag 
                    completion:(void (^)(void))completion {
    
    // 获取弹窗标题和消息
    NSString *title = self.title;
    NSString *message = self.message;
    
    // 检测第三方插件弹窗关键词
    BOOL shouldBlock = NO;
    
    if (title || message) {
        NSArray *blockKeywords = @[
            @"激活", @"授权", @"激活码", @"注册", @"正版", @"正版验证",
            @"插件", @"license", @"license key", @"activation",
            @"key", @"keygen", @"crack", @"破解", @"warning",
            @"警告", @"提示", @"注意", @"弹窗", @"弹窗提示"
        ];
        
        NSString *combined = [NSString stringWithFormat:@"%@ %@", 
                              title ?: @"", message ?: @""];
        
        for (NSString *keyword in blockKeywords) {
            if ([combined.lowercaseString containsString:keyword.lowercaseString]) {
                shouldBlock = YES;
                break;
            }
        }
    }
    
    if (shouldBlock) {
        // 屏蔽弹窗 - 不显示
        NSLog(@"[BlockPopup] Blocked popup - Title: %@", title);
        return;
    }
    
    %orig;
}

%end

%hook UIActionSheet

- (void)showInView:(UIView *)view {
    NSString *title = self.title;
    
    if (title) {
        NSArray *blockKeywords = @[
            @"激活", @"授权", @"激活码", @"插件验证"
        ];
        
        for (NSString *keyword in blockKeywords) {
            if ([title.lowercaseString containsString:keyword.lowercaseString]) {
                NSLog(@"[BlockPopup] Blocked action sheet - Title: %@", title);
                return;
            }
        }
    }
    
    %orig;
}

%end

%hook UIWindow

- (void)makeKeyAndVisible {
    // 检查是否是可疑的自定义弹窗窗口
    // 某些第三方插件使用独立的 UIWindow
    
    UIViewController *rootVC = self.rootViewController;
    if (rootVC) {
        NSString *vcName = NSStringFromClass([rootVC class]);
        if ([vcName.lowercaseString containsString:@"alert"] ||
            [vcName.lowercaseString containsString:@"popup"] ||
            [vcName.lowercaseString containsString:@"dialog"]) {
            NSLog(@"[BlockPopup] Blocked custom popup window - VC: %@", vcName);
            return;
        }
    }
    
    %orig;
}

%end