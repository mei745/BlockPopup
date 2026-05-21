#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ==========================================
// 配置区域：关键词
// ==========================================
static NSArray *kBlockKeywords = @[
    @"激活", @"授权", @"激活码", @"注册", @"正版", @"正版验证",
    @"请注意", @"微密友", @"盗版", @"更新", @"卡密",
    @"插件", @"license", @"activation", @"key", @"破解",
    @"警告", @"提示", @"试用", @"购买", @"续费", @"过期",
    @"捐赠", @"赞助", @"PayPal", @"Alipay", @"WeChat Pay",
    @"封号", @"停止使用" // 增加了截图里的关键词
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

// ==========================================
// 核心逻辑：永久屏蔽记录 (UserDefaults)
// ==========================================
static BOOL HasUserConfirmedBlock() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"Mei745_PermanentBlockEnabled"];
}

static void MarkUserConfirmedBlock() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"Mei745_PermanentBlockEnabled"];
    [defaults synchronize];
}

// ==========================================
// 拦截目标 1：微信原生视图 (针对截图这种弹窗)
// 这种弹窗通常不是 UIAlertController，而是微信自定义的 View
// 类名通常是 WCPayErrorSheet 或类似的
// ==========================================
%hook UIView // 我们 Hook 基类 UIView 的显示方法，或者针对特定类

// 很多微信弹窗是通过 addSubview 添加进来的，或者是 present
// 这里我们尝试 Hook 一个常见的显示时机
- (void)layoutSubviews {
    %orig;

    // 如果已经开启了永久屏蔽，直接不执行下面的检查，节省性能
    if (HasUserConfirmedBlock()) {
        return;
    }

    // 检查类名，WCPayErrorSheet 是微信常见的警告弹窗类
    // 也可以用 description 包含关键词来判断
    NSString *className = NSStringFromClass([self class]);

    if ([className containsString:@"Sheet"] || [className containsString:@"Dialog"]) {
        // 如果是微信的弹窗视图，尝试获取它的标题或文本（如果有的话）
        // 这里简单粗暴：如果类名包含 Sheet 且 界面上有“盗版”字样，直接隐藏

        // 简单的防御：如果这个 View 的层级里包含了我们要屏蔽的文字
        // 注意：这种方法比较重，只建议作为最后手段
        // 这里我们用更精准的方法：Hook 它的 show 方法（见下文 %hook WCPayErrorSheet）
    }
}

%end

// 针对微信特定的错误页/弹窗类进行 Hook (这是解决截图问题的关键)
%hook WCPayErrorSheet // 或者是 WCCashierErrorSheet，微信版本不同可能不同

// 拦截它的呈现方法
- (void)presentFromViewController:(id)arg1 animated:(BOOL)arg2 completion:(id)arg3 {
    if (HasUserConfirmedBlock()) {
        NSLog(@"[BlockPopup] 🛡️ 永久屏蔽模式开启：拦截 WCPayErrorSheet");
        return; // 直接不显示
    }

    // 检查内容（如果能获取到的话，通常这种类有 _errorLabel 或类似属性）
    // 如果不确定具体属性，我们先根据类名直接拦截，或者通过标记位拦截

    // 既然我们要屏蔽“盗版/请注意”，一旦检测到这个类出现，大概率就是它
    // 为了保险，我们可以先让它显示一次，记录下来，以后就不显示了

    BOOL shouldBlock = NO;

    // 这里可以加更细致的判断，比如检查内部 label 的文字
    // 但通常这种类一出现就是坏事，直接拦截比较干脆
    shouldBlock = YES;

    if (shouldBlock) {
        NSLog(@"[BlockPopup] 🚫 拦截到微信原生警告页: WCPayErrorSheet");

        // 标记为已屏蔽
        MarkUserConfirmedBlock();

        // 不调用 %orig，直接吞掉这个弹窗
        return;
    }

    %orig;
}

%end

// ==========================================
// 拦截目标 2：标准 UIAlertController (通用弹窗)
// ==========================================
%hook UIAlertController

- (void)viewWillAppear:(BOOL)animated {
    %orig;

    if (HasUserConfirmedBlock()) {
        return; // 既然已经永久屏蔽了，就不用再检查文字了
    }

    if (self.preferredStyle != UIAlertControllerStyleAlert) {
        return;
    }

    BOOL shouldBlock = NO;

    if (ContainsBlockKeyword(self.title) || ContainsBlockKeyword(self.message)) {
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

    if (shouldBlock) {
        NSLog(@"[BlockPopup] 🚫 拦截到标准弹窗: %@", self.title ?: self.message);

        // 标记：只要拦截过一次，以后就不再弹任何类似的（或者你可以只标记特定关键词）
        // 为了安全，我们只在拦截到特定关键词时标记
        if (ContainsBlockKeyword(self.title) || ContainsBlockKeyword(self.message)) {
             MarkUserConfirmedBlock();
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:NO completion:nil];
        });
    }
}

%end

// ==========================================
// 拦截目标 3：老式 UIAlertView
// ==========================================
%hook UIAlertView

- (void)show {
    if (HasUserConfirmedBlock()) {
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
        NSLog(@"[BlockPopup] 🚫 拦截到老式弹窗: %@", self.title);
        MarkUserConfirmedBlock();
        return;
    }

    %orig;
}

%end
