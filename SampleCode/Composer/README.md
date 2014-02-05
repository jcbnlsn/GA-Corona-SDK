
---------------------------------------------------------------------------------
GameAnalytics for Corona SDK: Composer example 
---------------------------------------------------------------------------------

This is a simple example showing how to use the GameAnalytics SDK with Composer (Corona's built in 
scene management system). When using Composer the GA SDK is context aware and can automatically
submit events for scene changes.

In order to try this example you need to sign up for a GameAnalytics account and paste the game 
key and secret key you recieve in the initialization fields in the main.lua file.

When running this example you should look at the Corona terminal to see what events are being 
sent when going through the 2 Composer scenes.

- The main.lua file shows you how to setup the GA SDK using Composer.

- Scene 1 and 2 shows how the GA SDK automatically submits scene change events to the GA servers
if the GA.submitComposerEvents is set to true.

Events are being sent for Composers "show", "hide" states ( in the "did" phase ). 
Each event contains an area parameter with the current Composer scene name. 
In the "hide" events there are also sent value parameters representing the time spent on the scene (in seconds).

- Scene 2 also shows how to send a custom event and how the GA SDK will automatically assign the Composer 
scene name to the area parameter, if no other value is supplied for it. This applies to all custom events 
in the design, quality and business categories if the GA.useComposer property is set to true.

