--[[------------------------------------------------------------------------------------------------
Title:          House Data Manager
Author:         Static_Recharge
Description:    Keeps track of the user's owned houses and which zones they are in.
------------------------------------------------------------------------------------------------]]--


--[[------------------------------------------------------------------------------------------------
Libraries and Aliases
------------------------------------------------------------------------------------------------]]--
local CDM = ZO_COLLECTIBLE_DATA_MANAGER

if AutoRecruit == nil then AutoRecruit = {} end
local AR = AutoRecruit

--[[------------------------------------------------------------------------------------------------
HDM Class Initialization
HDM    - Object containing all functions, tables, variables,and constants.
  |-  Data      - Contains the gathered data for each house the player owns. Indexed the same as the 
                game client.
------------------------------------------------------------------------------------------------]]--
local HDM = ZO_InitializingObject:Subclass()


function HDM:Initialize()
  self.Data = {}
  self:Update()
end


--Collects all of the housing data from the collections menu.
function HDM:Update()
  local function IsHousingCat(categoryData)
    return categoryData:IsHousingCategory()
  end

  local function IsHouseCollectible(collectibleData)
    return collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_HOUSE)
  end

	for i, categoryData in CDM:CategoryIterator({IsHousingCat}) do
		for j, subCategoryData in categoryData:SubcategoryIterator({IsHousingCat}) do
			for k, subCatCollectibleData in subCategoryData:CollectibleIterator({IsHouseCollectible}) do
				if subCatCollectibleData:IsUnlocked() and not subCatCollectibleData:IsBlocked() then
					local name, _, _, _, _, _, _, _, _ = GetCollectibleInfo(subCatCollectibleData:GetId())
					local houseID = subCatCollectibleData:GetReferenceId()
					local data = {
            name = name,
            houseID = houseID,
            zoneID = GetHouseFoundInZoneId(houseID),
					}
					table.insert(self.Data, data)
				end
			end
		end
	end
	--table.sort(self.Data, function(k1, k2) return k1.name < k2.name end)
end


function HDM:GetName(id)
  for i,v in ipairs(self.Data) do
    if v.houseID == id then
      return v.name
    end
  end
end


function HDM:GetZoneID(id)
  local zoneID
  for i,v in ipairs(self.Data) do
    if v.houseID == id then
      return v.zoneID
    end
  end
end


function HDM:GetHouseIDFromZoneID(id)
  local houseID
  for i,v in ipairs(self.Data) do
    if v.zoneID == id then
      return v.houseID
    end
  end
end


function HDM:GetNamesList()
  local List = {}
  for i,v in ipairs(self.Data) do
    table.insert(List,v.name)
  end
  return List
end


function HDM:GetIDList()
  local List = {}
  for i,v in ipairs(self.Data) do
    table.insert(List,v.houseID)
  end
  return List
end

function AR.InitHouseDataManager()
  return HDM:New()
end