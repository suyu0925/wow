--[[
	A title frame widget that can search on double-click
--]]


local ADDON, Addon = ...
local Title = Addon.Tipped:NewClass('Title', 'Button')
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local C = LibStub('C_Everywhere')


--[[ Construct ]]--

function Title:New(parent, title)
	local b = self:Super(Title):New(parent)
	b.title = title

	b:RegisterSignal('SEARCH_TOGGLED', 'UpdateVisible')
	b:RegisterFrameSignal('OWNER_CHANGED', 'Update')
	b:SetScript('OnHide', b.OnMouseUp)
	b:RegisterForClicks('anyUp')
	b:SetToplevel(true)
	b:Update()
	b:Show()

	return b
end


--[[ Interaction ]]--

function Title:OnEnter()
	self:ShowTooltip(self:GetText(), format('|L %s   |L|L %s', L.Drag, SEARCH), '|R ' .. OPTIONS)
end

function Title:OnMouseDown()
	local parent = self:GetParent()
	if parent:CanDrag() then
		parent:StartMoving()
	end
end

function Title:OnMouseUp()
	local parent = self:GetParent()
	parent:StopMovingOrSizing()
	parent:SavePosition()
end

function Title:OnDoubleClick()
	Addon.canSearch = true
	Addon:SendSignal('SEARCH_TOGGLED', self:GetFrameID())
end

function Title:OnClick(button)
	if button == 'RightButton' and C.AddOns.LoadAddOn(ADDON .. '_Config') then
		Addon.FrameOptions.frame = self:GetFrameID()
		Addon.FrameOptions:Open()
	end
end


--[[ API ]]--

function Title:Update()
	self:SetFormattedText(self.title, self:GetOwner().name or ' ')
	self:GetFontString():SetAllPoints(self)
end

function Title:UpdateVisible(busy)
	self:SetShown(not busy)
end

function Title:IsFrameMovable()
	return not Addon.sets.locked
end

function Title:GetTipAnchor()
	return self, 'ANCHOR_TOPLEFT'
  end
