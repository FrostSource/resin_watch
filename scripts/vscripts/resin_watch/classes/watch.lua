
---@class ResinWatch : EntityClass
local base = entity("ResinWatch")

---Rotating indicator parented to the watch.
---@type EntityHandle
base.compassEnt = nil

---Text panel parented to the watch.
---@type EntityHandle
base.panelEnt = nil

---Level indicator parented to the watch.
---@type EntityHandle
base.levelIndicatorEnt = nil

---Amount of resin that was found in the map since last check.
---@type number
base.__lastResinCount = -1

---The resin current being tracked by the watch.
---@type EntityHandle
base.__lastResinTracked = nil

---The type of indicator the last level indicator used.
---@type 0|1|2 # 0 = Same floor, 1 = above floor, 2 = below floor
base.__lastLevelType = 0

local RESIN_NOTIFY_HAPTIC_SEQ = HapticSequence(0.12, 0.9, 0.08)

function base:Precache(context)
    PrecacheModel("models/resin_watch/resin_watch_compass.vmdl", context)
    PrecacheModel("models/resin_watch/resin_watch_base.vmdl", context)
    PrecacheModel("models/resin_watch/resin_watch_level_indicator.vmdl", context)
    PrecacheModel("models/hands/counter_panels.vmdl", context)
    PrecacheResource("sound", "ResinWatch.ResinTrackedBeep", context)
end


---Called automatically on spawn
---@param spawnkeys CScriptKeyValues
function base:OnSpawn(spawnkeys)
    -- Counter
    local panel = SpawnEntityFromTableSynchronous("prop_dynamic", {
        targetname = "resin_watch_panel",
        model = "models/hands/counter_panels.vmdl",
        disableshadows = "1",
        bodygroups = "{\n\tcounter = 1\n}",
        solid = "0",
    })
    panel:SetAbsScale(0.867)
    panel:SetParent(self, "")
    panel:SetLocalOrigin(Vector(-0.00900647, 1.00959, -0.160784))
    panel:SetLocalAngles(0, 359.293, -37.9338)
    panel:SetAbsOrigin(panel:GetAbsOrigin() + panel:GetUpVector() * 0.03)

    -- Compass
    local compass = SpawnEntityFromTableSynchronous("prop_dynamic", {
        targetname = "resin_watch_compass",
        model = "models/resin_watch/resin_watch_compass.vmdl",
        origin = self:GetAbsOrigin(),
        disableshadows = "1",
    })
    compass:SetParent(self, "")
    compass:ResetLocal()

    -- Level indicator
    local level = SpawnEntityFromTableSynchronous("prop_dynamic", {
        targetname = "resin_watch_level_indicator",
        model = "models/resin_watch/resin_watch_level_indicator.vmdl",
        origin = self:GetAbsOrigin(),
        disableshadows = "1",
    })
    level:SetParent(self, "")
    level:ResetLocal()

    self.panelEnt = panel
    self.compassEnt = compass
    self.levelIndicatorEnt = level
end

---Called automatically on activate.
---Any self values set here are automatically saved
---@param readyType OnReadyType
function base:OnReady(readyType)
    self.panelEnt:EntFire("SetRenderAttribute", "$CounterIcon=43")
    self.compassEnt:SetSkin(1)

    self:SetThink("ResinCountThink", "ResinWatchPanelThink", 0.1, self)
    self:ResumeThink()

    RegisterPlayerEventCallback("player_drop_resin_in_backpack", function (params)
        self:Delay(function()
            self:UpdateResinCount()
        end, 0)
    end, self)

    ---Moving watch to secondary hand.
    ---@param params PLAYER_EVENT_PRIMARY_HAND_CHANGED
    RegisterPlayerEventCallback("primary_hand_changed", function (params)
        self:AttachToHand(Player.SecondaryHand)
    end, self)
end

---Attach the watch to the desired hand.
---@param hand? CPropVRHand # Hand to attach to. If not given it will choose a hand based on convars.
---@param offset? Vector # Optional offset vector.
---@param angles? QAngle # Optional angles.
---@param attachment? string # Optional attachment name.
function base:AttachToHand(hand, offset, angles, attachment)
    if hand == nil then
        -- hand = self.attachToPrimary and Player.PrimaryHand or Player.SecondaryHand
        hand = EasyConvars:GetBool("resin_watch_primary_hand") and Player.PrimaryHand or Player.SecondaryHand
    end

    if hand == Player.LeftHand then
        attachment = attachment or "item_holder_l"
        offset = offset or Vector(0.6, 1.2, 0)
        angles = angles or QAngle(-7.07305, 0, -90)
    else
        attachment = attachment or "item_holder_r"
        offset = offset or Vector(0.6, 1.2, 0)
        angles = angles or QAngle(-7.07305-180, 0, -90)
    end
    -- if self.attachInverted then
    if EasyConvars:GetBool("resin_watch_inverted") then
        offset.y = -offset.y
        angles = RotateOrientation(angles, QAngle(180, 180, 0))
    end
    self:SetParent(hand:GetGlove(), attachment)
    self:SetLocalOrigin(offset)
    self:SetLocalQAngle(angles)
end

---Update the text panel on the watch with text.
---@param amount number
function base:UpdatePanel(amount)
    amount = Clamp(amount, 0, 99)
    local tens = math.floor(amount / 10)
    local ones = amount % 10
    self.panelEnt:EntFire("SetRenderAttribute", "$CounterDigitTens="..RemapVal(tens, 0, 9, 32, 41))
    self.panelEnt:EntFire("SetRenderAttribute", "$CounterDigitOnes="..RemapVal(ones, 0, 9, 32, 41))
end

function base:UpdateResinCount()
    local count = #Entities:FindAllByClassname("item_hlvr_crafting_currency_large") + #Entities:FindAllByClassname("item_hlvr_crafting_currency_small")
    if count ~= self.__lastResinCount then
        self:UpdatePanel(count)
        self.__lastResinCount = count
    end
end

---Check every 4 seconds for newly spawned resin.
---Updates immediately when resin is stored in backpack elsewhere in code.
function base:ResinCountThink()
    self:UpdateResinCount()
    return 4
end

---Main entity think function. Think state is saved between loads
function base:Think()
    local selfOrigin = self:GetAbsOrigin()
    local nearestSmall = Entities:FindByClassnameNearest("item_hlvr_crafting_currency_small", selfOrigin, EasyConvars:GetInt("resin_watch_radius"))
    local nearestLarge = Entities:FindByClassnameNearest("item_hlvr_crafting_currency_large", selfOrigin, EasyConvars:GetInt("resin_watch_radius"))

    ---@type EntityHandle
    local nearest = nil
    ---@type Vector
    local difference = nil

    if nearestSmall and nearestLarge then
        local differenceSmall = nearestSmall:GetCenter() - selfOrigin
        local differenceLarge = nearestLarge:GetCenter() - selfOrigin
        if differenceLarge:Length() < differenceSmall:Length() then
            nearest = nearestLarge
            difference = differenceLarge
        else
            nearest = nearestSmall
            difference = differenceSmall
        end
    else
        nearest = nearestSmall or nearestLarge
        if nearest then
            difference = nearest:GetCenter() - selfOrigin
        end
    end

    if nearest then

        if self.__lastResinTracked ~= nearest then
            self.__lastResinTracked = nearest
            if EasyConvars:GetBool("resin_watch_notify") then
                self:EmitSound("ResinWatch.ResinTrackedBeep")
                if Player.SecondaryHand then
                    RESIN_NOTIFY_HAPTIC_SEQ:Fire(Player.SecondaryHand)
                end
            end
            self.compassEnt:SetSkin(0)
        end

        local dir = difference:Normalized()
        local global_yaw_angle = math.atan2(dir.y, dir.x)
        global_yaw_angle = math.deg(global_yaw_angle)

        local parent_yaw = self:GetAngles().y
        local local_yaw_angle_degrees = global_yaw_angle - parent_yaw

        local final_yaw = LerpAngle(0.1, self.compassEnt:GetLocalAngles().y, local_yaw_angle_degrees)
        self.compassEnt:SetLocalAngles(0, final_yaw, 0)

        local zDiff = (nearest:GetCenter().z - selfOrigin.z)
        local levelType = 0

        if zDiff > EasyConvars:GetFloat("resin_watch_level_up") then
            levelType = 1
        elseif zDiff < EasyConvars:GetFloat("resin_watch_level_down") then
            levelType = 2
        end

        if self.__lastLevelType ~= levelType then
            self.__lastLevelType = levelType
            self.levelIndicatorEnt:SetSkin(levelType)
        end

    else
        if self.__lastResinTracked ~= nil then
            self.__lastResinTracked = nil
            self.compassEnt:SetSkin(1)
            self.__lastLevelType = 0
            self.levelIndicatorEnt:SetSkin(0)
        end
    end

    return 0
end

--Used for classes not attached directly to entities
return base
