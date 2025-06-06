--[[
Copyright 2008-2025 João Cardoso
Sushi is distributed under the terms of the GNU General Public License (or the Lesser GPL).
This file is part of Sushi.

Sushi is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Sushi is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Sushi. If not, see <http://www.gnu.org/licenses/>.
--]]

local Lib = LibStub('Sushi-3.2')
local Group = Lib.Callable:NewSushi('Group', 3, 'Frame')
if not Group then return end


--[[ Construct ]]--

function Group:Construct()
	local f = self:Super(Group):Construct()
	f:SetScript('OnSizeChanged', f.OnSizeChanged)
	f:SetScript('OnHide', f.ReleaseChildren)
	f:SetScript('OnShow', f.UpdateChildren)
	f.Children = {}
	return f
end

function Group:New(parent, children)
	local f = self:Super(Group):New(parent)
	f:SetSize(self.Size, self.Size)
	f:SetChildren(children)
	return f
end

function Group:Reset()
	self:SetBackdrop(nil)
	self:ReleaseChildren()
	self:Super(Group):Reset()
end


--[[ Events ]]--

function Group:OnSizeChanged()
	if self.limit ~= self:GetLimit() then
		self:Layout()
	elseif self:CanLayout() then
		self:FireCalls('OnResize')
	end
end


--[[ Children ]]--

function Group:SetChildren(call, force)
	self:SetCall('OnChildren', call)
	self:UpdateChildren(force)
end

function Group:UpdateChildren(force)
	if self:CanLayout() or force then
		self:ReleaseChildren()
		self:FireCalls('OnChildren')
		self:Layout()
	end
end

function Group:Add(object, ...)
	local kind = type(object)
	assert(kind == 'string' or kind == 'function' or kind == 'table', 'Bad argument #1 to `:Add` (string, function or frame expected)')

	if kind == 'string' then
		local class = Lib[object]
		assert(class, 'Sushi-3.2 class `' .. object .. '` was not found.')
		assert(type(class) == 'table', 'Sushi-3.2 class name `' .. object .. '` is a reserved keyword')
		object = class(self, ...)
	elseif kind == 'function' then
		object = object(self, ...)
	elseif object.SetParent then
		object:SetParent(self)
	end

	if object.SetCall then
		object:SetCall('OnUpdate', function() self:Update(); self:FireCalls('OnUpdate') end)
		object:SetCall('OnResize', function() self:Layout() end)
	end

	tinsert(self.Children, object)
	return object
end

function Group:AddBreak()
	tinsert(self.Children, self.Break)
end

function Group:ReleaseChildren()
	for i, child in self:IterateChildren() do
		if child.Release then
			child:Release()
		end
	end

	wipe(self.Children)
end

function Group:IterateChildren()
	return ipairs(self.Children)
end

function Group:NumChildren()
	return #self.Children
end


--[[ Layout ]]--

function Group:Layout(force)
	if self:CanLayout() or force then
		self.limit = self:GetLimit()
	else
		return
	end

	local w, h, x, y = 0, 0, 0, 0
	local function breakLine()
		y = y + h
		w = max(w, x)
		h, x = 0, 0
	end

	for i, child in self:IterateChildren() do
		if child ~= self.Break then
			local top, left = child.top or 0, child.left or 0
			local bottom, right = child.bottom or 0, child.right or 0
			local width, height = child:GetSize()

			if child.centered then
				if self:GetResizing() == 'HORIZONTAL' then
					top = (self:GetHeight() - child:GetHeight()) / 2
				else
					left = (self:GetWidth() - child:GetWidth()) / 2
				end
			end

			width, height = self:Orient(width + left + right, height + top + bottom)
			top, left = self:Orient(top, left)

			if self.limit and (x + width) > self.limit then
	 			breakLine()
	 		end

			local a,b = self:Orient(x + left, y + top)
			child:ClearAllPoints()
			child:SetPoint('TOPLEFT', a, -b)

			h = max(h, height)
			x = x + width
		else
			breakLine()
		end
	end

	x, y = self:Orient(max(x, w), y + h)
	if self:GetResizing() == 'HORIZONTAL' then
		self:SetSize(x, max(y, self:GetHeight()))
		self:FireCalls('OnResize')
	elseif self:GetResizing() == 'VERTICAL' then
		self:SetSize(max(x, self:GetWidth()), y)
		self:FireCalls('OnResize')
	end
end

function Group:CanLayout()
	return self:GetCalls('OnChildren') and self:IsVisible()
end


--[[ Orientation ]]--

function Group:SetOrientation(orientation)
	self.orientation = orientation
	self:Layout()
end

function Group:GetOrientation()
	return self.orientation
end

function Group:Orient(a, b)
	if self:GetOrientation() == 'HORIZONTAL' then
		return a,b
	end
	return b,a
end


--[[ Resizing ]]--

function Group:SetResizing(resizing)
	self.resizing = resizing
	self:Layout()
end

function Group:GetResizing()
	return self.resizing
end

function Group:GetLimit()
	return self:GetResizing() ~= self:GetOrientation() and self:Orient(self:GetSize())
end


--[[ Backdrop ]]--

function Group:SetBackdrop(template)
	if self.pool then
		self.pool:Release(self.bg)
	end

	if template and template ~= 'NONE' then -- backwards compatibility
		local template = self.Backdrops[template] or template -- backwards compatibility
		local pool = self.Pools[template] or CreateFramePool('Frame', UIParent, template)
		local bg = pool:Acquire()
		bg:SetParent(self)
		bg:SetFrameLevel(self:GetFrameLevel())
		bg:SetPoint('BOTTOMRIGHT', 0, -10)
		bg:SetPoint('TOPLEFT', 0, 10)
		bg:EnableMouse(true)
		bg:Show()

		self.pool, self.bg = pool, bg
		self.Pools[template] = pool
	else
		self.pool, self.bg = nil
	end

	self.backdrop = template
end

function Group:GetBackdrop()
	return self.backdrop
end


--[[ Properties ]]--

Group.orientation, Group.resizing = 'VERTICAL', 'VERTICAL'
Group.Update = Group.UpdateChildren
Group.Pools, Group.Break = {}, {}
Group.Size = 200
Group.Backdrops = { -- backwards compatibility
	DIALOG  = 'DialogBorderDarkTemplate',
	TOOLTIP = 'TooltipBackdropTemplate'}