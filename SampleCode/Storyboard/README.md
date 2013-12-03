
---------------------------------------------------------------------------------
Game Analytics for Corona SDK: Storyboard example 
---------------------------------------------------------------------------------

This is a simple example showing how to use the Game Analytics SDK with storyboard (Corona's built in 
scene management system). When using storyboard the GA SDK is context aware and can automatically
submit events for scene changes.

In order to try this example you need to sign up for a Game Analytics account and paste the game 
key and secret key you recieve in the initialization fields in the main.lua file.

When running this example you should look at the Corona terminal to see what events are being 
sent when going through the 3 storyboard scenes.

- The main.lua file shows you how to setup the GA SDK using storyboard.

- Scene 1 and 2 shows how the GA SDK automatically submits scene change events to the GA servers
if the GA.submitStoryboardEvents is set to true.

Events are being sent for storyboards "enterScene", "exitScene", "overlayBegan" and "overlayEnded" 
states. Each event contains an area parameter with the current storyboard scene name. In the "exitScene" 
and "overlayEnded" events there are also sent value parameters representing the time spent on the scene or overlay (in seconds).

- Scene 3 shows how to send a custom event and how the GA SDK will automatically assign the storyboard 
scene name to the area parameter, if no other value is supplied for it. This applies to all custom events 
in the design, quality and business categories if the GA.useStoryboard property is set to true.

