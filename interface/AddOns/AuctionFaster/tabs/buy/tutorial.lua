---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @type StdUi
local StdUi = LibStub('StdUi');
--- @type Tutorial
local Tutorial = AuctionFaster:GetModule('Tutorial');
--- @type Buy
local Buy = AuctionFaster:GetModule('Buy');

local C = WrapTextInColorCode;
local red = 'FFFF0000';
local green = 'FF00FF00';
local orange = 'FFFFFF00';

function Buy:DrawHelpButton()
	local helpBtn = StdUi:SquareButton(self.buyTab, 16, 16);
	helpBtn:SetIcon([[Interface\FriendsFrame\InformationIcon]], 16, 16, true);

	StdUi:GlueLeft(helpBtn, AuctionFrameCloseButton, -5, 0);

	helpBtn:SetScript('OnClick', function ()
		self:InitTutorial(true);
	end);

	local settingsBtn = StdUi:SquareButton(self.buyTab, 16, 16);
	settingsBtn:SetIcon([[Interface\GossipFrame\BinderGossipIcon]], 16, 16, true);

	StdUi:GlueLeft(settingsBtn, helpBtn, -5, 0);

	settingsBtn:SetScript('OnClick', function ()
		AuctionFaster:OpenSettingsWindow();
	end);

	StdUi:FrameTooltip(helpBtn, 'Addon Tutorial', 'afAddonTutorialTwo', 'TOPLEFT', true);
	StdUi:FrameTooltip(settingsBtn, 'Addon settings', 'afAddonSettingsTwo', 'TOPLEFT', true);

	self.helpBtn = helpBtn;
end

function Buy:InitTutorial(force)
	if not AuctionFaster.db.tutorials.buy and not force then
		return;
	end

	if not self.tutorials then
		local buyTab = self.buyTab;
		self.tutorials = {
			{
				text   = '欢迎使用快速拍卖！)',
				anchor = 'CENTER',
				parent = buyTab,
				noglow = true
			},
			{
				text   = '输入搜索查询后，此按钮会将其添加到\n收藏夹中。',
				anchor = 'LEFT',
				parent = buyTab.addFavoritesButton,
			},
			{
				text   = '此按钮打开筛选器。\n再次单击可关闭.',
				anchor = 'LEFT',
				action = function()
					self.filtersPane:Show();
				end,
				parent = buyTab.filtersButton,
			},
			{
				text   = '搜索结果。\n\n有三种快捷方式：\n\n' ..
					C('Shift + 左键 - 立即购买\n', red) ..
					C('Alt + 左键 - 添加到队列\n', green) ..
					C('Ctrl + 左键 - 连续购买\n', orange),
				anchor = 'LEFT',
				parent = buyTab.searchResults,
			},
			{
				text   = '您的收藏夹\n单击该名称将\n持续搜索此查询.\n\n' ..
					C('点击删除按钮删除该名称.', green),
				anchor = 'LEFT',
				parent = buyTab.favorites,
			},
			{
				text   = '连续购买将从您选择的第一个开始\n将所有拍卖添加到底部 '..
					'购买队表.\n\n' .. C('你需要确认一下.', red),
				anchor = 'LEFT',
				parent = buyTab.chainBuyButton,
			},
			{
				text   = '当前购买队列\n\n显示实际数量\n'..
					'进度条将显示\n拍卖数量.',
				anchor = 'LEFT',
				parent = buyTab.queueProgress,
			},
			{
				text   = '最小数量\n是你选择的.\n\n' ..
					C('选择左边2个按钮.', orange),
				anchor = 'LEFT',
				parent = buyTab.minStacks,
			},
			{
				text   = '将所有拍卖添加到输入数量的队列中'..
					' 在右边的输入框中',
				anchor = 'LEFT',
				parent = buyTab.addWithXButton,
			},
			{
				text   = '找到首次拍卖 ' .. C('在所有页面上', red) .. ' 最小'..
					' 数量\n\n' .. C('您需要先输入搜索查询', orange),
				anchor = 'LEFT',
				parent = buyTab.findXButton,
			},
			{
				text   = '再次打开此教程.\n希望你喜欢\n\n:)\n\n' ..
					C('一旦关闭本教程 如果你不点击它，它就不会再出现了', orange),
				anchor = 'LEFT',
				parent = self.helpBtn,
			}
		};
	end

	Tutorial:SetTutorials(self.tutorials);
	Tutorial:Show(false, function()
		AuctionFaster.db.tutorials.buy = false;
	end);
end