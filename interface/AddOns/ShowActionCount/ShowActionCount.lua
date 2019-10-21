local function ShowActionCount_UpdateCount(actionButton)
    local text = actionButton.Count
    local action = actionButton.action
    if not IsItemAction(action) and GetActionCount(action) > 0 then
        local count = GetActionCount(action)
        if ( count > (actionButton.maxDisplayCount or 9999 ) ) then
            text:SetText("*")
        else
            text:SetText(count)
            -- print(GetActionInfo(action))
        end
    end
end

local function ShowActionCount_Init()
    hooksecurefunc("ActionButton_UpdateCount", ShowActionCount_UpdateCount)
end

ShowActionCount_Init()