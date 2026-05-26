#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ==========================================
// 核心配置：针对第三方插件授权框的暴力拦截
// ==========================================

// 1. 拦截 UIWindow 的添加 (针对独立窗口类弹窗)
%hook UIWindow

- (void)makeKeyAndVisible {
    // 如果这个窗口不是微信主窗口，且带有 "Alert"、"Auth"、"License" 等特征，或者尺寸很小（通常是弹窗）
    // 这里我们采取更激进的策略：如果它是新创建的且不是主窗口，先检查内容
    if (self != [UIApplication sharedApplication].keyWindow) {
        // 简单的特征判断，防止误杀系统键盘等
        NSString *winClass = NSStringFromClass([self class]);
        if ([winClass containsString:@"UI"] || self.windowLevel > UIWindowLevelNormal) {
             // 这里可以加日志，但在暴力模式下，我们尝试直接忽略非主窗口的 makeKeyAndVisible
             // 注意：这可能会影响部分正常功能，如果发现问题请注释掉下面这行 return
             // return;
        }
    }
    %orig;
}

// 2. 拦截 addSubview (针对直接贴在屏幕上的弹窗)
%hook UIView

- (void)addSubview:(UIView *)view {
    // 检查即将被添加的视图是否包含敏感词（标题、按钮文字）
    // 这种方式比拦截 init 更有效，因为此时视图树已经构建好了

    if ([self isSuspiciousView:view]) {
        NSLog(@"[BlockPopup] 🚫 发现可疑视图添加，已拦截: %@", view);
        return; // 直接不添加，弹窗就不会出现
    }

    %orig;
}

// 辅助函数：递归检查视图及其子视图是否包含敏感信息
static BOOL isSuspiciousView(UIView *view) {
    // 检查当前视图的文字
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        if ([containsKeyword(label.text)]) return YES;
    }
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *btn = (UIButton *)view;
        if ([containsKeyword(btn.titleLabel.text)]) return YES;
    }
    if ([view isKindOfClass:[UITextField class]]) {
        UITextField *field = (UITextField *)view;
        if ([containsKeyword(field.placeholder)]) return YES;
    }

    // 递归检查子视图
    for (UIView *subview in view.subviews) {
        if (isSuspiciousView(subview)) return YES;
    }
    return NO;
}

// 关键词匹配函数
static BOOL containsKeyword(NSString *text) {
    if (!text || text.length == 0) return NO;
    NSArray *keywords = @[
        @"激活", @"授权", @"卡密", @"License", @"Auth",
        @"售后", @"续费", @"正版", @"微密友", @"朕知道了",
        @"2440841046", @"请输入您的授权"
    ];
    for (NSString *key in keywords) {
        if ([text containsString:key]) return YES;
    }
    return NO;
}

%end

// 3. 强制恢复屏幕交互 (解决卡死问题)
%hook UIApplication

- (void)sendEvent:(UIEvent *)event {
    %orig;

    // 每次有事件发生时，检查并解锁屏幕
    UIWindow *window = self.keyWindow;
    if (window && !window.userInteractionEnabled) {
        window.userInteractionEnabled = YES;
    }

    // 遍历所有窗口，移除可疑的遮罩层
    for (UIWindow *w in self.windows) {
        if (w != window && w.windowLevel > UIWindowLevelNormal) {
            // 这是一个悬浮层，如果是半透明黑色的，很可能是遮罩
            if (w.backgroundColor && CGColorGetAlpha(w.backgroundColor.CGColor) < 1.0) {
                w.hidden = YES;
                w.userInteractionEnabled = NO;
            }
        }
    }
}

%end
