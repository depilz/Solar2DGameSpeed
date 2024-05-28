# Solar2D - Game speed control
This tool is designed for controlling the game’s speed in Solar2D, primarily for debugging purposes. It allows you to adjust the speed of various game elements, providing a flexible environment for testing and debugging.


## Controls
You can find a keyboard.lua inside the GameSpeed folder which is has the basic controls for this tool. It is in a different file since this is very likely the file you will like to change according to your project.

- **Space bar:** Toggle auto speed up.
- **Left arrow key:** Slow down the game.
- **Right arrow key:** Speed up the game.
- **Up arrow key:** Make the game faster.
- **Down arrow key:** Make the game slower.
  

## Important Notes

- **Early Initialization:** The tool must be required early in the app to avoid issues with enterFrame events, transitions, or delays.
-	**Debugging Use Only:** This tool is intended for debugging purposes and should never be used in production. While reliable, it lacks precision.
-	**os.clock() Behavior:** The os.clock() function still returns the actual time to prevent “going back in time” when reloading the app.
-	**Physics Interaction:** The tool affects physics, but using physics.setTimeScale(scale) in conjunction with this tool can cause conflicts.

## Ownership and License

This tool was created by Depilz for Studycat Limited. Studycat Limited is happy to share it with the community as open-source software under the MIT License.

Feel free to adjust or expand upon this as needed to better suit your project’s specifics. If you have any additional details or sections you’d like to include, let me know!
