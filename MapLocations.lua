if AutoRecruit == nil then AutoRecruit = {} end
local AR = AutoRecruit

function WORLD_MAP_LOCATIONS:UpdateLocationList()
	local guild = AR.getGuildIndex(AR.getIDfromName(AR.settings.recruitFor))
    local cooldown = AR.settings.adCooldown[guild]
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
        --d(data.dataEntry.control:GetChild(1))
        --data.dataEntry.control:GetChild(1):SetColor(1, 1, 1, 1)
        local label = data.dataEntry.control:GetChild(1)
        local tex = label:GetChild(1)
        if label and tex == nil then
            tex = WINDOW_MANAGER:CreateControl("$(parent)Sent", label, CT_TEXTURE)
            tex:SetAnchor(TOPLEFT,label,TOPRIGHT,0,0)
            tex:SetDimensions(26,26)
            tex:SetTexture("esoui/art/tutorial/chat-notifications_up.dds")
		end
		local hidden = true
		if AR.lastPosted[data.locationName] then
			local cooldown = AR.settings.adCooldown[guild]*60-(GetTimeStamp()-AR.lastPosted[data.locationName])
		
			if cooldown>10 then
				hidden = false
			end
			-- d(data.locationName..': '..cooldown)
		end
		tex:SetHidden(hidden)

        local locName = data.locationName
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
		rebuildMapLocationsList()
	elseif newState == SCENE_SHOWN then
		rebuildMapLocationsList()
		-- PushActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_VOTANS_IMPROVED_LOCATIONS))
		-- addon:InitializeKeybindDescriptors()
		-- KEYBIND_STRIP:AddKeybindButtonGroup(addon.keybindStripDescriptor)
	elseif newState == SCENE_HIDING then
		-- KEYBIND_STRIP:RemoveKeybindButtonGroup(addon.keybindStripDescriptor)
		-- RemoveActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_VOTANS_IMPROVED_LOCATIONS))
	end
end

