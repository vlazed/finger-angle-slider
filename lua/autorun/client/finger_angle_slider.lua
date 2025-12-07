local xyLock = CreateClientConVar(
	"finger_lock_limits",
	"0",
	true,
	false,
	"If enabled, it locks the X and Y limits to a single value"
)

local fingerMode = "finger"

---@param ply Player
---@return TOOL|false
local function fingerposerEquipped(ply)
	---@type TOOL
	local tool = ply:GetTool()
	return tool and tool.Mode == fingerMode and tool
end

local function buildAngleSlider()
	---@class AngleSliderFrame: EditablePanel
	local frame = vgui.Create("EditablePanel")

	frame.list = vgui.Create("DCategoryList", frame)
	frame.list:Dock(FILL)

	local margin = 10
	function frame:PerformLayout(w, h)
		local cpanel = spawnmenu.ActiveControlPanel():GetParent():GetParent()
		if not cpanel then
			return
		end

		local x, y = cpanel:GetPos()
		w, h = cpanel:GetSize()

		self:SetSize(w, h * 0.55)
		-- self:SizeToChildren(false, true)
		self:SetPos(x, y - self:GetTall() - margin)
	end

	frame.form = vgui.Create("DForm", frame.list)
	frame.form:Dock(FILL)
	frame.form:SetLabel("Max Angle Sliders")

	frame.form:Help("Moving the sliders below will allow you to move a finger beyond its default limits.")

	---@class AngleSliderLockCheck: DCheckBoxLabel
	frame.checkbox = frame.form:CheckBox("Lock limits", "finger_lock_limits")
	---@class AngleSlider: DNumSlider
	frame.sliderX = frame.form:NumSlider("X Limit", "finger_max_x", 0, 360, 3)
	---@class AngleSlider
	frame.sliderY = frame.form:NumSlider("Y Limit", "finger_max_y", 0, 360, 3)

	frame.form:Help(
		"TIP: Hold shift to move a finger with more precision. This is default behavior provided by the game, not by this addon"
	)

	frame.hangOpen = false

	function frame:SetHangOpen(val)
		self.hangOpen = val
	end

	function frame:GetHangOpen()
		return self.hangOpen
	end

	function frame:StartKeyFocus(pPanel)
		self.focus = pPanel

		self:SetKeyboardInputEnabled(true)
		self:SetHangOpen(true)
	end

	function frame:EndKeyFocus(pPanel)
		if self.focus ~= pPanel then
			return
		end
		self:SetKeyboardInputEnabled(false)
	end

	function frame:TestHover(x, y)
		local x, y = self:ScreenToLocal(x, y)
		return (x >= 0 and x <= self:GetWide()) and (y >= 0 and y <= self:GetTall())
	end

	function frame:Think()
		frame.sliderY:SetEnabled(not frame.checkbox:GetChecked())
		if frame.checkbox:GetChecked() then
			frame.sliderY:SetValue(frame.sliderX:GetValue())
		end

		local x, y = input.GetCursorPos()
		self.hovered = self:TestHover(x, y)
		if self.hovered and not self:IsMouseInputEnabled() then
			self:MakePopup()
		elseif not self.hovered and self:IsMouseInputEnabled() then
			self:SetMouseInputEnabled(false)
			self:SetKeyboardInputEnabled(false)
		end
	end

	return frame
end

---@type AngleSliderFrame
VLAZED_FINGER_ANGLE_SLIDER = VLAZED_FINGER_ANGLE_SLIDER
if VLAZED_FINGER_ANGLE_SLIDER then
	VLAZED_FINGER_ANGLE_SLIDER:Remove()
end
-- After a few ticks, vgui components should be available
timer.Simple(0.1, function()
	VLAZED_FINGER_ANGLE_SLIDER = buildAngleSlider()
end)

local function openAngleSlider()
	if
		fingerposerEquipped(LocalPlayer())
		and IsValid(VLAZED_FINGER_ANGLE_SLIDER)
		and not VLAZED_FINGER_ANGLE_SLIDER:IsVisible()
	then
		VLAZED_FINGER_ANGLE_SLIDER:SetVisible(true)
		-- VLAZED_FINGER_ANGLE_SLIDER:MakePopup()
	end
end

local function closeAngleSlider()
	if not IsValid(VLAZED_FINGER_ANGLE_SLIDER) then
		return
	end

	if VLAZED_FINGER_ANGLE_SLIDER:GetHangOpen() then
		VLAZED_FINGER_ANGLE_SLIDER:SetHangOpen(false)
		return
	end

	VLAZED_FINGER_ANGLE_SLIDER:SetMouseInputEnabled(false)
	VLAZED_FINGER_ANGLE_SLIDER:SetKeyboardInputEnabled(false)
	VLAZED_FINGER_ANGLE_SLIDER:SetVisible(false)
end

hook.Remove("OnContextMenuOpen", "finger_angle_slider_hookcontext")
hook.Add("OnContextMenuOpen", "finger_angle_slider_hookcontext", openAngleSlider)

hook.Remove("OnContextMenuClose", "finger_angle_slider_hookcontext")
hook.Add("OnContextMenuClose", "finger_angle_slider_hookcontext", closeAngleSlider)

local function menuKeyboardFocusOn(pnl)
	if IsValid(VLAZED_FINGER_ANGLE_SLIDER) and IsValid(pnl) and pnl:HasParent(VLAZED_FINGER_ANGLE_SLIDER) then
		VLAZED_FINGER_ANGLE_SLIDER:StartKeyFocus(pnl)
	end
end
hook.Remove("OnTextEntryGetFocus", "finger_angle_slider_menuKeyboardFocusOn")
hook.Add("OnTextEntryGetFocus", "finger_angle_slider_menuKeyboardFocusOn", menuKeyboardFocusOn)

local function menuKeyboardFocusOff(pnl)
	if IsValid(VLAZED_FINGER_ANGLE_SLIDER) and IsValid(pnl) and pnl:HasParent(VLAZED_FINGER_ANGLE_SLIDER) then
		VLAZED_FINGER_ANGLE_SLIDER:EndKeyFocus(pnl)
	end
end
hook.Remove("OnTextEntryLoseFocus", "finger_angle_slider_menuKeyboardFocusOff")
hook.Add("OnTextEntryLoseFocus", "finger_angle_slider_menuKeyboardFocusOff", menuKeyboardFocusOff)
