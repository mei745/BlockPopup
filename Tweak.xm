#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// 【关键步骤】引入刚才下载的头文件
// 这样编译器就知道 SCLAlertView 是什么了
#import "SCLAlertView.h"

// ==========================================
// 核心配置：特征词库 (根据需求自行增删)
// ==========================================
static NSArray *kBlockKeywords = @[
    @"激活", @"授权", @"激活码", @"注册", @"正版", @"正版验证",
    @"注意", @"微密友", @"盗版", @"更新", @"卡密",
    @"插件", @"license", @"activation", @"key", @"破解",
    @"警告", @"提示", @"试用", @"购买", @"续费", @"过期",
    @"捐赠", @"赞助", @"PayPal", @"Alipay", @"WeChat Pay",
    @"售后", @"请输入您的授权", @"朕知道了", @"2440841046"
];

// ==========================================
// 工具函数：关键词匹配
// ==========================================
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
// 拦截策略 1：针对 SCLAlertView (第三方自定义弹窗)
// ==========================================
%hook SCLAlertView

// 拦截 show 方法：这是弹窗显示的必经之路
- (SCLAlertViewResponder *)showTitle:(NSString *)title subTitle:(NSString *)subTitle {
    // 检查标题或内容是否包含敏感词
    if (ContainsBlockKeyword(title) || ContainsBlockKeyword(subTitle)) {
        NSLog(@"[BlockPopup] 🚫 拦截 SCLAlertView: %@", title);
        // 不调用 %orig，直接返回 nil，弹窗就不会出现
        return nil;
    }
    return %orig;
}

// 补漏：拦截其他可能的 show 方法
- (SCLAlertViewResponder *)showSuccess:(NSString *)title subTitle:(NSString *)subTitle {
    if (ContainsBlockKeyword(title) || ContainsBlockKeyword(subTitle)) return nil;
    return %orig;
}

- (SCLAlertViewResponder *)showError:(NSString *)title subTitle:(NSString *)subTitle {
    if (ContainsBlockKeyword(title) || ContainsBlockKeyword(subTitle)) return nil;
    return %orig;
}

- (SCLAlertViewResponder *)showNotice:(NSString *)title subTitle:(NSString *)subTitle {
    if (ContainsBlockKeyword(title) || ContainsBlockKeyword(subTitle)) return nil;
    return %orig;
}

- (SCLAlertViewResponder *)showWarning:(NSString *)title subTitle:(NSString *)subTitle {
    if (ContainsBlockKeyword(title) || ContainsBlockKeyword(subTitle)) return nil;
    return %orig;
}

- (SCLAlertViewResponder *)showInfo:(NSString *)title subTitle:(NSString *)subTitle {
    if (ContainsBlockKeyword(title) || ContainsBlockKeyword(subTitle)) return nil;
    return %orig;
}

- (SCLAlertViewResponder *)showEdit:(NSString *)title subTitle:(NSString *)subTitle {
    if (ContainsBlockKeyword(title) || ContainsBlockKeyword(subTitle)) return nil;
    return %orig;
}

- (SCLAlertViewResponder *)showCustom:(NSString *)title subTitle:(NSString *)subTitle image:(UIImage *)image color:(UIColor *)color {
    if (ContainsBlockKeyword(title) || ContainsBlockKeyword(subTitle)) return nil;
    return %orig;
}

%end

// ==========================================
// 拦截策略 2：针对系统原生 UIAlertController
// ==========================================
%hook UIAlertController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    // 再次检查，防止漏网
    if (ContainsBlockKeyword(self.title) || ContainsBlockKeyword(self.message)) {
        NSLog(@"[BlockPopup] 🚫 拦截系统弹窗: %@", self.title);
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

%end

// ==========================================
// 拦截策略 3：针对老式 UIAlertView
// ==========================================
%hook UIAlertView

- (void)show {
    if (ContainsBlockKeyword(self.title) || ContainsBlockKeyword(self.message)) {
        NSLog(@"[BlockPopup] 🚫 拦截老式弹窗: %@", self.title);
        return; // 不执行 %orig，直接不显示
    }
    %orig;
}

%end
