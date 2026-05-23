#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ==========================================
// 核心配置区：插件弹窗特征词 (已更新最新截图关键词)
// ==========================================
static NSArray *kBlockKeywords = @[
    // --- 针对最新两张截图的精准打击 ---
    @"售后及续费",    // 截图1标题
    @"授权卡密",      // 截图1输入框提示
    @"激活码不存在",  // 截图2标题
    @"请输入您的授权", // 截图2输入框提示

    // --- 针对之前截图的通用打击 ---
    @"请注意", @"盗版", @"正版下载", @"停止使用", @"封号",
    @"续费提醒", @"授权即将到期", @"朕知道了",
    @"输入授权码", @"微信号与授权码绑定", @"重新购买",
    @"授权已到期", @"立即申请",
    @"激活", @"卡密", @"微密友", @"蜘蛛密友",
    @"充值", @"购买", @"赞助", @"捐赠", @"试用", @"过期"
];

// ==========================================
// 核心逻辑：拦截弹窗创建
// ==========================================

%hook UIAlertController

// 拦截初始化方法
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle {
    // 合并标题和内容进行检查
    NSString *checkString = [NSString stringWithFormat:@"%@%@", title, message];

    // 遍历黑名单
    for (NSString *keyword in kBlockKeywords) {
        if ([checkString containsString:keyword]) {
            // 🛑 发现匹配！直接返回 nil
            NSLog(@"[Tweak] 拦截到插件弹窗: %@", keyword);
            return nil;
        }
    }

    // ✅ 安全，放行
    return %orig;
}

%end

// ==========================================
// 额外保险：拦截旧式弹窗 (UIAlertView)
// ==========================================
%hook UIAlertView

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {
    NSString *checkString = [NSString stringWithFormat:@"%@%@", title, message];

    for (NSString *keyword in kBlockKeywords) {
        if ([checkString containsString:keyword]) {
            NSLog(@"[Tweak] 拦截到旧式插件弹窗: %@", keyword);
            return nil;
        }
    }

    return %orig;
}

%end
