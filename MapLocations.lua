if AutoRecruit == nil then AutoRecruit = {} end
local AR = AutoRecruit
local em = EVENT_MANAGER
local atWayshrine = false

local function tableContains(table, value)
    for i = 1,#table do
    --    d("* "..table[i].." vs "..value)
      if (table[i] == value) then
        return true
      end
    end
    return false
end

function AR.onStartFastTravel(eventCode, nodeIndex)
    atWayshrine = true
end

function AR.onEndFastTravel()
    atWayshrine = false
end
  
local ZONESTATE_HIDDEN = 0
local ZONESTATE_NOJUMP = 1
local ZONESTATE_FRIEND = 2
local ZONESTATE_HOUSE = 3
local ZONESTATE_COOLDOWN = 4

local function hasFriendInZone(zoneId)
    AR.getOnlinePlayers()
    local ownZone = GetUnitWorldPosition("player")
    for i=1, #AR.onlinePlayers do
        local userID = AR.onlinePlayers[i][1]
        local userZone = AR.onlinePlayers[i][2]
  
        if userZone == zoneId and ownZone ~= userZone then
            return true
         elseif i==#AR.onlinePlayers then
            return false
        end
    end
    return false
end

local function getZoneStates(guild)
    -- AR.getZones()
    local zones = {}
    for i=1, #AR.zones do
        local zoneID = AR.zones[i] --GetZoneId(i)
        local zoneName = GetZoneNameById(zoneID)
        
        local lastPosted = AR.lastPosted[zoneName]
        if lastPosted and AR.settings.adCooldown[guild]*60-(GetTimeStamp()-lastPosted) > 10 then
            zones[zoneID] = ZONESTATE_COOLDOWN
        else
            local houseId = AR.HM:GetHouseIDFromZoneID(zoneID)
            if houseId and CanJumpToHouseFromCurrentLocation() then
                -- d("|c6C00FFAuto Port - |cFFFFFF " .. AR.HM:GetName(houseId) .. " in " .. GetZoneNameById(zoneID))
                zones[zoneID] = ZONESTATE_HOUSE
            elseif hasFriendInZone(zoneID) then
                zones[zoneID] = ZONESTATE_FRIEND
                --d("Zone ID "..zoneID..": "..GetZoneNameById(zoneID).." - available")
            else
                zones[zoneID] = ZONESTATE_NOJUMP
            --     d("Zone ID "..zoneID..": "..GetZoneNameById(zoneID).." - nojump")
            end
        end
    end
    return zones
end

local function showWayshrineConfirm(name, nodeIndex)
	-- local nodeIndex,name,refresh,clicked = data.nodeIndex,data.name,data.refresh,data.clicked
	ZO_Dialogs_ReleaseDialog("FAST_TRAVEL_CONFIRM")
	ZO_Dialogs_ReleaseDialog("RECALL_CONFIRM")
	-- name = name or select(2, MapSearch.Wayshrine.Data.GetNodeInfo(nodeIndex)) -- just in case
	local id = (atWayshrine == false and "RECALL_CONFIRM") or "FAST_TRAVEL_CONFIRM"
	if atWayshrine == false then
		local _, timeLeft = GetRecallCooldown()
		if timeLeft ~= 0 then
			local text = zo_strformat(SI_FAST_TRAVEL_RECALL_COOLDOWN, name, ZO_FormatTimeMilliseconds(timeLeft, TIME_FORMAT_STYLE_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS))
		    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, text)
			return
		end
	end
	ZO_Dialogs_ShowPlatformDialog(id, {nodeIndex = nodeIndex}, {mainTextParams = {name}})
end

local function jumpToWayshrineInZoneId(zoneId, zoneName)
    local mapIndex = GetMapIndexByZoneId(zoneId)
    -- d("AutoRecruit: nextZone "..zoneId.." mapIndex "..mapIndex)
    ZO_WorldMap_SetMapByIndex(mapIndex)

    local totalNodes = GetNumFastTravelNodes()
    local i = 1
    while i <= totalNodes do
        local known, name, Xcord, Ycord, icon, glowIcon, typePOI, onMap, isLocked = GetFastTravelNodeInfo(i)
        if typePOI == 1 and not isLocked and onMap and known then
            -- d("Node: "..i)
            d("|c6C00FFAuto Port - |cFFFFFFJumping to " .. name .. " in " .. zoneName.." node "..i)
            -- d(GetFastTravelNodeInfo(i))
            showWayshrineConfirm(name, i)
            -- zo_callLater(function() FastTravelToNode(zoneId) end, 100)
            EVENT_MANAGER:RegisterForEvent("AutoPortArrived", EVENT_PLAYER_ACTIVATED, function() AR.afterPort(zoneId) end)
            --SCENE_MANAGER:Hide("worldMap")
            return true
        end
        i = i + 1
    end

    return false
end

local function onLocationIconPressed(btn)
    if atWayshrine then
        if jumpToWayshrineInZoneId(btn.zoneId, btn.zoneName) then
            return
        end
    end

    if btn.state == ZONESTATE_HOUSE then
        local houseId = AR.HM:GetHouseIDFromZoneID(btn.zoneId)
        if houseId and CanJumpToHouseFromCurrentLocation() then
            -- local houseZone = AR.zones[AR.nextZone]
            d("|c6C00FFAuto Port - |cFFFFFFJumping to " .. AR.HM:GetName(houseId) .. " in " .. btn.zoneName)
            zo_callLater(function() RequestJumpToHouse(houseId, true) end, 100)
            em:RegisterForEvent("AutoPortArrived", EVENT_PLAYER_ACTIVATED, function() AR.afterPort(btn.zoneId) end)
            SCENE_MANAGER:Hide("worldMap")
            return
        end
    elseif btn.state == ZONESTATE_FRIEND then
        for i=1, #AR.onlinePlayers do
            local userID = AR.onlinePlayers[i][1]
            local userZone = AR.onlinePlayers[i][2]

            if userZone == btn.zoneId then
                d("|c6C00FFAuto Port - |cFFFFFFJumping to " .. userID .. " in " .. GetZoneNameById(btn.zoneId))
                zo_callLater(function() JumpToGuildMember(userID) end, 100)
                em:RegisterForEvent("AutoPortArrived", EVENT_PLAYER_ACTIVATED, function() AR.afterPort(btn.zoneId) end)
                SCENE_MANAGER:Hide("worldMap")
                return
            end
        end
    else
        jumpToWayshrineInZoneId(btn.zoneId, btn.zoneName)
    end
end

function WORLD_MAP_LOCATIONS:UpdateLocationList()
	local guild = AR.getGuildIndex(AR.getIDfromName(AR.settings.recruitFor))
    local cooldown = AR.settings.adCooldown[guild]

    local zoneStates = getZoneStates(guild)
    -- AR.getZones()
    -- if not addon.playerAlliance then
    --     addon:MarkDirty()
    --     return
    -- end

    -- ZO_ScrollList_Clear(self.list)

    -- local mapData = addon:BuildLocationList()

    -- self.list.mode = 2
    -- local ZO_ScrollList_CreateDataEntry = ZO_ScrollList_CreateDataEntry
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    for i = 1, #scrollData do
        local data = scrollData[i].data

        -- TODO: Need to compare Location data zone with AR.lastPosted entries;
        -- get the proper name for this Location zone
        local mapName, mapType, mapContentType, zoneIndex, description = GetMapInfoByIndex(data.index)
        local zoneName = GetZoneNameByIndex(zoneIndex)
        local zoneId = GetZoneId(zoneIndex)
        -- local zoneIndex = GetZoneId(zoneIndex)
        --d("AutoRecruit: map '"..data.locationName.."' -> zone "..zoneIndex.." '"..zoneName.."'")

        --d(data.dataEntry.control:GetChild(1))
        local row = data.dataEntry.control
        local label = row:GetChild(1)
        local btn = row:GetChild(2)
        if label and btn == nil and zoneStates[zoneId] then
            btn = WINDOW_MANAGER:CreateControl("$(parent)Sent", row, CT_BUTTON)
            btn.zoneId = zoneId
            btn.zoneName = zoneName
            btn:SetAnchor(TOPLEFT,label,TOPRIGHT,0,0)
            btn:SetDimensions(26,26)
            btn:SetPressedTexture("esoui/art/chatwindow/chat_notification_down.dds")
            btn:SetMouseOverTexture("esoui/art/chatwindow/chat_notification_over.dds")
            btn:SetClickSound(sound or SOUNDS.DEFAULT_CLICK)
        
            btn:SetDrawLayer(DL_CONTROLS)
            btn:SetMouseEnabled(true)
            btn:SetHandler("OnMouseEnter", function(control) ZO_Tooltips_ShowTextTooltip(control, BOTTOM, control.info) end )
            btn:SetHandler("OnMouseExit", function(control) ZO_Tooltips_HideTextTooltip() end )
            btn:SetHandler("OnMouseUp", function(control, button, isInside)
                if(button == 1 and isInside) then
                    onLocationIconPressed(control)
                end
            end)
        end
        if btn then
            if zoneStates[zoneId] then
                btn:SetHidden(false)
                btn:SetEnabled(false)
                btn.state = zoneStates[zoneId]
                -- local r, g, b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
                if zoneStates[zoneId] == ZONESTATE_COOLDOWN then
                    btn:SetNormalFontColor(0.7,1,0.7, 1)
                    btn:SetNormalTexture("esoui/art/miscellaneous/check.dds")
                    btn.info = "Recruitment in cooldown"
                elseif zoneStates[zoneId] == ZONESTATE_NOJUMP then
                    btn:SetNormalFontColor(1,1,1, 1)
                    btn:SetNormalTexture("esoui/art/chatwindow/chat_notification_disabled.dds")
                    btn.info = "Port to wayshrine"
                elseif zoneStates[zoneId] == ZONESTATE_HOUSE then
                    btn:SetNormalFontColor(1,0.9,0.7, 1)
                    btn:SetNormalTexture("esoui/art/chatwindow/chat_notification_up.dds")
                    btn.info = "Jump to house"
                else
                    btn:SetNormalFontColor(1,1,1, 1)
                    btn:SetNormalTexture("esoui/art/chatwindow/chat_notification_up.dds")
                    btn.info = "Jump to friend"
                end
            else
                btn:SetHidden(true)
            end
        end
    end
    -- ARCooldownMarkers.DATA = scrollData[1].data
    -- ARCooldownMarkers.ARSV = arsv

    -- if #addon.account.favorites > 0 then
    --     scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(MAP_TYPE_ID, {alliance = 1001})
    --     for i = 1, #addon.account.favorites do
    --         scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(FAV_TYPE_ID, {index = i})
    --     end
    -- end

    -- addon.recentPosition = #scrollData
    -- if addon.account.showRecentList then
    --     scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(MAP_TYPE_ID, {alliance = 1000})
    --     for i = 1, #addon.player.recent do
    --         scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(RECENT_TYPE_ID, {index = i})
    --     end
    -- end
    -- addon.nextRecentIndex = #scrollData - addon.recentPosition

    -- local lastAlliance = -1
    -- for i = 1, #mapData do
    --     local entry = mapData[i]
    --     if entry.allianceOrder ~= lastAlliance then
    --         lastAlliance = entry.allianceOrder
    --         if entry.alliance < 999 then
    --             scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(ALLIANCE_TYPE_ID, entry)
    --         else
    --             scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(MAP_TYPE_ID, entry)
    --         end
    --     end

    --     scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(LOCATION_TYPE_ID, entry)
    -- end

    -- ZO_ScrollList_Commit(self.list)
end


local function rebuildMapLocationsList()
	-- if GAMEPAD_WORLD_MAP_LOCATIONS.votanListIsDirty and GAMEPAD_WORLD_MAP_LOCATIONS_FRAGMENT:IsShowing() then
	-- 	GAMEPAD_WORLD_MAP_LOCATIONS:BuildLocationList()
	-- 	SortFavs(addon.account.favorites)
	-- 	GAMEPAD_WORLD_MAP_LOCATIONS.votanListIsDirty = false
	-- end
	-- if WORLD_MAP_LOCATIONS.votanListIsDirty and WORLD_MAP_LOCATIONS_FRAGMENT:IsShowing() then
    if WORLD_MAP_LOCATIONS_FRAGMENT:IsShowing() then
        WORLD_MAP_LOCATIONS:UpdateLocationList()
		-- SortFavs(addon.account.favorites)
		-- WORLD_MAP_LOCATIONS.votanListIsDirty = false
	end
end

function AR.MapLocationsStateChange(oldState, newState)
	if newState == SCENE_SHOWING then
        -- d("AutoRecruit.MapLocationsStateChange: SCENE_SHOWING")
		rebuildMapLocationsList()
	-- elseif newState == SCENE_SHOWN then
    --     d("AutoRecruit.MapLocationsStateChange: SCENE_SHOWN")
	-- 	rebuildMapLocationsList()
		-- PushActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_VOTANS_IMPROVED_LOCATIONS))
		-- addon:InitializeKeybindDescriptors()
		-- KEYBIND_STRIP:AddKeybindButtonGroup(addon.keybindStripDescriptor)
	elseif newState == SCENE_HIDING then
		-- KEYBIND_STRIP:RemoveKeybindButtonGroup(addon.keybindStripDescriptor)
		-- RemoveActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_VOTANS_IMPROVED_LOCATIONS))
	end
end
