if AutoRecruit == nil then AutoRecruit = {} end
local AR = AutoRecruit

local function OnRowSelect()
end

local function LayoutCategoryRow(rowControl, data, scrollList)
    d("LayoutCategoryRow")
    rowControl.label:SetText(data.text)
end

local function BuildScrollList()
    d("BuildScrollList")
    local scrollList = AutoRecruit_WorldMapTabList

    -- Build a scroll list (test)
    ZO_ScrollList_Clear(scrollList)
    local scrollData = ZO_ScrollList_GetDataList(scrollList)

    local apEntry = ZO_ScrollList_CreateDataEntry(0, { text = "Auto Port Zones" })
    table.insert(scrollData, apEntry)

    local mEntry = ZO_ScrollList_CreateDataEntry(0, { text = "Manual Zones" })
    table.insert(scrollData, mEntry)

    ZO_ScrollList_Commit(scrollList)    
end

function AR.initializeMapTab()
    local mapTabControl = AutoRecruit_WorldMapTab

    local normal = "/esoui/art/guildfinder/tabicon_recruitment_up.dds"
    local highlight = "/esoui/art/guildfinder/tabicon_recruitment_over.dds"
    local pressed = "/esoui/art/guildfinder/tabicon_recruitment_down.dds"

    -- Set up tab at top of Map screen's right pane
    WORLD_MAP_INFO.modeBar:Add(AUTO_RECRUIT_MAPTAB, { mapTabControl.fragment }, { pressed = pressed, highlight = highlight, normal = normal })

    -- Set up the scroll list
    local scrollList = AutoRecruit_WorldMapTabList
    ZO_ScrollList_AddDataType(scrollList, 0, "AutoRecruit_WorldMapCategoryRow", 40, LayoutCategoryRow, nil, nil, nil)
	-- ZO_ScrollList_AddDataType(scrollList, 1, "AutoRecruit_WorldMapZoneRow", 23, setupFunction, hideCallback, dataTypeSelectSound, resetControlCallback)
	ZO_ScrollList_EnableSelection(scrollList, "ZO_ThinListHighlight", OnRowSelect)

    BuildScrollList()
end