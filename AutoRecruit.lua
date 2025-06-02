if AutoRecruit == nil then AutoRecruit = {} end
local AR = AutoRecruit
local em = EVENT_MANAGER
AutoRecruitKeybind = {}

AR.name = "AutoRecruit"
AR.version = "3.1.0"
AR.cooldown = {0, 0, 0, 0, 0}
AR.inviteeID = "@"
AR.posted = ""
AR.lastPosted = {}
AR.doubleCheck = 0
AR.onlinePlayers = {}
AR.zones = {}
AR.nextZone = 1
AR.status = 0
AR.lastRound = 0
AR.failed = 0
AR.portingTo = nil
AR.settings = {}
AR.defaults = {
    recruitFor = GetGuildName(GetGuildId(1)),

    whisperEnabled = false,
    standardEnabled = true,
    keyword = "",
    caseSensitive = false,

    notifications = true,
    trader = true,
    warning = 5,
    shown = true,
		showPending = true,

    portMode = "Semi-auto",
    postAd = true,
    keepPorting = false,
    portingTime = 15,
    skipZoneOnCD = true,
    includedZones = "Major",
    saveLastPosted = false,

    guild1 = false,
    ad = {"", "", "", "", ""},
    guild = {},
    welcome = {},
    welcomeText = {"", "", "", "", ""},
    welcomeCooldown = {30, 30, 30, 30, 30},
    adCooldown = {15, 15, 15, 15, 15},
}


	function AR.getIDfromName(guildname)
		for guild = 1, GetNumGuilds() do
		  if guildname == GetGuildName(GetGuildId(guild))
		   then return GetGuildId(guild)
	    end
	  end
	end
	

	function AR.getGuildIndex(guildID)
		for guild = 1, GetNumGuilds() do
		  if guildID == GetGuildId(guild) then
		  	return guild
	    end
	  end
	end


  function AR.checkFor(string1, string2)
  	if string1 == nil or string2 == nil then
  		return false
  	 elseif string.match(string1, string2) == string2 then
  	 	return true
  	 else
  	 	return false
  	end
  end


  function AutoRecruitKeybind.pasteText(guild)
  	CHAT_SYSTEM:Maximize()
    local currentZone = GetPlayerActiveZoneName()

  	if string.len(AR.settings.ad[guild]) > 0 then
  	 	local cooldown = 0

  	 	if AR.lastPosted[currentZone] then
  	 		cooldown = math.ceil((AR.settings.adCooldown[guild]*60-(GetTimeStamp()-AR.lastPosted[currentZone]))/60)
  	 	end

  	 	if cooldown>1 and AR.doubleCheck ~= 1 then
  	 		d("|c6C00FFAuto Recruit - |cFFFFFF " .. currentZone .. " still on cooldown for " .. cooldown .. " more minutes")
  	 		zo_callLater(function() d("|cFFFFFFPress 'Paste' again within 5 seconds to post it anyways") end, 1500)
  	 		AR.doubleCheck = 1
  	 		zo_callLater(function() AR.doubleCheck = 0 end, 6000)
  	 	 elseif cooldown==1 and AR.doubleCheck ~= 1 then
  	 		d("|c6C00FFAuto Recruit - |cFFFFFF " .. currentZone .. " still on cooldown for " .. cooldown .. " more minute")
  	 		zo_callLater(function() d("|cFFFFFFPress 'Paste' again within 5 seconds to post it anyways") end, 1500)
  	 		AR.doubleCheck = 1
  	 		zo_callLater(function() AR.doubleCheck = 0 end, 6000)
  	 	 else
    		d("|c82fa58Recruitment message for " .. GetGuildName(GetGuildId(guild)) .. " pasted to the chat (" .. currentZone .. ")")
    		ZO_ChatWindowTextEntryEditBox:SetText("/z " .. AR.settings.ad[guild])
    		AR.settings.recruitFor = GetGuildName(GetGuildId(guild))
				AR.RefreshWindow()
  	  end
  	 else
		d("|c6C00FFAuto Recruit - |cFF8174You have not specified a recruitment message for " .. GetGuildName(GetGuildId(guild)) .. " yet.")
  	end
  end


  function AR.freeSpots(guildID)
  	local freeSpots = 500-zo_strformat("<<1>>", GetGuildInfo(guildID))-zo_strformat("<<4>>", GetGuildInfo(guildID))

  	if freeSpots<=AR.settings.warning then
  		if freeSpots == 0 then
  			return ("|cFF8174This guild is now full!")
  		 elseif freeSpots == 1 then
  			return ("|c82fa58There is just|cFF8174 1 |c82fa58free spot left. Please notify |cFFFFFF" .. zo_strformat("<<3>>", GetGuildInfo(guildID)) .. ".")
  		 else
  			return ("|c82fa58There are just |cFF8174" .. freeSpots .. "|c82fa58 free spots left. Please notify |cFFFFFF" .. zo_strformat("<<3>>", GetGuildInfo(guildID)) .. ".")
  		end
  	 else
  	 	return ("|c82fa58There are " .. freeSpots .. " free spots left.")
  	end
  end


  function AR.memberAdded(eventCode, guildID, userID)
  	local guild = AR.getGuildIndex(guildID)

  	if AR.settings.notifications then
  		CHAT_SYSTEM:Maximize()
    	for guild=1, GetNumGuilds() do
        if guildID == AR.getIDfromName(AR.settings.recruitFor) or guildID == GetGuildId(guild) and AR.settings.guild[guild] then
         	if not GetGuildMemberIndexFromDisplayName(guildID, userID) then
         		d("|cFFFFFF" .. userID .. "|c82fa58 has been invited to " .. GetGuildName(guildID) .. ".")
   			   else
   			   	d("|cFFFFFF" .. userID .. "|c82fa58 joined " .. GetGuildName(guildID) .. ".")
   				  d(AR.freeSpots(guildID))
   				end
   			  break
        end
  		end
	  end

	  if AR.settings.welcome[guild] and GetGuildMemberIndexFromDisplayName(guildID, userID) then
	   	AR.inviteeID = userID
    	local message = string.gsub(AR.settings.welcomeText[guild], "@", userID, 1)
    	local messageAnon = string.gsub(string.gsub(AR.settings.welcomeText[guild], ", @", "", 1), " @", "", 1)
	   	local _, _, _, playerStatus = GetGuildMemberInfo(guildID, GetGuildMemberIndexFromDisplayName(guildID, userID))

  	  if playerStatus~=4 then
  	  	if AR.cooldown[guild]<GetTimeStamp() and string.len(ZO_ChatWindowTextEntryEditBox:GetText())==0 then
  	     	CHAT_SYSTEM:Maximize()
  	     	ZO_ChatWindowTextEntryEditBox:SetText("/g" .. guild .. " " .. message)
  	     	AR.posted = (ZO_ChatWindowTextEntryEditBox:GetText())
  	     elseif ZO_ChatWindowTextEntryEditBox:GetText() == AR.posted then
  	     	CHAT_SYSTEM:Maximize()
  	     	ZO_ChatWindowTextEntryEditBox:SetText("/g" .. guild .. " " .. messageAnon)
  	    end
  	  end
	  end
  end


  function AR.Invite(userID)
  	local delay = math.random(2500, 10000)
  	local guildID = AR.getIDfromName(AR.settings.recruitFor)

  	zo_callLater(function()
  		CHAT_SYSTEM:Maximize()
  		GuildInvite(guildID, userID)
  		if AR.settings.trader and not GetGuildKioskAttribute(guildID) then
  			d("|cFF8174" .. AR.settings.recruitFor .. " has not hired a trader!")
  		end
  	end, delay)
  end


  function AR.context(userID)

    for guild = 1, GetNumGuilds() do
      local guildID = GetGuildId(guild)

      if DoesPlayerHaveGuildPermission(guildID, GUILD_PERMISSION_INVITE) and not GetGuildMemberIndexFromDisplayName(guildID, userID) then
        AddCustomMenuItem("|c82fa58Invite to |cFFFFFF" .. GetGuildName(guildID), function() GuildInvite(guildID, userID)  end)
      end

      if GetGuildMemberIndexFromDisplayName(guildID, userID) and DoesPlayerHaveGuildPermission(guildID, GUILD_PERMISSION_REMOVE)
       and tonumber(zo_strformat("<<3>>", GetGuildMemberInfo(guildID, GetGuildMemberIndexFromDisplayName(guildID, userID)))) > tonumber(zo_strformat("<<3>>", GetGuildMemberInfo(guildID, GetGuildMemberIndexFromDisplayName(guildID, GetDisplayName())))) then
      	AddCustomMenuItem("|cFF8174Kick from |cFFFFFF" .. GetGuildName(guildID), function() GuildRemove(guildID, userID) end)
      end
    end
  end


  function AR.getZones()
	  AR.zones = {}
    local minSkyshards = (AR.settings.includedZones == "All") and 0 or 15

    for i = 1, GetNumMaps() do
      local _, _, _, zoneIndex, _ = GetMapInfoByIndex(i)
      local zoneID = GetZoneId(zoneIndex)
	  -- Include parent zones, plus Apocrypha, Arteum and Solstice;
	  -- exclude "Clean Test", Cyrodiil and Imperial City
      if (zoneID == GetParentZoneId(zoneID) or zoneID==1413 or zoneID==1027 or zoneID == 1502) and
					(GetNumSkyshardsInZone(zoneID)>=minSkyshards or zoneID == 1502) and
          zoneID~=181 and zoneID~=584 and zoneID~=2 and CanJumpToPlayerInZone(zoneID) then
        table.insert(AR.zones, zoneID)
      end
    end

		if minSkyshards == 0 then
			-- The Brass Fortress is a separate zone chat area, but not on a top-level map
			table.insert(AR.zones, 981)
		end
  end


  function AR.getOnlinePlayers()
  	AR.onlinePlayers = {}
  	for guild=1, GetNumGuilds() do
  		local guildID = GetGuildId(guild)

  		for i=1, GetNumGuildMembers(guildID) do
  			local userID, _, _, playerStatus = GetGuildMemberInfo(guildID, i)

  			if playerStatus~=4 and userID~=GetDisplayName() then
  			  local _, _, _, _, _, _, _, zoneID = GetGuildMemberCharacterInfo(guildID, i)
  			  table.insert(AR.onlinePlayers, { userID, zoneID })
  			end
    	end
    end
  end

  function AR.getHouses()
    AR.zoneHouses = {}
    local function IsHousingCat(categoryData)
      return categoryData:IsHousingCategory()
    end
  
    local function IsHouseCollectible(collectibleData)
      return collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_HOUSE)
    end
  
    for i, categoryData in ZO_COLLECTIBLE_DATA_MANAGER:CategoryIterator({IsHousingCat}) do
      for j, subCategoryData in categoryData:SubcategoryIterator({IsHousingCat}) do
        for k, subCatCollectibleData in subCategoryData:CollectibleIterator({IsHouseCollectible}) do
          if subCatCollectibleData:IsUnlocked() and not subCatCollectibleData:IsBlocked() then
            local houseID = subCatCollectibleData:GetReferenceId()
            local zoneID = GetHouseFoundInZoneId(houseID)
            if not AR.zoneHouses[zoneID] then
              local name, _, _, _, _, _, _, _, _ = GetCollectibleInfo(subCatCollectibleData:GetId())
              AR.zoneHouses[zoneID] = { houseID, name }
            end
          end
        end
      end
    end
  end
  
  function AutoRecruitKeybind.start()
  	AR.status = 1
  	AR.start()
  end


  function AutoRecruitKeybind.stop()
  	AR.status = 0
  	AR.stop()
  end




function AR.Initialize(event, addon)

	if addon ~= AR.name then return end

	em:UnregisterForEvent("AutoRecruitInitialize", EVENT_ADD_ON_LOADED)

	AR.settings = ZO_SavedVars:NewAccountWide("AutoRecruitSavedVars", 1, nil, AR.defaults)
  if AR.settings.saveLastPosted then
    AR.lastPosted = ZO_SavedVars:NewAccountWide("AutoRecruitLastPosted", 1, nil, {})
  end

	ZO_CreateStringId("SI_BINDING_NAME_AUTO_RECRUIT_PASTE1", "Paste " .. GetGuildName(GetGuildId(1)) .. "'s Ad")
	ZO_CreateStringId("SI_BINDING_NAME_AUTO_RECRUIT_PASTE2", "Paste " .. GetGuildName(GetGuildId(2)) .. "'s Ad")
	ZO_CreateStringId("SI_BINDING_NAME_AUTO_RECRUIT_PASTE3", "Paste " .. GetGuildName(GetGuildId(3)) .. "'s Ad")
	ZO_CreateStringId("SI_BINDING_NAME_AUTO_RECRUIT_PASTE4", "Paste " .. GetGuildName(GetGuildId(4)) .. "'s Ad")
	ZO_CreateStringId("SI_BINDING_NAME_AUTO_RECRUIT_PASTE5", "Paste " .. GetGuildName(GetGuildId(5)) .. "'s Ad")
	ZO_CreateStringId("SI_BINDING_NAME_AUTO_RECRUIT_STARTPORT", "Start porting")
	ZO_CreateStringId("SI_BINDING_NAME_AUTO_RECRUIT_STOPPORT", "Stop porting")

	AR.MakeMenu()
	AR.getZones()

	em:RegisterForEvent("AutoRecruitStart", EVENT_PLAYER_ACTIVATED, function(...) AR.RefreshWindow(...) end)
  em:RegisterForEvent("AutoRecruitStart", EVENT_CHAT_MESSAGE_CHANNEL, AR.chatMessage)
  em:RegisterForEvent("AutoRecruitStart", EVENT_ACTION_LAYER_POPPED, AR.chatMessage)
  em:RegisterForEvent("AutoRecruitInfo", EVENT_GUILD_MEMBER_ADDED, AR.memberAdded)

  LibCustomMenu:RegisterPlayerContextMenu(AR.context)

end

em:RegisterForEvent("AutoRecruitInitialize", EVENT_ADD_ON_LOADED, function(...) AR.Initialize(...) end)




function AR.afterPort(destination)
	em:UnregisterForEvent("AutoPortArrived", EVENT_PLAYER_ACTIVATED)

	if GetUnitWorldPosition("player") == destination then
		AR.failed = 0
		AR.portingTo = nil
		
		if AR.settings.postAd then
			AutoRecruitKeybind.pasteText(AR.getGuildIndex(AR.getIDfromName(AR.settings.recruitFor)))
		end

		if AR.status == 1 and AR.settings.portMode == "Full-auto" then AR.start() end
	end
end



function AR.portFailed(destination)
	local zoneName = GetZoneNameById(destination)

	if AR.status == 1 then
	  d("|c6C00FFAuto Port - |cFFFFFFFailed to port to " .. zoneName .. " trying again...")
		AR.portingTo = nil
	  AR.nextZone = AR.nextZone - 1
	  AR.start()
	end
end

function AR.keepPorting()
	if AR.status ~= 2 then return end

	local delay = AR.settings.portingTime*60-(GetTimeStamp()-AR.lastRound)

	if delay<=5 then
		AR.start()
	else
		AR.RefreshWindow()

		if AR.settings.shown then
			delay = 5 -- If the window is visible, update status every 5 seconds
		else
			if delay>120 then
				d("|c6C00FFAuto Port - |cFFFFFFStarting another loop in " .. math.floor(delay/60) .. " minutes...")
				delay = 60
			elseif delay>60 then
				d("|c6C00FFAuto Port - |cFFFFFFStarting another loop in ~1 minute...")
				delay = delay - 45 -- next alert with 45 seconds left
			else
				d("|c6C00FFAuto Port - |cFFFFFFStarting another loop in " .. delay .. " seconds...")
				delay = 15
			end
		end
		zo_callLater(function() AR.keepPorting() end, delay*1000)
	end
end

function AR.start()
	if AR.status == 0 then return end

	if AR.status == 2 then
		d("|c6C00FFAuto Port - |cFFFFFFStarting another loop now...")
	end

  CancelCast()
	em:UnregisterForEvent("AutoPortArrived", EVENT_PLAYER_ACTIVATED)
	AR.status = 1


  if AR.nextZone > #AR.zones then
  	AR.status = 2
  	AR.nextZone = 1
  	d("|c6C00FFAuto Port - |cFFFFFFLoop finished")

  	if AR.settings.keepPorting then
			AR.keepPorting()
  	end

	  AR.RefreshWindow()
  	return
  end

  AR.getOnlinePlayers()
  AR.getHouses()
  local nextZoneName = GetZoneNameById(AR.zones[AR.nextZone])
  local guild = AR.getGuildIndex(AR.getIDfromName(AR.settings.recruitFor))
  local ownZone = GetUnitWorldPosition("player")

  if AR.nextZone == 1 then
  	AR.lastRound = GetTimeStamp()
  end

  if ownZone == AR.zones[AR.nextZone] then
  	AR.nextZone = AR.nextZone + 1
  end

 	if AR.lastPosted[nextZoneName] and AR.settings.skipZoneOnCD then
 		local cooldown = AR.settings.adCooldown[guild]*60-(GetTimeStamp()-AR.lastPosted[nextZoneName])
 		
 		if cooldown>10 then
 			d("|c6C00FFAuto Port - |cFFFFFF" .. nextZoneName .. " is still on cooldown. Skipping this zone...")
  		AR.nextZone = AR.nextZone + 1
  		AR.start()
 		  return
 		end
 	end


  for i=1, #AR.onlinePlayers do
  	local userID = AR.onlinePlayers[i][1]
  	local userZone = AR.onlinePlayers[i][2]

  	if userZone == AR.zones[AR.nextZone] and ownZone ~= userZone then
  		d("|c6C00FFAuto Port - |cFFFFFFJumping to " .. userID .. " in " .. GetZoneNameById(userZone))
  		AR.nextZone = AR.nextZone + 1
			AR.portingTo = GetZoneNameById(userZone)
  		zo_callLater(function() JumpToGuildMember(userID) end, 100)
    	em:RegisterForEvent("AutoPortArrived", EVENT_PLAYER_ACTIVATED, function() AR.afterPort(userZone) end)
    	zo_callLater(function()
    		if ownZone==GetUnitWorldPosition("player") and userZone == AR.zones[AR.nextZone-1] then
    			if AR.failed<3 then
    		    AR.failed = AR.failed + 1
    		    AR.portFailed(userZone)
    		   else
    		   	d("|c6C00FFAuto Port - |cFFFFFFPorting to " .. GetZoneNameById(userZone) .. " failed. Try again later.")
    		   	AR.stop()
    		  end
    		end
    	end, 10000)
		  AR.RefreshWindow()
  		return
  	end
  end

  local houseId = AR.zoneHouses[AR.zones[AR.nextZone]] --AR.HM:GetHouseIDFromZoneID(AR.zones[AR.nextZone])
	if houseId and CanJumpToHouseFromCurrentLocation() then
		local houseZone = AR.zones[AR.nextZone]
    local houseID, houseName = unpack(AR.zoneHouses[houseZone])
		d("|c6C00FFAuto Port - |cFFFFFFJumping to " .. houseName .. " in " .. nextZoneName)
		AR.nextZone = AR.nextZone + 1
		AR.portingTo = nextZoneName
		zo_callLater(function() RequestJumpToHouse(houseID, true) end, 100)
		em:RegisterForEvent("AutoPortArrived", EVENT_PLAYER_ACTIVATED, function() AR.afterPort(houseZone) end)
		AR.RefreshWindow()
		return
	end

  d("|c6C00FFAuto Port - |cFFFFFFCould not port to " .. nextZoneName .. ". Skipping this zone...")
  AR.nextZone = AR.nextZone + 1
  AR.start()
end



function AR.stop()
	CancelCast()
	em:UnregisterForEvent("AutoPortArrived", EVENT_PLAYER_ACTIVATED)
  AR.status = 0
	d("|c6C00FFAuto Port - |cFFFFFFStopped porting.")
	AR.RefreshWindow()
end



function AR.chatMessage(_, channel, _, text, _, userID)
	if not text or string.len(text) < 1 then return end
	
	if channel == 2 and AR.settings.whisperEnabled then
		local key = AR.settings.keyword

		if not AR.settings.caseSensitive then
			text = string.lower(text)
			key = string.lower(AR.settings.keyword)
		end

		if AR.checkFor(text, key) and string.len(key) >= 1 and key ~= " " then
			AR.Invite(userID)
		end

		if AR.settings.standardEnabled then
			if AR.checkFor(text, "search") or AR.checkFor(text, "add") or AR.checkFor(text, "space") or AR.checkFor(text, "glad") or AR.checkFor(text, "need")
  			or AR.checkFor(text, "inv") or AR.checkFor(text, "+") or AR.checkFor(text, "join") or AR.checkFor(text, "sign") or AR.checkFor(text, "interest")
  			or AR.checkFor(text, "looking for") or AR.checkFor(text, "look for") and not AR.checkFor(text, "group") and not AR.checkFor(text, "raid")
  			and not AR.checkFor(text, "pve") and not AR.checkFor(text, "pvp")
			 then
				AR.Invite(userID)
			end
		end
	end
	
	
  if channel == 31 and text == AR.settings.ad[AR.getGuildIndex(AR.getIDfromName(AR.settings.recruitFor))] then
    AR.lastPosted[GetPlayerActiveZoneName()] = GetTimeStamp()
  end
  
  
	for guild=1, GetNumGuilds() do

		if AR.settings.welcomeText[guild] ~= nil and AR.settings.welcomeText[guild] ~= "" then
			local message = string.gsub(AR.settings.welcomeText[guild], "@", AR.inviteeID, 1)
			message = string.gsub(message, "%W", "")
			local messageAnon = string.gsub(string.gsub(AR.settings.welcomeText[guild], ", @", "", 1), " @", "", 1)
			messageAnon = string.gsub(messageAnon, "%W", "")
			local text2 = string.gsub(text, "%W", "")

			if channel == 11+guild and (AR.checkFor(text2, message) or AR.checkFor(text2, messageAnon)) then
				AR.cooldown[guild] = GetTimeStamp() + (AR.settings.welcomeCooldown[guild]*60)

				if ZO_ChatWindowTextEntryEditBox:GetText() == text then
					ZO_ChatWindowTextEntryEditBox:Clear()
				end
			end
		end
	end


	if channel == 31 and AR.status == 1 and AR.settings.portMode == "Semi-auto" and GetUnitWorldPosition("player") == AR.zones[AR.nextZone-1]
	   and userID == GetDisplayName() and text == AR.settings.ad[AR.getGuildIndex(AR.getIDfromName(AR.settings.recruitFor))] then
	 AR.start()
	end

	AR.RefreshWindow()
end