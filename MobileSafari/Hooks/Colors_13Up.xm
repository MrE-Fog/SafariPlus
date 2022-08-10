// Copyright (c) 2017-2022 Lars Fröder

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import "../SafariPlus.h"

#import <libundirect/libundirect_dynamic.h>
#import <libundirect/libundirect_hookoverwrite.h>

#import "../Defines.h"
#import "../Util.h"
#import "../Classes/SPPreferenceManager.h"
#import "../../Shared/ColorPickerCompat.h"

#import <dlfcn.h>

@interface SPCustomBlurEffect : UIBlurEffect
@property(nonatomic) _UIBackdropViewSettings* customSettings;
@end

@implementation SPCustomBlurEffect
- (_UIBackdropViewSettings*)effectSettings
{
	return self.customSettings;
}
@end

BOOL (*_SFIsPrivateTintStyle)(NSUInteger tintStyle);

@interface UIBlurEffect ()
+ (instancetype)_effectWithTintColor:(id)arg1;
@end

@interface _UIVisualEffectContentView
@property (nonatomic,copy) NSArray * viewEffects;
@end

@interface UIVisualEffectView ()
@property (nonatomic,copy) NSArray * backgroundEffects;
@property (nonatomic,copy) NSArray * contentEffects;
@end

@interface UIToolbar ()
@property (nonatomic,copy) NSArray * backgroundEffects;
@end

%hook _SFBarTheme

// stock bug: when theme has private tint, _preferredControlsTintColor is not correctly copied
// this hook fixes that
+ (instancetype)themeWithTheme:(__kindof _SFBarTheme*)theme
{
	__kindof _SFBarTheme* themeCopy = %orig;

	if(preferenceManager.topBarNormalLightTintColorEnabled || preferenceManager.topBarNormalDarkTintColorEnabled ||
		preferenceManager.topBarPrivateLightTintColorEnabled || preferenceManager.topBarPrivateDarkTintColorEnabled ||
		preferenceManager.bottomBarNormalLightTintColorEnabled || preferenceManager.bottomBarNormalDarkTintColorEnabled ||
		preferenceManager.bottomBarPrivateLightTintColorEnabled || preferenceManager.bottomBarPrivateDarkTintColorEnabled)
	{
		UIColor* origPreferredControlsTintColor = [theme valueForKey:@"_preferredControlsTintColor"];
		UIColor* copyPreferredControlsTintColor = [themeCopy valueForKey:@"_preferredControlsTintColor"];

		if(![origPreferredControlsTintColor isEqual:copyPreferredControlsTintColor])
		{
			[themeCopy setValue:origPreferredControlsTintColor forKey:@"_preferredControlsTintColor"];
		}

		UIColor* origControlsTintColor = [theme valueForKey:@"_controlsTintColor"];
		UIColor* copyControlsTintColor = [themeCopy valueForKey:@"_controlsTintColor"];

		if(![origControlsTintColor isEqual:copyControlsTintColor])
		{
			[themeCopy setValue:origControlsTintColor forKey:@"_controlsTintColor"];
		}
	}

	return themeCopy;
}

%end

%hook _SFNavigationBar

// setTheme:
// gets dark mode state from userInterfaceStyle
// if passed theme is nil, creates new theme via +[_SFBarTheme themeWithBarTintStyle:]
// if not equal to theme ivar, it sets the ivar to new theme and calls _updateEffectiveTheme

// _updateEffectiveTheme:
// creates _SFNavigationBarTheme from ivar theme
// checks if the theme should be overwritten for security warning, in that case fallbackTheme is used
// if not, it checks if effectiveTheme ivar and newly created theme are not equal
// in that case, it stores the newly created theme in effectiveTheme ivar and calls _didUpdateEffectiveTheme

// setHasToolbar:
// gets current theme from effectiveTheme ivar
// applies it to the toolbar it creates

- (void)setTheme:(_SFBarTheme*)theme
{
	if(preferenceManager.topBarNormalLightTintColorEnabled || preferenceManager.topBarNormalDarkTintColorEnabled ||
		preferenceManager.topBarPrivateLightTintColorEnabled || preferenceManager.topBarPrivateDarkTintColorEnabled)
	{
		BOOL isPrivateMode = _SFIsPrivateTintStyle(theme.tintStyle);
		BOOL isDarkMode = UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
		_SFBarTheme* themeToApply;
		if(theme)
		{
			themeToApply = [%c(_SFBarTheme) themeWithTheme:theme];
		}
		else
		{
			//fall back to default theme
			themeToApply = [%c(_SFBarTheme) themeWithBarTintStyle:isDarkMode];
		}

		UIColor* tintColorToSet;

		if(preferenceManager.topBarNormalLightTintColorEnabled && !isPrivateMode && !isDarkMode)
		{
			tintColorToSet = colorFromHex(preferenceManager.topBarNormalLightTintColor);
		}
		else if(preferenceManager.topBarNormalDarkTintColorEnabled && !isPrivateMode && isDarkMode)
		{
			tintColorToSet = colorFromHex(preferenceManager.topBarNormalDarkTintColor);
		}
		else if(preferenceManager.topBarPrivateLightTintColorEnabled && isPrivateMode && !isDarkMode)
		{
			tintColorToSet = colorFromHex(preferenceManager.topBarPrivateLightTintColor);
		}
		else if(preferenceManager.topBarPrivateDarkTintColorEnabled && isPrivateMode && isDarkMode)
		{
			tintColorToSet = colorFromHex(preferenceManager.topBarPrivateDarkTintColor);
		}

		if(tintColorToSet)
		{
			[themeToApply setValue:tintColorToSet forKey:@"_preferredControlsTintColor"];
			[themeToApply setValue:tintColorToSet forKey:@"_controlsTintColor"];
		}

		%orig(themeToApply);
		return;
	}

	%orig;
}

- (void)_didUpdateEffectiveTheme
{
	if(preferenceManager.topBarNormalLightURLFontColorEnabled || preferenceManager.topBarNormalDarkURLFontColorEnabled ||
		preferenceManager.topBarPrivateLightURLFontColorEnabled || preferenceManager.topBarPrivateDarkURLFontColorEnabled ||
		preferenceManager.topBarNormalLightProgressBarColorEnabled || preferenceManager.topBarNormalDarkProgressBarColorEnabled ||
		preferenceManager.topBarPrivateLightProgressBarColorEnabled || preferenceManager.topBarPrivateDarkProgressBarColorEnabled)
	{
		BOOL isPrivateMode = _SFIsPrivateTintStyle(self.effectiveTheme.tintStyle);
		BOOL isDarkMode = UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;

		UIColor* URLColorToSet;

		if(preferenceManager.topBarNormalLightURLFontColorEnabled && !isPrivateMode && !isDarkMode)
		{
			URLColorToSet = colorFromHex(preferenceManager.topBarNormalLightURLFontColor);
		}
		else if(preferenceManager.topBarNormalDarkURLFontColorEnabled && !isPrivateMode && isDarkMode)
		{
			URLColorToSet = colorFromHex(preferenceManager.topBarNormalDarkURLFontColor);
		}
		else if(preferenceManager.topBarPrivateLightURLFontColorEnabled && isPrivateMode && !isDarkMode)
		{
			URLColorToSet = colorFromHex(preferenceManager.topBarPrivateLightURLFontColor);
		}
		else if(preferenceManager.topBarPrivateDarkURLFontColorEnabled && isPrivateMode && isDarkMode)
		{
			URLColorToSet = colorFromHex(preferenceManager.topBarPrivateDarkURLFontColor);
		}

		if(URLColorToSet)
		{
			[self.effectiveTheme setValue:URLColorToSet forKey:@"_textColor"];
			[self.effectiveTheme setValue:URLColorToSet forKey:@"_secureTextColor"];
			[self.effectiveTheme setValue:URLColorToSet forKey:@"_warningTextColor"];
			[self.effectiveTheme setValue:URLColorToSet forKey:@"_platterTextColor"];
			[self.effectiveTheme setValue:URLColorToSet forKey:@"_platterSecureTextColor"];
			[self.effectiveTheme setValue:URLColorToSet forKey:@"_platterWarningTextColor"];
			[self.effectiveTheme setValue:URLColorToSet forKey:@"_platterAnnotationTextColor"];
			[self.effectiveTheme setValue:[URLColorToSet colorWithAlphaComponent:0.5] forKey:@"_platterPlaceholderTextColor"];
		}

		UIColor* loadingBarColorToSet;

		if(preferenceManager.topBarNormalLightProgressBarColorEnabled && !isPrivateMode && !isDarkMode)
		{
			loadingBarColorToSet = colorFromHex(preferenceManager.topBarNormalLightProgressBarColor);
		}
		else if(preferenceManager.topBarNormalDarkProgressBarColorEnabled && !isPrivateMode && isDarkMode)
		{
			loadingBarColorToSet = colorFromHex(preferenceManager.topBarNormalDarkProgressBarColor);
		}
		else if(preferenceManager.topBarPrivateLightProgressBarColorEnabled && isPrivateMode && !isDarkMode)
		{
			loadingBarColorToSet = colorFromHex(preferenceManager.topBarPrivateLightProgressBarColor);
		}
		else if(preferenceManager.topBarPrivateDarkProgressBarColorEnabled && isPrivateMode && isDarkMode)
		{
			loadingBarColorToSet = colorFromHex(preferenceManager.topBarPrivateDarkProgressBarColor);
		}

		if(loadingBarColorToSet)
		{
			[self.effectiveTheme setValue:loadingBarColorToSet forKey:@"_platterProgressBarTintColor"];
		}
	}

	%orig;

	if(preferenceManager.topBarNormalLightBackgroundColorEnabled || preferenceManager.topBarNormalDarkBackgroundColorEnabled ||
		preferenceManager.topBarPrivateLightBackgroundColorEnabled || preferenceManager.topBarPrivateDarkBackgroundColorEnabled)
	{
		UIVisualEffectView* backdrop = [self valueForKey:@"_backdrop"];

		UIColor* colorToSet;

		BOOL isPrivateMode = _SFIsPrivateTintStyle(self.effectiveTheme.tintStyle);
		BOOL isDarkMode = UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;

		if(preferenceManager.topBarNormalLightBackgroundColorEnabled && !isPrivateMode && !isDarkMode)
		{
			colorToSet = colorFromHex(preferenceManager.topBarNormalLightBackgroundColor);
		}
		else if(preferenceManager.topBarNormalDarkBackgroundColorEnabled && !isPrivateMode && isDarkMode)
		{
			colorToSet = colorFromHex(preferenceManager.topBarNormalDarkBackgroundColor);
		}
		else if(preferenceManager.topBarPrivateLightBackgroundColorEnabled && isPrivateMode && !isDarkMode)
		{
			colorToSet = colorFromHex(preferenceManager.topBarPrivateLightBackgroundColor);
		}
		else if(preferenceManager.topBarPrivateDarkBackgroundColorEnabled && isPrivateMode && isDarkMode)
		{
			colorToSet = colorFromHex(preferenceManager.topBarPrivateDarkBackgroundColor);
		}

		if(colorToSet)
		{
			UIColor* colorTint = [colorToSet colorWithAlphaComponent:1.0];
			CGFloat alpha;
			[colorToSet getRed:nil green:nil blue:nil alpha:&alpha];

			_UIBackdropViewSettings* settings = [[%c(_UIBackdropViewSettingsColored) alloc] init];
			settings.colorTint = colorTint;
			settings.colorTintAlpha = alpha;

			SPCustomBlurEffect* effect = [[%c(SPCustomBlurEffect) alloc] init];
			effect.customSettings = settings;

			backdrop.contentView.backgroundColor = [UIColor clearColor];

			backdrop.backgroundEffects = @[effect];
		}
	}
}

%end

%hook BrowserToolbar

- (void)setTheme:(_SFBarTheme*)theme
{
	BOOL needsManualReload = (theme == self.theme) || [theme isEqual:self.theme];
	_SFBarTheme* themeToApply = theme;

	if(preferenceManager.bottomBarNormalLightTintColorEnabled || preferenceManager.bottomBarNormalDarkTintColorEnabled ||
		preferenceManager.bottomBarPrivateLightTintColorEnabled || preferenceManager.bottomBarPrivateDarkTintColorEnabled)
	{
		themeToApply = [%c(_SFBarTheme) themeWithTheme:theme];

		UIColor* tintColorToSet;

		BOOL isPrivateMode = _SFIsPrivateTintStyle(theme.tintStyle);
		BOOL isDarkMode = UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;

		if(preferenceManager.bottomBarNormalLightTintColorEnabled && !isPrivateMode && !isDarkMode)
		{
			tintColorToSet = colorFromHex(preferenceManager.bottomBarNormalLightTintColor);
		}
		else if(preferenceManager.bottomBarNormalDarkTintColorEnabled && !isPrivateMode && isDarkMode)
		{
			tintColorToSet = colorFromHex(preferenceManager.bottomBarNormalDarkTintColor);
		}
		else if(preferenceManager.bottomBarPrivateLightTintColorEnabled && isPrivateMode && !isDarkMode)
		{
			tintColorToSet = colorFromHex(preferenceManager.bottomBarPrivateLightTintColor);
		}
		else if(preferenceManager.bottomBarPrivateDarkTintColorEnabled && isPrivateMode && isDarkMode)
		{
			tintColorToSet = colorFromHex(preferenceManager.bottomBarPrivateDarkTintColor);
		}

		if(tintColorToSet)
		{
			[themeToApply setValue:tintColorToSet forKey:@"_controlsTintColor"];
		}
	}

	if(needsManualReload)
	{
		if(preferenceManager.bottomBarNormalLightBackgroundColorEnabled || preferenceManager.bottomBarNormalDarkBackgroundColorEnabled ||
		preferenceManager.bottomBarPrivateLightBackgroundColorEnabled || preferenceManager.bottomBarPrivateDarkBackgroundColorEnabled ||
		preferenceManager.tabSwitcherNormalLightToolbarBackgroundColorEnabled || preferenceManager.tabSwitcherNormalDarkToolbarBackgroundColorEnabled ||
		preferenceManager.tabSwitcherPrivateLightToolbarBackgroundColorEnabled || preferenceManager.tabSwitcherPrivateDarkToolbarBackgroundColorEnabled)
		{
			[self _updateBackgroundViewEffects];
		}
	}

	%orig(themeToApply);
}

- (void)_updateBackgroundViewEffects
{
	%orig;

	if(preferenceManager.bottomBarNormalLightBackgroundColorEnabled || preferenceManager.bottomBarNormalDarkBackgroundColorEnabled ||
		preferenceManager.bottomBarPrivateLightBackgroundColorEnabled || preferenceManager.bottomBarPrivateDarkBackgroundColorEnabled ||
		preferenceManager.tabSwitcherNormalLightToolbarBackgroundColorEnabled || preferenceManager.tabSwitcherNormalDarkToolbarBackgroundColorEnabled ||
		preferenceManager.tabSwitcherPrivateLightToolbarBackgroundColorEnabled || preferenceManager.tabSwitcherPrivateDarkToolbarBackgroundColorEnabled)
	{
		//valueForKey returns a UIImageView here???????
		UIVisualEffectView* backgroundView = MSHookIvar<UIVisualEffectView*>(self, "_backgroundView");

		BOOL isPrivateMode = _SFIsPrivateTintStyle(self.theme.tintStyle);
		BOOL isDarkMode = UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
		BOOL isInTabSwitcher = (self.replacementToolbar != nil);

		UIColor* colorToSet;

		if(isInTabSwitcher)
		{
			if(preferenceManager.tabSwitcherNormalLightToolbarBackgroundColorEnabled && !isPrivateMode && !isDarkMode)
			{
				colorToSet = colorFromHex(preferenceManager.tabSwitcherNormalLightToolbarBackgroundColor);
			}
			else if(preferenceManager.tabSwitcherNormalDarkToolbarBackgroundColorEnabled && !isPrivateMode && isDarkMode)
			{
				colorToSet = colorFromHex(preferenceManager.tabSwitcherNormalDarkToolbarBackgroundColor);
			}
			else if(preferenceManager.tabSwitcherPrivateLightToolbarBackgroundColorEnabled && isPrivateMode && !isDarkMode)
			{
				colorToSet = colorFromHex(preferenceManager.tabSwitcherPrivateLightToolbarBackgroundColor);
			}
			else if(preferenceManager.tabSwitcherPrivateDarkToolbarBackgroundColorEnabled && isPrivateMode && isDarkMode)
			{
				colorToSet = colorFromHex(preferenceManager.tabSwitcherPrivateDarkToolbarBackgroundColor);
			}
		}
		else
		{
			if(preferenceManager.bottomBarNormalLightBackgroundColorEnabled && !isPrivateMode && !isDarkMode)
			{
				colorToSet = colorFromHex(preferenceManager.bottomBarNormalLightBackgroundColor);
			}
			else if(preferenceManager.bottomBarNormalDarkBackgroundColorEnabled && !isPrivateMode && isDarkMode)
			{
				colorToSet = colorFromHex(preferenceManager.bottomBarNormalDarkBackgroundColor);
			}
			else if(preferenceManager.bottomBarPrivateLightBackgroundColorEnabled && isPrivateMode && !isDarkMode)
			{
				colorToSet = colorFromHex(preferenceManager.bottomBarPrivateLightBackgroundColor);
			}
			else if(preferenceManager.bottomBarPrivateDarkBackgroundColorEnabled && isPrivateMode && isDarkMode)
			{
				colorToSet = colorFromHex(preferenceManager.bottomBarPrivateDarkBackgroundColor);
			}
		}

		if(colorToSet)
		{
			_UIBackdropViewSettings* settings = [[%c(_UIBackdropViewSettingsColored) alloc] init];
			settings.colorTint = [colorToSet colorWithAlphaComponent:1.0];
			CGFloat alpha;
			[colorToSet getRed:nil green:nil blue:nil alpha:&alpha];
			settings.colorTintAlpha = alpha;

			SPCustomBlurEffect* effect = [[%c(SPCustomBlurEffect) alloc] init];
			effect.customSettings = settings;

			backgroundView.contentView.backgroundColor = [UIColor clearColor];

			backgroundView.backgroundEffects = @[effect];
		}
	}
}

%end

%hook TabBarItemView

- (void)setActive:(BOOL)active
{
	%orig;

	if(preferenceManager.topBarNormalLightTabBarTitleColorEnabled || preferenceManager.topBarNormalDarkTabBarTitleColorEnabled ||
		preferenceManager.topBarPrivateLightTabBarTitleColorEnabled || preferenceManager.topBarPrivateDarkTabBarTitleColorEnabled)
	{
		[UIView performWithoutAnimation:^
		{
			TabBar* tabBar = [self valueForKey:@"_tabBar"];
			BrowserController* bc = [tabBar.delegate valueForKey:@"_browserController"];
			BOOL isPrivateMode = privateBrowsingEnabled(bc);
			BOOL isDarkMode = UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;

			UILabel* titleLabel = [self valueForKey:@"_titleLabel"];

			CGFloat inactiveAlphaToSet = 0;
			UIColor* colorToSet;

			if(preferenceManager.topBarNormalLightTabBarTitleColorEnabled && !isPrivateMode && !isDarkMode)
			{
				inactiveAlphaToSet = preferenceManager.topBarNormalLightTabBarInactiveTitleOpacity;
				colorToSet = colorFromHex(preferenceManager.topBarNormalLightTabBarTitleColor);
			}
			else if(preferenceManager.topBarNormalDarkTabBarTitleColorEnabled && !isPrivateMode && isDarkMode)
			{
				inactiveAlphaToSet = preferenceManager.topBarNormalDarkTabBarInactiveTitleOpacity;
				colorToSet = colorFromHex(preferenceManager.topBarNormalDarkTabBarTitleColor);
			}
			else if(preferenceManager.topBarPrivateLightTabBarTitleColorEnabled && isPrivateMode && !isDarkMode)
			{
				inactiveAlphaToSet = preferenceManager.topBarPrivateLightTabBarInactiveTitleOpacity;
				colorToSet = colorFromHex(preferenceManager.topBarPrivateLightTabBarTitleColor);
			}
			else if(preferenceManager.topBarPrivateDarkTabBarTitleColorEnabled && isPrivateMode && isDarkMode)
			{
				inactiveAlphaToSet = preferenceManager.topBarPrivateDarkTabBarInactiveTitleOpacity;
				colorToSet = colorFromHex(preferenceManager.topBarPrivateDarkTabBarTitleColor);
			}

			UIVisualEffectView* effectView = [self valueForKey:@"_contentEffectsView"];

			if(active && colorToSet)
			{
				CGFloat activeAlphaToSet;
				[colorToSet getRed:nil green:nil blue:nil alpha:&activeAlphaToSet];
				titleLabel.alpha = activeAlphaToSet;
				effectView.effect = nil;
			}
			else if(!active && (inactiveAlphaToSet != 0))
			{
				titleLabel.alpha = inactiveAlphaToSet;
				effectView.effect = nil;
			}
			else
			{
				titleLabel.alpha = 1.0;
			}
		}];
	}	
}

- (void)updateTabBarStyle
{
	%orig;

	if(preferenceManager.topBarNormalLightTabBarTitleColorEnabled || preferenceManager.topBarNormalDarkTabBarTitleColorEnabled ||
		preferenceManager.topBarPrivateLightTabBarTitleColorEnabled || preferenceManager.topBarPrivateDarkTabBarTitleColorEnabled ||
		preferenceManager.topBarNormalLightTabBarCloseButtonColorEnabled || preferenceManager.topBarNormalDarkTabBarCloseButtonColorEnabled ||
		preferenceManager.topBarPrivateLightTabBarCloseButtonColorEnabled || preferenceManager.topBarPrivateDarkTabBarCloseButtonColorEnabled)
	{
		TabBar* tabBar = [self valueForKey:@"_tabBar"];
		BrowserController* bc = [tabBar.delegate valueForKey:@"_browserController"];
		BOOL isPrivateMode = privateBrowsingEnabled(bc);
		BOOL isDarkMode = UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;

		UIColor* textColorToSet;

		if(preferenceManager.topBarNormalLightTabBarTitleColorEnabled && !isPrivateMode && !isDarkMode)
		{
			textColorToSet = colorFromHex(preferenceManager.topBarNormalLightTabBarTitleColor);
		}
		else if(preferenceManager.topBarNormalDarkTabBarTitleColorEnabled && !isPrivateMode && isDarkMode)
		{
			textColorToSet = colorFromHex(preferenceManager.topBarNormalDarkTabBarTitleColor);
		}
		else if(preferenceManager.topBarPrivateLightTabBarTitleColorEnabled && isPrivateMode && !isDarkMode)
		{
			textColorToSet = colorFromHex(preferenceManager.topBarPrivateLightTabBarTitleColor);
		}
		else if(preferenceManager.topBarPrivateDarkTabBarTitleColorEnabled && isPrivateMode && isDarkMode)
		{
			textColorToSet = colorFromHex(preferenceManager.topBarPrivateDarkTabBarTitleColor);
		}

		UIColor* buttonColorToSet;

		if(preferenceManager.topBarNormalLightTabBarCloseButtonColorEnabled && !isPrivateMode && !isDarkMode)
		{
			buttonColorToSet = colorFromHex(preferenceManager.topBarNormalLightTabBarCloseButtonColor);
		}
		else if(preferenceManager.topBarNormalDarkTabBarCloseButtonColorEnabled && !isPrivateMode && isDarkMode)
		{
			buttonColorToSet = colorFromHex(preferenceManager.topBarNormalDarkTabBarCloseButtonColor);
		}
		else if(preferenceManager.topBarPrivateLightTabBarCloseButtonColorEnabled && isPrivateMode && !isDarkMode)
		{
			buttonColorToSet = colorFromHex(preferenceManager.topBarPrivateLightTabBarCloseButtonColor);
		}
		else if(preferenceManager.topBarPrivateDarkTabBarCloseButtonColorEnabled && isPrivateMode && isDarkMode)
		{
			buttonColorToSet = colorFromHex(preferenceManager.topBarPrivateDarkTabBarCloseButtonColor);
		}

		if(textColorToSet)
		{
			UILabel* titleLabel = [self valueForKey:@"_titleLabel"];
			titleLabel.textColor = [textColorToSet colorWithAlphaComponent:1.0];

			if([self respondsToSelector:@selector(barStyle)])
			{
				TabBar* tabBar = [self valueForKey:@"_tabBar"];
				[tabBar.barStyle setValue:textColorToSet forKey:@"_itemTitleColor"];
			}
			else
			{
				self.closeButton.tintColor = textColorToSet;

				if([self respondsToSelector:@selector(lockButton)])
				{
					self.lockButton.tintColor = textColorToSet;
				}
			}			

			UIVisualEffectView* effectView = [self valueForKey:@"_contentEffectsView"];
			effectView.effect = nil;
		}

		if(buttonColorToSet)
		{
			UIVisualEffectView* closeButtonEffectsView = [self valueForKey:@"_closeButtonEffectsView"];
			UIButton* closeButton = [self valueForKey:@"_closeButton"];

			dispatch_async(dispatch_get_main_queue(), ^
			{
        		closeButtonEffectsView.effect = nil;
				closeButton.tintColor = buttonColorToSet;
   			});
		}
	}
}

%end

%hook BrowserRootViewController

- (NSInteger)preferredStatusBarStyle
{
	if(preferenceManager.topBarNormalLightStatusBarStyleEnabled || preferenceManager.topBarNormalDarkStatusBarStyleEnabled || 
		preferenceManager.topBarPrivateLightStatusBarStyleEnabled || preferenceManager.topBarPrivateDarkStatusBarStyleEnabled)
	{
		BrowserController* browserController;

		if([self respondsToSelector:@selector(browserController)])
		{
			browserController = self.browserController;
		}
		else
		{
			browserController = browserControllers().firstObject;
		}

		if(!browserControllerIsShowingTabView(browserController))
		{
			BOOL isPrivateMode = privateBrowsingEnabled(browserController);
			BOOL isDarkMode = UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;

			UIStatusBarStyle styleToSet = 10;

			if(preferenceManager.topBarNormalLightStatusBarStyleEnabled && !isPrivateMode && !isDarkMode)
			{
				styleToSet = preferenceManager.topBarNormalLightStatusBarStyle;
			}
			else if(preferenceManager.topBarNormalDarkStatusBarStyleEnabled && !isPrivateMode && isDarkMode)
			{
				styleToSet = preferenceManager.topBarNormalDarkStatusBarStyle;
			}
			else if(preferenceManager.topBarPrivateLightStatusBarStyleEnabled && isPrivateMode && !isDarkMode)
			{
				styleToSet = preferenceManager.topBarPrivateLightStatusBarStyle;
			}
			else if(preferenceManager.topBarPrivateDarkStatusBarStyleEnabled && isPrivateMode && isDarkMode)
			{
				styleToSet = preferenceManager.topBarPrivateDarkStatusBarStyle;
			}

			if(styleToSet != 10)
			{
				if(styleToSet == UIStatusBarStyleDefault)
				{
					styleToSet = UIStatusBarStyleDarkContent;
				}

				return styleToSet;
			}
		}
	}

	return %orig;
}

%end

%hook TabOverview

%new
- (void)updateHeaderStyle
{
	BrowserController* browserController = [self.delegate valueForKey:@"_browserController"];
	BOOL isPrivateMode = privateBrowsingEnabled(browserController);
	BOOL isDarkMode = UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;

	UIColor* colorToSet;

	if(preferenceManager.tabSwitcherNormalLightToolbarBackgroundColorEnabled && !isPrivateMode && !isDarkMode)
	{
		colorToSet = colorFromHex(preferenceManager.tabSwitcherNormalLightToolbarBackgroundColor);
	}
	else if(preferenceManager.tabSwitcherNormalDarkToolbarBackgroundColorEnabled && !isPrivateMode && isDarkMode)
	{
		colorToSet = colorFromHex(preferenceManager.tabSwitcherNormalDarkToolbarBackgroundColor);
	}
	else if(preferenceManager.tabSwitcherPrivateLightToolbarBackgroundColorEnabled && isPrivateMode && !isDarkMode)
	{
		colorToSet = colorFromHex(preferenceManager.tabSwitcherPrivateLightToolbarBackgroundColor);
	}
	else if(preferenceManager.tabSwitcherPrivateDarkToolbarBackgroundColorEnabled && isPrivateMode && isDarkMode)
	{
		colorToSet = colorFromHex(preferenceManager.tabSwitcherPrivateDarkToolbarBackgroundColor);
	}

	UIVisualEffectView* header = [self valueForKey:@"_header"];

	if(colorToSet)
	{
		_UIBackdropViewSettings* settings = [[%c(_UIBackdropViewSettingsColored) alloc] init];
		settings.colorTint = [colorToSet colorWithAlphaComponent:1.0];
		CGFloat alpha;
		[colorToSet getRed:nil green:nil blue:nil alpha:&alpha];
		settings.colorTintAlpha = alpha;

		SPCustomBlurEffect* effect = [[%c(SPCustomBlurEffect) alloc] init];
		effect.customSettings = settings;

		header.effect = effect;
	}
	else
	{
		header.effect = [UIBlurEffect effectWithStyle:2];
	}
}

- (id)initWithFrame:(CGRect)arg1
{
	self = %orig;

	if(self)
	{
		if(preferenceManager.tabSwitcherNormalLightToolbarBackgroundColorEnabled || preferenceManager.tabSwitcherNormalDarkToolbarBackgroundColorEnabled ||
			preferenceManager.tabSwitcherPrivateLightToolbarBackgroundColorEnabled || preferenceManager.tabSwitcherPrivateDarkToolbarBackgroundColorEnabled)
		{
			[self updateHeaderStyle];
		}
	}

	return self;
}

- (void)traitCollectionDidChange:(id)arg1
{
	%orig;
	if(preferenceManager.tabSwitcherNormalLightToolbarBackgroundColorEnabled || preferenceManager.tabSwitcherNormalDarkToolbarBackgroundColorEnabled ||
		preferenceManager.tabSwitcherPrivateLightToolbarBackgroundColorEnabled || preferenceManager.tabSwitcherPrivateDarkToolbarBackgroundColorEnabled)
	{
		[self updateHeaderStyle];
	}
}

%end

%hook BrowserController

- (void)setPrivateBrowsingEnabled:(BOOL)newPrivateBrowsingState
{
	if(preferenceManager.tabSwitcherNormalLightToolbarBackgroundColorEnabled || preferenceManager.tabSwitcherNormalDarkToolbarBackgroundColorEnabled ||
		preferenceManager.tabSwitcherPrivateLightToolbarBackgroundColorEnabled || preferenceManager.tabSwitcherPrivateDarkToolbarBackgroundColorEnabled)
	{
		BOOL prevEnabled = privateBrowsingEnabled(self);

		if(newPrivateBrowsingState != prevEnabled)
		{
			%orig;
			[self.tabController.tabOverview updateHeaderStyle];
			return;
		}
	}

	%orig;
}

%end

@interface TabThumbnailView ()
@property (nonatomic,weak) TiltedTabView *tiltedTabView;
@end

%hook TabThumbnailView

//Tab Title Color
- (UIColor*)titleColor
{
	if(preferenceManager.tabTitleBarNormalLightTextColorEnabled || preferenceManager.tabTitleBarNormalDarkTextColorEnabled ||
		preferenceManager.tabTitleBarPrivateLightTextColorEnabled || preferenceManager.tabTitleBarPrivateDarkTextColorEnabled)
	{
		TabDocument* td = tabDocumentForTabThumbnailView(self);
		TabController* tc = browserControllerForTabDocument(td).tabController;
		BOOL isPrivateMode = [tc.privateTabDocuments containsObject:td];
		BOOL isDarkMode = self.usesDarkTheme;

		UIColor* colorToUse;

		if(preferenceManager.tabTitleBarNormalLightTextColorEnabled && !isPrivateMode && !isDarkMode)
		{
			colorToUse = colorFromHex(preferenceManager.tabTitleBarNormalLightTextColor);
		}
		else if(preferenceManager.tabTitleBarNormalDarkTextColorEnabled && !isPrivateMode && isDarkMode)
		{
			colorToUse = colorFromHex(preferenceManager.tabTitleBarNormalDarkTextColor);
		}
		else if(preferenceManager.tabTitleBarPrivateLightTextColorEnabled && isPrivateMode && !isDarkMode)
		{
			colorToUse = colorFromHex(preferenceManager.tabTitleBarPrivateLightTextColor);
		}
		else if(preferenceManager.tabTitleBarPrivateDarkTextColorEnabled && isPrivateMode && isDarkMode)
		{
			colorToUse = colorFromHex(preferenceManager.tabTitleBarPrivateDarkTextColor);
		}

		if(colorToUse)
		{
			return colorToUse;
		}
	}

	return %orig;
}

//Tab Background Color
- (UIColor*)headerBackgroundColor
{
	if(preferenceManager.tabTitleBarNormalLightBackgroundColorEnabled || preferenceManager.tabTitleBarNormalDarkBackgroundColorEnabled ||
		preferenceManager.tabTitleBarPrivateLightBackgroundColorEnabled || preferenceManager.tabTitleBarPrivateDarkBackgroundColorEnabled)
	{
		TabDocument* td = tabDocumentForTabThumbnailView(self);
		TabController* tc = browserControllerForTabDocument(td).tabController;
		BOOL isPrivateMode = [tc.privateTabDocuments containsObject:td];
		BOOL isDarkMode = self.usesDarkTheme;

		UIColor* colorToUse;

		if(preferenceManager.tabTitleBarNormalLightBackgroundColorEnabled && !isPrivateMode && !isDarkMode)
		{
			colorToUse = colorFromHex(preferenceManager.tabTitleBarNormalLightBackgroundColor);
		}
		else if(preferenceManager.tabTitleBarNormalDarkBackgroundColorEnabled && !isPrivateMode && isDarkMode)
		{
			colorToUse = colorFromHex(preferenceManager.tabTitleBarNormalDarkBackgroundColor);
		}
		else if(preferenceManager.tabTitleBarPrivateLightBackgroundColorEnabled && isPrivateMode && !isDarkMode)
		{
			colorToUse = colorFromHex(preferenceManager.tabTitleBarPrivateLightBackgroundColor);
		}
		else if(preferenceManager.tabTitleBarPrivateDarkBackgroundColorEnabled && isPrivateMode && isDarkMode)
		{
			colorToUse = colorFromHex(preferenceManager.tabTitleBarPrivateDarkBackgroundColor);
		}

		if(colorToUse)
		{
			return colorToUse;
		}
	}

	return %orig;
}
%end

void initColors_13Up()
{
	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		return;
	}

	void* safariServicesHandle = dlopen("/System/Library/Frameworks/SafariServices.framework/SafariServices", RTLD_NOW);
	_SFIsPrivateTintStyle = (BOOL (*)(NSUInteger))dlsym(safariServicesHandle, "_SFIsPrivateTintStyle");

	%init();
}