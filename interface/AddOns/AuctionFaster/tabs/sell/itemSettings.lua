---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
--- @type ItemCache
local ItemCache = AuctionFaster:GetModule('ItemCache');
--- @type Sell
local Sell = AuctionFaster:GetModule('Sell');

function Sell:DrawItemSettingsPane()
	local sellTab = self.sellTab;

	local pane = StdUi:Window(sellTab, '物品设定', 200, 100);
	StdUi:GlueAfter(pane, sellTab, 0, -150, 0, 0);

	if AuctionFaster.db.itemSettingsOpened then
		pane:Show();
	else
		pane:Hide();
	end

	pane:SetScript('OnShow', function() AuctionFaster.db.itemSettingsOpened = true end);
	pane:SetScript('OnHide', function() AuctionFaster.db.itemSettingsOpened = false end);

	sellTab.itemSettingsPane = pane;
	self:DrawItemSettings();
end

function Sell:DrawItemSettings()
	local pane = self.sellTab.itemSettingsPane;

	local icon = StdUi:Texture(pane, 30, 30, nil);

	local itemName = StdUi:Label(pane, '没有选择物品', nil, 'GameFontNormalLarge', 150);

	local rememberStack = StdUi:Checkbox(pane, '记住堆叠设定');

	local rememberLastPrice = StdUi:Checkbox(pane, '记住最后价格');

	local alwaysUndercut = StdUi:Checkbox(pane, '持续竞价');

	local useCustomDuration = StdUi:Checkbox(pane, '自定义时间');

	local options = {
		{text = '12h', value = 1},
		{text = '24h', value = 2},
		{text = '48h', value = 3}
	}
	local duration = StdUi:Dropdown(pane, 150, 20, options);
	StdUi:AddLabel(pane, duration, '拍卖持续时间', 'TOP');

	local priceModels = AuctionFaster:GetModule('Pricing'):GetPricingModels();
	local priceModel = StdUi:Dropdown(pane, 150, 20, priceModels);
	StdUi:AddLabel(pane, priceModel, '定价模式', 'TOP');

	StdUi:GlueTop(icon, pane, 10, -40, 'LEFT');
	StdUi:GlueAfter(itemName, icon, 10, 0);
	StdUi:GlueBelow(rememberStack, icon, 0, -10, 'LEFT');
	StdUi:GlueBelow(rememberLastPrice, rememberStack, 0, -10, 'LEFT');
	StdUi:GlueBelow(alwaysUndercut, rememberLastPrice, 0, -10, 'LEFT');
	StdUi:GlueBelow(useCustomDuration, alwaysUndercut, 0, -10, 'LEFT');
	StdUi:GlueBelow(duration, useCustomDuration, 0, -30, 'LEFT');
	StdUi:GlueBelow(priceModel, duration, 0, -30, 'LEFT');

	pane.icon = icon;
	pane.itemName = itemName;
	pane.rememberStack = rememberStack;
	pane.rememberLastPrice = rememberLastPrice;
	pane.alwaysUndercut = alwaysUndercut;
	pane.useCustomDuration = useCustomDuration;
	pane.duration = duration;
	pane.priceModel = priceModel;

	self:LoadItemSettings();
	self:InitItemSettingsScripts();
	self:InitItemSettingsTooltips();
	-- this will mark all settings disabled
end

function Sell:InitItemSettingsScripts()
	local pane = self.sellTab.itemSettingsPane;

	pane.rememberStack.OnValueChanged = function(self, flag)
		Sell:UpdateItemSettings('rememberStack', flag);
	end;

	pane.rememberLastPrice.OnValueChanged = function(self, flag)
		Sell:UpdateItemSettings('rememberLastPrice', flag);
	end;

	pane.alwaysUndercut.OnValueChanged = function(self, flag)
		Sell:UpdateItemSettings('alwaysUndercut', flag);
	end;

	pane.useCustomDuration.OnValueChanged = function(self, flag)
		Sell:UpdateItemSettings('useCustomDuration', flag);
		Sell:UpdateItemSettingsCustomDuration(flag);
	end;

	pane.duration.OnValueChanged = function(self, value)
		Sell:UpdateItemSettings('duration', value);
	end;

	pane.priceModel.OnValueChanged = function(_, value)
		if not self.loadingItemSettings then
			self:UpdateItemSettings('priceModel', value);
			self:RecalculateCurrentPrice();
		end
	end
end

function Sell:UpdateItemSettingsCustomDuration(useCustomDuration)
	local pane = self.sellTab.itemSettingsPane;

	if useCustomDuration then
		pane.duration:Enable();
	else
		pane.duration:Disable();
	end
end

function Sell:InitItemSettingsTooltips()
	local pane = self.sellTab.itemSettingsPane;

	StdUi:FrameTooltip(
		pane.rememberStack,
		'选中此选项将使操作更快地记住\n' ..
		'您希望立即出售的堆叠\n以及堆栈有多大',
		'AFInfoTT', 'TOPLEFT', true
	);

	StdUi:FrameTooltip(
		pane.rememberLastPrice, function(tip)
			tip:AddLine('如果此项目没有拍卖,');
			tip:AddLine('记住最后价格.');
			tip:AddLine('');
			tip:AddLine('您的竞价被否决', 1, 0, 0);
			tip:AddLine('如果选中了“持续竞价”选项！', 1, 0, 0);
		end,
		'AFInfoTTX', 'TOPLEFT', true
	);

	StdUi:FrameTooltip(
		pane.alwaysUndercut,
		'默认情况下，拍卖速度越快，价格越低\n如果切换“则不会记住最后一次价格”，\n'..
		'如果取消选中此选项，则拍卖速度更快\n将永远不会降低您的物品价格。',
		'AFInfoTT', 'TOPLEFT', true
	);
end

function Sell:LoadItemSettings()
	local pane = self.sellTab.itemSettingsPane;
	self.loadingItemSettings = true;

	if not self.selectedItem then
		pane.icon:SetTexture(nil);

		pane.itemName:SetText('No Item selected');
		pane.rememberStack:SetChecked(true);
		pane.rememberLastPrice:SetChecked(false);
		pane.alwaysUndercut:SetChecked(true);
		pane.useCustomDuration:SetChecked(false);
		pane.duration:SetValue(2);
		pane.priceModel:SetValue('Simple');

		self:EnableDisableItemSettings(false);

		self.loadingItemSettings = false;
		return;
	end

	local item = self:GetSelectedItemRecord();

	self:EnableDisableItemSettings(true);
	pane.icon:SetTexture(self.selectedItem.icon);
	pane.itemName:SetText(self.selectedItem.link);
	pane.rememberStack:SetChecked(item.settings.rememberStack);
	pane.rememberLastPrice:SetChecked(item.settings.rememberLastPrice);
	pane.alwaysUndercut:SetChecked(item.settings.alwaysUndercut);
	pane.useCustomDuration:SetChecked(item.settings.useCustomDuration);
	pane.duration:SetValue(item.settings.duration);
	if not item.settings.priceModel then
		item.settings.priceModel = 'Simple';
	end
	pane.priceModel:SetValue(item.settings.priceModel);

	Sell:UpdateItemSettingsCustomDuration(item.settings.useCustomDuration);

	self.loadingItemSettings = false;
end

function Sell:EnableDisableItemSettings(enable)
	local pane = self.sellTab.itemSettingsPane;
	if enable then
		pane.rememberStack:Enable();
		pane.rememberLastPrice:Enable();
		pane.alwaysUndercut:Enable();
		pane.useCustomDuration:Enable();
		pane.duration:Enable();
		pane.priceModel:Enable();
	else
		pane.rememberStack:Disable();
		pane.rememberLastPrice:Disable();
		pane.alwaysUndercut:Disable();
		pane.useCustomDuration:Disable();
		pane.duration:Disable();
		pane.priceModel:Disable();
	end
end

function Sell:UpdateItemSettings(settingName, settingValue)
	if not self.selectedItem or self.loadingItemSettings then
		return;
	end

	local cacheKey = self.selectedItem.itemId .. self.selectedItem.itemName;
	ItemCache:UpdateItemSettingsInCache(cacheKey, settingName, settingValue);
end

function Sell:ToggleItemSettingsPane()
	if self.sellTab.itemSettingsPane:IsShown() then
		self.sellTab.itemSettingsPane:Hide();
	else
		self.sellTab.itemSettingsPane:Show();
	end
end