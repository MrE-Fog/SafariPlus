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

#import "Util.h"
#import "Classes/SPPreferenceManager.h"
#import "Classes/SPFileManager.h"
#import "Defines.h"
#import <libSandy.h>

// One constructor that inits all hooks

extern void initUndirection();

extern void init_SFDownloadManager();
extern void initApplication();
extern void initAVFullScreenPlaybackControlsViewController();
extern void initAVPlaybackControlsView();
extern void initBookmarkFavoritesActionsView();
extern void initBrowserController();
extern void initBrowserRootViewController();
extern void initBrowserToolbar();
extern void initCatalogViewController();
extern void initColors();
extern void initColors_13Up();
extern void initFeatureManager();
extern void initNavigationBar();
extern void initNavigationBarItem();
extern void initSafariWebView();
extern void initSearchEngineController();
extern void initSFBarRegistration();
extern void initSPTabManagerBookmarkPicker();
extern void initSPMediaFetcher();
extern void initTabItemLayoutInfo();
extern void initTabBarItemView();
extern void initTabController();
extern void initTabDocument();
extern void initTabExposeActionsController();
extern void initTabOverview();
extern void initTabOverviewItemLayoutInfo();
extern void initTabThumbnailView();
extern void initTiltedTabItemLayoutInfo();
extern void initTiltedTabView();
extern void initWKFileUploadPanel();
extern void initWKFullScreenViewController();

%ctor
{
	@autoreleasepool
	{
		HBLogDebugWeak(@"started loading SafariPlus!");

		initUndirection();

		#ifdef DEBUG_LOGGING
		initDebug();
		#endif

		preferenceManager = [SPPreferenceManager sharedInstance];
		fileManager = [SPFileManager sharedInstance];

		if(preferenceManager.tweakEnabled)	//Only initialise hooks if tweak is enabled
		{
			init_SFDownloadManager();
			initApplication();
			initAVFullScreenPlaybackControlsViewController();
			initAVPlaybackControlsView();
			initBookmarkFavoritesActionsView();
			initBrowserController();
			initBrowserRootViewController();
			initBrowserToolbar();
			initCatalogViewController();
			initColors();
			initColors_13Up();
			initFeatureManager();
			initNavigationBar();
			initNavigationBarItem();
			initSafariWebView();
			initSearchEngineController();
			initSFBarRegistration();
			initSPTabManagerBookmarkPicker();
			initSPMediaFetcher();
			initTabItemLayoutInfo();
			initTabBarItemView();
			initTabController();
			initTabDocument();
			initTabExposeActionsController();
			initTabOverview();
			initTabOverviewItemLayoutInfo();
			initTabThumbnailView();
			initTiltedTabItemLayoutInfo();
			initTiltedTabView();
			initWKFileUploadPanel();
			initWKFullScreenViewController();
		}

		HBLogDebugWeak(@"finished loading SafariPlus!");
	}
}
