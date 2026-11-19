FFXIVDurabilityBarsAddOn = LibStub("AceAddon-3.0"):NewAddon("FFXIVDurabilityBars")
local addon = FFXIVDurabilityBarsAddOn

local ffxivDuraOptions = {
	name = "FFXIV Durability Bars",
	handler = addon,
	type = "group",
	childGroups = "tab",
	args = {
		settingsTab = {
			type = "group",
			name = "Settings",
			order = 1,
			inline = true,
			args = {
				showDurabilityFreeBars = {
					type = "toggle",
					name = "Show Durability Free Bars",
					desc = "Should durability bars be shown for items without durability? (eg. trinkets, cloak...)",
					set = function(info, input) addon.db.profile.showDurabilityFreeBars = input; addon:RefreshAllSlots() end,
					get = function(info) return addon.db.profile.showDurabilityFreeBars end,
				},
				useQualityColours = {
					type = "toggle",
					name = "Use Quality Colours",
					desc = "Should durability bars use the quality/rarity colour of the items?",
					set = function(info, input) addon.db.profile.useQualityColours = input; addon:RefreshAllSlots() end,
					get = function(info) return addon.db.profile.useQualityColours end,
				},
				useGreenWhenDamaged = {
					type = "toggle",
					name = "Use Green When Damaged",
					desc = "Should durability bars use green instead of another colour when damaged?",
					set = function(info, input) addon.db.profile.useGreenWhenDamaged = input; addon:RefreshAllSlots() end,
					get = function(info) return addon.db.profile.useGreenWhenDamaged end,
				},
			},
		},
	},
}

local defaults = {
	profile = {
		showDurabilityFreeBars = true,
		useQualityColours = true,
		useGreenWhenDamaged = false,
	}
}

function addon:SetLinePoints(line, frame, durability, maxDurability, side)
	-- Calculate the endpoint of a bar based on its proportional durability
	if side == "left" then
		line:SetStartPoint("CENTER", frame, -22, -18 + 36 * (durability / maxDurability))
		line:SetEndPoint("CENTER", frame, -22, -18)
	elseif side == "right" then
		line:SetStartPoint("CENTER", frame, 22, -18 + 36 * (durability / maxDurability))
		line:SetEndPoint("CENTER", frame, 22, -18)
	elseif side == "top" then
		line:SetStartPoint("CENTER", frame, -18 + 36 * (durability / maxDurability), 22)
		line:SetEndPoint("CENTER", frame, -18, 22)
	end
end

function addon:AddDurabilityBarToSlot(button, side)
	if button.ffxivDurabilityBar then button.ffxivDurabilityBar:Hide() end
	if button.ffxivDurabilityBarBG then button.ffxivDurabilityBarBG:Hide() end
	if not button.ffxivDurabilityBar then
		local overlayFrame = CreateFrame("FRAME", nil, button)
		overlayFrame:SetAllPoints()
		overlayFrame:SetFrameLevel(button:GetFrameLevel() + 1)
		button.ffxivDuraOverlay = overlayFrame

		button.ffxivDurabilityBarBG = overlayFrame:CreateLine()
		button.ffxivDurabilityBarBG:Hide()
		button.ffxivDurabilityBarBG:SetColorTexture(1, 0, 0)
		button.ffxivDurabilityBarBG:SetThickness(2)
		button.ffxivDurabilityBarBG:SetDrawLayer("BACKGROUND")
		addon:SetLinePoints(button.ffxivDurabilityBarBG, overlayFrame, 1, 1, side)

		button.ffxivDurabilityBar = overlayFrame:CreateLine()
		button.ffxivDurabilityBar:Hide()
		button.ffxivDurabilityBar:SetThickness(2)
		button.ffxivDurabilityBar:SetDrawLayer("OVERLAY")
	end

	if button:GetID() >= INVSLOT_FIRST_EQUIPPED and button:GetID() <= INVSLOT_LAST_EQUIPPED then
		if GetInventoryItemID("player", button:GetID()) then
			local colour
			local r, g, b
			if (addon.db.profile.useQualityColours) then
				colour = GetInventoryItemQuality("player", button:GetID()) -- Using this over GetItemInfo(item:GetItemID()) because of upgradable items - they return their base rarity rather than the one equipped
				if (colour) then
					r, g, b = C_Item.GetItemQualityColor(colour)
				else
					r, g, b = C_Item.GetItemQualityColor(3)
				end
				button.ffxivDurabilityBar:SetColorTexture(r, g, b)
			end
			
			local durability, maxDura = GetInventoryItemDurability(button:GetID())
			if durability and maxDura then -- Items with durability, whether full or not
				if (not addon.db.profile.useQualityColours) then
					r, g, b = C_Item.GetItemQualityColor(3)
					button.ffxivDurabilityBar:SetColorTexture(r, g, b)
				end
				if durability == 0 then
					button.ffxivDurabilityBar:SetColorTexture(1, 0, 0)
				elseif durability < maxDura and addon.db.profile.useGreenWhenDamaged then
					button.ffxivDurabilityBar:SetColorTexture(0, 1, 0)
				end
				addon:SetLinePoints(button.ffxivDurabilityBar, button.ffxivDuraOverlay, durability, maxDura, side)
				button.ffxivDurabilityBar:Show()
				button.ffxivDurabilityBarBG:Show()
			else -- Items that don't have durability
				if (addon.db.profile.showDurabilityFreeBars) then
					if (not addon.db.profile.useQualityColours) then
						r = 1
						g = 1
						b = 0
						button.ffxivDurabilityBar:SetColorTexture(r, g, b)
					end
					addon:SetLinePoints(button.ffxivDurabilityBar, button.ffxivDuraOverlay, 1, 1, side)
					button.ffxivDurabilityBar:Show()
					button.ffxivDurabilityBarBG:Show()
				end
			end
		end
	end
end

addon.slotButtons = {}

function addon:UpdateSlot(button)
	local id = button:GetID()
	local side = "left" -- Default to a bar on the left, this should only end up on right side items
	if id == INVSLOT_MAINHAND or -- Weapons have a bar above them
		id == INVSLOT_OFFHAND or
		id == INVSLOT_RANGED then
			side = "top"
	elseif id == INVSLOT_HEAD or -- Left side items have a bar on the right
		id == INVSLOT_NECK or
		id == INVSLOT_SHOULDER or
		id == INVSLOT_BACK or
		id == INVSLOT_CHEST or
		id == INVSLOT_BODY or
		id == INVSLOT_TABARD or
		id == INVSLOT_WRIST then
			side = "right"
	end
	addon:AddDurabilityBarToSlot(button, side)
end

function addon:RefreshAllSlots()
	for button in pairs(addon.slotButtons) do
		addon:UpdateSlot(button)
	end
end

hooksecurefunc("PaperDollItemSlotButton_Update",
	function(button)
		addon.slotButtons[button] = true
		addon:UpdateSlot(button)
	end)

-- Blizzard only redraws slot buttons on durability *threshold* alerts, so
-- refresh our bars on every durability change while they're visible.
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
eventFrame:SetScript("OnEvent", function()
	for button in pairs(addon.slotButtons) do
		if button:IsVisible() then
			addon:UpdateSlot(button)
		end
	end
end)

function addon:AddDurabilityPercentToTooltip(tooltip, data)
	-- Retail durability percentages.
	-- Runs as a line *post*-call and edits the already-rendered FontString.
	-- Never write to `data` (Blizzard's lineData table): doing so taints the
	-- secure tooltip pipeline and breaks tooltips that carry secret values
	-- (e.g. minimap tracking mouseover).
	if tooltip ~= GameTooltip or not data or not data.lineIndex then
		return
	end
	local text = data.leftText
	if not text or issecretvalue(text) then
		return
	end
	local newText = addon:AppendDurabilityPercentString(text)
	if newText ~= text then
		local line = tooltip:GetLeftLine(data.lineIndex)
		if line then
			line:SetText(newText)
		end
	end
end

function addon:AddDurabilityPercentToTooltipClassic(tooltip)
	-- Non-retail durability percentages
	if tooltip then
		local numLines = tooltip:NumLines()
		if numLines == 0 then
			return
		end
		
		for line = 1, numLines do
			GameTooltip:GetLeftLine(line):SetText(addon:AppendDurabilityPercentString(GameTooltip:GetLeftLine(line):GetText()))
		end
	end
end

-- Build a Lua pattern from the client's localized durability string
-- (enUS: "Durability %d / %d") so this works on every locale and only
-- matches the real durability line.
local function BuildDurabilityPattern()
	local template = DURABILITY_TEMPLATE or "Durability %d / %d"
	local pattern = template:gsub("%p", "%%%0")         -- escape all punctuation
	pattern = pattern:gsub("%%%%%d%%%$d", "(%%d+)")     -- positional "%1$d"
	pattern = pattern:gsub("%%%%d", "(%%d+)")           -- plain "%d"
	return "^" .. pattern .. "$"
end
local DURABILITY_PATTERN = BuildDurabilityPattern()

function addon:AppendDurabilityPercentString(text)
	-- Append the percentage to a durability line
	if not text or issecretvalue(text) then
		return text
	end
	local cur, max = string.match(text, DURABILITY_PATTERN)
	cur, max = tonumber(cur), tonumber(max)
	if cur and max and max > 0 then
		return text .. " (" .. string.format("%.1f", cur / max * 100) .. "%)"
	end
	return text
end

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("FFXIVDurabilityBarsDB", defaults)
	ffxivDuraOptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("FFXIVDurabilityBars", ffxivDuraOptions)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("FFXIVDurabilityBars", "FFXIV Durability Bars")

	local buildVersion, buildNumber, buildDate, interfaceVersion = GetBuildInfo()
	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPreCall and (interfaceVersion > 100000 or (interfaceVersion > 16000 and interfaceVersion < 20000)) then
		TooltipDataProcessor.AddLinePostCall(Enum.TooltipDataLineType.None, function(tooltip, data) addon:AddDurabilityPercentToTooltip(tooltip, data) end)
	elseif GameTooltip.HookScript then
		GameTooltip:HookScript("OnTooltipSetItem", function(tooltip) addon:AddDurabilityPercentToTooltipClassic(tooltip) end)
	end
end