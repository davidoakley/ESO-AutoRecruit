if AutoRecruit == nil then AutoRecruit = {} end
local AR = AutoRecruit

local ZONESTATE_HIDDEN = 0
local ZONESTATE_NOJUMP = 1
local ZONESTATE_FRIEND = 2
local ZONESTATE_HOUSE = 3
local ZONESTATE_COOLDOWN = 4

local atWayshrine = false

-- city: /esoui/art/icons/poi/poi_city_complete.dds
-- town: /esoui/art/icons/poi/poi_town_complete.dds

local function OnStartFastTravel(eventCode, nodeIndex)
	atWayshrine = true
end

local function OnEndFastTravel()
	atWayshrine = false
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
	local zones = {}
	local timestamp = GetTimeStamp()
	local cooldown = AR.settings.adCooldown[guild]*60
	for i=1, #AR.zones do
		local zoneID = AR.zones[i] --GetZoneId(i)
		local zoneName = GetZoneNameById(zoneID)

		local lastPosted = AR.lastPosted[zoneName]
		if lastPosted and cooldown-(timestamp-lastPosted) > 10 then
			zones[zoneID] = ZONESTATE_COOLDOWN
		else
			local houseId = AR.zoneHouses[zoneID]
			if houseId and CanJumpToHouseFromCurrentLocation() then
				zones[zoneID] = ZONESTATE_HOUSE
			elseif hasFriendInZone(zoneID) then
				zones[zoneID] = ZONESTATE_FRIEND
			else
				zones[zoneID] = ZONESTATE_NOJUMP
			end
		end
	end
	return zones
end

function AutoRecruitRowMouseUp(control, mouseButton, upInside)
	if(upInside) then
		local data = ZO_ScrollList_GetData(control:GetParent())
		--MapSearch.clickedData = data
		-- ShowWayshrineConfirm(data, MapSearch.isRecall)
		jumpToWayshrineInZoneId(data.zoneId, data.text)
		-- if data.clicked then
		-- 	data:clicked(control,button)
		-- 	-- self:RowMouseClicked(control,data,button)
		-- 	logger:Info("Row Mouse Up clicked? "..data.clicked)
		-- end
	end
end

local function LayoutCategoryRow(rowControl, data, scrollList)
	rowControl.label:SetText(data.text)
end

local function LayoutZoneRow(rowControl, data, scrollList)
	rowControl.label:SetText(data.text)
	if data.icon ~= nil then
		rowControl.icon:SetTexture(data.icon)
		rowControl.icon:SetHidden(false)
	else
		rowControl.icon:SetHidden(true)
	end
	if data.state == ZONESTATE_COOLDOWN then
		rowControl.disabled = true
		rowControl:SetAlpha(0.75)
		rowControl.label:SetMouseEnabled(false)
		rowControl.icon:SetMouseEnabled(false)
		-- rowControl:SetDesaturation(1.0)
	end
end

function AR.rebuildMapTabList()
	local guild = AR.getGuildIndex(AR.getIDfromName(AR.settings.recruitFor))

	local zoneStates = getZoneStates(guild)

	local scrollList = AutoRecruit_WorldMapTabList

	-- Build a scroll list (test)
	ZO_ScrollList_Clear(scrollList)
	local scrollData = ZO_ScrollList_GetDataList(scrollList)

	local apEntry = ZO_ScrollList_CreateDataEntry(0, { text = "Auto Port Zones" })
	table.insert(scrollData, apEntry)

	local hasInCooldown = false
	for i=1, #AR.zones do
			local zoneId = AR.zones[i]
			if zoneStates[zoneId] ~= ZONESTATE_COOLDOWN then
					local zoneName = GetZoneNameById(zoneId)

					local entry = ZO_ScrollList_CreateDataEntry(1, {
							zoneId = zoneId,
							text = zoneName,
							icon = "/esoui/art/tutorial/poi_wayshrine_complete.dds",
							state = zoneStates[zoneId]
					})
					table.insert(scrollData, entry)
			else
					hasInCooldown = true
			end
	end

	if hasInCooldown then
			local apEntry = ZO_ScrollList_CreateDataEntry(0, { text = "Zones In Cooldown" })
			table.insert(scrollData, apEntry)

			for i=1, #AR.zones do
					local zoneId = AR.zones[i]
					if zoneStates[zoneId] == ZONESTATE_COOLDOWN then
							local zoneName = GetZoneNameById(zoneId)

							local entry = ZO_ScrollList_CreateDataEntry(1, {
									zoneId = zoneId,
									text = zoneName,
									icon = "esoui/art/miscellaneous/check.dds",
									state = zoneStates[zoneId]
							})
							table.insert(scrollData, entry)
					end
			end

	end
	-- local mEntry = ZO_ScrollList_CreateDataEntry(0, { text = "Manual Zones" })
	-- table.insert(scrollData, mEntry)

	ZO_ScrollList_Commit(scrollList)
end

function AR.initializeMapTab()
	local mapTabControl = AutoRecruit_WorldMapTab

	-- Set up tab at top of Map screen's right pane
	local normal = "/esoui/art/guildfinder/tabicon_recruitment_up.dds"
	local highlight = "/esoui/art/guildfinder/tabicon_recruitment_over.dds"
	local pressed = "/esoui/art/guildfinder/tabicon_recruitment_down.dds"
	mapTabControl.fragment = ZO_FadeSceneFragment:New(mapTabControl)
	mapTabControl.fragment.duration = 100
	WORLD_MAP_INFO.modeBar:Add(AUTO_RECRUIT_MAPTAB, { mapTabControl.fragment }, { pressed = pressed, highlight = highlight, normal = normal })

	-- Set up the scroll list
	local scrollList = AutoRecruit_WorldMapTabList
	ZO_ScrollList_AddDataType(scrollList, 0, "AutoRecruit_WorldMapCategoryRow", 40, LayoutCategoryRow, nil, nil, nil)
	ZO_ScrollList_AddDataType(scrollList, 1, "AutoRecruit_WorldMapZoneRow", 23, LayoutZoneRow, nil, nil, nil)
	-- ZO_ScrollList_EnableSelection(scrollList, "ZO_ThinListHighlight", OnRowSelect)

	AR.rebuildMapTabList()

	SCENE_MANAGER:GetScene('worldMap'):RegisterCallback("StateChange",
	function(oldState, newState)
		if newState == SCENE_SHOWING then
			AR.rebuildMapTabList()
			-- KEYBIND_STRIP:AddKeybindButtonGroup(ButtonGroup)
		elseif newState == SCENE_HIDDEN then
			-- KEYBIND_STRIP:RemoveKeybindButtonGroup(ButtonGroup)
		end
	end)

	EVENT_MANAGER:RegisterForEvent("AutoRecruitStartFastTravel", EVENT_START_FAST_TRAVEL_INTERACTION, OnStartFastTravel)
  EVENT_MANAGER:RegisterForEvent("AutoRecruitEndFastTravel", EVENT_END_FAST_TRAVEL_INTERACTION, OnEndFastTravel)
end