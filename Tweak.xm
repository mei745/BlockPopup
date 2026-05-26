#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ==========================================
// 配置区域：关键词库
// ==========================================
static NSArray *kBlockKeywords = @[
    @"激活", @"授权", @"激活码", @"注册", @"正版", @"正版验证",
    @"注意", @"微密友", @"盗版", @"更新", @"卡密",
    @"插件", @"license", @"activation", @"key", @"破解",
    @"警告", @"提示", @"试用", @"购买", @"续费", @"过期",
    @"捐赠", @"赞助", @"PayPal", @"Alipay", @"WeChat Pay",
    // 补充你截图里的词
    @"售后", @"请输入您的授权", @"朕知道了", @"2440841046"
];

// 工具函数：判断是否包含关键词
static BOOL ContainsBlockKeyword(NSString *text) {
    if (!text || text.length == 0) return NO;
    NSString *lowerText = [text lowercaseString];
    for (NSString *keyword in kBlockKeywords) {
        if ([lowerText containsString:[keyword lowercaseString]]) {
            return YES;
        }
    }
    return NO;
}

// ==========================================
// 第一层拦截：UIAlertController (现代弹窗)
// 核心策略：在 init 阶段直接杀掉，速度最快
// ==========================================
%hook UIAlertController

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle {

    // 1. 检查标题和内容
    BOOL shouldBlock = NO;
    if (ContainsBlockKeyword(title) || ContainsBlockKeyword(message)) {
        shouldBlock = YES;
    }

    // 2. 如果命中关键词，直接返回 nil (不创建对象)
    if (shouldBlock) {
        NSLog(@"[BlockPopup] 🚀 极速拦截 (Init阶段): %@", title ?: message);
        return nil;
    }

    // 3. 没命中，正常创建
    return %orig;
}

// 补漏：防止某些奇葩写法绕过了 init
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    // 如果漏网之鱼到了这一步，依然检查并关闭
    if (self.preferredStyle == UIAlertControllerStyleAlert) {
        if (ContainsBlockKeyword(self.title) || ContainsBlockKeyword(self.message)) {
             [self dismissViewControllerAnimated:NO completion:nil];
        }
    }
}

%end

// ==========================================
// 第二层拦截：UIAlertView (老式弹窗)
// 核心策略：拦截 show 方法，不让它显示
// ==========================================
%hook UIAlertView

- (void)show {
    BOOL shouldBlock = NO;

    // 检查标题、内容、按钮文字
    if (ContainsBlockKeyword(self.title) || ContainsBlockKeyword(self.message)) {
        shouldBlock = YES;
    } else {
        for (int i = 0; i < self.numberOfButtons; i++) {
            if (ContainsBlockKeyword([self buttonTitleAtIndex:i])) {
                shouldBlock = YES;
                break;
            }
        }
    }

    if (shouldBlock) {
        NSLog(@"[BlockPopup] 🚀 极速拦截 (UIAlertView): %@", self.title);
        return; // 直接 return，不调用 %orig，弹窗就不会出来
    }

    %orig;
}

%end
