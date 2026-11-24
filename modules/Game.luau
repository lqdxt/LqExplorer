do
 local Services = {
  "Workspace",
  "Players",
  "CoreGui",
  "CorePackages",
  "Lighting",
  "MaterialService",
  "NetworkClient",
  "PluginGuiService",
  "ReplicatedFirst",
  "ReplicatedStorage",
  "RobloxPluginGuiService",
  "ServerScriptService",
  "ServerStorage",
  "StarterGui",
  "StarterPack",
  "StarterPlayer",
  "Teams",
  "SoundService",
  "Chat",
  "TextChatService",
  "VoiceChatService",
  "LocalizationService",
  "TestService",
 }

 local HIDDEN_SERVICES = { CoreGui = true, CorePackages = true }
 local UserHidden = {}
 local YIELD_BUDGET = 0.008
 local scanning = false
 local scanned = false
 local showNil = false
 local deepLoaded, deepRunning, deepToken = false, false, 0
 local realToV = setmetatable({}, {__mode = "k"})
 local rowsDirty, drawDirty = false, false

 local virtualRoot = Explorer.Root
 local gameRoot = setmetatable({
  Name = "game",
  ClassName = "Root",
  Parent = nil,
  Children = {},
 }, VirtualInstance)

 local nilRoot = setmetatable({
  Name = "nil",
  ClassName = "Root",
  Parent = nil,
  Children = {},
 }, VirtualInstance)

 Explorer.Mode = "Game"
 Explorer.Root = gameRoot

 local function CurrentRoot()
  if Explorer.Mode ~= "Game" then return virtualRoot end
  return showNil and nilRoot or gameRoot
 end

 local function Safe(f, ...)
  local ok, r = pcall(f, ...)
  if ok then return r end
  return nil
 end

 local function ReadParent(i) return i.Parent end
 local function ReadNameOf(i) return i.Name end

 local function VOf(real)
  if real == nil then return nil end
  local v = realToV[real]
  if v then return v end
  local ok, par = pcall(ReadParent, real)
  if ok and par == game then
   local okN, nm = pcall(ReadNameOf, real)
   local okC, cls = pcall(function() return real.ClassName end)
   if okN then
    local kids = gameRoot.Children
    for i = 1, #kids do
     local c = kids[i]
     if c.Real and (c.Name == nm or (okC and c.ClassName == cls)) then
      realToV[real] = c
      return c
     end
    end
   end
  end
  return nil
 end

 local function MirrorOne(real, parent)
  local ok, name, class = pcall(ReadInfo, real)
  if not ok then return nil end
  local v = setmetatable({
   Name = tostring(name),
   ClassName = class or "Instance",
   Parent = parent,
   Children = {},
   Real = real,
  }, VirtualInstance)
  local ch = parent.Children
  ch[#ch + 1] = v
  parent._sorted = nil
  if parent ~= nilRoot then realToV[real] = v end
  return v
 end

 local function Finish()
  Explorer.ScanTree()
  RefreshTree()
  if Explorer.RefreshProperties then Explorer.RefreshProperties() end
 end

 local function ClearGameRoot()
  Explorer.SelectedSet = {}
  Explorer.Selected = nil
  config.Anchor = nil
  gameRoot.Children = {}
  gameRoot._sorted = nil
  deepLoaded, deepRunning = false, false
  deepToken += 1
 end

 local function ScanGame()
  if scanning then return end
  scanning = true
  ClearGameRoot()
  local showHidden = config.ShowHiddenServices ~= false
  for i, svcName in ipairs(Services) do
   if (showHidden or not HIDDEN_SERVICES[svcName]) and not UserHidden[svcName] then
    local svc = Safe(GetService, svcName)
    if svc then
     local v = MirrorOne(cloneref(svc), gameRoot)
     if v then
      v.Name = svcName
      v.Metadata.Order = i
     end
    end
   end
  end
  local have = {}
  for _, c in ipairs(gameRoot.Children) do have[c.Name] = true end
  for hn in pairs(UserHidden) do have[hn] = true end
  local okC, top = pcall(game.GetChildren, game)
  if showHidden and okC and type(top) == "table" then
   for j = 1, #top do
    local kid = top[j]
    local okN, nm = pcall(ReadNameOf, kid)
    if okN and not have[nm] and kid ~= config.folder then
     local v = MirrorOne(cloneref(kid), gameRoot)
     if v then
      have[nm] = true
      v.Metadata.Order = #Services + j
     end
    end
   end
  end
  scanning = false
  scanned = true
  Finish()
  if config.SearchQuery ~= "" then Explorer.EnsureDeepLoad() end
 end

 local function Unregister(v)
  local stack, top = {v}, 1
  while top > 0 do
   local n = stack[top]
   stack[top] = nil
   top -= 1
   local r = n.Real
   if r and realToV[r] == n then realToV[r] = nil end
   local ch = n.Children
   for i = 1, #ch do top += 1; stack[top] = ch[i] end
  end
 end

 local function DropDetachedSelection()
  local changedSel = false
  for sel in pairs(Explorer.SelectedSet) do
   local cur = sel
   while cur.Parent do cur = cur.Parent end
   if cur.ClassName ~= "Root" then
    Explorer.SelectedSet[sel] = nil
    changedSel = true
   end
  end
  local s0 = Explorer.Selected
  if s0 then
   local cur = s0
   while cur.Parent do cur = cur.Parent end
   if cur.ClassName ~= "Root" then
    Explorer.Selected = nil
    config.Anchor = nil
    changedSel = true
   end
  end
  if changedSel then
   if Explorer.PropsOnSelect then Explorer.PropsOnSelect() end
   if Explorer.OnSelectCb then pcall(Explorer.OnSelectCb, Explorer.Selected) end
  end
 end

 local IGNORE_CLASSES = {
  ["Frame"] = true,
  ["ScrollingFrame"] = true,
  ["TextLabel"] = true,
  ["TextButton"] = true,
  ["TextBox"] = true,
  ["ImageLabel"] = true,
  ["ImageButton"] = true,
  ["UICorner"] = true,
  ["UIStroke"] = true,
  ["UIPadding"] = true,
  ["UIListLayout"] = true,
  ["Tween"] = true,
  ["InputObject"] = true,
  ["Sound"] = true,
  ["MeshPart"] = true,
  ["DistortionSoundEffect"] = true,
  ["Animation"] = true,
  ["PitchShiftSoundEffect"] = true,
  ["EqualizerSoundEffect"] = true,
  ["DataModel"] = true,
  ["AnimationTrack"] = true,
  ["TextChatMessageProperties"] = true,
  ["TextChatMessage"] = true,
  ["Motor6D"] = true,
  ["TouchTransmitter"] = true,
  ["Part"] = true,
 }
 local function ReadClassOf(i) return i.ClassName end

 local function ScanNilInstances()
  if scanning then return end
  if type(getnilinstances) ~= "function" then return end
  scanning = true
  local list = Safe(getnilinstances) or {}
  local existing = {}
  for _, c in ipairs(nilRoot.Children) do
   if c.Real then existing[c.Real] = c end
  end
  local present = {}
  local added, removed = false, false
  local t0 = os.clock()
  for i = 1, #list do
   local real = list[i]
   local ok, par = pcall(ReadParent, real)
   if ok and par == nil then
    local okC, cls = pcall(ReadClassOf, real)
    if okC and not IGNORE_CLASSES[cls] then
     present[real] = true
     if not existing[real] and MirrorOne(real, nilRoot) then added = true end
    end
   end
   if i % 64 == 0 and os.clock() - t0 > YIELD_BUDGET then
    task.wait()
    t0 = os.clock()
   end
  end
  local keep, n = {}, 0
  for _, c in ipairs(nilRoot.Children) do
   if not c.Real or present[c.Real] then
    n += 1
    keep[n] = c
   else
    c.Parent = nil
    Unregister(c)
    removed = true
   end
  end
  if removed then
   nilRoot.Children = keep
   nilRoot._sorted = nil
   DropDetachedSelection()
  end
  scanning = false
  if added or removed then
   if Explorer.Root == nilRoot then rowsDirty = true end
   if config.SearchQuery ~= "" then Explorer.EnsureDeepLoad() end
  end
 end

 function Explorer.ResetDeepLoad()
  if not deepRunning then deepLoaded = false end
 end

 function Explorer.EnsureDeepLoad()
  if Explorer.Mode ~= "Game" or deepLoaded or deepRunning then return end
  deepRunning = true
  local myToken = deepToken
  task.spawn(function()
   local stack, top = {}, 0
   local roots = Explorer.Root.Children
   for i = #roots, 1, -1 do top += 1; stack[top] = roots[i] end
   local t0 = os.clock()
   local lastRefresh = t0
   local refreshGap = 0.6
   while top > 0 do
    if myToken ~= deepToken then return end
    local n = stack[top]
    stack[top] = nil
    top -= 1
    if n.Real and not n.Loaded then Explorer.LoadChildren(n) end
    local ch = n.Children
    for i = 1, #ch do top += 1; stack[top] = ch[i] end
    local now = os.clock()
    if now - t0 > YIELD_BUDGET then
     task.wait()
     if myToken ~= deepToken then return end
     t0 = os.clock()
     if config.SearchQuery ~= "" and Explorer.Mode == "Game" and t0 - lastRefresh > refreshGap then
      Explorer.ScanTree()
      RefreshTree()
      local done = os.clock()
      refreshGap = math.max(0.6, (done - t0) * 6)
      lastRefresh, t0 = done, done
     end
    end
   end
   deepRunning = false
   deepLoaded = true
   if config.SearchQuery ~= "" and Explorer.Mode == "Game" then
    Explorer.ScanTree()
    RefreshTree()
   end
  end)
 end

 local function ApplyRoot()
  Explorer.Selected = nil
  Explorer.SelectedSet = {}
  config.Anchor = nil
  Explorer.Root = CurrentRoot()
  deepLoaded, deepRunning = false, false
  deepToken += 1
  Finish()
  if Explorer.PropsOnSelect then Explorer.PropsOnSelect() end
  if Explorer.OnSelectCb then pcall(Explorer.OnSelectCb, nil) end
  if config.SearchQuery ~= "" then Explorer.EnsureDeepLoad() end
 end

 local nilBtn
 nilBtn = Explorer.AddMenuButton("Nil Instances", function()
  if Explorer.Mode ~= "Game" then return end
  showNil = not showNil
  ApplyRoot()
  if showNil and not scanning then
   task.spawn(ScanNilInstances)
  end
 end)

 local settingsDirty = false
 local function RescanGame()
  if scanning then return end
  for _, c in ipairs(gameRoot.Children) do Unregister(c) end
  ScanGame()
 end

 local function ServiceOrder(name)
  for i, n in ipairs(Services) do
   if n == name then return i end
  end
  return #Services + 100
 end

 function Explorer.HideServices(list)
  if Explorer.Mode ~= "Game" or Explorer.Root ~= gameRoot or scanning then return end
  local any = false
  for _, v in ipairs(table.clone(list or {})) do
   if v.Parent == gameRoot then
    UserHidden[v.Name] = true
    Unregister(v)
    v:SetParent(nil)
    Explorer.Expanded[v] = nil
    any = true
   end
  end
  if not any then return end
  gameRoot._sorted = nil
  DropDetachedSelection()
  Finish()
 end

 function Explorer.GetHiddenServices()
  local out = {}
  if Explorer.Mode ~= "Game" then return out end
  local present, seen = {}, {}
  for _, c in ipairs(gameRoot.Children) do present[c.Name] = true end
  local function Add(name)
   if seen[name] or present[name] then return end
   seen[name] = true
   out[#out + 1] = name
  end
  for _, name in ipairs(Services) do
   if UserHidden[name] then
    Add(name)
   elseif not present[name] and (config.ShowHiddenServices ~= false or not HIDDEN_SERVICES[name]) then
    if Safe(GetService, name) then Add(name) end
   end
  end
  for name in pairs(UserHidden) do Add(name) end
  table.sort(out, function(a, b)
   local oa, ob = ServiceOrder(a), ServiceOrder(b)
   if oa ~= ob then return oa < ob end
   return a < b
  end)
  return out
 end

 function Explorer.ShowService(name)
  if Explorer.Mode ~= "Game" or Explorer.Root ~= gameRoot or scanning then return end
  UserHidden[name] = nil
  for _, c in ipairs(gameRoot.Children) do
   if c.Name == name then return end
  end
  local svc = Safe(GetService, name)
  if not svc then
   local okF, f = pcall(game.FindFirstChild, game, name)
   if okF then svc = f end
  end
  if not svc then return end
  local v = MirrorOne(cloneref(svc), gameRoot)
  if v then
   v.Name = name
   v.Metadata.Order = ServiceOrder(name)
  end
  Finish()
 end

 local settingsBtn
 settingsBtn = Explorer.AddMenuButton("Settings", function()
  local syntaxItems = {}
  Explorer.OpenSettings({
   Tabs = {
    { name = "General", cats = {
     { name = "Explorer", items = {
      {
       name = "Show Hidden Services", type = "toggle",
       value = config.ShowHiddenServices ~= false, default = true,
       onChange = function(v)
        config.ShowHiddenServices = v
        if Explorer.Mode == "Game" then
         RescanGame()
        else
         settingsDirty = true
        end
       end,
      },
      {
       name = "Theme", type = "dropdown",
       options = { "Dark", "Light" },
       value = config.Theme, default = "Dark",
       onChange = function(v)
        Explorer.SetTheme(v)
        local defaults = Explorer.GetSyntaxDefaults()
        for key, it in pairs(syntaxItems) do
         it.default = defaults[key]
         if not config.SyntaxOverrides[key] then
          it.value = defaults[key]
          if it.refresh then it.refresh() end
         end
        end
       end,
      },
     } },
    } },
    { name = "Source Viewer", cats = {
     { name = "Display", items = {
      {
       name = "Show Headers", type = "toggle",
       value = config.SourceHeaders ~= false, default = true,
       onChange = function(v)
        config.SourceHeaders = v
        Explorer.ReloadHighlight()
       end,
      },
     } },
     { name = "Highlighting", items = (function()
      local defaults, current = Explorer.GetSyntaxDefaults(), Explorer.GetSyntaxColors()
      local items = {}
      for _, key in ipairs(config.SyntaxKeys) do
       local item = {
        name = key:sub(1, 1):upper() .. key:sub(2), type = "color",
        value = current[key], default = defaults[key],
        onChange = function(c) Explorer.SetSyntaxColor(key, c) end,
       }
       syntaxItems[key] = item
       items[#items + 1] = item
      end
      return items
     end)() },
    } },
   },
  })
 end)

 function Explorer.SetMode(mode)
  if mode ~= "Game" and mode ~= "Virtual" then return false end
  if Explorer.Mode == mode then return true end
  Explorer.Mode = mode
  Explorer.Selected = nil
  Explorer.SelectedSet = {}
  config.Anchor = nil
  Explorer.Root = CurrentRoot()
  nilBtn.Visible = (mode == "Game")
  if mode == "Game" and not scanned then
   task.spawn(function() ScanGame() end)
  elseif mode == "Game" and settingsDirty then
   settingsDirty = false
   RescanGame()
  end
  Finish()
  if Explorer.PropsOnSelect then Explorer.PropsOnSelect() end
  if Explorer.OnSelectCb then pcall(Explorer.OnSelectCb, nil) end
  return true
 end

 function Explorer.GetMode() return Explorer.Mode end

 do
  local origLoad = Explorer.LoadChildren
  function Explorer.LoadChildren(v)
   if v.Loaded then return end
   origLoad(v)
   local ch = v.Children
   for i = 1, #ch do
    local c = ch[i]
    local r = c.Real
    if r then realToV[r] = c end
   end
  end

  local ADD_BUDGET = 0.001
  local BUILD_BUDGET = 0.0008
  local BG_NAME_BUDGET = 0.0003
  local VIEW_NAME_INTERVAL = 0.1
  local BG_NAME_INTERVAL = 0.25
  local NIL_INTERVAL = 4
  local DRAW_GAP = 0.05
  local SEARCH_GAP = 0.3

  local addQ, addHead, addN = {}, 1, 0
  local removeQ = {}
  local addedSinceDeep = false
  local nextUI, lastDraw, lastView, lastBg, lastNil, lastDeep = 0, 0, 0, 0, 0, 0
  local nameCursor = 1
  local build = nil

  local function ReadName(i) return i.Name end

  local function OnAdded(inst)
   if VOf(inst.Parent) then
    addN += 1
    addQ[addN] = inst
   end
  end

  local function OnRemoving(inst)
   local v = realToV[inst]
   if v then
    removeQ[v] = true
   else
    local pv = VOf(inst.Parent)
    if pv and not pv.Loaded then pv.HasKids = nil end
   end
  end

  local function MarkParent(pv)
   if pv == Explorer.Root then rowsDirty = true; return end
   local idx = Explorer.RowIndex
   if idx and idx[pv] then
    if Explorer.Expanded[pv] == true then rowsDirty = true else drawDirty = true end
   end
  end

  local function Bsearch(cache, key, n)
   local lo, hi = 1, n + 1
   while lo < hi do
    local mid = (lo + hi) // 2
    if RefreshKey(cache[mid]) <= key then lo = mid + 1 else hi = mid end
   end
   return lo
  end

  local function SortedInsert(pv, v)
   local ch = pv.Children
   local n = #ch
   ch[n + 1] = v
   local cache = pv._sorted
   if cache and #cache == n then
    table.insert(cache, Bsearch(cache, RefreshKey(v), n), v)
    pv._live = true
   else
    pv._sorted = nil
   end
  end

  local function Reposition(pv, v)
   local cache = pv._sorted
   if cache and pv._live then
    local old = table.find(cache, v)
    if old then
     table.remove(cache, old)
     local pos = Bsearch(cache, RefreshKey(v), #cache)
     table.insert(cache, pos, v)
     return pos ~= old
    end
   end
   pv._sorted = nil
   return true
  end

  local function FilterOut(arr, set)
   local n, w = #arr, 0
   for i = 1, n do
    local c = arr[i]
    if not set[c] then
     w += 1
     arr[w] = c
    end
   end
   for i = w + 1, n do arr[i] = nil end
  end

  local function ProcessRemovals()
   local byParent, any = {}, false
   for v in pairs(removeQ) do
    removeQ[v] = nil
    local pv, r = v.Parent, v.Real
    local pr = pv and pv.Real
    if r and pr then
     local ok, cur = pcall(ReadParent, r)
     if not (ok and cur ~= nil and VOf(cur) == pv) then
      local set = byParent[pv]
      if not set then set = {}; byParent[pv] = set end
      set[v] = true
     end
    end
   end
   for pv, set in pairs(byParent) do
    local ch = pv.Children
    local cache = pv._sorted
    local cacheOk = cache ~= nil and #cache == #ch
    local k = 0
    for _ in pairs(set) do k += 1 end
    if k <= 8 then
     for v in pairs(set) do
      local i = table.find(ch, v)
      if i then table.remove(ch, i) end
      if cacheOk then
       local j = table.find(cache, v)
       if j then table.remove(cache, j) end
      end
     end
    else
     FilterOut(ch, set)
     if cacheOk then FilterOut(cache, set) end
    end
    if not cacheOk then pv._sorted = nil end
    for v in pairs(set) do
     v.Parent = nil
     Unregister(v)
    end
    any = true
    MarkParent(pv)
   end
   if any then DropDetachedSelection() end
  end

  local function ProcessAdds(t0)
   local count, added = 0, false
   while addHead <= addN do
    local inst = addQ[addHead]
    addQ[addHead] = nil
    addHead += 1
    count += 1
    if inst ~= config.folder then
     local pv = VOf(inst.Parent)
     if pv then
      if not pv.Loaded then
       if pv.HasKids ~= true then
        pv.HasKids = true
        local idx = Explorer.RowIndex
        if idx and idx[pv] then drawDirty = true end
       end
      elseif not realToV[inst] then
       local ok, name, class = pcall(ReadInfo, inst)
       if ok then
        local v = setmetatable({
         Name = tostring(name),
         ClassName = class or "Instance",
         Parent = pv,
         Children = {},
         Real = inst,
        }, VirtualInstance)
        SortedInsert(pv, v)
        realToV[inst] = v
        added = true
        MarkParent(pv)
       end
      end
     end
    end
    if count % 32 == 0 and os.clock() - t0 > ADD_BUDGET then break end
   end
   if addHead > addN then addQ, addHead, addN = {}, 1, 0 end
   return added
  end

  local function Reconcile(pv)
   local real = pv.Real
   if not real or not pv.Loaded then return end
   local ok, kids = pcall(real.GetChildren, real)
   if not ok or type(kids) ~= "table" then return end
   local present, changed = {}, false
   for i = 1, #kids do
    local kid = kids[i]
    present[kid] = true
    if kid ~= config.folder and not realToV[kid] then
     local okI, name, class = pcall(ReadInfo, kid)
     if okI then
      local v = setmetatable({
       Name = tostring(name),
       ClassName = class or "Instance",
       Parent = pv,
       Children = {},
       Real = kid,
      }, VirtualInstance)
      SortedInsert(pv, v)
      realToV[kid] = v
      changed = true
     end
    end
   end
   local ch = pv.Children
   for i = 1, #ch do
    local c = ch[i]
    if c.Real and not present[c.Real] then removeQ[c] = true; changed = true end
   end
   if changed then MarkParent(pv) end
  end

  local RECON_INTERVAL = 0.25
  local reconCursor, lastRecon = 1, 0
  local function ReconcileStep()
   local rows = config.visiblerows
   local n = #rows
   if n == 0 then return end
   for _ = 1, math.min(n, 32) do
    if reconCursor > n then reconCursor = 1 end
    local row = rows[reconCursor]
    reconCursor += 1
    local v = row.instance
    if row.expanded and v.Real and v.Loaded then
     Reconcile(v)
     return
    end
   end
  end

  local function CheckRow(row)
   local v = row and row.instance
   local r = v and v.Real
   if not r then return end
   local ok, name = pcall(ReadName, r)
   if not ok then return end
   name = tostring(name)
   if name == v.Name then return end
   v.Name = name
   drawDirty = true
   local p = v.Parent
   if p and Reposition(p, v) then MarkParent(p) end
  end

  local function ViewNames()
   local rows = config.visiblerows
   local from = config.ScrollIndex + 1
   local to = math.min(#rows, from + math.ceil(config.body.AbsoluteSize.Y / config.ROW_H) + 2)
   for i = from, to do CheckRow(rows[i]) end
  end

  local function BgNames()
   local rows = config.visiblerows
   local n = #rows
   if n == 0 then return end
   if nameCursor > n then nameCursor = 1 end
   local t0, checked = os.clock(), 0
   while checked < n do
    CheckRow(rows[nameCursor])
    nameCursor += 1
    if nameCursor > n then nameCursor = 1 end
    checked += 1
    if checked % 16 == 0 and os.clock() - t0 > BG_NAME_BUDGET then break end
   end
  end

  -- sK[top] = children array at this depth
  -- sI[top] = next index into that array
  -- sD[top] = depth
  local function StartBuild()
   local b = {
    rows = {}, index = {}, n = 0,
    sK = {}, sI = {}, sD = {}, top = 1,
    bestEst = -1, bestRow = nil,
    rev = config.RowsRev,
   }
   b.sK[1] = table.clone(SortedChildren(Explorer.Root))
   b.sI[1] = 1
   b.sD[1] = 0
   build = b
  end

  local function StepBuild(budget)
   local b = build
   local rows, index = b.rows, b.index
   local sK, sI, sD = b.sK, b.sI, b.sD
   local Expanded = Explorer.Expanded
   local INDENT = config.Positions.INDENT
   local n, count, t0 = b.n, 0, os.clock()
   while b.top > 0 do
    local top = b.top
    local kids, i = sK[top], sI[top]
    if i > #kids then
     sK[top] = nil
     b.top = top - 1
    else
     sI[top] = i + 1
     local child = kids[i]
     local depth = sD[top]
     local expanded = Expanded[child] == true
     n += 1
     local row = { instance = child, depth = depth, expanded = expanded, searchLeaf = false, match = false }
     rows[n] = row
     index[child] = n
     local est = depth * INDENT + #child.Name * 8
     if est > b.bestEst then b.bestEst, b.bestRow = est, row end
     if expanded then
      if child.Real and not child.Loaded then Explorer.LoadChildren(child) end
      top += 1
      b.top = top
      sK[top] = table.clone(SortedChildren(child))
      sI[top] = 1
      sD[top] = depth + 1
     end
     count += 1
     if count % 64 == 0 and os.clock() - t0 > budget then
      b.n = n
      return false
     end
    end
   end
   b.n = n
   return true
  end

  local function FinishBuild()
   local b = build
   build = nil
   if b.rev ~= config.RowsRev then
    rowsDirty = true
    return
   end
   config.visiblerows = b.rows
   Explorer.RowIndex = b.index
   local br = b.bestRow
   config.TreeWidthRow = br
   config.TreeWidthBase = br and (br.depth * config.Positions.INDENT + 44 + NameWidth(br.instance) + 60) or 0
   config.emptyLabel.Visible = (b.n == 0)
   drawDirty = false
   lastDraw = os.clock()
   RefreshTree()
  end

  local function Step()
   local now = os.clock()
   local game_ = Explorer.Mode == "Game"
   if next(removeQ) ~= nil then ProcessRemovals() end
   if addHead <= addN and ProcessAdds(now) then addedSinceDeep = true end
   if game_ and not config.IsMinimized then
    if now - lastView >= VIEW_NAME_INTERVAL then
     lastView = now
     ViewNames()
    end
    if now - lastBg >= BG_NAME_INTERVAL then
     lastBg = now
     BgNames()
    end
    if now - lastRecon >= RECON_INTERVAL then
     lastRecon = now
     ReconcileStep()
    end
   end
   if config.IsMinimized then return end

   if config.SearchQuery ~= "" then
    build = nil
    if rowsDirty and now >= nextUI then
     rowsDirty, drawDirty = false, false
     local a = os.clock()
     Explorer.ScanTree()
     RefreshTree()
     nextUI = os.clock() + math.max(SEARCH_GAP, (os.clock() - a) * 20)
     if addedSinceDeep and os.clock() - lastDeep > 2 then
      addedSinceDeep = false
      lastDeep = os.clock()
      deepLoaded = false
      Explorer.EnsureDeepLoad()
     end
    elseif drawDirty and now - lastDraw >= DRAW_GAP then
     drawDirty = false
     lastDraw = now
     RefreshTree()
    end
    return
   end

   if not build and rowsDirty then
    rowsDirty = false
    StartBuild()
   end
   if build then
    if StepBuild(BUILD_BUDGET) then FinishBuild() end
   elseif drawDirty and now - lastDraw >= DRAW_GAP then
    drawDirty = false
    lastDraw = now
    RefreshTree()
   end
  end

  local function LoadKids(pv)
   if pv.Real and not pv.Loaded then Explorer.LoadChildren(pv) end
  end

  local function WorkspaceNode()
   for _, c in ipairs(gameRoot.Children) do
    if c.ClassName == "Workspace" then return c end
   end
   return nil
  end

  local function EnsureNode(real, pv)
   if pv == nilRoot then return MirrorOne(real, nilRoot) end
   LoadKids(pv)
   local v = realToV[real]
   if v then return v end
   local ok, name, class = pcall(ReadInfo, real)
   if not ok then return nil end
   v = setmetatable({
    Name = tostring(name),
    ClassName = class or "Instance",
    Parent = pv,
    Children = {},
    Real = real,
   }, VirtualInstance)
   SortedInsert(pv, v)
   realToV[real] = v
   return v
  end

  local G = {}
  Explorer.Game = G
  G.GameRoot = gameRoot

  function G.IsGame(v)
   return Explorer.Mode == "Game" and v ~= nil and (v.Real ~= nil or v == gameRoot or v == nilRoot)
  end

  function G.Create(className, name, pv)
   if pv == gameRoot then
    pv = WorkspaceNode()
    if not pv then return nil end
   end
   LoadKids(pv)
   local ok, real = pcall(Instance.new, className)
   if not ok or not real then return nil end
   pcall(function() real.Name = Explorer.UniqueName(pv, name) end)
   if pv ~= nilRoot then
    local okP = pcall(function() real.Parent = pv.Real end)
    if not okP then
     pcall(real.Destroy, real)
     return nil
    end
   end
   return EnsureNode(real, pv)
  end

  function G.Destroy(v)
   if v.Parent == gameRoot then return false end
   local real = v.Real
   if real then
    local ok = pcall(real.Destroy, real)
    if not ok then return false end
   end
   Unregister(v)
   return true
  end

  function G.Rename(v, name)
   local ok = pcall(function() v.Real.Name = name end)
   if not ok and v.Parent ~= gameRoot then return false end
   v.Name = name
   local p = v.Parent
   if p then Reposition(p, v) end
   return true
  end

  function G.WorkspaceNode() return WorkspaceNode() end

  function G.Move(src, pv)
   local real = src.Real
   if pv == gameRoot then pv = WorkspaceNode() end
   if not real or not pv then return false end
   LoadKids(pv)
   local ok = pcall(function()
    if pv == nilRoot then real.Parent = nil else real.Parent = pv.Real end
   end)
   if not ok then return false end
   src:SetParent(pv)
   if pv == nilRoot then Unregister(src) else realToV[real] = src end
   return true
  end

  local function CloneReal(real)
   local flipped = {}
   pcall(function()
    if real.Archivable == false then
     real.Archivable = true
     flipped[#flipped + 1] = real
    end
    for _, d in ipairs(real:GetDescendants()) do
     if d.Archivable == false then
      d.Archivable = true
      flipped[#flipped + 1] = d
     end
    end
   end)
   local ok, c = pcall(real.Clone, real)
   for _, i in ipairs(flipped) do pcall(function() i.Archivable = false end) end
   if ok then return c end
   return nil
  end

  function G.Clone(src, pv)
   local real = src.Real
   if pv == gameRoot then pv = WorkspaceNode() end
   if not real or not pv then return nil end
   LoadKids(pv)
   local c = CloneReal(real)
   if not c then return nil end
   pcall(function() c.Name = Explorer.UniqueName(pv, src.Name) end)
   if pv ~= nilRoot then
    local okP = pcall(function() c.Parent = pv.Real end)
    if not okP then
     pcall(c.Destroy, c)
     return nil
    end
   end
   return EnsureNode(c, pv)
  end

  local gm = cloneref(game)
  pcall(function() gm.DescendantAdded:Connect(OnAdded) end)
  pcall(function() gm.DescendantRemoving:Connect(OnRemoving) end)
  config.SV.RunSrv.Heartbeat:Connect(function()
   pcall(Step)
  end)
 end

 task.spawn(function()
  repeat task.wait() until config.window.AbsoluteSize.X > 0
  if Explorer.Mode == "Game" and not scanned then
   ScanGame()
  end
 end)
end
