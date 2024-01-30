--[[
    v0.1.0
    https://github.com/FrostSource/hla_extravaganza

    Allows for quick creation of convars which support persistence saving, checking GlobalSys
    for default values, and callbacks on value change.

    If not using `vscripts/core.lua`, load this file at game start using the following line:
    
    ```lua
    require "util.util"
    ```

    ======================================== Usage ==========================================



]]


---Allows quick creation of convars with persistence, globalsys checks, and callbacks.
---@class EasyConvars
EasyConvars = {}

---@class EasyConvarsRegisteredData
---@field value string # Raw value of the convar.
---@field persistent boolean # If the value is saved to player on change.
---@field callback? fun(...):any? # Optional callback function whenever the convar is changed

---@type table<string, EasyConvarsRegisteredData>
EasyConvars.registered = {}

---Converts any value to "1" or "0" depending on whether it represents true or false.
local function valueToBoolStr(val)
    return val == true or val == 1 or val == "1" or (type(val) == "table" and #val > 0)
end

---Create convar
---@param name string
---@param default any # Will be converted to a string.
---@param func? fun(...):any? # Optional callback function.
---@param helpText? string
---@param flags? integer
function EasyConvars:Register(name, default, func, helpText, flags)

    self.registered[name] = {
        value = GlobalSys:CommandLineStr("-"..name, GlobalSys:CommandLineCheck("-"..name) and "1" or tostring(default or "0")),
        persistent = false
    }
    helpText = helpText or ""
    flags = flags or 0

    -- if func then
    local reg = self.registered[name]
    reg.callback = func

    Convars:RegisterCommand(name, function (_, ...)
        local args = {...}

        -- Display current value
        if #args == 0 then
            Msg(name .. " = " .. reg.value)
            return
        end

        reg.value = args[1]

        if type(reg.callback) == "function" then
            local result = reg.callback(...)
            if result ~= nil then
                if type(result) == "boolean" then result = result and "1" or "0" end
                reg.value = tostring(result)
            end
        end

        self:Save(name)
    end, helpText, flags)
    -- else
    --     Convars:RegisterConvar(name, self.registered[name].value, helpText, flags)
    -- end
end

---Manually saves the current value of the convar with a given name.
---This is done automatically when the value is changed if SetPersistent is set to true.
---@param name string
function EasyConvars:Save(name)
    if not self.registered[name] then return end

    local saver = Player or GetListenServerHost()
    if not saver then
        warn("Cannot save convar '"..name.."', player does not exist!")
        return
    end

    saver:SaveString("easyconvar_"..name, self.registered[name].value)
end

---Manually loads the saved value of the convar with a given name.
---This is done automatically when the player spawns for any previously saved convar.
---@param name string
function EasyConvars:Load(name)
    if not self.registered[name] then return end

    local loader = Player or GetListenServerHost()
    if not loader then
        warn("Cannot load convar '"..name.."', player does not exist!")
        return
    end

    print(name, loader:LoadString("easyconvar_"..name, nil))
    self.registered[name].value = loader:LoadString("easyconvar_"..name, self.registered[name].value)
    self.registered[name].persistent = true
    -- If it has a callback, execute to run any necessary code
    if type(self.registered[name].callback) == "function" then
        self.registered[name].callback(self.registered[name].value)
    end
end

---Sets the convar as persistent. It will be saved to the player when changed and load its
---previous state when the map starts.
---
---Convars with previously saved data will have persistence automatically turned on when loaded.
---@param name string
---@param persistent boolean
function EasyConvars:SetPersistent(name, persistent)
    if not self.registered[name] then return end
    self.registered[name].persistent = persistent

    -- Clear data when persistence is turned off
    if not persistent then
        local saver = Player or GetListenServerHost()
        if not saver then
            warn("Could not clear data for convar '"..name.."', player does not exist!")
            return
        end
        saver:SaveString("easyconvar_"..name, nil)
    end
end

---Calls the register function using the same syntax as the built-in convar library, for easy converting.
---@param name string
---@param defaultValue? string
---@param helpText? string
---@param flags? integer
function EasyConvars:RegisterConvar(name, defaultValue, helpText, flags)
    self:Register(name, defaultValue, nil, helpText, flags)
end

---Calls the register function using the same syntax as the built-in convar library, for easy converting.
---@param name string
---@param callback fun(...):any?
---@param helpText? string
---@param flags? integer
function EasyConvars:RegisterCommand(name, callback, helpText, flags)
    self:Register(name, nil, callback, helpText, flags)
end

---Returns the convar as a string.
---@param name string
---@return string?
function EasyConvars:GetString(name)
    if not self.registered[name] then return nil end
    return self.registered[name].value
end

---Returns the convar as a boolean.
---@param name string
---@return boolean?
function EasyConvars:GetBool(name)
    if not self.registered[name] then return nil end
    return truthy(self:GetString(name))
end

---Returns the convar as a float.
---@param name string
---@return number?
function EasyConvars:GetFloat(name)
    if not self.registered[name] then return nil end
    return tonumber(self:GetString(name)) or 0
end

---Returns the convar as an integer.
---@param name string
---@return integer?
function EasyConvars:GetInt(name)
    if not self.registered[name] then return nil end
    return math.floor(self:GetFloat(name))
end

RegisterPlayerEventCallback("player_activate", function (params)
    for name, data in pairs(EasyConvars.registered) do
        EasyConvars:Load(name)
    end
end)