# SafariPlus
Various enhancements to Safari

## Features

### Privacy
- Force HTTPS (+ configurable exception sites)

- Locked Tabs - Adds a lock switch to every tab inside the tab switcher that, when enabled, prevents the specific tab from being closed until the switch is disabled again

- Biometric Protection - Require TouchID / FaceID verification for switching browsing modes, locking tabs, unlocking tabs or accessing locked tabs

### Uploads & Downloads
- Upload Any File - An additional option to the document sheet that can be used to upload any file on your root file system

- Download Manager - Extensive enhancements to the downloading functionality of Safari, check the preference page for more detailed info

### Usability
- Both Link Opening Options - Have both the "Open in Background" option and the "Open in New Tab" option available alongside each other

- Open in Opposite Mode Option - Adds an option to open a long pressed URL in the respective other browsing mode

- Desktop Mode Switch - A switch inside the tab switcher that can be used to toggle desktop mode on / off globally

- Tab Manager - An easy way to batch-export, batch-close, and batch-add tabs

- Disable Tab Limit - Disables the default tab limit (varies between devices)

- Always Open Links in New Tab (+ Option to always open in background)

- Disable tab Swiping (Only available on iOS 12 and up)

- Fully Disable Private Browsing

- Insert Suggestion on Long Press - Insert a search suggestion into the URL bar by long pressing it

- Suggestion Insert Button - Insert a search suggestion into the URL bar by pressing a button on the right of it

- Show Tab Count - Shows the tab count on the button that opens the tab switcher

- Fullscreen Scrolling - Hide the top bar when scrolling down

- Lock Bars - Lock the top and buttom bar into place while scrolling

- Show Full Site URL - Always show the full URL in the top bar

- Suppress Mailto Dialog (on iOS 10 and above)

### Actions
- Change Browsing Mode on App Start, App Resume, and when an External Link is Opened

- Auto Close Tabs when Safari is Minimized or Closed

- Auto-Clear Browser Data hen Safari is Minimized or Closed

### Gestures
- URL Bar Swipe Left, Right, and Down Gestures

- Toolbar Swipe Left, Right, and Up / Down Gestures

- Many available actions to trigger

### Customization
- Color Settings for the Top Toolbar, Bottom Toolbar and the Tab Switcher for both normal and private browsing modes

- Change the button order of the Top and Bottom Toolbars and add additional buttons

- Custom Start Site - Change the default favorites view when opening a new tab to a specified URL

- Custom Start Engine - Change the search engine of Safari to any URL

- Custom User Agent - Change the user agent for both mobile and desktop mode

## Compatibilty
Any iOS device running iOS versions 8.0 to 14.8.1 should be supported!

## Compiling

You will need the following libraries / frameworks in order to compile Safari Plus:

- [Cephei](https://hbang.github.io/libcephei/)

- [libCSColorPicker](https://github.com/CreatureSurvive/libCSColorPicker)

- [RocketBootstrap](https://github.com/rpetrich/RocketBootstrap/)

To compile the WebContent part of Safari Plus, slightly patched WebKit headers are needed. Running the `get_webkit.sh` script will download and patch them automatically.

There are also some variables you can set when running make:

`SIMJECT=1` to compile Safari Plus for an iOS simulator

`ROOTLESS=1` to compile Safari Plus for rootless jailbreaks

`NO_LIBCOLORPICKER=1` to compile Safari Plus without the Alderis/libCSColorPicker dependecy (color settings will be disabled if this flag is set)

`NO_DEPENDENCIES=1` to compile Safari Plus with all of the above NO_* flags set 

`DEBUG_LOGGING=1` to compile a version of Safari Plus that produces some very verbose debug logs related to the Download Manager feature that are stored inside sandbox container/Documents/Logs

## Localization
If you wish to help with localizing the tweak, take the english template from [here](https://github.com/opa334/SafariPlus/blob/master/layout/Library/Application%20Support/SafariPlus.bundle/en.lproj/Localizable.strings) and contact me somewhere with the localized file.
