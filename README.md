---------------------------------------------------------------------------------
Game Analytics for Corona SDK v.0.2.2
---------------------------------------------------------------------------------

Here you will find the GameAnalytics.lua module you need to copy to your project folder and require to use the GA SDK.
The SampleCode folder contains some examples to get you started.

- For documentation see:  http://support.gameanalytics.com/forums/21747243-Corona-SDK

In order to use Game Analytics you need to sign up for an account and paste the game 
key and secret key you recieve in the initialization fields in the main.lua file.

- Sign up and get your keys here: http://www.gameanalytics.com

---------------------------------------------------------------------------------

New in this version:
v.0.2.2
+ Composer support.

v.0.2.1
+ Batch requests
+ Built in reporting of average fps
+ Built in reporting of critical fps
+ Built in reporting of runtime errors and stack traces
+ Built in reporting of memorywarnings ( iOS only)
+ Storyboard integration: Built in reporting of storyboard scene changes.
+ Optimizations and more.

---------------------------------------------------------------------------------

Notes for Android developers:

- Remember to set android permissions in your build settings:
"android.permission.INTERNET"
"android.permission.ACCESS_NETWORK_STATE",