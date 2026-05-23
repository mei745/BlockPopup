#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ==========================================
// 暴力模式：只要标题或内容不为空，一律拦截
// 如果你想保留极少数微信弹窗，请看下面的“微调区”
// ==========================================

%hook UIAlertController

// 拦截所有试图显示标题和内容的弹窗
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle {
    
    // --- 微调区：如果你想保留微信自带的某些提示，可以在这里加例外 ---
    // 比如：如果标题是空，或者标题包含“微信”，就放行（通常微信系统提示比较克制）
    // 但根据你的情况，建议直接全部杀掉，所以这里不做例外处理。
    
    // 如果标题或内容有字，直接返回 nil（不让弹窗出生）
    if ((title && title.length > 0) || (message && message.length > 0)) {
        // 这里可以加一行日志方便调试，但在暴力模式下，我们直接杀
        // NSLog(@"[暴力拦截] 拦截了一个弹窗: %@", title);
        return nil; 
    }

    // 如果啥都没有（纯空弹窗），放行（极少情况）
    return %orig;
}

%end

// ==========================================
// 第二道防线：拦截古老弹窗 (UIAlertView)
// 很多插件弹窗卡死就是因为这个旧接口
// ==========================================
%hook UIAlertView

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {
    // 只要有标题或内容，直接杀掉
    if ((title && title.length > 0) || (message && message.length > 0)) {
        NSLog(@"[暴力拦截] 拦截了一个古老弹窗: %@", title);
        return nil;
    }
    return %orig;
}

// 额外拦截 show 方法，防止有些弹窗已经创建好了试图强弹
- (void)show {
    // 直接不调用 %orig，让它静默失效
    NSLog(@"[暴力拦截] 阻止了一个古老弹窗的显示动作");
    return; 
}

%end
