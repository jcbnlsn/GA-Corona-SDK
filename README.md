---------------------------------------------------------------------------------
Game Analytics for Corona SDK v.2.1
---------------------------------------------------------------------------------

Here you will find the GameAnalytics.lua module you need to copy to your project folder and require to use the GA SDK.
The SampleCode folder contains some examples to get you started.

- For documentation see: http://support.gameanalytics.com/forums/21747243-Corona-SDK

In order to use Game Analytics you need to sign up for an account and paste the game 
key and secret key you recieve in the initialization fields in the main.lua file.

- Sign up and get your keys here: http://www.gameanalytics.com

---------------------------------------------------------------------------------

New in this version:

+ Batch requests
+ Built in reporting of average fps
+ Built in reporting of critical fps
+ Built in reporting of runtime errors and stack traces
+ Built in reporting of memorywarnings ( iOS only)
+ Storyboard integration: Built in reporting of storyboard scene changes.
+ Optimizations and more.

IMPORTANT change from previous version: The GameAnalytics.lua module is no longer global when it's required.
This means you need to require it in every lua module or storyboard scene you wan't to send custom events from.
But you should only initialize it and set it's properties in the projects main.lua file.

Take a look at the storyboard example if you are confused by this!

---------------------------------------------------------------------------------

Notes for Android developers:

- Remember to set: "android.permission.INTERNET" in your build settings.

- Do NOT set: "android.permission.READ_PHONE_STATE" in your build settings.  
it will prevent your app from sending the right Android IDs to our system!
