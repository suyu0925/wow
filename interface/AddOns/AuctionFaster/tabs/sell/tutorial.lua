---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
--- @type Tutorial
local Tutorial = AuctionFaster:GetModule('Tutorial');
--- @type Sell
local Sell = AuctionFaster:GetModule('Sell');

local C = WrapTextInColorCode;
local red = 'FFFF0000';
local green = 'FF00FF00';
local orange = 'FFFFFF00';

function Sell:DrawHelpButton()
	local helpBtn = StdUi:SquareButton(self.sellTab, 16, 16);
	helpBtn:SetIcon([[Interface\FriendsFrame\InformationIcon]], 16, 16, true);

	StdUi:GlueLeft(helpBtn, AuctionFrameCloseButton, -10, 0);

	helpBtn:SetScript('OnClick', function ()
		self:InitTutorial(true);
	end);

	local settingsBtn = StdUi:SquareButton(self.sellTab, 16, 16);
	settingsBtn:SetIcon([[Interface\GossipFrame\BinderGossipIcon]], 16, 16, true);

	StdUi:GlueLeft(settingsBtn, helpBtn, -5, 0);

	settingsBtn:SetScript('OnClick', function ()
		AuctionFaster:OpenSettingsWindow();
	end);

	StdUi:FrameTooltip(helpBtn, 'Addon Tutorial', 'afAddonTutorialOne', 'TOPLEFT', true);
	StdUi:FrameTooltip(settingsBtn, 'Addon settings', 'afAddonSettingsOne', 'TOPLEFT', true);

	self.helpBtn = helpBtn;
end

function Sell:InitTutorial(force)
	if not AuctionFaster.db.tutorials.sell and not force then
		return;
	end

	if not self.tutorials then
		local sellTab = self.sellTab;
		self.tutorials = {
			{
				text   =  '欢迎更快地进行拍卖。\n\n我建议您至少在“”之前查看一次“卖出”教程。' ..
					' 防止你不小心把贵重物品卖了.\n\n:)',
				anchor = 'CENTER',
				parent = sellTab,
				noglow = true
			},
			{
				text   = '这是可以出售的所有库存项目的列表，无需移动任何内容。\n\n' ..
					C('选择项目后，AuctionFaster将自动扫描第一页和竞价'..
					' 根据选择的价格模型设置出价/购买。', red),
				anchor = 'LEFT',
				parent = sellTab.itemsList,
			},
			{
				text   = '在这里您将看到所选项目。最大堆叠是指你能卖出多少栈'
					.. ' 剩余将仍然留在袋子后。',
				anchor = 'RIGHT',
				parent = sellTab.iconBackdrop,
			},
			{
				text   = '将拍卖缓存保留大约10分钟，您可以看到上一次真正扫描的时间' ..
					' 已执行.\n\n' .. C('您可以单击刷新拍卖再次扫描', green),
				anchor = 'RIGHT',
				parent = sellTab,
				customAnchor = sellTab.lastScan,
			},
			{
				text   = '您的竞价 ' .. C('每项.', red) .. '\n\n' ..
					C('明白多种货币形式', green) ..
					', 举例:\n\n' .. '5金 6银 19铜\n999银 50铜\n3000银\n9000000铜',
				anchor = 'LEFT',
				parent = sellTab.bidPerItem,
			},
			{
				text   = '你的买价 ' .. C('每项.', red) .. ' 按物品拍卖的货币格式.',
				anchor = 'LEFT',
				parent = sellTab.buyPerItem,
			},
			{
				text   = '要出售的最大堆叠数\n\n' ..
					C('将此值设置为0则出售所有内容', orange),
				anchor = 'LEFT',
				parent = sellTab.maxStacks,
			},
			{
				text   = '这将打开项目设置。\n再次单击可关闭。\n\n' ..
					C('将鼠标悬停在复选框上以查看选项是什么。\n\n', green) ..
					C('这些设置是针对特定项目的', orange),
				anchor = 'RIGHT',
				action = function()
					sellTab.itemSettingsPane:Show();
				end,
				parent = sellTab.buttons.itemSettings,
			},
			{
				text   = '这将打开拍卖信息：\n\n' ..
					'- 总拍卖买入价。\n' ..
					'- 押金成本。\n'..
					'- 拍卖数量\n' ..
					'- 拍卖持续时间\n\n' ..
					C('这将在更改堆叠大小或最大堆叠时动态更改.', green),
				anchor = 'RIGHT',
				action = function()
					sellTab.infoPane:Show();
				end,
				parent = sellTab.buttons.infoPane,
			},
			{
				text   = '这是当前所选项目的拍卖列表.\n'..
					'你可以肯定你的商品是最便宜的.\n' ..
					C('这些总是按每件商品的最低价格分类。.', red),
				anchor = 'LEFT',
				parent = sellTab.currentAuctions,
			},
			{
				text   = '此按钮允许您购买所选商品。用于重新进货.',
				anchor = 'LEFT',
				parent = sellTab.buttons.buyItemButton,
			},
			{
				text   = '卖出 ' .. C('one auction', red) .. ' 不考虑您的\n“堆叠”设置的选定项的值，',
				anchor = 'RIGHT',
				parent = sellTab.buttons.postOneButton,
			},
			{
				text   = '卖出' .. C('all auctions', red) .. ' 根据您的\n“堆叠”设置选择的项目',
				anchor = 'RIGHT',
				parent = sellTab.buttons.postButton,
			},
			{
				text   = '再次打开此教程。\n希望您喜欢它\n \n:）\n \n' ..
					C('一旦关闭此教程，除非单击它，否则它将不再显示。', orange),
				anchor = 'LEFT',
				parent = self.helpBtn,
			}
		};
	end

	Tutorial:SetTutorials(self.tutorials);
	Tutorial:Show(false, function()
		AuctionFaster.db.tutorials.sell = false;
	end);
end