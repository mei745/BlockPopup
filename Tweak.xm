#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ==========================================
// 配置区域：在这里添加你想屏蔽的关键词
// ==========================================
static NSArray *kBlockKeywords = @[
    @"激活", @"授权", @"激活码", @"注册", @"正版", @"正版验证",
    @"请注意", @"微密友", @"盗版", @"更新", @"卡密",@"正版下载",
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

// ==========================================
// 核心逻辑：拦截 UIAlertController (iOS 8+)
// ==========================================
%hook UIAlertController

- (void)viewWillAppear:(BOOL)animated {
    %orig; // 先调用原方法

    // 1. 检查“永久屏蔽”开关
    // 如果开关是 YES，说明以前拦截过，直接跳过，不再处理
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"Mei745_AlwaysBlockAlert"]) {
        return; // 直接返回，什么都不做
    }

    // 2. 只处理 Alert 样式
    if (self.preferredStyle != UIAlertControllerStyleAlert) {
        return;
    }

    // 3. 检查标题、内容和按钮
    BOOL shouldBlock = NO;

    if (ContainsBlockKeyword(self.title)) {
        shouldBlock = YES;
    }

    if (!shouldBlock && ContainsBlockKeyword(self.message)) {
        shouldBlock = YES;
    }

    if (!shouldBlock) {
        for (UIAlertAction *action in self.actions) {
            if (ContainsBlockKeyword(action.title)) {
                shouldBlock = YES;
                break;
            }
        }
    }

    // 4. 执行拦截与记录
    if (shouldBlock) {
        NSLog(@"[BlockPopup] 🚫 检测到关键词，执行拦截并永久屏蔽！");

        // 【关键步骤】写入记录，下次启动就不会再进这个判断了
        [defaults setBool:YES forKey:@"Mei745_AlwaysBlockAlert"];
        [defaults synchronize]; // 强制保存

        // 关闭弹窗
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:NO completion:nil];
        });
    }
}

%end

// ==========================================
// 核心逻辑：拦截老式 UIAlertView
// ==========================================
%hook UIAlertView

- (void)show {
    // 1. 检查“永久屏蔽”开关
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"Mei745_AlwaysBlockAlert"]) {
        %orig; // 如果开关开了，老式弹窗直接放行（或者你也可以选择 return 直接屏蔽所有）
        return;
    }

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
        NSLog(@"[BlockPopup] 🚫 检测到老式弹窗关键词，拦截并永久屏蔽！");

        // 【关键步骤】写入记录
        [defaults setBool:YES forKey:@"Mei745_AlwaysBlockAlert"];
        [defaults synchronize];

        return; // 直接不调用 %orig，弹窗就不会显示
    }

    %orig;
}

%end
