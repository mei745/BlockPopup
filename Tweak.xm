#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ==========================================
// 配置区域：关键词（已扩充，覆盖截图所有文字）
// ==========================================
static NSArray *kBlockKeywords = @[
    // 核心屏蔽词
    @"激活", @"授权", @"激活码", @"注册", @"正版", @"正版验证",
    @"请注意", @"微密友", @"盗版", @"更新", @"卡密",
    @"插件", @"license", @"activation", @"key", @"破解",
    @"警告", @"提示", @"试用", @"购买", @"续费", @"过期",
    @"捐赠", @"赞助", @"PayPal", @"Alipay", @"WeChat Pay",
    @"售后", @"联系QQ", @"输入密码",
    // 针对最新截图补充的词
    @"充值", @"请输入充值", @"确认充值", @"复制我的授权码", @"蜘蛛密友"
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

%hook UIAlertController

// Hook 弹窗显示的方法
- (void)viewWillAppear:(BOOL)animated {
    %orig; // 先调用原方法

    // 只处理 Alert 样式
    if (self.preferredStyle != UIAlertControllerStyleAlert) {
        return;
    }

    BOOL shouldBlock = NO;

    // 1. 检查标题
    if (ContainsBlockKeyword(self.title)) {
        shouldBlock = YES;
    }

    // 2. 检查内容
    if (!shouldBlock && ContainsBlockKeyword(self.message)) {
        shouldBlock = YES;
    }

    // 3. 检查按钮文字
    if (!shouldBlock) {
        for (UIAlertAction *action in self.actions) {
            if (ContainsBlockKeyword(action.title)) {
                shouldBlock = YES;
                break;
            }
        }
    }

    // 4. 【关键修复】检查输入框的占位符文字（针对截图里的“请输入...”）
    if (!shouldBlock && self.textFields.count > 0) {
        UITextField *textField = self.textFields.firstObject;
        if (ContainsBlockKeyword(textField.placeholder)) {
            shouldBlock = YES;
        }
    }

    // 5. 执行拦截
    if (shouldBlock) {
        NSLog(@"[BlockPopup] 🚫 成功拦截: %@", self.title ?: self.message);
        // 延迟关闭，防止崩溃
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:NO completion:nil];
        });
    }
}

%end

// ==========================================
// 针对老式弹窗（如果有的话）
// ==========================================
%hook UIAlertView
- (void)show {
    BOOL shouldBlock = NO;
    if (ContainsBlockKeyword(self.title) || ContainsBlockKeyword(self.message)) {
        shouldBlock = YES;
    }
    if (shouldBlock) {
        NSLog(@"[BlockPopup] 🚫 拦截老式弹窗: %@", self.title);
        return;
    }
    %orig;
}
%end
