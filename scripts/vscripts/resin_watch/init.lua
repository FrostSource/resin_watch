require "resin_watch.classes.watch"

local watch_name = "resin_watch_attached_to_hand"

-- Convars:RegisterConvar("resin_watch_radius", "700", "Distance to track resin", 0)
-- Convars:RegisterConvar("resin_watch_notify", "1", "Plays sound and vibrates when resin nearby", 0)
-- Convars:RegisterConvar("resin_watch_inverted", "1", "Watch faces underneath the wrist", 0)

EasyConvars:RegisterConvar("resin_watch_radius", "700", "Distance to track resin")
EasyConvars:SetPersistent("resin_watch_radius", true)
EasyConvars:RegisterConvar("resin_watch_notify", "1", "Plays sound and vibrates when resin nearby")
EasyConvars:SetPersistent("resin_watch_notify", true)

EasyConvars:Register("resin_watch_inverted", "0", function (isInverted)
    if not IsEntity(ResinWatch, true) then
        Warning("Resin watch does not exist in game!\n")
        return
    end

    -- ResinWatch.attachInverted = truthy(isInverted)
    ResinWatch:AttachToHand()
    -- return ResinWatch.attachInverted
end, "Watch faces underneath the wrist")

EasyConvars:Register("resin_watch_primary_hand", "0", function (usePrimary)
    if not IsEntity(ResinWatch, true) then
        Warning("Resin watch does not exist in game!\n")
        return
    end

    print('primary convar', EasyConvars:GetBool("resin_watch_primary_hand"))
    -- ResinWatch.attachToPrimary = truthy(usePrimary)
    ResinWatch:AttachToHand()
end, "Watch attaches to primary hand")

-- local watchIsInverted = false
-- Convars:RegisterCommand("resin_watch_inverted", function (_, isInverted)
--     if not IsEntity(ResinWatch, true) then
--         Warning("Resin watch does not exist in game!\n")
--         return
--     end

--     if isInverted == nil then
--         Msg("resin_watch_inverted" .. (ResinWatch.attachInverted and "1" or "0"))
--         return
--     end

--     ResinWatch.attachInverted = truthy(isInverted)
--     ResinWatch:AttachToHand()
-- end, "Watch faces underneath the wrist", 0)

-- local watchIsInverted = false
-- Convars:RegisterCommand("resin_watch_primary_hand", function (_, usePrimary)
--     if not IsEntity(ResinWatch, true) then
--         Warning("Resin watch does not exist in game!\n")
--         return
--     end

--     if usePrimary == nil then
--         Msg("resin_watch_primary_hand" .. (ResinWatch.attachToPrimary and "1" or "0"))
--     end

--     ResinWatch.attachToPrimary = truthy(usePrimary)
--     ResinWatch:AttachToHand()
-- end, "Watch attaches to primary hand instead of secondary", 0)

---@type ResinWatch
_G.ResinWatch = nil

---commentary_started
---@param params PLAYER_EVENT_VR_PLAYER_READY
RegisterPlayerEventCallback("vr_player_ready", function (params)
    if Entities:FindByName(nil, watch_name) then
        return
    end

    devprint("Spawning resin watch...")

    SpawnEntityFromTableAsynchronous("prop_dynamic", {
        targetname = "resin_watch_attached_to_hand",
        model = "models/resin_watch/resin_watch_base.vmdl",
        vscripts = "resin_watch/entity/watch",
        disableshadows = "1",
    }, function (spawnedEnt)
        ---@cast spawnedEnt ResinWatch
        spawnedEnt:AttachToHand(Player.SecondaryHand)
        ResinWatch = spawnedEnt
    end, nil)

end)