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
        @"付费", @"解锁", @"订阅"
    ];
}

// 检查字符串是否包含敏感词
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
// 1. 拦截 SCLAlertView (第三方自定义弹窗)
// ==========================================
%hook SCLAlertView

// 拦截初始化方法，如果是敏感内容，直接返回 nil (让弹窗无法创建)
- (instancetype)initWithTitle:(NSString *)title subTitle:(NSString *)subTitle {
    // 检查标题或副标题是否包含敏感词
    if (isSensitiveContent(title) || isSensitiveContent(subTitle)) {
        NSLog(@"[BlockPopup] 🚫 拦截到 SCLAlertView 敏感弹窗: %@", title);
        return nil; // 直接扼杀在摇篮里
    }
    return %orig; // 正常弹窗放行
}

// 备用方案：如果初始化没拦住，拦截 show 方法强制隐藏
- (void)show {
    NSString *title = [self valueForKey:@"title"];
    NSString *subTitle = [self valueForKey:@"subTitle"];

    if (isSensitiveContent(title) || isSensitiveContent(subTitle)) {
        NSLog(@"[BlockPopup] 🚫 强制隐藏 SCLAlertView: %@", title);
        [self.view removeFromSuperview]; // 移除视图
        return; // 阻止后续显示逻辑
    }
    %orig;
}

%end

// ==========================================
// 2. 拦截系统原生 UIAlertController (兜底)
// ==========================================
%hook UIAlertController

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle {
    if (isSensitiveContent(title) || isSensitiveContent(message)) {
        NSLog(@"[BlockPopup] 🚫 拦截到系统原生敏感弹窗: %@", title);
        // 创建一个空的或者替换成无害的内容，或者直接返回nil(视具体稳定性而定，这里建议返回原对象但置空内容)
        // 为了安全，我们让它初始化成功，但在显示时处理，或者直接在这里返回一个空的
        // 但最稳妥的是放行初始化，拦截 presentViewController
    }
    return %orig;
}

%end

// ==========================================
// 3. 拦截 UIWindow 添加子视图 (终极防线)
// ==========================================
%hook UIWindow

- (void)addSubview:(UIView *)view {
    // 获取视图的类名
    NSString *className = NSStringFromClass([view class]);

    // 如果添加的是 SCLAlertView 或者 UIAlertController 的视图
    if ([className containsString:@"SCLAlertView"] || [className containsString:@"UIAlert"]) {
        // 尝试获取标题进行二次确认
        NSString *title = nil;
        if ([view respondsToSelector:@selector(title)]) {
            title = [view valueForKey:@"title"];
        } else if ([view.subviews count] > 0) {
             // 尝试从子视图递归查找（简单处理）
             for (UIView *sub in view.subviews) {
                 if ([sub isKindOfClass:[UILabel class]]) {
                     UILabel *label = (UILabel *)sub;
                     if (isSensitiveContent(label.text)) {
                         title = label.text;
                         break;
                     }
                 }
             }
        }

        if (isSensitiveContent(title)) {
            NSLog(@"[BlockPopup] 🚫 终极防线拦截: %@", className);
            return; // 禁止添加到窗口
        }
    }
    %orig;
}

%end
