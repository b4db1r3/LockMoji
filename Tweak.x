#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import "rootless.h"

@interface SBUIProudLockIconView : UIView
@property (nonatomic, strong, readwrite) UIColor *contentColor;
@property (assign, nonatomic) long long state;
- (void)setContentColor:(UIColor *)arg1;
- (void)updateSymbolForAuthenticationState;
- (BOOL)isEmoji:(NSString *)symbol;
@end

@interface BSUICAPackageView : UIView
@property (nonatomic, assign, readwrite) CGRect frame;
-(void)setFrame:(CGRect)arg1;
-(void)setBounds:(CGRect)bounds;
@end

#define LockMoji @"/var/jb/var/mobile/Library/Preferences/com.b4db1r3.LockMojiprefs.plist"

static BOOL tweakEnabled = YES;
static NSString *authenticatedSymbol = @"\u2713"; // Default to checkmark
static NSString *unauthenticatedSymbol = @"\u2715"; // Default to X

static void loadPrefs() {
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:LockMoji];
    if (prefs) {
        tweakEnabled = [prefs[@"tweakEnabled"] ?: @(tweakEnabled) boolValue];
        authenticatedSymbol = prefs[@"authenticatedSymbol"] ?: authenticatedSymbol;
        unauthenticatedSymbol = prefs[@"unauthenticatedSymbol"] ?: unauthenticatedSymbol;
    }
}


%hook SBUIProudLockIconView

%new
- (BOOL)isEmoji:(NSString *)symbol {
    const unichar hs = [symbol characterAtIndex:0];
    // Surrogate pair range
    return (0xd800 <= hs && hs <= 0xdbff);
}

%new
- (void)updateSymbolForAuthenticationState {
    UILabel *symbolLabel = (UILabel *)[self viewWithTag:123];
    if (!symbolLabel) {
        symbolLabel = [[UILabel alloc] init]; // Frame will be adjusted below
        symbolLabel.tag = 123;
        symbolLabel.textAlignment = NSTextAlignmentCenter;
        symbolLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:symbolLabel];
    }

    CGFloat xOffset = -2.0;
    CGPoint newCenter = CGPointMake(CGRectGetMidX(self.bounds) + xOffset, CGRectGetMidY(self.bounds));

    BOOL authenticated = self.state == 2;
    NSString *symbolText = authenticated ? authenticatedSymbol : unauthenticatedSymbol;
    symbolLabel.text = symbolText;

   
    if ([self isEmoji:symbolText]) {
        symbolLabel.font = [UIFont systemFontOfSize:14]; // Smaller font for emoji
    } else {
        symbolLabel.font = [UIFont systemFontOfSize:20]; // Larger font for Unicode symbols
    }

    [symbolLabel sizeToFit]; // Resize label 
    symbolLabel.center = newCenter; // Center label  
    symbolLabel.textColor = authenticated ? [UIColor greenColor] : [UIColor redColor];
}



- (void)layoutSubviews {
    %orig;
    
    if (tweakEnabled) {

        UIView *lockView = [self valueForKey:@"_lockView"];
        if (lockView) {
            lockView.hidden = YES;
        }
        
        [self updateSymbolForAuthenticationState];
    }

    else {
        %orig;
    }
}
%end

%ctor {
    loadPrefs();

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, (CFStringRef)@"com.b4db1r3.mojilock16/ReloadPrefs", NULL, (CFNotificationSuspensionBehavior)kNilOptions);
}
