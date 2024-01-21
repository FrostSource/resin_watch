
local MIN_PULSE_WIDTH = 1
local MAX_PULSE_WIDTH = 30

---@class HapticSequence
local HapticSequenceClass = {
    ---@type string
    IDENTIFIER = UniqueString(),
    ---@type number
    duration = 0.5,
    ---@type number
    pulseInterval = 0.01,

    ---@type number
    pulseWidth_us = 0,
}
HapticSequenceClass.__index = HapticSequenceClass

---commentary_started
---@param hand CPropVRHand
function HapticSequenceClass:Fire(hand)
    local ref = {
        increment = 0,
        prevTime = Time(),
    }

    hand:SetThink(function()
        hand:FireHapticPulsePrecise(self.pulseWidth_us)
        if ref.increment < self.duration then
            local currentTime = Time()
            ref.increment = ref.increment + (currentTime - ref.prevTime)
            ref.prevTime = currentTime
            return self.pulseInterval
        else
            return nil
        end
    end, "Fire" .. self.IDENTIFIER .. "Haptic", 0)
end

function HapticSequence(duration, pulseStrength, pulseInterval)
    local inst = {
        duration = duration,
        pulseInterval = pulseInterval,

        IDENTIFIER = UniqueString(),
        pulseWidth_us = 0,
    }

    pulseStrength = pulseStrength or 0.1
    pulseStrength = Clamp(pulseStrength, 0, 1)
    pulseStrength = pulseStrength * pulseStrength

    if pulseStrength > 0 then
        inst.pulseWidth_us = Lerp(pulseStrength, MIN_PULSE_WIDTH, MAX_PULSE_WIDTH)
    end

    return setmetatable(inst, HapticSequenceClass)
end