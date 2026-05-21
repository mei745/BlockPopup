#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ==========================================
// 配置区域：在这里添加你想屏蔽的关键词
// ==========================================
static NSArray *kBlockKeywords = @[
    @"激活", @"授权", @"激活码", @"注册", @"正版", @"正版验证",
    @"插件", @"license", @"activation", @"key", @"破解",
    @"警告", @"提示", @"试用", "@\"购买", @"续费", @"过期",
    @"捐赠", @"赞助", @"PayPal", @"Alipay", @"WeChat Pay"
];

// 工具函数：判断字符串是否包含关键词
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

// --- 新语法写法 ---
// 替换 %hook UIAlertController 为 [LC] 格式
@interface UIAlertController ()
// 如果需要访问私有属性可以在这里声明，这里暂时不需要
@end

// 使用 __attribute__((constructor)) 替代 %hook
__attribute__((constructor))
static void initialize() {
    // 这里可以做初始化日志
    NSLog(@"[BlockPopup] 🚀 Loaded and running (New Syntax)");
}

// Hook UIAlertController
%subclass(UIAlertController : UIViewController)

// 重写 viewWillAppear:
%new
- (void)blockpopup_viewWillAppear:(BOOL)animated {
    %orig;
    
    if (self.preferredStyle != UIAlertControllerStyleAlert) {
        return;
    }

    BOOL shouldBlock = NO;
    if (ContainsBlockKeyword(self.title)) shouldBlock = YES;
    if (!shouldBlock && ContainsBlockKeyword(self.message)) shouldBlock = YES;

    // 检查按钮
    if (!shouldBlock) {
        for (UIAlertAction *action in self.actions) {
            if (ContainsBlockKeyword(action.title)) {
                shouldBlock = YES;
                break;
            }
        }
    }

    if (shouldBlock) {
        NSLog(@"[BlockPopup] 🚫 已拦截恶意弹窗: %@", self.title ?: self.message);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:NO completion:nil];
        });
    }
}

%end

// --- 针对 UIAlertView 的旧式弹窗 ---
%subclass(UIAlertView : UIView)

%new
- (void)blockpopup_show {
    BOOL shouldBlock = NO;
    if (ContainsBlockKeyword(self.title) || ContainsBlockKeyword(self.message)) {
        shouldBlock = YES;
    }
    
    for (int i = 0; i < self.numberOfButtons; i++) {
        if (ContainsBlockKeyword([self buttonTitleAtIndex:i])) {
            shouldBlock = YES;
            break;
        }
    }

    if (shouldBlock) {
        NSLog(@"[BlockPopup] 🚫 已拦截老式弹窗: %@", self.title);
        return;
    }
    %orig;
}

%end
