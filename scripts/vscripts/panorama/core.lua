--[[
    v0.1.1
]]

if thisEntity then
    require"panorama.core"

    ---The unique ID for this script.
    local ID = DoUniqueString("panoid")

    thisEntity:SetContextThink("sendid", function()
        Panorama:Register(ID, thisEntity)
    end, 0)

    ---Get the ID for this entity's panel.
    ---@return string
    function thisEntity:GetPanoramaID()
        return ID
    end

    ---Send data to this script's registered panel.
    ---@param command string
    ---@param ... string
    function thisEntity:SendToPanel(command, ...)
        Panorama:Send(ID, command, ...)
    end

    ---@param spawnkeys CScriptKeyValues
    function Spawn(spawnkeys)
        thisEntity:SetContextNum("panel_width",spawnkeys:GetValue("width"),0)
        thisEntity:SetContextNum("panel_height",spawnkeys:GetValue("height"),0)
        thisEntity:SetContextNum("panel_dpi",spawnkeys:GetValue("panel_dpi"),0)
    end

else

    ---@class Panorama
    Panorama = {}

    ---Send the unique ID to this panel so it knows which data to parse.
    ---This is done automatically on script execution if you include this script:
    ---
    ---    DoIncludeScript("panorama/core", thisEntity:GetPrivateScriptScope())
    ---@param id string # Unique ID for the panel.
    ---@param panel EntityHandle # The panel entity to assign id.
    function Panorama:Register(id, panel)
        DoEntFireByInstanceHandle(panel, "AddCSSClass", id, 0, nil, nil)
    end


    ---Filters text string to replace problematic characters.
    ---@param text string
    ---@return string
    local function FilterText(text)
        text = text:gsub("'", "U+00027")
        text = text:gsub("\n", "U+000A")
        return text
    end

    ---Sends data to panorama panel.
    ---The first argument should be the command and all subsequent values are args.
    ---@param id string
    ---@param ... any
    function Panorama:Send(id, ...)
        local dataString = id .. "|"
        local data = {...}
        local i = 1
        -- Quick hack to flatten nested tables into data
        while i <= #data do
            if type(data[i]) == "table" then
                data = vlua.extend(vlua.slice(data, 1, #data), data[i])
            end
            i = i + 1
        end
        for index, value in ipairs(data) do
            dataString = dataString .. tostring(value)
            if index < #data then dataString = dataString .. "|" end
        end
        dataString = FilterText(dataString)
        --print("Sending to pano:", dataString)
        SendToConsole("@panorama_dispatch_event AddStyleToEachChild('"..dataString.."')")
    end

end
