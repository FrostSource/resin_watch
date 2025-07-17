
-- AlyxLib can only run on server
if IsClient() then return end
-- Load alyxlib before using it, in case this mod loads before the alyxlib mod.
require("alyxlib.init")

local version = "v3.1.0"

local alyxlibAddonIndex = RegisterAlyxLibAddon("Resin Watch (Item Tracker)", version, "3145397582", "resin_watch", "v2.0.0")

RegisterAlyxLibDiagnostic(alyxlibAddonIndex, function ()
    if not Player.HMDAvatar then
        return false, "Resin watch requires VR or +vr_enable_fake_vr to be enabled"
    end

    local convars = {
        "resin_watch_primary_hand",
        "resin_watch_allow_ammo_tracking",
        "resin_watch_allow_item_tracking",
        "resin_watch_radius",
        "resin_watch_notify",
        "resin_watch_level_up",
        "resin_watch_level_down"
    }

    for _, convar in ipairs(convars) do
        if EasyConvars:WasChangedByUser(convar) then
            Msg(convar .. " = " .. EasyConvars:GetStr(convar) .. "\n")
        end
    end

    local watch = GetResinWatch()
    if not watch then
        return false, "Resin watch does not exist in game, try using the 'resin_watch_reset_watch' command"
    end

    local hand = EasyConvars:GetBool("resin_watch_primary_hand") and Player.PrimaryHand or Player.SecondaryHand
    if not hand then
        return false, "The hand that the watch should be attached to does not exist"
    end

    local attachedHand = watch:GetAttachedHand()
    if not attachedHand then
        return false, "The watch is not attached to a hand"
    end
    Msg("Resin watch is attached to " .. Input:GetHandName(attachedHand) .. "\n")

    local thinkTime = watch:GetLocalLastThinkTime()
    Msg("Resin watch last think time: " .. thinkTime .. " seconds ago.\n")

    return true, "No issues were detected, try using `resin_watch_reset_watch` to fix any issues"
end)

-- execute code or load mod libraries here
require "resin_watch.classes.watch"

local watch_name = "resin_watch_attached_to_hand"

local function spawnResinWatch()
    SpawnEntityFromTableAsynchronous("prop_dynamic", {
        targetname = watch_name,
        model = "models/resin_watch/resin_watch.vmdl",
        vscripts = "resin_watch/classes/watch",
        disableshadows = "1",
    }, function (spawnedEnt)
        ---@cast spawnedEnt ResinWatch
        spawnedEnt:AttachToHand()
        ResinWatch = spawnedEnt
    end, nil)
end

ListenToPlayerEvent("primary_hand_changed", function()
    if GetResinWatch() then
        ResinWatch:AttachToHand()
    end
end)

EasyConvars:RegisterConvar("resin_watch_radius", "700", "Distance to track resin")
EasyConvars:SetPersistent("resin_watch_radius", true)
EasyConvars:RegisterConvar("resin_watch_notify", "1", "Plays sound and vibrates when resin nearby")
EasyConvars:SetPersistent("resin_watch_notify", true)

EasyConvars:RegisterConvar("resin_watch_level_up", "90", "How far above the watch resin is considered on another floor")
EasyConvars:SetPersistent("resin_watch_level_up", true)
EasyConvars:RegisterConvar("resin_watch_level_down", "-90", "How far below the watch resin is considered on another floor")
EasyConvars:SetPersistent("resin_watch_level_down", true)

EasyConvars:RegisterConvar("resin_watch_inverted", "0", "Watch faces underneath the wrist", nil,
function (newVal, oldVal)
    if not GetResinWatch() then
        EasyConvars:Warn("Cannot set resin_watch_inverted, resin watch does not exist in game!")
        return oldVal
    end

    ResinWatch:AttachToHand()
end)
EasyConvars:SetPersistent("resin_watch_inverted", true)

EasyConvars:RegisterConvar("resin_watch_primary_hand", "0", "Watch attaches to primary hand", nil,
function (newVal, oldVal)
    if not GetResinWatch() then
        EasyConvars:Warn("Cannot set resin_watch_primary_hand, resin watch does not exist in game!")
        return oldVal
    end

    ResinWatch:AttachToHand()
end)
EasyConvars:SetPersistent("resin_watch_primary_hand", true)

EasyConvars:RegisterConvar("resin_watch_allow_ammo_tracking", "1", "Allow ammo to be tracked by the watch's alternate tracking mode", nil,
function (newVal, oldVal)
    if not GetResinWatch() then
        EasyConvars:Warn("Cannot set resin_watch_allow_ammo_tracking, resin watch does not exist in game!")
        return oldVal
    end

    ResinWatch:ForceUpdateTracking()

    if not truthy(newVal) and not EasyConvars:GetBool("resin_watch_allow_item_tracking") then
        ResinWatch:SetTrackingMode("resin")
    end
end)
EasyConvars:SetPersistent("resin_watch_allow_ammo_tracking", true)

EasyConvars:RegisterConvar("resin_watch_allow_item_tracking", "1", "Allow items to be tracked by the watch's alternate tracking mode", nil,
function (newVal, oldVal)

    if not GetResinWatch() then
        EasyConvars:Warn("Cannot set resin_watch_allow_item_tracking, resin watch does not exist in game!")
        return oldVal
    end

    ResinWatch:ForceUpdateTracking()

    if not truthy(newVal) and not EasyConvars:GetBool("resin_watch_allow_ammo_tracking") then
        ResinWatch:SetTrackingMode("resin")
    end
end)
EasyConvars:SetPersistent("resin_watch_allow_item_tracking", true)

EasyConvars:RegisterConvar("resin_watch_toggle_button",
-- Initializer
function()
    return DefaultTable({
        [VR_CONTROLLER_TYPE_KNUCKLES] = DIGITAL_INPUT_ARM_XEN_GRENADE,
        [VR_CONTROLLER_TYPE_RIFT_S] = DIGITAL_INPUT_USE_GRIP,
    }, DIGITAL_INPUT_ARM_XEN_GRENADE)[Player:GetVRControllerType()]
end,
"The digital action that must be double pressed to toggle watch modes", nil,
-- Main callback
function (newVal, oldVal)
    local button = tonumber(newVal)
    if not button or button < 0 or button > 27 then
        warn("Value '"..newVal.."' is not a valid button ID, must be [0-27]!")
        return oldVal
    end

    if not GetResinWatch() then
        EasyConvars:Warn("Cannot set resin_watch_toggle_button, resin watch does not exist in game!")
        return oldVal
    end

    ResinWatch:UpdateControllerInputs()

    Msg("Toggle digital action is now'" .. Input:GetButtonDescription(tonumber(newVal)) .. "\n")
end)
EasyConvars:SetPersistent("resin_watch_toggle_button", true)

EasyConvars:RegisterCommand("resin_watch_reset_watch", function ()
    local watch = GetResinWatch()
    if watch then
        devprint("Watch exists, resetting...")
        watch:AttachToHand()
    else
        devprint("Watch does not exist, spawning...")
        spawnResinWatch()
    end
end, "Resets the resin watch, or spawns a new one if it doesn't exist", 0)

---Global entity for Resin Watch attached to the player wrist.
---@type ResinWatch
_G.ResinWatch = nil

---
---Attempts to find the resin watch attached to the player wrist.
---
---@return ResinWatch?
function GetResinWatch()
    if not IsEntity(ResinWatch, true) then
        if Player == nil or Player.HMDAvatar == nil then
            return nil
        end
        for i = 1, 2 do
            for _, child in ipairs(Player.Hands[i]:GetChildrenMemSafe()) do
                if isinstance(child, "ResinWatch") then
                    ResinWatch = child--[[@as ResinWatch]]
                    return ResinWatch
                end
            end
        end
    end

    return ResinWatch
end

---@param params PlayerEventVRPlayerReady
ListenToPlayerEvent("vr_player_ready", function (params)
    if not GetResinWatch() then
        devprint("Resin Watch: Not found, spawning new watch...")
        spawnResinWatch()
    end

    -- If vr isn't enabled but hmd exists, assume +vr_enable_fake_vr 1
    if not IsVREnabled() then
        Convars:SetInt("vr_fakehands_rotate_y_left", 90)
        Convars:SetInt("vr_fakehands_hand_vertical_left", 5)
    end

end)

--- NO VR TESTING

ListenToPlayerEvent("novr_player", function (params)
    Convars:RegisterCommand("resin_watch_novr_debug", function (enabled)
        enabled = truthy(enabled)
        if enabled then
            SpawnEntityFromTableAsynchronous("prop_dynamic", {
                targetname = "resin_watch_novr",
                model = "models/resin_watch/resin_watch.vmdl",
                vscripts = "resin_watch/classes/watch",
                disableshadows = "1",
            }, function (spawnedEnt)
                ---@cast spawnedEnt ResinWatch
                spawnedEnt:SetParent(Player, "")
                spawnedEnt:SetLocalOrigin(Vector(8,0,60))
                spawnedEnt:SetLocalAngles(45,180,0)
                ResinWatch = spawnedEnt
            end, nil)
        end
    end, "", 0)

    Convars:RegisterCommand("resin_watch_novr_toggle_mode", function ()
        if IsEntity(ResinWatch, true) then
            ResinWatch:ToggleTrackingMode()
        end
    end, "", 0)
end)

require("resin_watch.debug_menu")

print("Resin watch "..version.." initialized...")
