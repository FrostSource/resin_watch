
-- AlyxLib can only run on server
if IsClient() then return end
-- Load alyxlib before using it, in case this mod loads before the alyxlib mod.
require("alyxlib.init")

local version = "v2.0.0"

-- execute code or load mod libraries here
require "resin_watch.classes.watch"

local watch_name = "resin_watch_attached_to_hand"

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
"", nil,
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
end)
EasyConvars:SetPersistent("resin_watch_toggle_button", true)

---Global entity for Resin Watch attached to the player wrist.
---@type ResinWatch
_G.ResinWatch = nil

---
---Attempts to find the resin watch attached to the player wrist.
---
---@return ResinWatch?
function GetResinWatch()
    if not IsEntity(ResinWatch, true) then
        for i = 1, 2 do
            for _, child in ipairs(Player.Hands[i]) do
                if isinstance(child, "ResinWatch") then
                    ResinWatch = child
                    return child
                end
            end
        end
    end

    return ResinWatch
end

ListenToPlayerEvent("primary_hand_changed", function() 
    if GetResinWatch() then
        ResinWatch:AttachToHand()
    end
end)


---@param params PLAYER_EVENT_VR_PLAYER_READY
ListenToPlayerEvent("vr_player_ready", function (params)
    if Entities:FindByName(nil, watch_name) then
        return
    end

    devprint("Spawning resin watch...")

    SpawnEntityFromTableAsynchronous("prop_dynamic", {
        targetname = "resin_watch_attached_to_hand",
        model = "models/resin_watch/resin_watch.vmdl",
        vscripts = "resin_watch/classes/watch",
        disableshadows = "1",
    }, function (spawnedEnt)
        ---@cast spawnedEnt ResinWatch
        spawnedEnt:AttachToHand()
        ResinWatch = spawnedEnt
    end, nil)

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

print("Resin watch "..version.." initialized...")
