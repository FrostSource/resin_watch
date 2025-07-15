local categoryId = "resin_watch"

DebugMenu:AddCategory(categoryId, "Resin Watch")

local function toggle(name, command)
    DebugMenu:AddToggle(categoryId, command, name, command)
end

DebugMenu:AddLabel(categoryId, "resin_watch_settings_label", "Settings")
toggle("Watch On Primary Hand", "resin_watch_primary_hand")
toggle("Inverted Watch", "resin_watch_inverted")
toggle("Track Ammo", "resin_watch_allow_ammo_tracking")
toggle("Track Items", "resin_watch_allow_item_tracking")
toggle("Sound / Vibration", "resin_watch_notify")
DebugMenu:AddSlider(categoryId, "resin_watch_radius", "Tracking Distance", 10, 5000, false, "resin_watch_radius", 0)
DebugMenu:AddSeparator(categoryId)
DebugMenu:AddLabel(categoryId, "resin_watch_reset_label", "Reset the watch if there are issues")
DebugMenu:AddButton(categoryId, "resin_watch_reset", "Reset Watch", "resin_watch_reset_watch")