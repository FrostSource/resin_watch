if thisEntity then
    -- Inherit this script if attached to entity
    -- Will also load the script at the same time if needed
    inherit(GetScriptFile())
    return
end

local RESIN_NOTIFY_HAPTIC_SEQ = HapticSequence(0.12, 0.9, 0.08)

local RESIN_COUNTER_INDEX_0 = 32
local RESIN_COUNTER_INDEX_9 = 41
local RESIN_COUNTER_INDEX_BLANK = 43
local AMMO_COUNTER_INDEX_0 = 16
local AMMO_COUNTER_INDEX_9 = 25
local AMMO_COUNTER_INDEX_BLANK = 27

local SKIN_COMPASS_RESIN = 0
local SKIN_COMPASS_RESIN_BLANK = 1
local SKIN_COMPASS_AMMO = 2
local SKIN_COMPASS_AMMO_BLANK = 3

-- First skin has to be a level one, so both get unique materials.
local SKIN_BODY_LED_LEVEL_UP = 0
local SKIN_BODY_LED_LEVEL_DOWN = 1
local SKIN_BODY_LED_FOUND_AMMO = 2
local SKIN_BODY_LED_FOUND_RESIN = 3
local SKIN_BODY_LED_OFF = 4

-- This bodygroup flips the static elements.
local BODY_WATCH_SIDE = 1
local BODY_VAL_SIDE_LHAND = 0
local BODY_VAL_SIDE_RHAND = 1

-- The switch has values lhand-up, lhand-down, rhand-up, rhand-down.
local BODY_WATCH_MODE = 2
local BODY_VAL_SWITCH_UP = 0
local BODY_VAL_SWITCH_DOWN = 1
local BODY_VAL_SWITCH_RHAND = 2

local CLASS_LIST_RESIN = {
    "item_hlvr_crafting_currency_small",
    "item_hlvr_crafting_currency_large"
}

local CLASS_LIST_AMMO = {
    "item_hlvr_clip_energygun",
    "item_hlvr_clip_energygun_multiple",
    "item_hlvr_clip_rapidfire",
    "item_hlvr_clip_shotgun_single",
    "item_hlvr_clip_shotgun_multiple",
    "item_hlvr_clip_generic_pistol",
    "item_hlvr_clip_generic_pistol_multiple",
}

local CLASS_LIST_ITEMS = {
    "item_hlvr_grenade_frag",
    "item_hlvr_grenade_xen",
    "item_healthvial",
    "item_hlvr_health_station_vial",
    "item_item_crate",
}

-- For specific classes, a function to determine if the item is valid.
--- @type table<string, (fun(entity: CBaseAnimating): boolean)>
local CLASS_FILTERS = {
    item_healthvial = function(entity) 
        local capsule = entity:GetFirstChildWithClassname("prop_item_healthvial_capsule")
        -- If no capsule can't determine, track anyway.
        -- If the mask is 2, the needle is gone and it's used up.
        return capsule == nil or tostring(capsule:GetMaterialGroupMask()) ~= "2"
    end
};

---The length of the model for calculating wrist attachment
local MODEL_LENGTH = 2.5

--- Time between blinks, and number of cycles when items are found.
local BLINK_DELAY = 0.25
local BLINK_COUNT = 4

require "alyxlib.controls.input"
Input.AutoStart = true


---@class ResinWatch : EntityClass
local base = entity("ResinWatch")

---Rotating indicator parented to the watch.
---@type EntityHandle
base.compassEnt = nil

---Whether the watch is left or right handed.
---@type boolean
base.rightHanded = false

---The type of entity to track.
---@type "resin"|"ammo"
base.trackingMode = "resin"

---Amount of resin that was found in the map since last check.
---@type number
base.__lastResinCount = -1

---The resin current being tracked by the watch.
---@type EntityHandle
base.__lastResinTracked = nil

---The skin for the last LED used.
---@type number
base.__idleLED = SKIN_BODY_LED_OFF

---If >0, the number of blinks still to occur.
base.__blinkCount = 0

---List of classnames that are currently tracked.
---@type string[]
base.__currentTrackedClasses = CLASS_LIST_RESIN



local CLASS_LIST_AMMO_ITEMS = ArrayAppend(CLASS_LIST_AMMO, CLASS_LIST_ITEMS)

function base:Precache(context)
    PrecacheModel("models/resin_watch/resin_watch_compass.vmdl", context)
    PrecacheModel("models/resin_watch/resin_watch.vmdl", context)
    PrecacheResource("sound", "ResinWatch.ResinTrackedBeep", context)
end


---Called automatically on spawn
---@param spawnkeys CScriptKeyValues
function base:OnSpawn(spawnkeys)
    -- Compass
    local compass = SpawnEntityFromTableSynchronous("prop_dynamic", {
        targetname = self:GetName().."_compass",
        model = "models/resin_watch/resin_watch_compass.vmdl",
        origin = self:GetAbsOrigin(),
        disableshadows = "1",
    })
    compass:SetParent(self, "")
    compass:ResetLocal()

    self.compassEnt = compass
end

---Called automatically on activate.
---Any self values set here are automatically saved
---@param readyType OnReadyType
function base:OnReady(readyType)
    self:SetTrackingMode(self.trackingMode)
    self:SetBlankVisuals()

    self:SetThink("ResinCountThink", "ResinWatchPanelThink", 0.1, self)
    self:ResumeThink()

    ListenToPlayerEvent("player_drop_resin_in_backpack", function (params)
        self:Delay(function()
            self:UpdateCounterPanel()
        end, 0)
    end, self)

    if self:IsAttachedToHand() then
        self:UpdateControllerInputs()
    end

    self:ForceUpdateTracking()
end

---Attach the watch to the desired hand.
---@param hand? CPropVRHand|"primary"|"secondary" # Hand to attach to. If not given it will choose a hand based on convars.
---@param inverted? boolean # If the watch should face underneath the wrist. If not given it will be based on convars.
function base:AttachToHand(hand, inverted)
    local offset,angles,handType
    if hand == nil then
        handType = EasyConvars:GetBool("resin_watch_primary_hand") and "primary" or "secondary"
    elseif IsEntity(hand) then
            handType = (hand == Player.PrimaryHand) and "primary" or "secondary"
    else
        handType = hand
    end

    hand = handType == "primary" and Player.PrimaryHand or Player.SecondaryHand

    base.rightHanded = hand == Player.RightHand
    self:SetBodygroup(BODY_WATCH_SIDE, base.rightHanded and BODY_VAL_SIDE_RHAND or BODY_VAL_SIDE_LHAND)

    -- X axis is ignored, set by model length.
    offset = offset or Vector(0, 1.4, 0)
    if hand == Player.LeftHand then
        angles = angles or QAngle(270, 180, 85)
    else
        angles = angles or QAngle(90, 180, 95)
    end

    if inverted or (inverted == nil and EasyConvars:GetBool("resin_watch_inverted")) then
        offset.y = -offset.y
        angles = RotateOrientation(angles, QAngle(180, 180, 0))
    end

    if WristAttachments:IsEntityAttached(self) then
        WristAttachments:SetHand(self, handType, offset, angles)
    else
        WristAttachments:Add(self, handType, MODEL_LENGTH, 0, offset, angles)
    end

    self:SetOwner(Player)

    self:ForceUpdateTracking()
    self:UpdateControllerInputs()
end

---Gets the hand that this watch is attached to (if attached).
---@return EntityHandle?
function base:GetAttachedHand()
    local glove = self:GetMoveParent()
    if glove and glove:GetClassname() == "hlvr_prop_renderable_glove" then
        local hand = glove:GetMoveParent()
        if hand and hand:GetClassname() == "hl_prop_vr_hand" then
            return hand
        end
    end
    return nil
end

---Gets if the watch is currently attached to a player hand.
---@return boolean
function base:IsAttachedToHand()
    return self:GetAttachedHand() ~= nil
end

function base:UpdateControllerInputs()

    ---@TODO Is there a way to untrack the previous button only if no other mod is using it?
    local button = EasyConvars:GetInt("resin_watch_toggle_button")

    local hand = self:GetAttachedHand()
    Input:StopListeningCallbackContext(self._InputTrackingModeToggleCallback, self)
    Input:ListenToButton("press", hand, button, 2, self._InputTrackingModeToggleCallback, self)
end

---Internal callback for tracking mode toggle button press.
---@param params InputPressCallback
function base:_InputTrackingModeToggleCallback(params)
    self:ToggleTrackingMode()
end

---Update the text panel on the watch with text.
---@param amount number
function base:UpdateCounterPanelNumber(amount)
    amount = Clamp(amount, 0, 99)
    local tens = math.floor(amount / 10)
    local ones = amount % 10

    local ind0,ind9 = RESIN_COUNTER_INDEX_0, RESIN_COUNTER_INDEX_9
    if self.trackingMode == "ammo" then
        ind0,ind9 = AMMO_COUNTER_INDEX_0, AMMO_COUNTER_INDEX_9
    end

    self:EntFire("SetRenderAttribute", "$CounterDigitTens="..RemapVal(tens, 0, 9, ind0, ind9))
    self:EntFire("SetRenderAttribute", "$CounterDigitOnes="..RemapVal(ones, 0, 9, ind0, ind9))
end

---Set the tracking mode.
---@param mode "resin"|"ammo"
---@param silent boolean?
function base:SetTrackingMode(mode, silent)
    if not EasyConvars:GetBool("resin_watch_allow_ammo_tracking") and not EasyConvars:GetBool("resin_watch_allow_item_tracking") then
        mode = "resin"
    end
    -- Early exit if new mode isn't different
    if mode == self.trackingMode then return end

    if not silent then
        self:EmitSound("ResinWatch.TrackingModeToggle")
    end

    self.trackingMode = mode

    self:ForceUpdateTracking()
end

---Forces the watch to update all tracking entities and visuals.
function base:ForceUpdateTracking()
    self:SetBlankVisuals()
    self:UpdateTrackedClassList()
    self:UpdateTrackedEntities()
    self:UpdateCounterPanel(true)
end

---Toggle the tracking mode between resin and ammo/items.
function base:ToggleTrackingMode()
    if self.trackingMode == "resin" then
        self:SetTrackingMode("ammo")
    else
        self:SetTrackingMode("resin")
    end
end

---Set the indication visuals to blank, color based on tracking mode.
function base:SetBlankVisuals()
    local isResin = self.trackingMode == "resin"
    self.compassEnt:SetSkin(isResin and SKIN_COMPASS_RESIN_BLANK or SKIN_COMPASS_AMMO_BLANK)
    local mode = isResin and BODY_VAL_SWITCH_DOWN or BODY_VAL_SWITCH_UP
    if self.rightHanded then
        mode = mode + BODY_VAL_SWITCH_RHAND
    end
    self:SetBodygroup(BODY_WATCH_MODE, mode)
    self:SetSkin(SKIN_BODY_LED_OFF)
    self:EntFire("SetRenderAttribute", "$CounterIcon=" .. (isResin and RESIN_COUNTER_INDEX_BLANK or AMMO_COUNTER_INDEX_BLANK))
    self.__lastResinTracked = nil
end

---Get the list of classnames related to the current tracking mode.
---@return string[]
function base:GetTrackedClassList()
    if self.trackingMode == "resin" then
        return CLASS_LIST_RESIN
    elseif self.trackingMode == "ammo" then
        local ammo, items = EasyConvars:GetBool("resin_watch_allow_ammo_tracking"), EasyConvars:GetBool("resin_watch_allow_item_tracking")
        if ammo and items then
            return CLASS_LIST_AMMO_ITEMS
        elseif ammo then
            return CLASS_LIST_AMMO
        elseif items then
            return CLASS_LIST_ITEMS
        end
    end
    return {}
end

---Set __currentTrackedClasses to the correct list based on mode and convars.
function base:UpdateTrackedClassList()
    self.__currentTrackedClasses = self:GetTrackedClassList()
end

---Get the total number of entities from a list of classes.
---@param classes string[]
---@return number
local function countClassList(classes)
    local count = 0
    for _, class in ipairs(classes) do
        count = count + #Entities:FindAllByClassname(class)
    end
    return count
end

---Updates the digit counter panel with the current number of tracked entities in the map.
---@param force? boolean # If true the number will be updated even if the number of entities hasn't changed.
function base:UpdateCounterPanel(force)
    local count = countClassList(self.__currentTrackedClasses)

    if force then
        self.__lastResinCount = -1
    end

    if count ~= self.__lastResinCount then
        self:UpdateCounterPanelNumber(count)
        self.__lastResinCount = count
    end
end

---Check every 4 seconds for newly spawned resin.
---Updates immediately when resin is stored in backpack elsewhere in code.
function base:ResinCountThink()
    self:UpdateCounterPanel()
    return 4
end

---@type EntityHandle[]
local allExistingTrackedEntities = {}

local TRACKED_ENTITIES_UPDATE_TIME = 30

local trackedEntitiesTime = 0

function base:UpdateTrackedEntities()
    allExistingTrackedEntities = {}
    for _, class in ipairs(self.__currentTrackedClasses) do
        vlua.extend(allExistingTrackedEntities, Entities:FindAllByClassname(class))
    end
end

---Get if an entity is attached to player (i.e. ammo clip, wrist pocket item).
---@param ent EntityHandle
---@return boolean
local function isAttachedToPlayer(ent)
    local parent = ent:GetRootMoveParent()
    if parent then
        local pclass = parent:GetClassname()
        if (pclass == "hlvr_weapon_energygun"
        or pclass == "hlvr_weapon_shotgun"
        or pclass== "hlvr_weapon_rapidfire"
        or pclass == "hl_prop_vr_hand")
        then
            return true
        end
    end
    return false
end

local function getNearestEntity(origin, maxRadius)
    local bestEnt = nil
    local bestDist = math.huge
    for index, ent in ipairs(allExistingTrackedEntities) do
        if IsValidEntity(ent) then
            local dist = VectorDistance(ent:GetOrigin(), origin)
            if dist <= bestDist and dist <= maxRadius and not isAttachedToPlayer(ent) then
                bestEnt = ent
                bestDist = dist
            end
        end
    end

    return bestEnt
end

function base:BlinkThink()
    self.__blinkCount = self.__blinkCount - 1
    if self.__blinkCount % 2 == 0 then
        self:SetSkin(self.trackingMode == "resin" and SKIN_BODY_LED_FOUND_RESIN or SKIN_BODY_LED_FOUND_AMMO)
    else
        self:SetSkin(SKIN_BODY_LED_OFF)
    end
    if self.__blinkCount > 0 then
        return BLINK_DELAY
    else
        self:SetSkin(self.__idleLED)
        self:SetContextThink("blinkThink", nil, 0)
    end
end

-- Used for debugging purposes, i.e. `alyxlib_diagnose resin_watch`
local lastThinkTime = 0

---
---Gets the last server time the resin watch think function was run.
---This value is shared for all instances of the watch.
---
---@return integer
function base:GetLocalLastThinkTime()
    return lastThinkTime
end

---Main entity think function. Think state is saved between loads
function base:Think()
    lastThinkTime = Time()

    local selfOrigin = self:GetAbsOrigin()

    if Time() - trackedEntitiesTime > TRACKED_ENTITIES_UPDATE_TIME then
        self:UpdateTrackedEntities()
        trackedEntitiesTime = Time()
    end
    -- if Time() - nearestEntityTime > NEAREST_ENTITY_UPDATE_TIME then
        local nearest = getNearestEntity(selfOrigin, EasyConvars:GetInt("resin_watch_radius"))
    --     nearestEntityTime = Time()
    -- end

    if nearest then

        ---@type Vector
        local difference = nearest:GetCenter() - selfOrigin

        if self.__lastResinTracked ~= nearest then
            self.__lastResinTracked = nearest
            if EasyConvars:GetBool("resin_watch_notify") then
                self:EmitSound("ResinWatch.ResinTrackedBeep")
                local attachedHand = self:GetAttachedHand()
                if attachedHand then
                    RESIN_NOTIFY_HAPTIC_SEQ:Fire(attachedHand)
                end
                if self.__blinkCount == 0 then
                    self:SetContextThink("blinkThink", function() return self:BlinkThink() end, BLINK_DELAY);
                end -- Else, already thinking.
                self.__blinkCount = BLINK_COUNT
                self:SetSkin(self.trackingMode == "resin" and SKIN_BODY_LED_FOUND_RESIN or SKIN_BODY_LED_FOUND_AMMO)
            end
            local skin = SKIN_COMPASS_RESIN
            if self.trackingMode == "ammo" then skin = SKIN_COMPASS_AMMO end
            self.compassEnt:SetSkin(skin)
        end

        local dir = difference:Normalized()
        local global_yaw_angle = math.atan2(dir.y, dir.x)
        global_yaw_angle = math.deg(global_yaw_angle)

        local parent_yaw = self:GetAngles().y
        local local_yaw_angle_degrees = global_yaw_angle - parent_yaw
        if self:GetUpVector().z < -0.8 then
            local_yaw_angle_degrees = -local_yaw_angle_degrees
        end

        local final_yaw = LerpAngle(0.1, self.compassEnt:GetLocalAngles().y, local_yaw_angle_degrees)
        self.compassEnt:SetLocalAngles(0, final_yaw, 0)

        local zDiff = (nearest:GetCenter().z - selfOrigin.z)
        local levelType = 0

        if zDiff > EasyConvars:GetFloat("resin_watch_level_up") then
            self.__idleLED = SKIN_BODY_LED_LEVEL_UP
        elseif zDiff < EasyConvars:GetFloat("resin_watch_level_down") then
            self.__idleLED = SKIN_BODY_LED_LEVEL_DOWN
        else
            self.__idleLED = SKIN_BODY_LED_OFF
        end
        if self.__blinkCount == 0 then
            self:SetSkin(self.__idleLED)
        end

    else
        if self.__lastResinTracked ~= nil then
            self:SetBlankVisuals()
        end
    end

    return 0
end

--Used for classes not attached directly to entities
return base
