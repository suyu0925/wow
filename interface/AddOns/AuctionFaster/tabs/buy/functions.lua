---@type AuctionFaster
local AuctionFaster = unpack(select(2, ...));
--- @var StdUi StdUi
local StdUi = LibStub('StdUi');

--- @type Auctions
local Auctions = AuctionFaster:GetModule('Auctions');

--- @type Buy
local Buy = AuctionFaster:GetModule('Buy');

--- @type ChainBuy
local ChainBuy = AuctionFaster:GetModule('ChainBuy');
--- @type AuctionCache
local AuctionCache = AuctionFaster:GetModule('AuctionCache');

function Buy:Enable()
	self:AddBuyAuctionHouseTab();
	self:InterceptLinkClick();
end

function Buy:OnShow()
	self:RegisterEvent('AUCTION_ITEM_LIST_UPDATE');

	self.buyTab.auctions = {};

	self:UpdateSearchAuctions();
	self:UpdateStateText();
	self:UpdatePager();

	self:InitTutorial();
end

function Buy:OnHide()
	self:UnregisterEvent('AUCTION_ITEM_LIST_UPDATE');
end

function Buy:Disable()
	self:UnregisterEvent('AUCTION_ITEM_LIST_UPDATE');
end

----------------------------------------------------------------------------
--- Searching functions
----------------------------------------------------------------------------

function Buy:SearchAuctions(name, exact, page)
	self.currentQuery = {
		name = name,
		page = page or 0,
		exact = exact or false,
	};

	self:ApplyFilters(self.currentQuery);

	self:ClearSearchAuctions();
	self:UpdateStateText(true);

	Auctions:QueryAuctions(self.currentQuery, function(shown, total, items)
		Buy:SearchAuctionsCallback(shown, total, items)
	end);
end

function Buy:RefreshSearchAuctions()
	if not self.currentQuery then
		AuctionFaster:Echo(3, '以前没有关键字搜索');
		return;
	end

	self:SearchAuctions(self.currentQuery.name, self.currentQuery.exact, self.currentQuery.page);
end

function Buy:SearchNextPage()
	-- if last page is not yet defined or it would be over last page, just abandon
	if not self.currentQuery.lastPage or self.currentQuery.page + 1 > self.currentQuery.lastPage then
		return;
	end

	self:SearchAuctions(self.currentQuery.name, self.currentQuery.exact, self.currentQuery.page + 1);
end

function Buy:SearchPreviousPage()
	-- just in case there are no search results abort
	if not self.currentQuery.lastPage or self.currentQuery.page - 1 < 0 then
		return;
	end

	self:SearchAuctions(self.currentQuery.name, self.currentQuery.exact, self.currentQuery.page - 1);
end

----------------------------------------------------------------------------
--- Searching callback function
----------------------------------------------------------------------------

function Buy:SearchAuctionsCallback(shown, total, items)
	if self.currentQuery.page == 0 then
		AuctionCache:ParseScanResults(items, total);
	end
end

function Buy:UpdateStateText(inProgress)
	if inProgress then
		self.buyTab.stateLabel:SetText('正在搜索...');
		self.buyTab.stateLabel:Show();
	elseif #self.buyTab.auctions == 0 then
		self.buyTab.stateLabel:SetText('按此查询没有找到任何数据.');
		self.buyTab.stateLabel:Show();
	else
		self.buyTab.stateLabel:Hide();
	end
end

function Buy:UpdatePager()
	if not self.currentQuery then return; end

	local p = self.currentQuery.page + 1;
	local lp = self.currentQuery.lastPage + 1;
	local pager = self.buyTab.pager;
	self.updatingPagerLock = true;

	pager.pageText:SetText('页数: ' .. lp);

	pager.leftButton:Enable();
	pager.rightButton:Enable();

	local opts = {};
	for i = 0, self.currentQuery.lastPage do
		tinsert(opts, {text = tostring(i + 1), value = i});
	end

	pager.pageJump:SetOptions(opts);
	pager.pageJump:SetValue(self.currentQuery.page);

	if p <= 1 then
		pager.leftButton:Disable();
	end

	if p >= lp then
		pager.rightButton:Disable();
	end
	self.updatingPagerLock = false;
end

function Buy:UpdateQueue()
	local buyTab = Buy.buyTab;
	buyTab.queueLabel:SetText('队列数量: ' .. ChainBuy:CalcRemainingQty());

	buyTab.queueProgress:SetMinMaxValues(0, #ChainBuy.requests);
	buyTab.queueProgress:SetValue(ChainBuy.currentIndex);
end

function Buy:AddToFavorites()
	local searchBox = self.buyTab.searchBox;
	local text = searchBox:GetText();

	if not text or strlen(text) < 2 then
		--show error or something
		return ;
	end

	local favorites = AuctionFaster.db.favorites;
	for i = 1, #favorites do
		if favorites[i].text == text then
			--already exists - no error
			return ;
		end
	end

	tinsert(favorites, { text = text });
	self:DrawFavorites();
end

function Buy:RemoveFromFavorites(i)
	local favorites = AuctionFaster.db.favorites;

	if favorites[i] then
		tremove(favorites, i);
	end

	self:DrawFavorites();
end

function Buy:SearchFavorite(i)
	local favorites = AuctionFaster.db.favorites;

	if favorites[i] then
		self.buyTab.searchBox:SetText(favorites[i].text);
		self:SearchAuctions(self.buyTab.searchBox:GetText(), false, 0);
	end
end

function Buy:RemoveCurrentSearchAuction()
	local index = self.buyTab.searchResults:GetSelection();
	if not index then
		return ;
	end

	if not self.buyTab.auctions[index] then
		return;
	end

	tremove(self.buyTab.auctions, index);
	self:UpdateSearchAuctions();

	if self.buyTab.auctions[index] then
		self.buyTab.searchResults:SetSelection(index);
	end
end

function Buy:UpdateSearchAuctions()
	self.buyTab.searchResults:SetData(self.buyTab.auctions, true);
end

function Buy:ClearSearchAuctions()
	self.buyTab.searchResults:SetData({}, true);
end

function Buy:LockBuyButton(lock)
	local buyButton = self.confirmFrame.buttons['ok'];

	if lock then
		buyButton:Disable();
	else
		buyButton:Enable();
	end
end

function Buy:AUCTION_ITEM_LIST_UPDATE()
	local items, hasAllInfo, shown, total = Auctions:CollectAuctionsFromList();

	self.currentQuery.lastPage = ceil(total / 50) - 1;

	self.buyTab.auctions = items;

	self:UpdateSearchAuctions();
	self:UpdateStateText();
	self:UpdatePager();
end

function Buy.CloseCallback()
	Buy:UpdateQueue();
	Buy:RefreshSearchAuctions();
end

function Buy:InstantBuy(rowData, rowIndex)
	Auctions:BuyItem(rowData);

	tremove(Buy.buyTab.auctions, rowIndex);
	self:UpdateSearchAuctions();
end

function Buy:ChainBuyStart(index)
	local queue = {};
	local filtered = self.buyTab.searchResults.filtered;
	local filteredIndex = 0;

	for i = 1, #filtered do
		if filtered[i] == index then filteredIndex = i; break; end
	end

	for i = filteredIndex, #self.buyTab.auctions do
		local rowIndex = filtered[i];
		tinsert(queue, self.buyTab.auctions[rowIndex]);
	end

	ChainBuy:Start(queue, self.UpdateQueue, self.CloseCallback);
end

function Buy:AddToQueue(rowData, rowIndex)
	if not rowData then
		rowIndex = self.buyTab.searchResults:GetSelection();
		rowData = self.buyTab.searchResults:GetSelectedItem();
		if not rowData then
			AuctionFaster:Echo(3, '请先选择物品');
			return;
		end
	end

	ChainBuy:AddBuyRequest(rowData);
	ChainBuy:Start(nil, self.UpdateQueue, self.CloseCallback);

	tremove(Buy.buyTab.auctions, rowIndex);
	Buy:UpdateSearchAuctions();
end

function Buy:AddToQueueWithXStacks(amount)
	local queue = {};
	for i = 1, #self.buyTab.auctions do
		local auction = self.buyTab.auctions[i];
		if auction.count >= amount then
			tinsert(queue, auction);
		end
	end

	if #queue == 0 then
		AuctionFaster:Echo(3, '没有找到请求队列数量的拍卖: ' .. amount);
	end

	ChainBuy:Start(queue, self.UpdateQueue, self.CloseCallback);
end

function Buy:SearchStacksCallback(items, minStacks, page)
	local found = false;
	for x = 1, #items do
		if items[x].count >= minStacks then
			found = true;
			break;
		end
	end

	local foundIndex = 0;
	if found then
		for i = 1, #self.buyTab.auctions do
			local auction = self.buyTab.auctions[i];
			if auction.count >= minStacks then
				foundIndex = i;
				break;
			end
		end
	else
		Buy:FindFirstWithXStacks(minStacks, page);
		return;
	end

	C_Timer.After(0.7, function ()
		self.buyTab.searchResults:SetSelection(foundIndex);
		self.buyTab.searchResults:ScrollToLine(foundIndex);
	end);
end

function Buy:FindFirstWithXStacks(minStacks, page)
	if not self.currentQuery or not self.currentQuery.name or not self.currentQuery.lastPage then
		AuctionFaster:Echo(3, '先输入查询并点击搜索按钮');
		return;
	end

	if page == nil then
		page = 0;
	else
		page = page + 1;
	end;

	if page > self.currentQuery.lastPage then
		AuctionFaster:Echo(3, '未找到最小堆叠的拍卖 ' .. minStacks);
		return;
	end

	self.currentQuery.page = page;
	Auctions:QueryAuctions(self.currentQuery, function(shown, total, items)
		C_Timer.After(0.7, function()
			self:SearchStacksCallback(items, minStacks, page);
		end);
	end);
end

----------------------------------------------------------------------------
--- Filters functions
----------------------------------------------------------------------------

function Buy:GetSearchCategories()
	if self.categories and self.subCategories then
		return self.categories, self.subCategories;
	end

	local categories = {
		{value = 0, text = 'All'}
	};

	local subCategories = {
		[0] = {
			{value = 0, text = 'All'}
		}
	};

	for i = 1, #AuctionCategories do
		local children = AuctionCategories[i].subCategories;

		tinsert(categories, { value = i, text = AuctionCategories[i].name});

		subCategories[i] = {};
		if children then
			tinsert(subCategories[i], {value = 0, text = 'All'});
			for x = 1, #children do
				tinsert(subCategories[i], {value = x, text = children[x].name});
			end
		end
	end

	self.categories = categories;
	self.subCategories = subCategories;
end

function Buy:ApplyFilters(query)
	local filters = self.filtersPane;

	query.exact = filters.exactMatch:GetChecked();
	local minLevel = filters.minLevel:GetValue();
	local maxLevel = filters.maxLevel:GetValue();

	if minLevel then
		query.minLevel = minLevel;
	end

	if maxLevel then
		query.maxLevel = maxLevel;
	end

	local categoryIndex = filters.category:GetValue();
	local subCategoryIndex = filters.subCategory:GetValue();

	if categoryIndex > 0 and subCategoryIndex > 0 then
		query.filterData = AuctionCategories[categoryIndex].subCategories[subCategoryIndex].filters;
	elseif categoryIndex > 0 then
		query.filterData = AuctionCategories[categoryIndex].filters;
	end
end

function Buy:InterceptLinkClick()
	if self.linksIntercepted then
		return;
	end

	local origChatEdit_InsertLink = ChatEdit_InsertLink;
	local origHandleModifiedItemClick = HandleModifiedItemClick;
	local function SearchItemLink(origMethod, link)
		if Buy.buyTab.searchBox:HasFocus() then
			local itemName = GetItemInfo(link);
			Buy.buyTab.searchBox:SetText(itemName);
			return true;
		else
			return origMethod(link);
		end
	end

	Buy:RawHook('HandleModifiedItemClick', function(link)
		return SearchItemLink(origHandleModifiedItemClick, link);
	end, true);

	Buy:RawHook('ChatEdit_InsertLink', function(link)
		return SearchItemLink(origChatEdit_InsertLink, link);
	end, true);

	self.linksIntercepted = true;
end