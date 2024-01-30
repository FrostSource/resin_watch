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

EasyConvars:Register("resin_watch_inverted", "0", function (isInverted)
    if not IsEntity(ResinWatch, true) then
        warn("Resin watch does not exist in game!")
        return
    end

    ResinWatch:AttachToHand()
end, "Watch faces underneath the wrist")

EasyConvars:Register("resin_watch_primary_hand", "0", function (usePrimary)
    if not IsEntity(ResinWatch, true) then
        warn("Resin watch does not exist in game!")
        return
    end

    ResinWatch:AttachToHand()
end, "Watch attaches to primary hand")

---Global entity for Resin Watch.
---@type ResinWatch
_G.ResinWatch = nil

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
        spawnedEnt:AttachToHand()
        ResinWatch = spawnedEnt
    end, nil)

end)

print("Resin watch v1.0.1 initialized...")