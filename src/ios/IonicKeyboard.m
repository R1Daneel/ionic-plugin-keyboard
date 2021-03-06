#import "IonicKeyboard.h"
// #import "UIWebViewExtension.h"
#import <Cordova/CDVAvailability.h>

@implementation IonicKeyboard

@synthesize hideKeyboardAccessoryBar = _hideKeyboardAccessoryBar;
@synthesize disableScroll = _disableScroll;
//@synthesize styleDark = _styleDark;

- (void)pluginInitialize {

    Class wkClass = NSClassFromString([@[@"UI", @"Web", @"Browser", @"View"] componentsJoinedByString:@""]);
    wkMethod = class_getInstanceMethod(wkClass, @selector(inputAccessoryView));
    wkOriginalImp = method_getImplementation(wkMethod);
    Class uiClass = NSClassFromString([@[@"WK", @"Content", @"View"] componentsJoinedByString:@""]);
    uiMethod = class_getInstanceMethod(uiClass, @selector(inputAccessoryView));
    uiOriginalImp = method_getImplementation(uiMethod);
    nilImp = imp_implementationWithBlock(^(id _s) {
        return nil;
    });
    
    //set defaults
    self.hideKeyboardAccessoryBar = YES;
    self.disableScroll = NO;
    //self.styleDark = NO;
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    __weak IonicKeyboard* weakSelf = self;
    _keyboardShowObserver = [nc addObserverForName:UIKeyboardWillShowNotification
                               object:nil
                               queue:[NSOperationQueue mainQueue]
                               usingBlock:^(NSNotification* notification) {

                                   CGRect screen = [[UIScreen mainScreen] bounds];
                                   CGRect keyboard = ((NSValue*)notification.userInfo[@"UIKeyboardFrameEndUserInfoKey"]).CGRectValue;
                                   CGRect intersection = CGRectIntersection(screen, keyboard);
                                   CGFloat height = MIN(intersection.size.width, intersection.size.height);

                                   [weakSelf.commandDelegate evalJs:[NSString stringWithFormat:@"cordova.plugins.Keyboard.isVisible = true; cordova.fireWindowEvent('native.keyboardshow', { 'keyboardHeight': %f }); ", height]];

                                   //deprecated
                                   [weakSelf.commandDelegate evalJs:[NSString stringWithFormat:@"cordova.fireWindowEvent('native.showkeyboard', { 'keyboardHeight': %f }); ", height]];
                               }];

    _keyboardHideObserver = [nc addObserverForName:UIKeyboardWillHideNotification
                               object:nil
                               queue:[NSOperationQueue mainQueue]
                               usingBlock:^(NSNotification* notification) {

                                   CGRect screen = [[UIScreen mainScreen] bounds];
                                   CGRect keyboard = ((NSValue*)notification.userInfo[@"UIKeyboardFrameBeginUserInfoKey"]).CGRectValue;
                                   CGRect intersection = CGRectIntersection(screen, keyboard);

                                   /*
                                    * When an hardware keyboard is attached to the device just a toolbar is displayed when an input obtain the focus.
                                    * The toolbar has various buttons and one of this (the down arrow) can be used to dismiss it an blur the input.
                                    * If the keyboard is dismissed in this way the next time that an input obtains the focus the toolbar does not appear
                                    * until that the user starts to type a char in the keyboard. The problem is that when this happen iOS send two consecutive
                                    * UIKeyboardWillHide notifications. The need to be skipped otherwise the input is automatically blurred.
                                    */
                                   if (intersection.size.height > 0) {
                                       [weakSelf.commandDelegate evalJs:@"cordova.plugins.Keyboard.isVisible = false; cordova.fireWindowEvent('native.keyboardhide'); "];

                                       //deprecated
                                       [weakSelf.commandDelegate evalJs:@"cordova.fireWindowEvent('native.hidekeyboard'); "];
                                   }
                               }];
}

- (BOOL)disableScroll {
    return _disableScroll;
}

- (void)setDisableScroll:(BOOL)disableScroll {
    if (disableScroll == _disableScroll) {
        return;
    }
    if (disableScroll) {
        self.webView.scrollView.scrollEnabled = NO;
        self.webView.scrollView.delegate = self;
    }
    else {
        self.webView.scrollView.scrollEnabled = YES;
        self.webView.scrollView.delegate = nil;
    }

    _disableScroll = disableScroll;
}

//keyboard swizzling inspired by:
//https://github.com/cjpearson/cordova-plugin-keyboard/

- (BOOL)hideKeyboardAccessoryBar {
    return _hideKeyboardAccessoryBar;
}

- (void)setHideKeyboardAccessoryBar:(BOOL)hideKeyboardAccessoryBar {
    if (hideKeyboardAccessoryBar == _hideKeyboardAccessoryBar) {
        return;
    }

    if (hideKeyboardAccessoryBar) {
        method_setImplementation(wkMethod, nilImp);
        method_setImplementation(uiMethod, nilImp);
    } else {
        method_setImplementation(wkMethod, wkOriginalImp);
        method_setImplementation(uiMethod, uiOriginalImp);
    }
    
    _hideKeyboardAccessoryBar = hideKeyboardAccessoryBar;
}

/*
- (BOOL)styleDark {
    return _styleDark;
}

- (void)setStyleDark:(BOOL)styleDark {
    if (styleDark == _styleDark) {
        return;
    }
    if (styleDark) {
        self.webView.styleDark = YES;
    }
    else {
        self.webView.styleDark = NO;
    }

    _styleDark = styleDark;
}
*/


/* ------------------------------------------------------------- */

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [scrollView setContentOffset: CGPointZero];
}

/* ------------------------------------------------------------- */

- (void)dealloc {
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

    [nc removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [nc removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

/* ------------------------------------------------------------- */

- (void) disableScroll:(CDVInvokedUrlCommand*)command {
    if (!command.arguments || ![command.arguments count]){
      return;
    }
    id value = [command.arguments objectAtIndex:0];
    if (value != [NSNull null]) {
      self.disableScroll = [value boolValue];
    }
}

- (void) hideKeyboardAccessoryBar:(CDVInvokedUrlCommand*)command {
    if (!command.arguments || ![command.arguments count]){
        return;
    }
    id value = [command.arguments objectAtIndex:0];
    if (value != [NSNull null]) {
        self.hideKeyboardAccessoryBar = [value boolValue];
    }
}

- (void) close:(CDVInvokedUrlCommand*)command {
    [self.webView endEditing:YES];
}

- (void) show:(CDVInvokedUrlCommand*)command {
    NSLog(@"Showing keyboard not supported in iOS due to platform limitations.");
}

/*
- (void) styleDark:(CDVInvokedUrlCommand*)command {
    if (!command.arguments || ![command.arguments count]){
      return;
    }
    id value = [command.arguments objectAtIndex:0];

    self.styleDark = [value boolValue];
}
*/

@end

