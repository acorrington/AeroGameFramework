-- Store Service
-- Crazyman32
-- December 1, 2015

-- Updated: December 31, 2016
-- Updated: March 2, 2017

--[[
	
	Server:
		
		StoreService:HasPurchased(player, productId)
		StoreService:GetNumberPurchased(player, productId)
		
		StoreService.PromptPurchaseFinished(player, receiptInfo)
	
	
	Client:
		
		StoreService:HasPurchased(productId)
		StoreService:GetNumberPurchased(productId)
	
		StoreService.PromptPurchaseFinished(receiptInfo)
	
--]]



local StoreService = {
	Client = {};
}

local PRODUCT_PURCHASES_KEY = "ProductPurchases"
local PROMPT_PURCHASE_FINISHED_EVENT = "PromptPurchaseFinished"

local marketplaceService = game:GetService("MarketplaceService")

local dataStoreScope = "PlayerReceipts"
local services


function IncrementPurchase(player, productId)
	productId = tostring(productId)
	local productPurchases = services.DataService:Get(player, PRODUCT_PURCHASES_KEY)
	if (not productPurchases) then
		productPurchases = {}
		services.DataService:Set(player, PRODUCT_PURCHASES_KEY, productPurchases)
	end
	local n = productPurchases[productId]
	productPurchases[productId] = (n and (n + 1) or 1)
	services.DataService:FlushKey(player, PRODUCT_PURCHASES_KEY)
end


function ProcessReceipt(receiptInfo)
	
	--[[
		ReceiptInfo:
			PlayerId               [Number]
			PlaceIdWherePurchased  [Number]
			PurchaseId             [String]
			ProductId              [Number]
			CurrencyType           [CurrencyType Enum]
			CurrencySpent          [Number]
	--]]
	
	local player = game:GetService("Players"):GetPlayerByUserId(receiptInfo.PlayerId)
	
	local dataStoreName = tostring(receiptInfo.PlayerId)
	local key = tostring(receiptInfo.PurchaseId)
	
	-- Check if unique purchase was already completed:
	local alreadyPurchased = services.DataService:GetCustom(dataStoreName, dataStoreScope, key)
	
	if (not alreadyPurchased) then
		-- Mark as purchased and save immediately:
		services.DataService:SetCustom(dataStoreName, dataStoreScope, key, true)
		services.DataService:FlushCustom(dataStoreName, dataStoreScope, key)
	end
	
	if (player) then
		IncrementPurchase(player, receiptInfo.ProductId)
		StoreService:FireEvent(PROMPT_PURCHASE_FINISHED_EVENT, player, receiptInfo)
		StoreService:FireClientEvent(PROMPT_PURCHASE_FINISHED_EVENT, player, receiptInfo)
	end
	
	return Enum.ProductPurchaseDecision.PurchaseGranted
	
end


function StoreService:HasPurchased(player, productId)
	local productPurchases = services.DataService:Get(player, PRODUCT_PURCHASES_KEY)
	return (productPurchases and productPurchases[tostring(productId)] ~= nil)
end


-- Get the number of productId's purchased:
function StoreService:GetNumberPurchased(player, productId)
	local n = 0
	local productPurchases = services.DataService:Get(player, PRODUCT_PURCHASES_KEY)
	if (productPurchases) then
		n = (productPurchases[tostring(productId)] or 0)
	end
	return n
end


-- Get the number of productId's purchased:
function StoreService.Client:GetNumberPurchased(player, productId)
	return self.Server:GetNumberPurchased(player, productId)
end


-- Whether or not the productId has been purchased before:
function StoreService.Client:HasPurchased(player, productId)
	return self.Server:HasPurchased(player, productId)
end


function StoreService:Start()
	marketplaceService.ProcessReceipt = ProcessReceipt
end


function StoreService:Init()
	services = self.Services
	self:RegisterEvent(PROMPT_PURCHASE_FINISHED_EVENT)
	self:RegisterClientEvent(PROMPT_PURCHASE_FINISHED_EVENT)
end


return StoreService