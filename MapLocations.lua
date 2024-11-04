if AutoRecruit == nil then AutoRecruit = {} end
local AR = AutoRecruit

local function tableContains(table, value)
    for i = 1,#table do
    --    d("* "..table[i].." vs "..value)
      if (table[i] == value) then
        return true
      end
    end
    return false
end

local ZONESTATE_HIDDEN = 0
local ZONESTATE_NOJUMP = 1
local ZONESTATE_AVAILABLE = 2

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

local function getZoneStates()
    local zones = {}
    for i=1, GetNumZones() do
        local zoneID = GetZoneId(i)
        if GetZoneId(i) == GetParentZoneId(zoneID) and
           CanJumpToPlayerInZone(zoneID) and
           (GetNumSkyshardsInZone(zoneID)>=AR.settings.minSkyshards) and
           zoneID~=181 and zoneID~=584 then
            if hasFriendInZone(zoneID) then
                zones[zoneID] = ZONESTATE_AVAILABLE
                --d("Zone ID "..zoneID..": "..GetZoneNameById(zoneID).." - available")
            else
                zones[zoneID] = ZONESTATE_NOJUMP
            --     d("Zone ID "..zoneID..": "..GetZoneNameById(zoneID).." - nojump")
            end
        elseif zoneID == 1027 then
            -- d("Zone ID "..zoneID..": "..GetZoneNameById(zoneID).." - hidden parent "..GetParentZoneId(zoneID).." shards "..GetNumSkyshardsInZone(zoneID))
            --     zones[zoneID] = ZONESTATE_HIDDEN
        end
    end
    return zones
end

function WORLD_MAP_LOCATIONS:UpdateLocationList()
	local guild = AR.getGuildIndex(AR.getIDfromName(AR.settings.recruitFor))
    local cooldown = AR.settings.adCooldown[guild]

    local zoneStates = getZoneStates()
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
        local label = data.dataEntry.control:GetChild(1)
        local tex = label:GetChild(1)
        if label and tex == nil then
            tex = WINDOW_MANAGER:CreateControl("$(parent)Sent", label, CT_TEXTURE)
            tex:SetAnchor(TOPLEFT,label,TOPRIGHT,0,0)
            tex:SetDimensions(26,26)
		end
		local hidden = true
        local inCooldown = false
        local noJump = false
        if zoneStates[zoneId] then
            hidden = false
            local lastPosted = AR.lastPosted[zoneName]
            if lastPosted then
                local cooldown = AR.settings.adCooldown[guild]*60-(GetTimeStamp()-lastPosted)
            
                if cooldown>10 then
                    inCooldown = true
                end
                -- d(data.locationName..': '..cooldown)
            elseif zoneStates[zoneId] == ZONESTATE_NOJUMP then
                noJump = true
            end
        else
            d("AutoRecruit: zoneId "..zoneId.." '"..zoneName.."' not in zones")
        end
		tex:SetHidden(hidden)
        local r, g, b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
        if inCooldown then
            tex:SetTexture("esoui/art/miscellaneous/check.dds")
            tex:SetColor(r, g, b, 1)
            tex.info = "Recruitment in cooldown"
        elseif noJump then
            tex:SetColor(1,1,1, 0.5)
            tex:SetTexture("esoui/art/chatwindow/chat_notification_disabled.dds")
            tex.info = "No friend to jump to"
        else
            tex:SetColor(1,1,1, 1)
            tex:SetTexture("esoui/art/chatwindow/chat_notification_up.dds")
            tex.info = "Jump available"
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

