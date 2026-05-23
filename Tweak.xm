#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ==========================================
// 核心配置区：插件弹窗特征词
// 把你截图里出现的所有烦人字眼都加在这里
// ==========================================
static NSArray *kBlockKeywords = @[
    // 截图1 & 4 特征词
    @"请注意", @"盗版", @"正版下载", @"停止使用", @"封号",
    // 截图2 特征词
    @"续费提醒", @"授权即将到期", @"朕知道了", @"2440841046",
    // 截图3 特征词
    @"输入授权码", @"微信号与授权码绑定", @"重新购买",
    // 截图4 特征词
    @"授权已到期", @"立即申请",
    // 通用特征词
    @"激活", @"授权", @"激活码", @"注册", @"正版", @"正版验证",
    @"请注意", @"微密友", @"盗版", @"更新", @"卡密",
    @"插件", @"license", @"activation", @"key", @"破解",
    @"警告", @"提示", @"试用", @"购买", @"续费", @"过期",
    @"捐赠", @"赞助", @"PayPal", @"Alipay", @"WeChat Pay",
    @"售后", @"联系QQ", @"输入密码",@"联系",
    // 针对最新截图补充的词
    @"充值", @"请输入充值", @"确认充值", @"复制我的授权码", @"蜘蛛密友"
    @"激活", @"卡密", @"微密友", @"蜘蛛密友", @"授权码",
    @"充值", @"购买", @"赞助", @"捐赠", @"试用", @"过期"
];

// ==========================================
// 核心逻辑：在弹窗创建阶段直接拦截 (alloc hook)
// 这样弹窗根本不会显示，彻底解决“闪一下”的问题
// ==========================================

%hook UIAlertController

// 拦截 alloc 方法
+ (instancetype)alloc {
    // 获取调用堆栈，判断是谁在尝试弹窗
    // 注意：这里我们主要检查即将初始化的内容，但在 alloc 阶段很难直接拿到 title/message
    // 所以我们需要配合 init 方法进行双重保险
    return %orig;
}

// 拦截初始化方法，这时候已经有标题和内容了
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle {
    NSString *checkString = [NSString stringWithFormat:@"%@%@", title, message];

    // 遍历黑名单关键词
    for (NSString *keyword in kBlockKeywords) {
        if ([checkString containsString:keyword]) {
            // 🛑 发现匹配！直接返回 nil，让弹窗“胎死腹中”
            NSLog(@"[Tweak] 拦截到插件弹窗: %@", keyword);
            return nil;
        }
    }

    // ✅ 没发现关键词，放行，正常显示微信原生弹窗
    return %orig;
}

%end

// ==========================================
// 额外保险：防止某些老旧插件直接调用 UIAlertView
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
