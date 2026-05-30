#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ==========================================
// 核心配置区
// ==========================================
// 在这里定义需要屏蔽的弹窗关键词（支持模糊匹配）
static NSArray *sensitiveKeywords() {
    return @[
        @"激活", @"授权", @"注册", @"正版", @"购买", @"续费",
        @"试用", @"过期", @"License", @"Activation", @"VIP",
        @"付费", @"解锁", @"Pro"
    ];
}

// 判断字符串是否包含敏感词
static BOOL isSensitiveContent(NSString *text) {
    if (!text || text.length == 0) return NO;
    for (NSString *keyword in sensitiveKeywords()) {
        if ([text rangeOfString:keyword options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

// ==========================================
// Hook SCLAlertView (第三方弹窗库)
// ==========================================
%hook SCLAlertView

- (void)showTitle:(NSString *)title subTitle:(NSString *)subTitle style:(NSInteger)style {
    // 1. 检查标题或副标题是否包含敏感词
    BOOL shouldBlock = isSensitiveContent(title) || isSensitiveContent(subTitle);

    if (shouldBlock) {
        // 如果包含敏感词，直接拦截，不执行原来的 show 方法
        NSLog(@"[BlockPopup] 已拦截 SCLAlertView 弹窗: %@", title);
        return;
    }

    // 2. 如果不包含敏感词，放行（执行原方法）
    %orig;
}

// 备用拦截：防止通过其他方式初始化
- (void)showView:(UIView *)view {
    // 这里很难获取标题，通常直接放行，主要靠上面的 showTitle 拦截
    %orig;
}

%end

// ==========================================
// Hook UIAlertController (系统原生弹窗)
// ==========================================
%hook UIAlertController

- (void)viewWillAppear:(BOOL)animated {
    %orig;

    // 获取弹窗标题
    NSString *title = [self valueForKey:@"title"];
    NSString *message = [self valueForKey:@"message"];

    if (isSensitiveContent(title) || isSensitiveContent(message)) {
        NSLog(@"[BlockPopup] 已拦截系统弹窗: %@", title);
        // 强制关闭弹窗
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

%end
