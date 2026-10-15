# Zenity UI

Check-UI style Roblox UI library used by Zenity Hub.

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/okame7x/zenity-ui/main/zenityui.lua"))()
```

## Screen positioning

In the game HUD (`PlayerGui.HUD.GameHUD`), the main opener is centered one button spacing above `LeftControls.ShopBTN`, using the spacing to `IndexBTN`. The Steal toggle is centered one spacing above the first visible button in `RightButtons`, using the same square height. The expanded panel opens beside that column.

Alignment reads the actual rendered positions and sizes each frame, so it follows viewport/layout changes. A marker in Zenity's own ScreenGui converts screen coordinates without copying the game's insets. Hidden, off-screen and temporarily shrunken HUD controls do not replace the last valid layout.

`OpenPosition` and `ButtonPosition` preserve explicit UDim2 overrides. `AlignWith()` can supply the Steal reference buttons; otherwise the game HUD is discovered automatically. `ButtonTemplate` still supplies the toggle appearance. `EdgeGap` overrides automatic panel spacing, in reference-layout pixels (1050 pixels wide). If the game HUD is unavailable, the default positions fall back to screen percentages.