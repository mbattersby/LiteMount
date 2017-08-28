--[[----------------------------------------------------------------------------

  LiteMount/PlayerMounts.lua

  Information on all your mounts.

  Copyright 2011-2017 Mike Battersby

----------------------------------------------------------------------------]]--

LM_PlayerMounts = LM_CreateAutoEventFrame("Frame", "LM_PlayerMounts", UIParent)

-- Type, type class create args
local LM_MOUNT_SPELLS = {
    { "RunningWild", LM_SPELL.RUNNING_WILD },
    { "FlightForm", LM_SPELL.FLIGHT_FORM },
    { "GhostWolf", LM_SPELL.GHOST_WOLF },
    { "TravelForm", LM_SPELL.TRAVEL_FORM },
    { "Nagrand", LM_SPELL.FROSTWOLF_WAR_WOLF },
    { "Nagrand", LM_SPELL.TELAARI_TALBUK },
    { "ItemSummoned",
        LM_ITEM.LOANED_GRYPHON_REINS, LM_SPELL.LOANED_GRYPHON,
        { 'FLY' }
    },
    { "ItemSummoned",
        LM_ITEM.LOANED_WIND_RIDER_REINS, LM_SPELL.LOANED_WIND_RIDER,
        { 'FLY' }
    },
    { "ItemSummoned",
        LM_ITEM.FLYING_BROOM, LM_SPELL.FLYING_BROOM,
        { 'FLY' },
    },
    { "ItemSummoned",
        LM_ITEM.MAGIC_BROOM, LM_SPELL.MAGIC_BROOM,
        { 'RUN', 'FLY' },
    },
    { "ItemSummoned",
        LM_ITEM.DRAGONWRATH_TARECGOSAS_REST, LM_SPELL.TARECGOSAS_VISAGE,
        { 'FLY' }
    },
    { "ItemSummoned",
        LM_ITEM.SHIMMERING_MOONSTONE, LM_SPELL.MOONFANG,
        { 'RUN' },
    },
    { "ItemSummoned",
        LM_ITEM.RATSTALLION_HARNESS, LM_SPELL.RATSTALLION_HARNESS,
        { 'RUN' },
    },
}

local RefreshEvents = {
    -- Companion change. Don't add COMPANION_UPDATE to this as it fires
    -- for units other than "player" and triggers constantly.
    "COMPANION_LEARNED", "COMPANION_UNLEARNED",
    -- Talents (might have mount abilities). Glyphs that teach spells
    -- fire PLAYER_TALENT_UPDATE too, don't need to watch GLYPH_ events.
    "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_LEVEL_UP", "PLAYER_TALENT_UPDATE",
    -- You might have received a mount item (e.g., Magic Broom).
    "BAG_UPDATE",
    -- Draenor flying is an achievement
    "ACHIEVEMENT_EARNED",
}

function LM_PlayerMounts:Initialize()

    self.list = LM_ShuffleList:New()

    self:AddJournalMounts()
    self:AddSpellMounts()

    for m in self.list:Iterate() do
        LM_Options:SeenMount(m)
    end

    -- Refresh event setup
    for _,ev in ipairs(RefreshEvents) do
        self[ev] = function (self, event, ...)
                            LM_Debug("Got refresh event "..event)
                            self.needRefresh = true
                        end
        self:RegisterEvent(ev)
    end
end

function LM_PlayerMounts:AddMount(m)
    tinsert(self.list, m)
end

function LM_PlayerMounts:AddJournalMounts()
    for _, mountID in ipairs(C_MountJournal.GetMountIDs()) do
        local m = LM_Mount:Get("Journal", mountID)
        self:AddMount(m)
    end
end

-- The unpack function turns a table into a list. I.e.,
--      unpack({ a, b, c }) == a, b, c
function LM_PlayerMounts:AddSpellMounts()
    for _,typeAndArgs in ipairs(LM_MOUNT_SPELLS) do
        local m = LM_Mount:Get(unpack(typeAndArgs))
        self:AddMount(m)
    end
end

function LM_PlayerMounts:RefreshMounts()
    if self.needRefresh then
        LM_Debug("Refreshing status of all mounts.")

        for m in self:Iterate() do
            m:Refresh()
        end
        self.needRefresh = nil
    end
end

function LM_PlayerMounts:Iterate()
    return self.list:Iterate()
end

function LM_PlayerMounts:Search(matchfunc)
    self:RefreshMounts()
    return self.list:Search(matchfunc)
end

function LM_PlayerMounts:Find(matchfunc)
    return self.list:Find(matchfunc)
end

function LM_PlayerMounts:GetAllMounts()
    local function match() return true end
    return self:Search(match)
end

function LM_PlayerMounts:GetAvailableMounts(filters)
    local function match(m)
        if not m:MatchesFilter(filters) then return end
        if not m:IsCastable() then return end
        if LM_Options:IsExcludedMount(m) then return end
        return true
    end

    return self:Search(match)
end

function LM_PlayerMounts:GetMountFromUnitAura(unitid)
    local buffs = { }
    for i = 1,BUFF_MAX_DISPLAY do
        local aura = UnitAura(unitid, i)
        if aura then tinsert(buffs, aura) end
    end
    local function match(m)
        local spellName = GetSpellInfo(m.spellID)
        return m.isCollected and tContains(buffs, spellName) and m:IsCastable()
    end
    return self:Find(match)
end

function LM_PlayerMounts:GetMountByName(name)
    local function match(m) return m.name == name end
    return self:Find(match)
end

function LM_PlayerMounts:GetMountBySpell(id)
    local function match(m) return m.spellID == id end
    return self:Find(match)
end

-- For some reason GetShapeshiftFormInfo doesn't work on Ghost Wolf.
function LM_PlayerMounts:GetMountByShapeshiftForm(i)
    if not i then return end
    local class = select(2, UnitClass("player"))
    if class == "SHAMAN" and i == 1 then
         return self:GetMountBySpell(LM_SPELL.GHOST_WOLF)
    end
    local name = select(2, GetShapeshiftFormInfo(i))
    if name then return self:GetMountByName(name) end
end

function LM_PlayerMounts:GetRandomMount(filters)
    local poss = self:GetAvailableMounts(filters)
    return poss:Random()
end

function LM_PlayerMounts:Dump()
    for m in self.list:Iterate() do
        m:Dump()
    end
end
