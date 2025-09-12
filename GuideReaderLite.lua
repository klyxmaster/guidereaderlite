--[[
    GuideReaderLite
    Copyright (C) 2025 Richard Scorpio

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see <https://www.gnu.org/licenses/>.
]]


GuideReaderLiteDB = GuideReaderLiteDB or {}
--GuideReaderLiteSavedVars = GuideReaderLiteSavedVars or {}

-- Main Addon Table
local GRL = GuideReaderLite or {}
GuideReaderLite = GRL

GRL._doneCache = GRL._doneCache or {}
GRL._events = GRL._events or {}
GRL.guides = GRL.guides or {}
GRL.guidelist = GRL.guidelist or {}
GRL.turnedinquests = GRL.turnedinquests or {}
GRL.trace = GRL.trace or false
GRL.frame = GRL.frame or CreateFrame("Frame", "GuideReaderLiteFrame", UIParent)
GRL._sticky = GRL._sticky or {}
GRL._inGossip = GRL._inGossip or false
GRL._recentAccepted  = GRL._recentAccepted or {}
GRL._recentTurnedIn  = GRL._recentTurnedIn or {}
GRL._inGossip        = GRL._inGossip or false

GRL.AutoAdvance = true

---------------------------------------------------------------
-- Per-Character State & DB
---------------------------------------------------------------
GRL.db                 = GuideReaderLiteDB
GRL.db.char            = GRL.db.char or {}
local realmName = GetRealmName()
local playerName = UnitName("player")
GRL.db.char[realmName] = GRL.db.char[realmName] or {}
GRL.db.char[realmName][playerName] = GRL.db.char[realmName][playerName] or {}
local charDB = GRL.db.char[realmName][playerName]

---------------------------------------------------------------
-- Utils
---------------------------------------------------------------

local TT = TomTom

local function add_tt(mapID, x_percent, y_percent, title)
  if not TT then return end
  if GRL._ttwp and TT.RemoveWaypoint then TT:RemoveWaypoint(GRL._ttwp) end
  -- TomTom API expects 0–1, we export 0–100
  GRL._ttwp = TT:AddWaypoint(mapID, x_percent/100, y_percent/100, { title = title or "Target" })
end

function GRL:SetHotspotWaypoint(questID, entryID)
  -- prefer per-entry if you have it; fall back to best-per-quest
  local rec
  local by = _G.GRL_HOTSPOT_BYENTRY and _G.GRL_HOTSPOT_BYENTRY[questID]
  if by and entryID and by[entryID] then
    rec = by[entryID]
  elseif _G.GRL_HOTSPOT_BEST then
    rec = _G.GRL_HOTSPOT_BEST[questID]
  end
  if not rec then return end

  local title = (rec.mob or "Target")
  if rec.zone and rec.zone ~= "" then title = title .. " @ " .. rec.zone end
  title = title .. (" (%.1f, %.1f)"):format(rec.x, rec.y)

  add_tt(rec.map, rec.x, rec.y, title)
end


local function _recent(tstamp, win) return tstamp and (GetTime() - tstamp) <= (win or 45) end


local function _norm(x)
    x = tostring(x or "")
    x = x:gsub("^%s+", ""):gsub("%s+$", ""):lower()
    return x
end
local function trim(s) return (s or ""):gsub("^%s+", ""):gsub("%s+$", "") end
local function splitlines(s)
    local t = {}; if not s then return t end
    s = s:gsub("\r\n", "\n")
    for line in s:gmatch("([^\n]+)") do t[#t + 1] = line end
    return t
end
local function deepcopy(src)
    if type(src) ~= "table" then return src end
    local t = {}; for k, v in pairs(src) do t[k] = deepcopy(v) end; return t
end
local function say(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55GuideReaderLite:|r " .. tostring(msg))
    end
end

function GRL:Debug(...)
    if self.trace then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i])
        end
        say(table.concat(args, " "))
    end
end

function GRL:DebugStepAdvance(msg, ...)
    if self.trace then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i])
        end
        say("|cffFFAA00StepAdvance:|r " .. tostring(msg) .. " " .. table.concat(args, " "))
    end
end

function GRL:After(delay, fn)
    local t, start = CreateFrame("Frame"), GetTime()
    t:SetScript("OnUpdate", function(self)
        if GetTime() - start >= (delay or 0) then
            self:SetScript("OnUpdate", nil); self:Hide()
            local ok, err = pcall(fn); if not ok then geterrorhandler()(err) end
        end
    end)
end

function GRL:_HasStickyUndone()
    for qid, info in pairs(self._sticky or {}) do
        if not GRL_AreObjectivesDone(qid, info and info.qo) then
            return true
        end
    end
    return false
end

function GRL:_FindQuestTextByQID(qid)
  for idx, tags in ipairs(self.tags or {}) do
    if tags and tags.qid == qid then
      return self.quests and self.quests[idx]
    end
  end
end



---------------------------------------------------------------
-- Faction Helpers & Class/Race Filtering
---------------------------------------------------------------
-- Hearthstone / Astral Recall cast detection (3.3.5a uses spell *name*, not ID)
GRL._hearthAt = GRL._hearthAt or nil
local HEARTH = (GetSpellInfo and GetSpellInfo(8690)) or "Hearthstone"
local ASTRAL = (GetSpellInfo and GetSpellInfo(556)) or "Astral Recall"

GRL._hearthFrame = GRL._hearthFrame or CreateFrame("Frame")
GRL._hearthFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
GRL._hearthFrame:SetScript("OnEvent", function(_, _, unit, spell)  -- WotLK: (unit, spell, rank, lineID)
    if unit ~= "player" then return end
    if spell == HEARTH or spell == ASTRAL then
        GRL._hearthAt = GetTime()
        if GRL.After then
            GRL:After(0.10, function()
                if GRL.AutoAdvance then GRL:AutoAdvance() end
            end)
        end
    end
end)


-- Detect "set hearth/home" via system message and advance
GRL._bindFrame = GRL._bindFrame or CreateFrame("Frame")
GRL._bindFrame:RegisterEvent("CHAT_MSG_SYSTEM")
GRL._bindFrame:SetScript("OnEvent", function(_, _, msg)
    -- Build a loose, locale-safe pattern from the global string
    local pat1 = (ERR_NEW_HOME or "Your home has been set to %s."):gsub("%%s", ".+")
    local pat2 = (ERR_DEATHBIND_SUCCESS or "You are now bound to this location."):gsub("%%s", ".+")
    local pat3 = (ERR_DEATHBIND_SUCCESS_S or "You are now bound to %s."):gsub("%%s", ".+")

    if msg and (msg:find(pat1) or msg:find(pat2) or msg:find(pat3)) then
        GRL._lastBindTime = GetTime()
        -- optional: remember the location for debugging/matching
        GRL._lastBindLoc = (GetBindLocation and GetBindLocation()) or GRL._lastBindLoc
        if GRL.After then
            GRL:After(0.10, function()
                if GRL.AutoAdvance then GRL:AutoAdvance() end
            end)
        end
    end
end)


local function GRL_PlayerHasBuff(match)
    if not match or match == "" then return false end
    local wantID = tonumber(match)
    for i=1,40 do
        local name, _, _, _, _, _, _, _, _, spellID = UnitBuff("player", i)
        if not name then break end
        if (wantID and spellID == wantID) or (not wantID and string.lower(name) == string.lower(match)) then
            return true
        end
    end
    return false
end

local function GRL_AnyItemCooling(list)
    if not list or list == "" then return false end
    for id in tostring(list):gmatch("%d+") do
        local start, dur = GetItemCooldown(tonumber(id))
        if start and start > 0 and dur and dur > 0 then return true end
    end
    return false
end

local function GRL_FindQuestLogIndexByID(qid)
    if not qid then return nil end
    local n = GetNumQuestLogEntries and GetNumQuestLogEntries() or 0
    for i = 1, n do
        local link = GetQuestLink and GetQuestLink(i)
        if link then
            local id = tonumber(link:match("quest:(%d+)"))
            if id == qid then return i end
        end
        local _, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)
        if not isHeader and questID and questID == qid then return i end
    end
    return nil
end

local function GRL_AreObjectivesDone(qid, which)
    local idx = GRL_FindQuestLogIndexByID(qid)
    if not idx then return false end
    local num = (GetNumQuestLeaderBoards and GetNumQuestLeaderBoards(idx)) or 0
    if num == 0 then return false end

    local function isDoneAt(objIdx)
        local text, typ, done = GetQuestLogLeaderBoard(objIdx, idx)
        return (done == 1 or done == true)
    end

    if type(which) == "table" and #which > 0 then
        for _, oi in ipairs(which) do
            if not isDoneAt(oi) then return false end
        end
        return true
    else
        for oi = 1, num do
            if not isDoneAt(oi) then return false end
        end
        return true
    end
end

-- Return an array of objective rows: { text=..., got=number|nil, need=number|nil, done=bool }
local function GRL_GetObjectiveRows(qid)
    local idx = GRL_FindQuestLogIndexByID(qid)
    if not idx then return {} end
    local num = (GetNumQuestLeaderBoards and GetNumQuestLeaderBoards(idx)) or 0
    local rows = {}
    for i = 1, num do
        local text, typ, done = GetQuestLogLeaderBoard(i, idx)
        local got, need = text and text:match("(%d+)%s*/%s*(%d+)")
        rows[i] = {
            text = text or "",
            got = got and tonumber(got) or nil,
            need = need and tonumber(need) or nil,
            done = (done == 1 or done == true)
        }
    end
    return rows
end

-- Format a compact progress string for a quest, honoring optional which-objective filter (QO)
local function GRL_FormatObjectiveProgress(qid, which)
    local rows = GRL_GetObjectiveRows(qid)
    local parts = {}

    local function add_obj(ix)
        local o = rows[ix]
        if not o then return end
        if o.got and o.need then
            table.insert(parts, string.format("%d/%d", o.got, o.need))
        else
            table.insert(parts, o.done and "(done)" or "(…)")
        end
    end

    if type(which) == "table" and #which > 0 then
        for _, ix in ipairs(which) do add_obj(ix) end
    else
        -- Aggregate all objectives if no QO filter given
        local g, n, any = 0, 0, false
        for _, o in ipairs(rows) do
            if o.got and o.need then g = g + o.got; n = n + o.need; any = true end
        end
        if any then table.insert(parts, string.format("%d/%d", g, n)) end
    end
    return table.concat(parts, ", ")
end


function GRL:GetPlayerFaction()
    local f = UnitFactionGroup and UnitFactionGroup("player")
    local _, race = UnitRace and UnitRace("player")
    self:Debug("FactionGroup:", tostring(f), "Race:", tostring(race))
    
    if not f or f == "Neutral" then
        local normrace = _norm(race)
        local h = { orc=true, troll=true, tauren=true, undead=true, scourge=true, bloodelf=true, ["blood elf"]=true }
        local a = { human=true, dwarf=true, gnome=true, nightelf=true, ["night elf"]=true, draenei=true }
        if h[normrace] then
            f = "Horde"
        elseif a[normrace] then
            f = "Alliance"
        else
            f = "Neutral"
        end
    end
    return f or "Neutral"
end

function GRL:IsGuideForPlayerFaction(rec)
    if not rec or rec.faction == nil then return true end
    local pf = _norm(self:GetPlayerFaction())
    local rf = _norm(rec.faction); if rf=="h" then rf="horde" elseif rf=="a" then rf="alliance" elseif rf=="" or rf=="n" or rf=="both" or rf=="any" then rf="neutral" end

    if pf == "neutral" or pf == "" then return true end
    if rf == "both" or rf == "any" or rf == "neutral" or rf == "" then return true end
    return rf == pf
end

function GRL:IsStepForPlayer(i)
    local t = self.tags and self.tags[i]
    if not t then return true end
    if t.C then
        local playerClass = (select(2, UnitClass("player"))):lower():gsub("[%s%-%_]+","")
        local allowed = {}
        for clz in tostring(t.C):gmatch("[^,]+") do allowed[_norm(clz):gsub("%s+","")] = true end

        if not allowed[playerClass] then return false end
    end
    if t.R then
        local playerRace = (select(2, UnitRace("player"))):lower():gsub("%s+","")
        local allowed = {}
        for race in tostring(t.R):gmatch("[^,]+") do
		  local k = _norm(race):gsub("[%s%-%_]+","")
		  if k == "undead" then k = "scourge" end
		  allowed[k] = true
		end

        if not allowed[playerRace] then return false end
    end
    return true
end

---------------------------------------------------------------
-- Guide Registration (Global API)
---------------------------------------------------------------
local function tcontains(t, v) for i = 1, #t do if t[i] == v then return true end end end
function GRL:RegisterGuide(name, nextzone, faction, textProvider)
    local provider = textProvider
    if type(provider) ~= "function" then
        local txt = tostring(provider or "")
        provider = function() return txt end
    end
    local ff=_norm(faction); if ff=="h" then faction="Horde" elseif ff=="a" then faction="Alliance" elseif ff=="" or ff=="n" or ff=="both" or ff=="any" then faction="Neutral" end
    self.guides = self.guides or {}
    self.guidelist = self.guidelist or {}
    self.guides[name] = { next = nextzone, faction = faction, text = provider }
    if not tcontains(self.guidelist, name) then table.insert(self.guidelist, name) end
    local wantedGuide = charDB.guideName
    if wantedGuide and name == wantedGuide and (not self.actions or #(self.actions) == 0) then
        self:After(0.1, function() self:LoadGuide(name, true) end)
    end
end

_G["GuideReaderLite_RegisterGuide"] = function(name, nextzone, faction, textProvider)
    GuideReaderLite:RegisterGuide(name, nextzone, faction, textProvider)
end

---------------------------------------------------------------
-- Minimal UI (Status Frame) – Modernized Look (gold header + dark panel)
---------------------------------------------------------------
-- =========================
-- Status Frame (clean)
-- =========================
local f = CreateFrame("Frame", "GuideReaderLiteStatus", UIParent)
GRL.status = f
f:SetSize(420, 170)
f:SetPoint("CENTER")
f:SetFrameStrata("DIALOG")

-- Dark panel + classic gold edge
f:SetBackdrop({
  bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = false, edgeSize = 14,
  insets = { left=8, right=8, top=8, bottom=8 },
})
f:SetBackdropColor(0, 0, 0, 0.88)
f:SetBackdropBorderColor(0.95, 0.80, 0.25, 1)

-- Movable
f:EnableMouse(true)
f:SetMovable(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop",  f.StopMovingOrSizing)

-- Header bar (gold gradient)
f.header = f:CreateTexture(nil, "ARTWORK")
f.header:SetPoint("TOPLEFT",  8, -8)
f.header:SetPoint("TOPRIGHT", -8, -8)
f.header:SetHeight(28)
f.header:SetTexture("Interface\\Buttons\\WHITE8x8")
f.header:SetGradientAlpha("VERTICAL",
  0.28, 0.22, 0.06, 1,   -- top
  0.15, 0.12, 0.03, 1)   -- bottom

-- Thin header border (to match the screenshot style)
local hb = CreateFrame("Frame", nil, f)
hb:SetFrameLevel(f:GetFrameLevel() + 2)
hb:SetPoint("TOPLEFT",     f.header, "TOPLEFT",     -5,  5)
hb:SetPoint("BOTTOMRIGHT", f.header, "BOTTOMRIGHT",  5, -5)
hb:SetBackdrop({
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  edgeSize = 12,
  insets   = { left=3, right=3, top=3, bottom=3 },
})
hb:SetBackdropBorderColor(0.95, 0.80, 0.25, 1)

-- Divider under header
f.divider = f:CreateTexture(nil, "ARTWORK")
f.divider:SetTexture("Interface\\Buttons\\WHITE8x8")
f.divider:SetVertexColor(1.0, 0.85, 0.25, 0.25)
f.divider:SetPoint("TOPLEFT",  f.header, "BOTTOMLEFT",  0, -6)
f.divider:SetPoint("TOPRIGHT", f.header, "BOTTOMRIGHT", 0, -6)
f.divider:SetHeight(1)

-- Title on header
f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
f.title:SetPoint("LEFT", f.header, "LEFT", 10, 0)
f.title:SetText("Guide Reader Lite")
f.title:SetTextColor(1, 0.85, 0.2, 1)

-- Guide name
f.guideName = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
f.guideName:SetPoint("TOPLEFT", f.header, "BOTTOMLEFT", 10, -10)
f.guideName:SetPoint("RIGHT", f, "RIGHT", -18, 0)
f.guideName:SetJustifyH("LEFT")
f.guideName:SetText("")

-- Step text
f.text = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
f.text:SetPoint("TOPLEFT",  f.guideName, "BOTTOMLEFT", 0, -8)
f.text:SetPoint("RIGHT",    f, "RIGHT", -18, 0)
f.text:SetJustifyH("LEFT")
f.text:SetJustifyV("TOP")
f.text:SetText("No guide loaded.")

-- Prev / Next
f.prev = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
f.prev:SetSize(80, 22)
f.prev:SetPoint("BOTTOMLEFT", 12, 12)
f.prev:SetText("« Prev")
f.prev:SetScript("OnClick", function() GRL:PrevStep() end)

f.next = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
f.next:SetSize(80, 22)
f.next:SetPoint("BOTTOMRIGHT", -12, 12)
f.next:SetText("Next »")
f.next:SetScript("OnClick", function() GRL:NextStep() end)

f:Show()

-- Auto-resize to content
function GRL:ResizeStatusFrame()
  local f = self.status
  if not f or not f.text or not f.title then return end
  local th  = f.text:GetStringHeight()  or 0
  local gnh = f.guideName and f.guideName:GetStringHeight() or 0
  local chrome = 28 + 44 + 28  -- header + spacing + buttons
  f:SetHeight(math.max(120, chrome + gnh + th))
end

---------------------------------------------------------------
-- Guide Picker (Unchanged from your old working version)
---------------------------------------------------------------
function GRL:BuildGuidePicker()
    if self.picker then return end
    local p = CreateFrame("Frame","GuideReaderLite_GuidePicker",UIParent)
    p:SetSize(420,360); p:SetPoint("CENTER")
    p:SetBackdrop({
        bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true, tileSize=32, edgeSize=32,
        insets={left=8,right=8,top=8,bottom=8}
    })
    p:EnableMouse(true); p:SetMovable(true); p:RegisterForDrag("LeftButton")
    p:SetScript("OnDragStart", p.StartMoving); p:SetScript("OnDragStop", p.StopMovingOrSizing)
    p:Hide()

    local title = p:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
    title:SetPoint("TOP",0,-12); title:SetText("GuideReaderLite – Choose a Guide")
    local close = CreateFrame("Button",nil,p,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-6,-6)

    local search = CreateFrame("EditBox",nil,p,"InputBoxTemplate")
    search:SetSize(240,20); search:SetPoint("TOPLEFT",16,-40); search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function() GRL:RefreshGuidePicker() end)
    p.search = search

    local scroll  = CreateFrame("ScrollFrame", "GuideReaderLite_GuidePickerScroll", p, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -70); scroll:SetPoint("BOTTOMRIGHT", -32, 16)
    local content = CreateFrame("Frame", "GuideReaderLite_GuidePickerScrollChild", scroll)
    content:SetSize(1, 1); scroll:SetScrollChild(content)
    p.scroll, p.content = scroll, content

    self.picker = p
end

function GRL:RefreshGuidePicker()
    local p = self.picker; if not p then return end
    p.items = p.items or {}
    for _, b in ipairs(p.items) do b:Hide() end

    local q = string.lower(p.search:GetText() or "")
    local function match(name) return q=="" or string.find(string.lower(name), q, 1, true) end

    local y, i, shown = -4, 1, 0
    for _, name in ipairs(self.guidelist or {}) do
        local rec = self.guides[name]
        if rec and self:IsGuideForPlayerFaction(rec) and match(name) then
            local b = p.items[i] or CreateFrame("Button",nil,p.content,"UIPanelButtonTemplate")
            p.items[i] = b
            b:SetSize(340,20); b:ClearAllPoints(); b:SetPoint("TOPLEFT",4,y)
            b:SetText(name)
            b:SetScript("OnClick", function()
                p:Hide()
                GRL:LoadGuide(name)
            end)
            b:Show()
            y = y - 22; i = i + 1; shown = shown + 1
        end
    end

    if shown == 0 then
        y, i = -4, 1
        for _, name in ipairs(self.guidelist or {}) do
            local b = p.items[i] or CreateFrame("Button",nil,p.content,"UIPanelButtonTemplate")
            p.items[i] = b
            b:SetSize(340,20); b:ClearAllPoints(); b:SetPoint("TOPLEFT",4,y)
            b:SetText(name)
            b:SetScript("OnClick", function()
                p:Hide()
                GRL:LoadGuide(name)
            end)
            b:Show()
            y = y - 22; i = i + 1
        end
        say("|cffff5555No faction-specific guides detected, showing ALL guides.|r")
    end

    p.content:SetSize(340, -y + 4)
end

function GRL:ShowGuidePicker()
    self:BuildGuidePicker()
    self.picker:Show()
    self:RefreshGuidePicker()
end

---------------------------------------------------------------
-- Parsing, Step Logic, TomTom, Icon Rendering
---------------------------------------------------------------

-- ICON table for step type icons
local ICON = {
    A = "Interface\\GossipFrame\\AvailableQuestIcon",
    T = "Interface\\GossipFrame\\ActiveQuestIcon",
    C = "Interface\\Icons\\Ability_Warrior_OffensiveStance",
    R = "Interface\\Icons\\Ability_Rogue_Sprint",
    N = "Interface\\Icons\\INV_Scroll_03",
    G = "Interface\\Icons\\INV_Box_01",   			-- Chest icon for collect quest
    B = "Interface\\Icons\\INV_Misc_Coin_01",   	-- Buy step icon
    Z = "Interface\\Icons\\INV_Misc_Map_01",    	-- Area/Zone step
}
local function IconPrefix(a)
    local tex = ICON[a]
    if tex then return "|T"..tex..":16:16:0:0|t " end
    return (a or "?").." "
end

local function parseTags(seg)
    local t = {}
    if not seg or seg == "" then return t end
    for k, v in seg:gmatch("|([A-Za-z]+)|([^|]*)|") do
        k = k:upper()
        t[k] = (v or ""):gsub("^%s+",""):gsub("%s+$","")
    end

	-- Check for multiple quest objectives
    if t.QID then
	  local ids = {}
	  for n in tostring(t.QID):gmatch("%d+") do ids[#ids+1] = tonumber(n) end
	  if #ids > 1 then t.qids = ids else t.qid = ids[1] or t.QID end
	end

    if t.QO then
        local arr = {}
        for n in tostring(t.QO):gmatch("%d+") do arr[#arr+1] = tonumber(n) end
        if #arr > 0 then t.QO = arr end
    end
    if t.ITEM then t.item = tonumber(t.ITEM) or t.ITEM end
    if t.N then t.N = t.N end
    if t.AREA then
        t._area = t.AREA
    end
	
	-- Zone hint (prefer ZONE or Z; fall back to AREA)
	if t.ZONE and t.ZONE ~= "" then t._zonehint = t.ZONE
	elseif t.Z and t.Z ~= "" then t._zonehint = t.Z
	elseif t.AREA and t.AREA ~= "" then t._zonehint = t.AREA end

    if t.TO then
        local v = tostring(t.TO):lower()
        t._tt_off = (v == "" or v == "1" or v == "on" or v == "true" or v == "yes")
    end
    -- sticky flags (presence-only)
    t.S  = (t.S  ~= nil and t.S  ~= false)
    t.US = (t.US ~= nil and t.US ~= false)
	t.AA = (t.AA ~= nil and t.AA ~= false) -- auto advance on directions

	
    return t
end

local function extractCoordsFromText(t, rawline)
    t._mx, t._my = nil, nil
    if not t then return end
    local coordStr = t.M or t.WM
    if not coordStr or coordStr == "" then return end
    -- Accept: "24,18"  "24.8, 18.2"  "24 18"  "24; 18"
	local x, y = tostring(coordStr):match("(%d+%.?%d*)%s*[,;%s]+%s*(%d+%.?%d*)")

    if x and y then t._mx, t._my = tonumber(x), tonumber(y) end
end

function GRL:_parseGuide(text)
    local actions, quests, tags = {}, {}, {}
    local lines = {}
    for _,line in ipairs(splitlines(text)) do
        local l = trim(line)
        if l ~= "" and l:sub(1,1) ~= ";" then
            table.insert(lines, l)
            local pline = l
            local lead = pline:match("^%s*(%d+)%s+")
            if lead then pline = pline:gsub("^%s*%d+%s+", "", 1) end
            local act = pline:match("^([A-Za-z])%s") or pline:sub(1,1)
            local body= trim(pline:sub(2))
            local tagstr = body:match("(|.+)$") or ""
            local name   = trim(body:gsub("(|.+)$",""))
            local t = parseTags(tagstr); t.raw = pline
            extractCoordsFromText(t, pline)
            actions[#actions+1]=act; quests[#quests+1]=name; tags[#tags+1]=t
        end
    end
    return actions, quests, tags, lines
end

function GRL:IsStepDone(i)
    local t = self.tags and self.tags[i] or {}
    local a = self.actions and self.actions[i]
    local result = false
	
	-- Hold A/T while gossip is open unless we just saw the explicit event
	if (a == "A" or a == "T") and self._inGossip then
		local qid = t.qid
		local ok_recent = (a == "A" and self._recentAccepted and qid and _recent(self._recentAccepted[qid], 10))
					   or (a == "T" and self._recentTurnedIn and qid and _recent(self._recentTurnedIn[qid], 10))
		if not ok_recent then
			self:DebugStepAdvance("IsStepDone HOLD (gossip open) a=", a, "qid=", qid)
			return false
		end
	end

    if not self:IsStepForPlayer(i) then
        result = true
    end

    if t.qid or a == "H" or a == "h" or a == "R" or (a == "C" and t.qids and #t.qids > 0) then

        -- Only relevant to T steps; guard nil QID
		if a == "T" and t.qid and self.turnedinquests[t.qid] then
			result = true
		end

		
		-- Check for multiple quest objectives completed
        if a == "C" then
			local ok
			if t.qids and #t.qids > 1 then
				ok = true
				for i, qid in ipairs(t.qids) do
					local qo = nil
					if type(t.QO) == "table" then
						if #t.QO == #t.qids then qo = t.QO[i]
						elseif #t.QO == 1 then qo = t.QO[1] end
					end
					if not GRL_AreObjectivesDone(qid, qo) then ok = false; break end
				end
			else
				ok = GRL_AreObjectivesDone(t.qid, t.QO)
			end
			if ok then result = true end
		end

        if a == "G" then
            if t.qid and GRL_AreObjectivesDone(t.qid, t.QO) then
                result = true
            end
        end
        if a == "B" then
            if t.item and GetItemCount(t.item, false, false) > 0 then
                result = true
            end
        end
        if a == "A" then
			-- Advance strictly on the explicit accept event for this QID.
			-- (Prevents NPC click → advance without actually accepting.)
			local recent = t.qid and self._recentAccepted and _recent(self._recentAccepted[t.qid], 15)
			if recent then
				result = true
			end
		end


        if a == "T" then
			if t.qid and (self.turnedinquests[t.qid]
				or (self._recentTurnedIn and _recent(self._recentTurnedIn[t.qid], 10))) then
				result = true
			end
			-- Do NOT treat "not in log" as turned-in; prevents premature advance on gossip.
		end


        -- NOTE: Convention in our guides:
		--   H = set hearth/home (bind)
		--   h = hearth (use Hearthstone / Astral Recall)
		if a == "H" then
			-- set home: succeed when we just saw the bind message OR current bind location matches |N|
			local bindLoc = GetBindLocation and GetBindLocation()
			local expectedLoc = (t.N or ""):gsub("^%s+",""):gsub("%s+$","")
			if bindLoc and expectedLoc ~= "" then
				local bl = string.lower(bindLoc or "")
				local ex = string.lower(expectedLoc or "")
				if bl:find(ex, 1, true) then
					result = true
				end
			end
			if self._lastBindTime and (GetTime() - self._lastBindTime) <= 45 then
				result = true
			end
		end
		if a == "h" then
			-- hearth used recently
			if self._hearthAt and (GetTime() - self._hearthAt) <= 90 then
				result = true
			end
		end
    end

    if a == "U" then
        if t.U and GRL_AnyItemCooling(t.U) then
            result = true
        end
        if t.BUFF and GRL_PlayerHasBuff(t.BUFF) then
            result = true
        end
        if t.BUFFID and GRL_PlayerHasBuff(t.BUFFID) then
            result = true
        end
    end

    if t.BUFF and GRL_PlayerHasBuff(t.BUFF) then
        result = true
    end
    if t.BUFFID and GRL_PlayerHasBuff(t.BUFFID) then
        result = true
    end

    if a == "R" then
        if self._arrivedAtStep == i then
            result = true
        else
            result = false
        end
    end


    if a == "Z" then
        result = false
    end

    self:DebugStepAdvance("IsStepDone", "step:", i, "action:", a, "qid:", t.qid, "result:", result)
	
	--Debug to make sure multiple quests are done.
	local dbgq = t.qid or (t.qids and table.concat(t.qids, ",")) or "nil"
	self:DebugStepAdvance("IsStepDone", "step:", i, "action:", a, "qid(s):", dbgq, "result:", result)

    return result
end

function GRL:FindFirstUndoneStep()
    if not self.actions then return 1 end
    for i=1,#self.actions do
        if self:IsStepForPlayer(i) and not self:IsStepDone(i) then
            return i
        end
    end
    return #self.actions
end

function GRL:SmartResumeStep()
    local max = #(self.actions or {})
    if max == 0 then self.current = 1; return end
    local g = self.currentGuide
    local savedIdx = charDB.idx and charDB.idx[g]
    if savedIdx and savedIdx >= 1 and savedIdx <= max and self:IsStepForPlayer(savedIdx) then
        self.current = savedIdx
        self:DebugStepAdvance("Resume via idx:", savedIdx)
        return
    end
    self.current = self:FindFirstUndoneStep()
    self:DebugStepAdvance("Resume via first-undone:", self.current)
end

function GRL:RememberStep()
    if not (self.currentGuide and self.current) then return end
    charDB.guideName = self.currentGuideDisplay or self.currentGuide
    local max = #(self.lines or self.actions or {})
    local idx = math.max(1, math.min(self.current, max>0 and max or 1))
    charDB.idx = charDB.idx or {}
    charDB.idx[self.currentGuideDisplay or self.currentGuide] = idx
    self:DebugStepAdvance("RememberStep: guideName=" .. tostring(charDB.guideName) .. ", step=" .. tostring(idx))
end

function GRL:_HookTomTom()
    if self._ttHooked or not TomTom then return end
    self._ttHooked = true
    local TT = TomTom
    self._tt_SetCrazyArrow = TT.SetCrazyArrow
    self._tt_SetClosest    = TT.SetClosestWaypoint

    TT.SetCrazyArrow = function(tt, uid, dist, ...)
        if GRL and GRL._allowArrow then
            return GRL._tt_SetCrazyArrow(tt, uid, dist, ...)
        end
        if tt.HideCrazyArrow then tt:HideCrazyArrow() end
    end
    if self._tt_SetClosest then
        TT.SetClosestWaypoint = function(tt, ...)
            if GRL and GRL._allowArrow then
                return GRL._tt_SetClosest(tt, ...)
            end
            if tt.HideCrazyArrow then tt:HideCrazyArrow() end
        end
    end
end

function GRL:_TTNuke()
    local tt = TomTom
    if not tt then return end
    pcall(function()
        if tt.HideCrazyArrow then tt:HideCrazyArrow() end
        if _G.TomTomCrazyArrow then
            local a = _G.TomTomCrazyArrow
            if a.SetWaypoint then a:SetWaypoint(nil) end
            if a.SetTarget   then a:SetTarget(nil)   end
            a.waypoint, a.poi = nil, nil
            if a:IsShown() then a:Hide() end
            if a.title and a.title.SetText then a.title:SetText("") end
        end
        if tt.ArrowFrame and tt.ArrowFrame.Hide then tt.ArrowFrame:Hide() end
        if tt.RemoveAllWaypoints then
            tt:RemoveAllWaypoints()
        elseif tt.waydb and tt.RemoveWaypoint then
            for _, prof in pairs(tt.waydb.profiles or {}) do
                for _, zone in pairs(prof.waypoints or {}) do
                    for _, w in pairs(zone) do tt:RemoveWaypoint(w) end
                end
            end
        end
    end)
end

local function GRL_FindCZByZoneName(name)
    if type(name) ~= "string" or name:match("^%s*$") then return nil, nil end
    local norm = _norm(name)
    local conts = GetMapContinents and {GetMapContinents()} or {}
    for c, _ in ipairs(conts) do
        local zones = GetMapZones and {GetMapZones(c)} or {}
        for z, zn in ipairs(zones) do
            if _norm(zn) == norm then return c, z end
        end
    end
    return nil, nil
end



function GRL:ShowPointer(idx, force)

    local i  = self.current or 1
    local t  = self.tags and self.tags[i]
    local a  = self.actions and self.actions[i]
    -- Do NOT clear _arrivedAtStep here! It's cleared only on step change.

    self:DebugStepAdvance("ShowPointer: step", i, "coords", t and t._mx, t and t._my)
	
	if t and t._zonehint and t._zonehint ~= "" then
		GRL._zoneHint = t._zonehint
	end


    self._allowArrow = false
    self._nukeTicket = (self._nukeTicket or 0) + 1
    local ticket = self._nukeTicket
    self:_TTNuke()

    if (t and t._tt_off) or (a == "Z" and (not t._mx or not t._my)) then
        self:_TTNuke()
        self:Debug("Pointer off: |TO| or Z step (no coords) " .. tostring(i))
        return
    end

    if TomTom then pcall(function()
        if TomTom.HideCrazyArrow then TomTom:HideCrazyArrow() end
        if TomTom.RemoveAllWaypoints then
            TomTom:RemoveAllWaypoints()
        elseif TomTom.waydb and TomTom.RemoveWaypoint then
            for _, prof in pairs(TomTom.waydb.profiles or {}) do
                for _, zone in pairs(prof.waypoints or {}) do
                    for _, w in pairs(zone) do TomTom:RemoveWaypoint(w) end
                end
            end
        end
    end) end

    if not t or not t._mx or not t._my or (self:IsStepDone(i) and not force) then
        local function renuke() if self._nukeTicket == ticket then self:_TTNuke() end end
        renuke()
        self:After(0.10, renuke)
        self:After(0.50, renuke)
        self:After(1.00, renuke)
        self:DebugStepAdvance("Pointer off: No coords or step completed for step " .. tostring(i))
        return
    end

    if not TomTom then return end

    local x = tonumber(t._mx)
    local y = tonumber(t._my)
    if not x or not y then
        self:DebugStepAdvance("Pointer off: coords invalid")
        return
    end

    local function toPercent(v) return (v > 1) and v or (v * 100) end
    local px, py = toPercent(x), toPercent(y)
    local fx, fy = px/100, py/100
    local desc   = (self.quests and self.quests[i] or "Guide Step") .. " (" .. i .. ")"

    self._nukeTicket = self._nukeTicket + 1
    self._allowArrow = true

	-- Auto-advance on arrival for all R steps (coords required)
	if a == "R" and t and t._mx and t._my then
		local thr = tonumber(t.TH) or 0.10  -- |TH| overrides arrival threshold (map percent)
		self:_StartNavWatch(i, tonumber(t._mx), tonumber(t._my), thr)
	end


    local function place(c, z)
        local uid, used

        if TomTom.AddZWaypoint then
            local ok, r = pcall(function() return TomTom:AddZWaypoint(c, z, px, py, desc) end)
            if ok and r then uid, used = r, "AddZWaypoint %" end
        end
        if not uid and TomTom.AddWaypoint then
            local ok, r = pcall(function() return TomTom:AddWaypoint(px, py, desc) end)
            if ok and r then uid, used = r, "AddWaypoint %" end
        end
        if not uid and TomTom.AddWaypoint then
            local ok, r = pcall(function() return TomTom:AddWaypoint(fx, fy, { title = tostring(desc) }) end)

            if ok and r then uid, used = r, "AddWaypoint frac" end
        end
        if not uid then
            local zn = (t and t._zonehint) or GRL._zoneHint or ((GetRealZoneText and GetRealZoneText()) or "")

            if zn ~= "" and TomTom.AddMFWaypoint then
                local ok, r = pcall(function()
                    return TomTom:AddMFWaypoint(zn, nil, fx, fy, { title = desc })
                end)
                if ok and r then uid, used = r, "AddMFWaypoint" end
            end
        end
		
		 if uid then
			self._tt_uid = uid
		end

        if uid and TomTom.SetCrazyArrow then
            pcall(function() TomTom:SetCrazyArrow(uid, 3, desc) end) -- hide arrow after 6feet
        end
        self:DebugStepAdvance("Pointer set with:", used or "none",
            string.format("pxy=%.2f,%.2f  fxy=%.2f,%.2f", px, py, fx, fy))
    end

    local targetC, targetZ
	local znameHint = (t and t._zonehint) or GRL._zoneHint
	if znameHint then targetC, targetZ = GRL_FindCZByZoneName(znameHint) end

	if targetC and targetZ then
		if SetMapZoom then pcall(SetMapZoom, targetC, targetZ) end
		place(targetC, targetZ)
	elseif self.WithReadyZone then
		self:WithReadyZone(function(c, z) place(c, z) end)
	else
		pcall(SetMapToCurrentZone)
		local c = (GetCurrentMapContinent and GetCurrentMapContinent()) or 0
		local z = (GetCurrentMapZone and GetCurrentMapZone()) or 0
		place(c, z)
	end
	
	end


-- === Proximity watcher for |AA| (auto-advance on arrival) ===
GRL._navWatchFrame = GRL._navWatchFrame or CreateFrame("Frame")
GRL._navWatchTarget = GRL._navWatchTarget or nil

local function _grl_GetPlayerXY()
    local x, y = 0, 0
    if SetMapToCurrentZone then SetMapToCurrentZone() end
    if GetPlayerMapPosition then
        local px, py = GetPlayerMapPosition("player")
        if px and py then x, y = px, py end -- 0-1
    end
    return x, y
end

function GRL:_StartNavWatch(stepIndex, mx_percent, my_percent, thresh_percent)
	--DEFAULT_CHAT_FRAME:AddMessage(("GRL navwatch start: step=%s target=%.2f,%.2f thr=%.4f%%")
    --:format(stepIndex, mx_percent or -1, my_percent or -1, thresh_percent or -1))

    -- Use map-percent only; 0.25% default is ~very close
    local tx, ty = (mx_percent or 0)/100, (my_percent or 0)/100
    local pct_thresh = (thresh_percent or 0.25) / 100  -- default 0.25%

    self._navWatchTarget = { i = stepIndex, x = tx, y = ty, th = pct_thresh }

    local acc = 0
    GRL._navWatchFrame:SetScript("OnUpdate", function(_, dt)
        acc = acc + (dt or 0)
        if acc < 0.20 then return end  -- ~5x/sec
        acc = 0

        local t = GRL._navWatchTarget
        if not t then return end
        if (GRL.current or 0) ~= t.i then
            GRL._navWatchTarget = nil
            GRL._navWatchFrame:SetScript("OnUpdate", nil)
            return
        end

        -- Pure map-percent distance (0..1)
        local px, py = _grl_GetPlayerXY()
        local dx, dy = (px - t.x), (py - t.y)
		
		--DEFAULT_CHAT_FRAME:AddMessage(("GRL navwatch d2=%.6f  th2=%.6f  px=%.4f py=%.4f")
	--:format(dx*dx + dy*dy, t.th * t.th, px, py))


        if (dx*dx + dy*dy) <= (t.th * t.th) then
            GRL._arrivedAtStep = t.i
            GRL._navWatchTarget = nil
            GRL._navWatchFrame:SetScript("OnUpdate", nil)
            if GRL.AutoAdvance then GRL:AutoAdvance(true) end
        end
    end)
end




function GRL:UpdateStatusFrame()
    local i = self.current or 1
    local total = #(self.actions or {})
    while i <= total and not self:IsStepForPlayer(i) do
        i = i + 1
    end
    if i > total then
        self.status.text:SetText("No guide loaded.")
        if self.status.guideName then self.status.guideName:SetText("") end
        return
    end
    local a = (self.actions or {})[i] or "?"
    local q = (self.quests  or {})[i] or ""
    local n = self.tags and self.tags[i] and self.tags[i].N or nil
    local guideName = self.currentGuideDisplay or self.currentGuide or ""
    local top = IconPrefix(a) .. q
    local note = ""
    if n and n ~= "" then
        n = n:gsub("\\n", "\n"):gsub("<br>", "\n")
        note = "\n|cffaaaaaa"..n.."|r"
    end
    local tt = self.tags and self.tags[i]
	
	-- Start sticky if this step has |S| and a QID
	if tt and tt.S and tt.qid then
		self._sticky = self._sticky or {}
		if not self._sticky[tt.qid] then
			self._sticky[tt.qid] = { qo = tt.QO }
		end
	end
	-- Auto-clear any stickies that are now done
	if self._sticky then
		for qid, info in pairs(self._sticky) do
			if GRL_AreObjectivesDone(qid, info and info.qo) then
				self._sticky[qid] = nil
			end
		end
	end

    if a == "Z" and tt and tt._area then
        note = note .. "\n|cff88ff88Go to area: " .. tt._area .. "|r"
    elseif tt and tt._mx and tt._my then
        note = note .. string.format("\n|cff88ccff[%.2f, %.2f]|r", tt._mx, tt._my)
    end
	
	-- show active sticky alongside current step
	local curqid = tt and tt.qid
	for qid, info in pairs(self._sticky or {}) do
	  if qid ~= curqid and not GRL_AreObjectivesDone(qid, info and info.qo) then
		local lbl = self:_FindQuestTextByQID(qid) or ("QID "..tostring(qid))
		note = note .. "\n|cffffcc00Also:|r " .. lbl
	  end
	end
	
	    -- Show live objective counts for "C" steps (supports single QID or multi-QID C lines)
    if a == "C" and tt and (tt.qid or (tt.qids and #tt.qids > 0)) then
        local lines = {}

        if tt.qids and #tt.qids > 1 then
            -- Multi-quest C: try to map QO per quest if author provided a 1:1 list; otherwise reuse single QO for all
            for i_q, qid in ipairs(tt.qids) do
                local qo = nil
                if type(tt.QO) == "table" then
                    if #tt.QO == #tt.qids then qo = { tt.QO[i_q] }
                    elseif #tt.QO == 1 then qo = tt.QO
                    end
                end
                local prog = GRL_FormatObjectiveProgress(qid, qo)
                if prog and prog ~= "" then
                    local label = (self:_FindQuestTextByQID(qid) or ("QID "..tostring(qid)))
                    table.insert(lines, "|cffaaffaa"..label.."|r "..prog)
                end
            end
        else
            -- Single quest C
            local prog = GRL_FormatObjectiveProgress(tt.qid, tt.QO)
            if prog and prog ~= "" then
                table.insert(lines, "|cffaaffaaProgress:|r "..prog)
            end
        end

        if #lines > 0 then
            note = note .. "\n" .. table.concat(lines, "\n")
        end
    end



    self.status.text:SetText(top..note)
    if self.status.guideName then
        self.status.guideName:SetText("|cffffff00"..guideName.."|r")
    end
    self:ResizeStatusFrame(); self:After(0.01, function() self:ResizeStatusFrame() end)
end

---------------------------------------------------------------
-- Per-Character Guide Save/Load Logic
---------------------------------------------------------------
function GRL:LoadGuide(name, quiet)
	self._arrivedAtStep = nil
    local rec = self.guides[name]
    if not rec then 
        if not quiet then say("|cffff5555guide not found:|r "..tostring(name)) end
        return 
    end
    if not self:IsGuideForPlayerFaction(rec) then
        if not quiet then say("|cffff5555That guide is for the other faction.|r") end
        return
    end
    if not rec.actions then
        local ok, text = pcall(rec.text)
        if not ok or type(text)~="string" then 
            say("|cffff5555bad guide text for|r "..name) 
            return 
        end
        rec.actions, rec.quests, rec.tags, rec.lines = self:_parseGuide(text)
    end

    self.actions, self.quests, self.tags, self.lines = deepcopy(rec.actions), deepcopy(rec.quests), deepcopy(rec.tags), deepcopy(rec.lines)
	self._sticky = {}
    self.currentGuide, self.currentGuideDisplay = name, name
    charDB.guideName = name

    local savedIdx = charDB.idx and charDB.idx[name]
	if savedIdx and savedIdx >= 1 and savedIdx <= #self.actions then
		self.current = savedIdx
		self:DebugStepAdvance("Resumed from saved step:", savedIdx)
	else
		self:SmartResumeStep()
	end

    self:RememberStep()
    self:UpdateStatusFrame()
    if not quiet then say("Loaded guide: "..name) end
    self:ShowPointer()
end

function GRL:NextStep()
	self._arrivedAtStep = nil
    if not self.actions then return end
    local i = self.current or 1
    i = i + 1

    if i > #self.actions then
		local cur = self.currentGuide
		local rec = cur and self.guides[cur]
		local nxt = rec and rec.next
		if nxt and self.guides[nxt] then
			say("|cff55ff55Guide complete – loading next:|r " .. nxt)
			self:LoadGuide(nxt)
		else
			self:ShowGuidePicker()
			say("|cff55ff55Guide complete! Please select the next guide to continue.|r")
		end
		return
	end

    while i <= #self.actions and not self:IsStepForPlayer(i) do
        i = i + 1
    end
    if i <= #self.actions then
        self.current = i
        self:RememberStep(); self:UpdateStatusFrame()
        self:ShowPointer()
        local t = self.tags and self.tags[self.current]
        if t and t.GP == "1" then
            self:ShowGuidePicker()
            say("|cff55ff55Guide step requests opening the guide picker.|r")
            return
        end
    end
end

function GRL:PrevStep()
	self._arrivedAtStep = nil
    if not self.actions then return end
    local i = self.current or 1
    repeat
        i = i - 1
    until i < 1 or self:IsStepForPlayer(i)
    if i >= 1 then
        self.current = i
        self:RememberStep(); self:UpdateStatusFrame()
        self:ShowPointer(self.current, true)
    end
end

function GRL:AutoAdvance(force)
    self:DebugStepAdvance("AutoAdvance: current=", self.current, "stepDone=", self:IsStepDone(self.current), "force=", force)
    if not self.actions or not self.current then return end
    local i = self.current
    if self:IsStepDone(i) or force then
	
		local t = self.tags and self.tags[i]
		-- If any sticky is still unfinished and this isn’t a |US| line, wait here
		if self:_HasStickyUndone() and not (t and t.US) then
			self:DebugStepAdvance("Sticky gate: waiting for sticky objectives to finish.")
			return
		end

        local oldCurrent = i
        repeat
            i = i + 1
        until i > #self.actions or (self:IsStepForPlayer(i) and not self:IsStepDone(i))
        
                if i <= #self.actions and i ~= oldCurrent then
            self.current = i
            self:RememberStep()
            self:UpdateStatusFrame()
            self:ShowPointer()
        else
            -- i > #self.actions : guide finished via auto-advance
            local cur = self.currentGuide
            local rec = cur and self.guides[cur]
            local nxt = rec and rec.next
            if nxt and self.guides[nxt] then
                say("|cff55ff55Guide complete – loading next:|r " .. nxt)
                self:LoadGuide(nxt)
            else
                self:ShowGuidePicker()
                say("|cff55ff55Guide complete! Please select the next guide to continue.|r")
            end
        end
    end
end


---------------------------------------------------------------
-- Events & Slash Commands
---------------------------------------------------------------

function GRL:RegisterEvent(ev, handler)
    self._events = self._events or {}
    self._events[ev] = handler or true
    self.frame = self.frame or CreateFrame("Frame", "GuideReaderLiteFrame", UIParent)
    self.frame:RegisterEvent(ev)
end

GRL.frame:SetScript("OnEvent", function(_, ev, ...)
    local h = GRL._events and GRL._events[ev]
    if not h then return end
    if type(h) == "string" then h = GRL[h] end
    if type(h) == "function" then h(GRL, ...) end
end)

GRL:RegisterEvent("QUEST_LOG_UPDATE", function(self)
    self:UpdateStatusFrame()
    -- Don’t advance steps just because we opened/are in gossip.
    if self.AutoAdvance and not self._inGossip then
        self:AutoAdvance()
    end
end)


GRL:RegisterEvent("BAG_UPDATE_COOLDOWN", function(self) 
    if self.AutoAdvance then self:AutoAdvance() end
end)

GRL:RegisterEvent("GOSSIP_SHOW",   function(self) self._inGossip = true  end)
GRL:RegisterEvent("GOSSIP_CLOSED", function(self) self._inGossip = false end)


GRL:RegisterEvent("UNIT_AURA", function(self, unit) 
    if unit == "player" and self.AutoAdvance then self:AutoAdvance() end
end)

GRL:RegisterEvent("ADDON_LOADED", function(self, addon)
    if addon == "TomTom" then
        self:After(0.10, function()
            GRL:_HookTomTom()
            local tt = TomTom
            if tt and tt.db and tt.db.profile then
                local p = tt.db.profile
                if p.arrow then p.arrow.setclosest = false end
                if p.poi   then p.poi.setclosest   = false end
                if tt.HideCrazyArrow then tt:HideCrazyArrow() end
                if tt.RemoveAllWaypoints then tt:RemoveAllWaypoints() end
            end
        end)
    elseif addon == "GuideReaderLite" then
        GuideReaderLiteDB = GuideReaderLiteDB or {}
		self.db = GuideReaderLiteDB
		self.db.char = self.db.char or {}
		self.db.char[realmName] = self.db.char[realmName] or {}
		self.db.char[realmName][playerName] = self.db.char[realmName][playerName] or {}
		charDB = self.db.char[realmName][playerName]
		charDB.idx = charDB.idx or {}

    end
end)

GRL:RegisterEvent("PLAYER_LOGIN", function(self)
    GuideReaderLiteDB = GuideReaderLiteDB or {}
	self.db = GuideReaderLiteDB
	self.db.char = self.db.char or {}
	self.db.char[realmName] = self.db.char[realmName] or {}
	self.db.char[realmName][playerName] = self.db.char[realmName][playerName] or {}
	charDB = self.db.char[realmName][playerName]
	charDB.idx = charDB.idx or {}
	
    self:After(0.20, function()
        GRL:_HookTomTom()
        local tt = TomTom
        if tt and tt.db and tt.db.profile then
            local p = tt.db.profile
            if p.arrow then p.arrow.setclosest = false end
            if p.poi   then p.poi.setclosest   = false end
            if tt.HideCrazyArrow then tt:HideCrazyArrow() end
            if tt.RemoveAllWaypoints then tt:RemoveAllWaypoints() end
        end
    end)

     local function try_autoload()
        say("Login: Saved guideName is: " .. tostring(charDB.guideName))
        say("Available guides are: " .. table.concat((function() local t = {}; for k in pairs(self.guides) do t[#t+1]=k end; return t end)(), ", "))
        local gname = charDB.guideName
        if gname and self.guides[gname] then
            self:LoadGuide(gname, true)
            return true
        end
        self:ShowGuidePicker(); return true
    end

    local ok = try_autoload()
    if not ok then self:After(1.0, try_autoload) end
    self:UpdateStatusFrame()
end)

GRL:RegisterEvent("QUEST_ACCEPTED", function(self, questIndex, questID)
    if type(questID) == "number" then
        self._recentAccepted[questID] = GetTime()
    end
    if self.AutoAdvance then self:AutoAdvance(true) end
end)

GRL:RegisterEvent("QUEST_TURNED_IN", function(self, questID)
    if type(questID) == "number" then
        self.turnedinquests = self.turnedinquests or {}
        self.turnedinquests[questID] = true
        self._recentTurnedIn[questID] = GetTime()
    end
    if self.AutoAdvance then self:AutoAdvance(true) end
end)

GRL:RegisterEvent("PLAYER_LEAVING_WORLD", function(self) 
    self:RememberStep()
end)

GRL:RegisterEvent("PLAYER_LOGOUT", function(self) 
    self:RememberStep()
end)

---------------------------------------------------------------
-- Slash Commands
---------------------------------------------------------------

SLASH_GUIDEREADERLITE1 = "/grlite"
SlashCmdList.GUIDEREADERLITE = function(msg)
    msg = trim(msg or ""):lower()
    if msg=="" then 
        say("/grlite picker | load <name> | step <n> | next | prev | trace on|off | debug") 
        return 
    end
    if msg == "where" then
        local i = GRL.current or 1
        local t = GRL.tags and GRL.tags[i]
        if t and t._mx and t._my then
            say(string.format("Step %d coords parsed: %.2f, %.2f", i, t._mx, t._my))
        else
            say("No coords parsed for this step.")
        end
        GRL:ShowPointer()
        return
    end
    if msg=="picker" or msg=="list" then GRL:ShowGuidePicker(); return end
    if msg:sub(1,4)=="load" then 
        local name=trim(msg:sub(5)); 
        if name~="" then GRL:LoadGuide(name) end; 
        return 
    end
    if msg=="next" then GRL:NextStep(); return end
    if msg=="prev" then GRL:PrevStep(); return end
    if msg == "debug" then
        say("Current guide: " .. tostring(GRL.currentGuideDisplay))
        say("Current step: " .. tostring(GRL.current) .. "/" .. tostring(#(GRL.actions or {})))
        say("Saved guideName: " .. tostring(charDB.guideName))
		if GRL.currentGuideDisplay then
			say("Saved step for this guide: " .. tostring((charDB.idx or {})[GRL.currentGuideDisplay]))
		end

        say("Available guides: " .. tostring(#(GRL.guidelist or {})))
        return
    end
    if msg == "trace on" then GRL.trace = true; say("trace: |cff55ff55ON|r"); return end
    if msg == "trace off" then GRL.trace = false; say("trace: |cffff5555OFF|r"); return end
    local stepnum = msg:match("^step%s+(%d+)$")
    if stepnum then
        local n = tonumber(stepnum); local max = #(GRL.actions or {})
        if max > 0 then
            while n <= max and not GRL:IsStepForPlayer(n) do n = n + 1 end
            GRL.current = math.max(1, math.min(n, max))
            GRL:RememberStep(); GRL:UpdateStatusFrame(); GRL:ShowPointer(); 
            say("forced step "..GRL.current.." / "..max)
        end
        return
    end
    say("unknown command")
end

-- === GRL Auto-Resume (append-only) ===
GRL.auto_resume = false  -- set false to disable auto jump on login

local function _grl_GetPlayerXY()
  local x, y = 0, 0
  local m = GetCurrentMapContinent and GetCurrentMapContinent() or 0
  if SetMapToCurrentZone then SetMapToCurrentZone() end
  if GetPlayerMapPosition then
    local px, py = GetPlayerMapPosition("player")
    if px and py then x, y = px*100, py*100 end  -- percent units
  end
  return x, y
end

function GRL:ResumeNearest()
  if not (self.actions and self.tags) then return end
  local zone = GetRealZoneText and GetRealZoneText() or nil
  local px, py = _grl_GetPlayerXY()
  local best_i, best_d2 = nil, 1e12

  for i=1,#self.actions do
    local t = self.tags[i]
    if t then
      local a = self.actions[i]
      local qid = t.qid or (t.qids and t.qids[1])
      -- hearth / flight / vendor steps are not great resume points; bias toward quest steps
      local prefer = (a == "C" or a == "T" or a == "A")
      -- consider only not-done steps
      if not self:IsStepDone(i, true) then
        local mx, my = t._mx, t._my
        local zhint = t._zonehint
        local zone_ok = (not zhint) or (zone and zhint == zone)
        if mx and my and zone_ok then
          local dx, dy = (mx - px), (my - py)
          local d2 = dx*dx + dy*dy
          -- prefer quest steps by shrinking their distance score
          if prefer then d2 = d2 * 0.5 end
          if d2 < best_d2 then best_i, best_d2 = i, d2 end
        elseif (not best_i) and zone_ok and prefer then
          -- no coords but good action in same zone: fallback candidate
          best_i, best_d2 = i, 9e11
        end
      end
    end
  end

  if best_i then
    self.current = best_i
	self:RememberStep()
	self:UpdateStatusFrame()
	self:ShowPointer()

    self:DebugStepAdvance("AutoResume → step "..best_i)
  end
end

-- run once on login, after everything loads
do
  local f = CreateFrame("Frame")
  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:SetScript("OnEvent", function()
    if GRL and GRL.auto_resume and not GRL._didAutoResume then
      GRL._didAutoResume = true
      GRL:After(1.0, function() GRL:ResumeNearest() end)
    end
  end)
end

-- /grl resume command
SLASH_GRLRESUME1 = "/grlresume"
SLASH_GRLRESUME2 = "/grlresume!"
SLASH_GRLRESUME3 = "/grlresume1"
SlashCmdList.GRLRESUME = function() if GRL then GRL:ResumeNearest() end end


-- === GRL Hotspot Lead Mode (append-only) ===
GRL.lead_mode = true   -- default ON. Toggle with /grl lead on|off

-- prefer hotspots for C-steps (even if |M| exists)
function GRL:_MaybeLeadWithHotspot(t)
  if not self.lead_mode then return false end
  if not t then return false end
  local a = t.a or t._action
  if a ~= "C" then return false end
  local qid = t.qid or (t.qids and t.qids[1])
  if not qid then return false end

  if GRL_HOTSPOT_BYENTRY and t.entry and GRL_HOTSPOT_BYENTRY[qid] and GRL_HOTSPOT_BYENTRY[qid][t.entry] then
    local r = GRL_HOTSPOT_BYENTRY[qid][t.entry]
    if r and r.x and r.y then
      add_tt(r.map, r.x, r.y, ("Hunt: %s"):format(r.mob or "targets"))
      return true
    end
  end
  if GRL_HOTSPOT_BEST and GRL_HOTSPOT_BEST[qid] then
    local r = GRL_HOTSPOT_BEST[qid]
    if r and r.x and r.y then
      add_tt(r.map, r.x, r.y, ("Hunt: %s"):format(r.mob or "targets"))
      return true
    end
  end
  return false
end

-- Hook your pointer setter ONCE to prefer hotspots for C-steps.
-- prefer hotspots for C steps, but FALL BACK cleanly
if not GRL._lead_hooked then
  GRL._lead_hooked = true
  local _orig_ShowPointer = GRL.ShowPointer

  function GRL:_MaybeLeadWithHotspot(t)
    if not (self and self.lead_mode and t) then return false end

    -- action must be C
    local a = self.actions and self.actions[self.current]
    if a ~= "C" then return false end

    -- get qid
    local qid = t.qid or (t.qids and t.qids[1])
    if not qid then return false end

    -- choose record (per-entry, then best)
    local r
    if GRL_HOTSPOT_BYENTRY and t.entry and GRL_HOTSPOT_BYENTRY[qid] then
      r = GRL_HOTSPOT_BYENTRY[qid][t.entry]
    end
    if not r and GRL_HOTSPOT_BEST then r = GRL_HOTSPOT_BEST[qid] end
    if not (r and type(r.x)=="number" and type(r.y)=="number") then
      if GRL.lead_debug then DEFAULT_CHAT_FRAME:AddMessage("GRL lead: no hotspot for QID "..qid) end
      return false
    end

    local map = r.map or (GetCurrentMapAreaID and GetCurrentMapAreaID()) or nil
    if not map then
      if GRL.lead_debug then DEFAULT_CHAT_FRAME:AddMessage("GRL lead: no map for QID "..qid) end
      return false
    end

    if GRL.lead_debug then
      DEFAULT_CHAT_FRAME:AddMessage(("GRL lead: QID %s → %.1f,%.1f (map %s)"):format(qid, r.x, r.y, tostring(map)))
    end

    -- your helper takes (mapID, x, y, title)
    add_tt(map, r.x, r.y, ("Hunt: %s"):format(r.mob or "targets"))
    return true
  end

  function GRL:ShowPointer(i, ...)
    local idx = i or self.current
    local t = self.tags and idx and self.tags[idx] or nil
    if t and self:_MaybeLeadWithHotspot(t) then
      return -- hotspot placed; skip normal pointer
    end
    -- IMPORTANT: pass idx on, so Prev/Next both work
    return _orig_ShowPointer(self, idx, ...)
  end
end


-- /grl lead on|off
SLASH_GRLLEAD1="/grllead"
SlashCmdList.GRLLEAD = function(msg)
  msg = tostring(msg or ""):lower()
  if msg:find("on") then GRL.lead_mode = true
  elseif msg:find("off") then GRL.lead_mode = false
  else
    DEFAULT_CHAT_FRAME:AddMessage(("GRL lead_mode: %s (use /grllead on|off)"):format(GRL.lead_mode and "ON" or "OFF"))
    return
  end
  DEFAULT_CHAT_FRAME:AddMessage(("GRL lead_mode set to %s"):format(GRL.lead_mode and "ON" or "OFF"))
end
