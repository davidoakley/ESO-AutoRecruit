local wm = GetWindowManager()

if AutoRecruit == nil then AutoRecruit = {} end
local AR = AutoRecruit


function AR.MakeWindow()
	AR.window = wm:CreateTopLevelWindow("ARWindow")
	local ar = AR.window
	ar:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AR.settings.x, AR.settings.y)
	ar:SetMovable(true)
	ar:SetHidden(not AR.settings.shown)
	ar:SetMouseEnabled(true)
	ar:SetClampedToScreen(true)
	ar:SetDimensions(0,0)
	ar:SetResizeToFitDescendents(true)
	ar:SetHandler("OnMoveStop", function()
		AR.settings.x = ar:GetLeft()
		AR.settings.y = ar:GetTop()
	end)

	ar.title = wm:CreateControl("ARTitle", ar, CT_LABEL)
	ar.title:SetAnchor(TOP, ar, TOP, 0, 5)
	ar.title:SetFont("EsoUi/Common/Fonts/Univers67.otf|18|soft-shadow-thin")
	ar.title:SetColor(.9,.9,.7,1)
	ar.title:SetStyleColor(0,0,0,1)
	ar.title:SetText("Auto Recruit")
	ar.title:SetHidden(not AR.settings.showtitle)

	ar.zone = wm:CreateControl("ARZone", ar, CT_LABEL)
	if (AR.settings.showtitle) then
		ar.zone:SetAnchor(TOP, ar.title, BOTTOM, 0, 5)
	else
		ar.zone:SetAnchor(TOP, ar, TOP, 0, 5)
	end
	ar.zone:SetFont("EsoUi/Common/Fonts/Univers67.otf|17|soft-shadow-thin")
	ar.zone:SetColor(.9, .9, .7, 1)
	ar.zone:SetStyleColor(0,0,0,1)
	ar.zone:SetText("Zone Name")

	ar.entries = wm:CreateControl("AREntries", ar, CT_CONTROL)
	ar.entries:SetAnchor(TOP, ar.zone, BOTTOM, 0, 0)
	ar.entries:SetHidden(false)
	ar.entries:SetResizeToFitDescendents(true)

	ar.entries:SetResizeToFitPadding(20, 10)
	
	if ZO_CompassFrame:IsHandlerSet("OnShow") then
		local oldHandler = ZO_CompassFrame:GetHandler("OnShow")
		ZO_CompassFrame:SetHandler("OnShow", function(...) oldHandler(...) if AR.settings.shown then AR.window:SetHidden(false) end end)
	else
		ZO_CompassFrame:SetHandler("OnShow", function(...) if AR.settings.shown then AR.window:SetHidden(false) end end)
	end
	if ZO_CompassFrame:IsHandlerSet("OnHide") then
		local oldHandler = ZO_CompassFrame:GetHandler("OnHide")
		ZO_CompassFrame:SetHandler("OnHide", function(...) oldHandler(...) if AR.settings.shown then AR.window:SetHidden(true) end end)
	else
		ZO_CompassFrame:SetHandler("OnHide", function(...) if AR.settings.shown then AR.window:SetHidden(true) end end)
	end
	
end


function AR.PopulateWindow(guildName)
	if AR.window == nil then AR.MakeWindow() end
	AR.window.zone:SetText(guildName)
	
	AR.window:SetHidden(ZO_CompassFrame:IsHidden() or not AR.settings.shown)
end