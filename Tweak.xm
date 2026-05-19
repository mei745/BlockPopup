#import <UIKit/UIKit.h>

%hook UIAlertController

- (void)presentViewController:(UIViewController *)viewController 
                      animated:(BOOL)flag 
                    completion:(void (^)(void))completion {
    
    NSString *title = self.title;
    NSString *message = self.message;
    
    BOOL shouldBlock = NO;
    
    if (title || message) {
        NSArray *blockKeywords = @[
            @"激活", @"授权", @"激活码", @"注册", @"正版", @"正版验证",
            @"插件", @"license", @"activation", @"key", @"破解",
            @"警告", @"提示"
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
