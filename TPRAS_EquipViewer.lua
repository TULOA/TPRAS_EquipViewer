-- TPRAS EquipViewer
-- SavedVariables: TPRAS_EquipViewerDB, TPRAS_EquipViewerDBPC

local addonName = ...
TPRAS_EquipViewerDB = TPRAS_EquipViewerDB or {}
TPRAS_EquipViewerDBPC = TPRAS_EquipViewerDBPC or {}

-------------------------------------------------
-- Inventory Slot Mapping
-------------------------------------------------
local SLOT_NAMES = {
    [1]  = "HeadSlot",
    [2]  = "NeckSlot",
    [3]  = "ShoulderSlot",
    [15] = "BackSlot",
    [5]  = "ChestSlot",
    [4]  = "ShirtSlot",
    [19] = "TabardSlot",
    [9]  = "WristSlot",
    [10] = "HandsSlot",
    [6]  = "WaistSlot",
    [7]  = "LegsSlot",
    [8]  = "FeetSlot",
    [11] = "Finger0Slot",
    [12] = "Finger1Slot",
    [13] = "Trinket0Slot",
    [14] = "Trinket1Slot",
    [16] = "MainHandSlot",
    [17] = "SecondaryHandSlot",
    [18] = "RangedSlot", -- not on all versions
}

local slotOrder = {
    1, 2, 3, 15, 5, 4, 19, 9,
    10, 6, 7, 8, 11, 12, 13, 14,
    16, -- MainHand
    -- OffHand OR Ranged will be added dynamically
}

-------------------------------------------------
-- Saved gear capture
-------------------------------------------------
local function SavePlayerGear()
    local charKey = UnitName("player") .. "-" .. GetRealmName()
    TPRAS_EquipViewerDB[charKey] = {}
    for id in pairs(SLOT_NAMES) do
        local itemID = GetInventoryItemID("player", id)
        if itemID then
            TPRAS_EquipViewerDB[charKey][id] = itemID
        end
    end
end

-------------------------------------------------
-- Viewer Frame
-------------------------------------------------
local viewer = CreateFrame("Frame", "TPRAS_EquipViewer", UIParent, "BackdropTemplate")
viewer:Hide()
viewer:SetSize(350, 500)
viewer:SetPoint("CENTER")
viewer:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
viewer:SetMovable(true)
viewer:EnableMouse(true)
viewer:RegisterForDrag("LeftButton")
viewer:SetScript("OnDragStart", viewer.StartMoving)
viewer:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    TPRAS_EquipViewerDBPC.pos = {point, relPoint, x, y}
end)

-- restore pos
viewer:SetScript("OnShow", function(self)
    local pos = TPRAS_EquipViewerDBPC.pos
    if pos then
        self:ClearAllPoints()
        self:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    end
end)

-- Title
local title = viewer:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOP", 0, -10)
title:SetText("TPRAS Equip Viewer")

-- Close + Gear
local close = CreateFrame("Button", nil, viewer, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -5, -5)

local gearButton = CreateFrame("Button", nil, viewer)
gearButton:SetSize(24, 24)
gearButton:SetPoint("RIGHT", close, "LEFT", -2, 0)
gearButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
gearButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

-------------------------------------------------
-- Options Frame
-------------------------------------------------
local options = CreateFrame("Frame", "TPRAS_EquipViewerOptions", viewer, "BackdropTemplate")
options:SetSize(200, 80)
options:SetPoint("CENTER", viewer, "CENTER")
options:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
options:Hide()

local optTitle = options:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
optTitle:SetPoint("TOP", 0, -10)
optTitle:SetText("Options")

local hideMinimap = CreateFrame("CheckButton", nil, options, "ChatConfigCheckButtonTemplate")
hideMinimap:SetPoint("TOPLEFT", 20, -35)
hideMinimap.Text:SetText("Hide minimap button")
hideMinimap:SetChecked(TPRAS_EquipViewerDBPC.hideMinimap)
hideMinimap:SetScript("OnClick", function(self)
    TPRAS_EquipViewerDBPC.hideMinimap = self:GetChecked()
    if TPRAS_EquipViewerDBPC.hideMinimap then
        LibStub("LibDBIcon-1.0"):Hide("TPRAS_EquipViewer")
    else
        LibStub("LibDBIcon-1.0"):Show("TPRAS_EquipViewer")
    end
end)

gearButton:SetScript("OnClick", function()
    if options:IsShown() then options:Hide() else options:Show() end
end)

-------------------------------------------------
-- Dropdown
-------------------------------------------------
local dropdown = CreateFrame("Frame", addonName.."Dropdown", viewer, "UIDropDownMenuTemplate")
dropdown:SetPoint("TOPLEFT", 15, -40)

local selectedChar
local function Dropdown_OnClick(self)
    selectedChar = self.value
    UIDropDownMenu_SetSelectedValue(dropdown, self.value)
    UIDropDownMenu_SetText(dropdown, self.value)
    viewer:UpdateFromCharacter(self.value)
end
local function Dropdown_Initialize(self, level)
    for charKey in pairs(TPRAS_EquipViewerDB) do
        local info = UIDropDownMenu_CreateInfo()
        info.text, info.value, info.func = charKey, charKey, Dropdown_OnClick
        UIDropDownMenu_AddButton(info, level)
    end
end
UIDropDownMenu_Initialize(dropdown, Dropdown_Initialize)
UIDropDownMenu_SetWidth(dropdown, 180)

-- Delete
local deleteBtn = CreateFrame("Button", nil, viewer, "UIPanelButtonTemplate")
deleteBtn:SetSize(80, 22)
deleteBtn:SetPoint("LEFT", dropdown, "RIGHT", 10, 0)
deleteBtn:SetText("Delete")
deleteBtn:SetScript("OnClick", function()
    if selectedChar then
        TPRAS_EquipViewerDB[selectedChar] = nil
        selectedChar = nil
        UIDropDownMenu_SetSelectedValue(dropdown, nil)
        UIDropDownMenu_SetText(dropdown, "")
        for _, b in pairs(viewer.slots) do
            if b.icon then b.icon:SetTexture(nil) end
            b.itemID = nil
        end
    end
end)

-------------------------------------------------
-- Slot buttons
-------------------------------------------------
viewer.slots = {}

local function SafeGetSlotTexture(slotName)
    local ok, _, tex = pcall(GetInventorySlotInfo, slotName)
    if ok then return tex end
    return "Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag"
end

local function CreateSlotButton(slotID)
    local slotName = SLOT_NAMES[slotID]
    if not slotName then return end
    local texture = SafeGetSlotTexture(slotName)

    local button
    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        button = CreateFrame("ItemButton", nil, viewer)
    else
        button = CreateFrame("Button", nil, viewer, "ItemButtonTemplate")
    end

    button.slotID, button.slotName = slotID, slotName
    button:SetSize(40, 40)
    if button.icon then button.icon:SetTexture(texture) end
    if button.Icon then button.Icon:SetTexture(texture) end
    viewer.slots[slotID] = button
    return button
end

local function LayoutSlots()
    local i = 1
    for _, id in ipairs(slotOrder) do
        local b = CreateSlotButton(id)
        if b then
            if i <= 8 then
                b:SetPoint("TOPLEFT", viewer, "TOPLEFT", 15, -80 - (i-1)*45)
            elseif i <= 16 then
                b:SetPoint("TOPRIGHT", viewer, "TOPRIGHT", -15, -80 - (i-9)*45)
            else
                b:SetPoint("BOTTOM", viewer, "BOTTOM", -25, 30)
            end
            b:Show()
            i = i + 1
        end
    end

    -- choose OffHand or Ranged
    if SLOT_NAMES[17] and pcall(GetInventorySlotInfo, "SecondaryHandSlot") then
        local off = CreateSlotButton(17)
        off:SetPoint("BOTTOM", viewer, "BOTTOM", 25, 30)
        off:Show()
    elseif SLOT_NAMES[18] and pcall(GetInventorySlotInfo, "RangedSlot") then
        local rng = CreateSlotButton(18)
        rng:SetPoint("BOTTOM", viewer, "BOTTOM", 25, 30)
        rng:Show()
    end
end
LayoutSlots()

-------------------------------------------------
-- Update
-------------------------------------------------
function viewer:UpdateFromCharacter(charKey)
    local data = TPRAS_EquipViewerDB[charKey]
    if not data then return end
    for id, button in pairs(self.slots) do
        local itemID = data[id]
        if itemID then
            local icon = select(5, GetItemInfoInstant(itemID))
            if button.icon then button.icon:SetTexture(icon) end
            if button.Icon then button.Icon:SetTexture(icon) end
            button.itemID = itemID
            button:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(itemID)
            end)
            button:SetScript("OnLeave", GameTooltip_Hide)
            button:SetScript("OnClick", function(self, btn)
                if HandleModifiedItemClick(select(2, GetItemInfo(self.itemID))) then return end
            end)
        else
            if button.icon then button.icon:SetTexture(nil) end
            if button.Icon then button.Icon:SetTexture(nil) end
            button.itemID = nil
            button:SetScript("OnEnter", nil)
            button:SetScript("OnLeave", nil)
            button:SetScript("OnClick", nil)
        end
    end
end

-------------------------------------------------
-- Slash
-------------------------------------------------
SLASH_TEV1 = "/tev"
SlashCmdList["TEV"] = function()
    if viewer:IsShown() then
        viewer:Hide()
    else
        local me = UnitName("player") .. "-" .. GetRealmName()
        SavePlayerGear()
        viewer:UpdateFromCharacter(me)
        UIDropDownMenu_SetSelectedValue(dropdown, me)
        UIDropDownMenu_SetText(dropdown, me)
        selectedChar = me
        viewer:Show()
    end
end

-------------------------------------------------
-- LDB Minimap
-------------------------------------------------
local ldb = LibStub("LibDataBroker-1.1"):NewDataObject("TPRAS_EquipViewer", {
    type = "launcher",
    text = "Equip Viewer",
    icon = "Interface\\Icons\\INV_Chest_Cloth_17",
    OnClick = function(_, button) if button=="LeftButton" then SlashCmdList["TEV"]() end end,
    OnTooltipShow = function(tt)
        tt:AddLine("TPRAS Equip Viewer")
        tt:AddLine("Left-click to toggle", 0.8,0.8,0.8)
    end,
})
LibStub("LibDBIcon-1.0"):Register("TPRAS_EquipViewer", ldb, TPRAS_EquipViewerDBPC.minimap or {})
