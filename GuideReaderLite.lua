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
GRL._hearthAt = GRL._hearthAt or nil
GRL._lastBindTime = GRL._lastBindTime or nil

GRL._hearthFrame = GRL._hearthFrame or CreateFrame("Frame")
GRL._hearthFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
GRL._hearthFrame:SetScript("OnEvent", function(_, _, unit, _, _, _, spellID)
    if unit ~= "player" then return end
    if spellID == 8690 or spellID == 556 or spellID == 3286 then
        GRL._hearthAt = GetTime()
        if GRL.After then
            GRL:After(0.1, function()
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
-- Minimal UI (Status Frame)
---------------------------------------------------------------
local f = CreateFrame("Frame", "GuideReaderLiteStatus", UIParent)
GRL.status = f
f:SetSize(380, 150)
f:SetPoint("CENTER")
f:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    --tile = true, tileSize = 16, edgeSize = 16,
	tile = false, edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
})
f:SetBackdropColor(1, 1, 1, 1)
--f:SetBackdropColor(0, 0, 0, 0.85)
f:EnableMouse(true)
f:SetMovable(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Show()

-- Title (addon name)
f.title = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
f.title:SetPoint("TOPLEFT", 16, -10)
f.title:SetText("Guide Reader Lite")
f.title:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
f.title:SetTextColor(1, 0.5, 0, 1)

-- Subtitle (guide name)
f.guideName = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
f.guideName:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -2)
f.guideName:SetText("")
f.guideName:SetFont("Fonts\\FRIZQT__.TTF", 14)

-- Step text
f.text = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
f.text:SetPoint("TOPLEFT", f.guideName, "BOTTOMLEFT", 0, -6)
f.text:SetJustifyH("LEFT")
f.text:SetJustifyV("TOP")
f.text:SetWidth(340)
f.text:SetText("No guide loaded.")

f.prev = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
f.prev:SetSize(60, 20); f.prev:SetPoint("BOTTOMLEFT", 16, 10); f.prev:SetText("« Prev")
f.prev:SetScript("OnClick", function() GRL:PrevStep() end)

f.next = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
f.next:SetSize(60, 20); f.next:SetPoint("BOTTOMRIGHT", -16, 10); f.next:SetText("Next »")
f.next:SetScript("OnClick", function() GRL:NextStep() end)

function GRL:ResizeStatusFrame()
    local f = self.status
    if not f or not f.text or not f.title then return end
    local th  = f.text:GetStringHeight()  or 0
    local tth = f.title:GetStringHeight() or 0
    local gnh = f.guideName and f.guideName:GetStringHeight() or 0
    local padTop, gapTitle, gapGuide, gapText, btnRow, padBot, minH = 12, 6, 8, 8, 24, 10, 110
    local needed = padTop + tth + gapTitle + gnh + gapGuide + th + gapText + btnRow + padBot
    f:SetHeight(math.max(minH, needed))
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
	
    return t
end

local function extractCoordsFromText(t, rawline)
    t._mx, t._my = nil, nil
    if not t then return end
    local coordStr = t.M or t.WM
    if not coordStr or coordStr == "" then return end
    local x, y = tostring(coordStr):match("([%d%.]+)%s*[,%s]%s*([%d%.]+)")
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

    if not self:IsStepForPlayer(i) then
        result = true
    end

    if t.qid or (a == "C" and t.qids and #t.qids > 0) then

        if self.turnedinquests[t.qid] then
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
            local idx = GRL_FindQuestLogIndexByID(t.qid)
            if idx then
                result = true
            end
        end
        if a == "T" then
            if t.qid and self.turnedinquests[t.qid] then
                result = true
            end
            if t.qid and not GRL_FindQuestLogIndexByID(t.qid) then
                result = true
            end
        end
        if a == "H" then
            if self._hearthAt and (GetTime() - self._hearthAt) < 30 then
                result = true
            end
        end
        if a == "h" then
            local bindLoc = GetBindLocation and GetBindLocation()
            local expectedLoc = t.N or ""
            if expectedLoc ~= "" and bindLoc and string.find(bindLoc:lower(), expectedLoc:lower(), 1, true) then
                result = true
            end
            if self._lastBindTime and (GetTime() - self._lastBindTime) < 30 then
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
        result = false
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



function GRL:ShowPointer()
    local i  = self.current or 1
    local t  = self.tags and self.tags[i]
    local a  = self.actions and self.actions[i]
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

    if not t or not t._mx or not t._my or self:IsStepDone(i) then
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
            local ok, r = pcall(function() return TomTom:AddWaypoint(fx, fy, desc) end)
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

        if uid and TomTom.SetCrazyArrow then
            pcall(function() TomTom:SetCrazyArrow(uid, 5, desc) end)
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
    if not self.actions then return end
    local i = self.current or 1
    i = i + 1
    if i > #self.actions then
        self:ShowGuidePicker()
        say("|cff55ff55Guide complete! Please select the next guide to continue.|r")
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
    if not self.actions then return end
    local i = self.current or 1
    repeat
        i = i - 1
    until i < 1 or self:IsStepForPlayer(i)
    if i >= 1 then
        self.current = i
        self:RememberStep(); self:UpdateStatusFrame()
        self:ShowPointer()
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
    if self.AutoAdvance then self:AutoAdvance() end 
end)

GRL:RegisterEvent("BAG_UPDATE_COOLDOWN", function(self) 
    if self.AutoAdvance then self:AutoAdvance() end
end)

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
    if self.AutoAdvance then self:AutoAdvance() end
end)

GRL:RegisterEvent("QUEST_TURNED_IN", function(self, questID)
    if type(questID) == "number" then
        self.turnedinquests = self.turnedinquests or {}
        self.turnedinquests[questID] = true
    end
    if self.AutoAdvance then self:AutoAdvance() end
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