# Zenity UI

Check-UI style Roblox UI library used by Zenity Hub.

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/okame7x/zenity-ui/main/zenityui.lua"))()
```

## Screen positioning

The default main-window opener, Steal panel and Steal toggle use screen percentages based on the original 1050 x 620 layout. Their anchors stay at the same relative screen position when the viewport changes; their sizes continue to use responsive scaling.

`OpenPosition` and `ButtonPosition` still accept explicit UDim2 overrides. Use `UDim2.fromScale(x, y)` for resolution-independent custom positions. `EdgeGap` is measured in reference-layout pixels (1050 pixels wide) and scales with viewport width. `Side = "Left"` mirrors the Steal layout.

`AlignWith` no longer moves or resizes the Steal toggle or changes screen insets. `ButtonTemplate` still supplies its appearance, so game HUD animations do not move the Zenity controls.