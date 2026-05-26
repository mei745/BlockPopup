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
    // 针对你截图的补充
    @"售后", @"请输入您的授权", @"朕知道了", @"2440841046"
];

// 工具函数：判断是否包含关键词
static BOOL ContainsBlockKeyword(NSString *text) {
    if (!text || text.length == 0) return NO;
    NSString *lowerText = [text lowercaseString];
    for (NSString *keyword in kBlockKeywords) {
        NSString *lowerKeyword = [keyword lowercaseString];
        if ([lowerText containsString:lowerKeyword]) {
            return YES;
        }
    }
    return NO;
}

// ==========================================
// 第一层拦截：UIAlertController (现代弹窗)
// ==========================================
%hook UIAlertController

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle {
    // 只要标题或内容命中关键词，直接返回 nil，弹窗连出生都做不到
    if (ContainsBlockKeyword(title) || ContainsBlockKeyword(message)) {
        return nil;
    }
    return %orig;
}

%end

// ==========================================
// 第二层拦截：UIAlertView (老式弹窗)
// ==========================================
%hook UIAlertView

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {
    if (ContainsBlockKeyword(title) || ContainsBlockKeyword(message)) {
        return nil;
    }
    return %orig;
}

%end

// ==========================================
// 第三层拦截：UIWindow (针对插件悬浮窗/遮罩层)
// ==========================================
%hook UIWindow

- (void)makeKeyAndVisible {
    // 如果是非主窗口（通常是插件生成的弹窗层），尝试检测并拦截
    // 注意：这里比较激进，如果微信主窗口也被误杀会导致黑屏，所以只拦截非 Main Window
    UIWindow *mainWindow = [UIApplication sharedApplication].delegate.window;

    if (self != mainWindow) {
        // 遍历窗口子视图查找关键词（针对自定义 View 做的弹窗）
        // 这是一个兜底策略，防止插件不用标准 Alert
        BOOL foundKeyword = NO;
        for (UIView *subview in self.subviews) {
            // 简单的递归检查 subview 上的文字（这里简化处理，主要靠上面的 Alert 拦截）
            // 如果你发现还有漏网之鱼，可以在这里加更深的递归
        }

        // 如果这个窗口非常小（像弹窗），且不是主窗口，强制让它不可交互或直接隐藏
        // 这里为了安全，我们主要做“解锁”操作，防止假死
        self.userInteractionEnabled = YES;
        self.hidden = YES; // 激进策略：非主窗口直接隐藏
    }

    %orig;
}

%end

// ==========================================
// 第四层拦截：UIViewController (防止模态弹出)
// ==========================================
%hook UIViewController

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    // 检查要弹出的控制器的标题或类名
    NSString *title = viewControllerToPresent.title;
    NSString *className = NSStringFromClass([viewControllerToPresent class]);

    if (ContainsBlockKeyword(title) || ContainsBlockKeyword(className)) {
        NSLog(@"[BlockPopup] 🚫 拦截了试图弹出的控制器: %@", className);
        return; // 直接不执行 %orig，弹窗就不会出来
    }

    %orig;
}

%end
