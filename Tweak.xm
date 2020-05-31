#include <CSColorPicker/CSColorPicker.h>
#import <Cephei/HBPreferences.h>
#define PLIST_PATH @"/User/Library/Preferences/com.crkatri.eggNotch.plist"

inline NSString *StringForPreferenceKey(NSString *key) {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PLIST_PATH] ? : [NSDictionary new];
    return prefs[key];
}

HBPreferences *preferences;
static BOOL alwaysShow;
static BOOL 

@interface CALayer (Undocumented)
@property (assign) BOOL continuousCorners;
@end

static UIView* coverView(void) {

    // I stole this idea from @LaughingQuoll
    // Thanks tho

    CGRect screenBounds = [UIScreen mainScreen].bounds;

    CGRect frame = CGRectMake(-40.4, -7, screenBounds.size.width + 80.5, screenBounds.size.height+2000); //this is the border which will cover the notch

    UIView *coverView = [[[UIView alloc] initWithFrame:frame] autorelease];
    coverView.layer.borderColor = [UIColor cscp_colorFromHexString:StringForPreferenceKey(@"eggNotchColor")].CGColor;
    coverView.layer.borderWidth = 40.0f;

    [coverView setClipsToBounds:YES];
    [coverView.layer setMasksToBounds:YES];
    coverView.layer.cornerRadius = [[prefs valueForKey:@"eggCornerRadius"] floatValue];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0 && [[[UIDevice currentDevice] systemVersion] floatValue] < 13.0) {
        coverView.layer.continuousCorners = YES;
    } else if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 13.0) {
        coverView.layer.cornerCurve = kCACornerCurveContinuous;
    }

    return coverView;
}

@interface _UIStatusBar : UIView
@property (nonatomic, retain) UIColor *foregroundColor;
@property BOOL didRemoveNotch;
-(void)removeNotch;
@end

@interface SBControlCenterController
+ (id)sharedInstance;
- (UIWindow*)_controlCenterWindow;
@property(readonly, nonatomic, getter=isVisible) _Bool visible;
@end

@interface LayoutContext : NSObject
- (id)layoutState;
@end

@interface SBAppStatusBarSettingsAssertion : NSObject
- (void)invalidate;
- (void)acquire;
-(id)initWithStatusBarHidden:(BOOL)hidden atLevel:(NSUInteger)level reason:(NSString *)reason;
@property (nonatomic,readonly) NSUInteger level; 
@property (nonatomic,copy,readonly) NSString * reason;   
@end

SBAppStatusBarSettingsAssertion *assertion;

// To Do : Add coverView to the control center

%hook _UIStatusBar

%property BOOL didRemoveNotch;

-(void)layoutSubviews {

    %orig;
    if([[prefs objectForKey:@"eggStaticColor"] boolValue]) {
        self.foregroundColor = [UIColor cscp_colorFromHexString:StringForPreferenceKey(@"eggNotchTextColor")];
    }

    if(![[[UIApplication sharedApplication] keyWindow] isKindOfClass:%c(SBControlCenterWindow)] && !self.didRemoveNotch) {
        [self removeNotch];
    }

	if (!assertion && [[prefs objectForKey:@"eggAlwaysShow"] boolValue]) {
		assertion = [[NSClassFromString(@"SBAppStatusBarSettingsAssertion") alloc] initWithStatusBarHidden:NO atLevel:5 reason:@"eggNotch"];
		[assertion acquire];
	}
}

%new
-(void)removeNotch {

    
    // [self setBackgroundColor:[UIColor blackColor]];

    UIView* notchHidingView = coverView();

    [self addSubview: notchHidingView];
    [self sendSubviewToBack: notchHidingView];

    self.didRemoveNotch = YES;

    //[notchHidingView release];
}

//Make the Statusbar slightly smaller

- (void)setFrame:(CGRect)frame {
    frame.size.height = 34;
    %orig(frame);
}
- (CGRect)bounds {
    CGRect frame = %orig;
    frame.size.height = 32;
    return frame;
}
%end

%ctor {
   preferences = [[HBPreferences alloc] initWithIdentifier:@"com.crkatri.eggNotch"];

   [preferences registerBool:&alwaysShow default:NO forKey:@"alwaysShow"];
 } 