#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ==========================================
// 配置区域：在这里添加你想屏蔽的关键词
// ==========================================
static NSArray *kBlockKeywords = @[
    @"激活", @"授权", @"激活码", @"注册", @"正版", @"正版验证",
    @"注意", @"微密友", @"盗版", @"更新", @"激活",@"卡密",
    @"插件", @"license", @"activation", @"key", @"破解",
    @"警告", @"提示", @"试用", @"购买", @"续费", @"过期",
    @"捐赠", @"赞助", @"PayPal", @"Alipay", @"WeChat Pay"
];

// 工具函数：判断字符串是否包含关键词
static BOOL ContainsBlockKeyword(NSString *text) {
    if (!text || text.length == 0) return NO;

    // 转小写，提高匹配率
    NSString *lowerText = [text lowercaseString];

    for (NSString *keyword in kBlockKeywords) {
        NSString *lowerKeyword = [keyword lowercaseString];
        if ([lowerText containsString:lowerKeyword]) {
            return YES;
        }
    }
    return NO;
}

%hook UIAlertController

// Hook 弹窗显示的方法
- (void)viewWillAppear:(BOOL)animated {
    %orig; // 先调用原方法，确保对象初始化完成

    // 1. 只处理 Alert 样式，放过底部的 ActionSheet
    if (self.preferredStyle != UIAlertControllerStyleAlert) {
        return;
    }

    // 2. 检查标题和内容
    BOOL shouldBlock = NO;

    if (ContainsBlockKeyword(self.title)) {
        shouldBlock = YES;
    }

    if (!shouldBlock && ContainsBlockKeyword(self.message)) {
        shouldBlock = YES;
    }

    // 3. (进阶) 检查按钮文字
    if (!shouldBlock) {
        for (UIAlertAction *action in self.actions) {
            if (ContainsBlockKeyword(action.title)) {
                shouldBlock = YES;
                break;
            }
        }
    }

    // 4. 执行拦截
    if (shouldBlock) {
        NSLog(@"[BlockPopup] 🚫 已拦截恶意弹窗: %@", self.title ?: self.message);

        // 延迟极短时间关闭，防止界面卡死
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:NO completion:nil];
        });
    }
}

// ==========================================
// 关键修复：
// %new 必须写在 %hook 的大括号内部，且在 %end 之前
// ==========================================
%new
- (void)blockPopup_dismissImmediately {
    [self dismissViewControllerAnimated:NO completion:nil];
}
%end // %hook UIAlertController 结束

// ==========================================
// 额外防御：针对老式 UIAlertView
// ==========================================
%hook UIAlertView

- (void)show {
    BOOL shouldBlock = NO;

    if (ContainsBlockKeyword(self.title) || ContainsBlockKeyword(self.message)) {
        shouldBlock = YES;
    }

    // 检查按钮
    for (int i = 0; i < self.numberOfButtons; i++) {
        if (ContainsBlockKeyword([self buttonTitleAtIndex:i])) {
            shouldBlock = YES;
            break;
        }
    }

    if (shouldBlock) {
        NSLog(@"[BlockPopup] 🚫 已拦截老式弹窗: %@", self.title);
        return; // 直接不调用 %orig，弹窗就不会显示
    }

    %orig;
}

%end
