--[[----------------------------------------------------------------------------

  LiteMount/UI/Groups.lua

  Options frame to plug in to the Blizzard interface menu.

  Copyright 2011-2020 Mike Battersby

----------------------------------------------------------------------------]]--

local _, LM = ...

--[[--------------------------------------------------------------------------]]--

LiteMountGroupsPanelMixin = {}

function LiteMountGroupsPanelMixin:OnLoad()
end

function LiteMountGroupsPanelMixin:Update()
    self.Groups:Update()
    self.Mounts:Update()
end

--[[--------------------------------------------------------------------------]]--

LiteMountGroupsPanelGroupMixin = {}

function LiteMountGroupsPanelGroupMixin:OnClick()
    LiteMountGroupsPanel.selectedFlag = self.flag
    LiteMountGroupsPanel:Update()
end

--[[--------------------------------------------------------------------------]]--

LiteMountGroupsPanelGroupsMixin = {}

function LiteMountGroupsPanelGroupsMixin:Update()
    if not self.buttons then return end

    local offset = HybridScrollFrame_GetOffset(self)

    local allFlags = {}
    for f in pairs(LM.Options:GetRawFlags()) do
        table.insert(allFlags, f)
    end

    local totalHeight = (#allFlags + 1) * self.buttons[1]:GetHeight()
    local displayedHeight = #self.buttons * self.buttons[1]:GetHeight()

    local buttonWidth = self:GetWidth() - 22

    local showAddButton, index, button

    for i = 1, #self.buttons do
        button = self.buttons[i]
        index = offset + i
        if index <= #allFlags then
            local flagText = allFlags[index]
            if LM.Options:IsPrimaryFlag(allFlags[index]) then
                flagText = ITEM_QUALITY_COLORS[2].hex .. flagText .. FONT_COLOR_CODE_CLOSE
                button.DeleteButton:Hide()
            else
                button.DeleteButton:Show()
            end
            button.Text:SetFormattedText(flagText)
            button.Text:Show()
            button:Show()
            button.flag = allFlags[index]
        elseif index == #allFlags + 1 then
            button.Text:Hide()
            button.DeleteButton:Hide()
            button:Show()
            button.flag = nil
            self.AddFlagButton:SetParent(button)
            self.AddFlagButton:ClearAllPoints()
            self.AddFlagButton:SetPoint("CENTER")
            button.DeleteButton:Hide()
            showAddButton = true
            button.flag = false
        else
            button:Hide()
            button.flag = nil
        end
        button:SetWidth(buttonWidth)
        button.SelectedTexture:SetShown(button.flag == self:GetParent().selectedFlag)
    end

    self.AddFlagButton:SetShown(showAddButton)

    HybridScrollFrame_Update(self, totalHeight, displayedHeight)
end

function LiteMountGroupsPanelGroupsMixin:OnSizeChanged()
    HybridScrollFrame_CreateButtons(self, 'LiteMountGroupsPanelGroupTemplate')
    for _, b in ipairs(self.buttons) do
        b:SetWidth(self:GetWidth())
    end
end

function LiteMountGroupsPanelGroupsMixin:OnShow()
    self:Update()
end

function LiteMountGroupsPanelGroupsMixin:OnLoad()
    self.scrollBar:ClearAllPoints()
    self.scrollBar:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -16)
    self.scrollBar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 16)
    local track = _G[self.scrollBar:GetName().."Track"]
    track:Hide()
    self.scrollBar.doNotHide = true
    self.update = self.Update
end

--[[--------------------------------------------------------------------------]]--

LiteMountGroupsPanelMountMixin = {}

function LiteMountGroupsPanelMountMixin:OnClick()
end

function LiteMountGroupsPanelMountMixin:SetMount(mount, flag)
    self.mount = mount
    if self.mount then
        self.Icon:SetTexture(mount.icon)
        self.Name:SetText(mount.name)
        if flag and mount:MatchesFilters(flag) then
            self.SelectedTexture:Show()
            self.CheckedTexture:Show()
        else
            self.SelectedTexture:Hide()
            self.CheckedTexture:Hide()
        end
    end
end

--[[--------------------------------------------------------------------------]]--

LiteMountGroupsPanelMountsMixin = {}

function LiteMountGroupsPanelMountsMixin:Update()
    if not self.buttons then return end

    local offset = HybridScrollFrame_GetOffset(self)

    local mounts = LM.UIFilter.GetFilteredMountList()

    for i, button in ipairs(self.buttons) do
        local index = offset + i
        if index <= #mounts then
            button:SetMount(mounts[index], self:GetParent().selectedFlag)
            button:Show()
        else
            button:Hide()
        end
    end

    local totalHeight = #mounts * self.buttons[1]:GetHeight()
    local displayedHeight = #self.buttons * self.buttons[1]:GetHeight()

    HybridScrollFrame_Update(self, totalHeight, displayedHeight)
end

function LiteMountGroupsPanelMountsMixin:OnSizeChanged()
    HybridScrollFrame_CreateButtons(self, 'LiteMountGroupsPanelMountTemplate')
    for _, b in ipairs(self.buttons) do
        b:SetWidth(self:GetWidth())
    end
end

function LiteMountGroupsPanelMountsMixin:OnShow()
    self:Update()
end

function LiteMountGroupsPanelMountsMixin:OnLoad()
    local track = _G[self.scrollBar:GetName().."Track"]
    track:Hide()
    self.update = self.Update
end
