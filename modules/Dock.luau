do
 local SIDES = { "left", "right" }
 local MIN_H = 120

 local Dock = {
  Entries = {},
  ByGui = setmetatable({}, { __mode = "k" }),
  Stacks = { left = {}, right = {} },
  Width = {},
 }
 config.DockMgr = Dock

 local function IndexOf(list, e)
  for i, v in ipairs(list) do
   if v == e then return i end
  end
  return nil
 end

 function Dock.Register(gui, adapter)
  local e = {
   gui = gui,
   GetSide = adapter.GetSide,
   SetSide = adapter.SetSide,
   GetSplitter = adapter.GetSplitter,
   Weight = 1,
  }
  Dock.Entries[#Dock.Entries + 1] = e
  Dock.ByGui[gui] = e
  return e
 end

 function Dock.Unregister(gui)
  local e = Dock.ByGui[gui]
  if not e then return end
  Dock.ByGui[gui] = nil
  local i = IndexOf(Dock.Entries, e)
  if i then table.remove(Dock.Entries, i) end
  for _, side in ipairs(SIDES) do
   local si = IndexOf(Dock.Stacks[side], e)
   if si then table.remove(Dock.Stacks[side], si) end
  end
 end

 function Dock.Reconcile()
  for _, side in ipairs(SIDES) do
   local st = Dock.Stacks[side]
   for i = #st, 1, -1 do
    if st[i].GetSide() ~= side then table.remove(st, i) end
   end
  end
  for _, e in ipairs(Dock.Entries) do
   local side = e.GetSide()
   if side and Dock.Stacks[side] and not IndexOf(Dock.Stacks[side], e) then
    local st = Dock.Stacks[side]
    local at = #st + 1
    if e.gui == config.main or e.gui == config.pmain then
     local isExplorer = e.gui == config.main
     local other = Dock.ByGui[isExplorer and config.pmain or config.main]
     local oi = other and IndexOf(st, other)
     if oi then
      local explorerOnTop = config.PDock.Order == "below"
      local above = (isExplorer == explorerOnTop)
      at = above and oi or oi + 1
     end
    end
    table.insert(st, at, e)
    e.Weight = 1
   end
  end
 end

 local function VisibleOn(side)
  local out = {}
  for _, e in ipairs(Dock.Stacks[side]) do
   if e.gui.Visible and e.GetSide() == side then out[#out + 1] = e end
  end
  return out
 end
 Dock.VisibleOn = VisibleOn

 function Dock.Docked()
  Dock.Reconcile()
  local out = {}
  for _, side in ipairs(SIDES) do
   for _, e in ipairs(VisibleOn(side)) do out[#out + 1] = { gui = e.gui, side = side } end
  end
  return out
 end

 local function Distribute(weights, total, minH)
  local n = #weights
  local hs, fixed = {}, {}
  local remH = total
  while true do
   local freeW = 0
   for i = 1, n do
    if not fixed[i] then freeW += weights[i] end
   end
   if freeW <= 0 then break end
   local clamped = false
   for i = 1, n do
    if not fixed[i] and remH * weights[i] / freeW < minH then
     fixed[i] = true
     hs[i] = minH
     remH -= minH
     clamped = true
     break
    end
   end
   if not clamped then
    for i = 1, n do
     if not fixed[i] then hs[i] = remH * weights[i] / freeW end
    end
    break
   end
  end
  local sum = 0
  for i = 1, n do
   hs[i] = math.floor(hs[i] or 0)
   sum += hs[i]
  end
  if n > 0 then hs[n] += total - sum end
  return hs
 end

 local splitters = {}
 local splitDrag = nil

 local function GetSplitter(i)
  local sp = splitters[i]
  if sp then return sp end
  local g = Instance.new("TextButton")
  g.Name = RandomString()
  g.BackgroundColor3 = config.COLORS.RESIZER
  g.BorderSizePixel = 0
  g.AutoButtonColor = false
  g.Text = ""
  g.Visible = false
  g.ZIndex = 9
  g.Archivable = false
  g.Parent = config.window
  sp = { gui = g, a = nil, b = nil }
  splitters[i] = sp
  g.InputBegan:Connect(function(inp)
   if not config.Fresh(inp) then return end
   if not IsPress(inp) then return end
   if not sp.a or not sp.b then return end
   splitDrag = {
    a = sp.a, b = sp.b, y = inp.Position.Y,
    ha = sp.a.gui.Size.Y.Offset, hb = sp.b.gui.Size.Y.Offset,
    wa = sp.a.Weight, wb = sp.b.Weight,
   }
  end)
  return sp
 end

 config.SV.UserInput.InputChanged:Connect(function(inp)
  if not splitDrag then return end
  if not config.Held(inp) then splitDrag = nil; return end
  if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  local d = splitDrag
  local sumH, sumW = d.ha + d.hb, d.wa + d.wb
  if sumH <= 0 then return end
  local minH = math.min(MIN_H, math.floor(sumH / 2))
  local newA = math.clamp(d.ha + (inp.Position.Y - d.y), minH, sumH - minH)
  d.a.Weight = sumW * newA / sumH
  d.b.Weight = sumW - d.a.Weight
  Dock.Layout()
 end)
 config.SV.UserInput.InputEnded:Connect(function(inp)
  if IsPress(inp) then splitDrag = nil end
 end)

 function Dock.Layout()
  local scr = config.window.AbsoluteSize
  if scr.X <= 0 or scr.Y <= 0 then return end
  Dock.Reconcile()
  local top = TopInset()
  local availH = scr.Y - top
  local placed = {}
  local splitIdx = 0

  for _, side in ipairs(SIDES) do
   local list = VisibleOn(side)
   local n = #list
   if n == 0 then
    Dock.Width[side] = nil
   else
    local W = math.max(1, Dock.Width[side] or list[1].gui.Size.X.Offset)
    Dock.Width[side] = W
    local minH = math.min(MIN_H, math.floor(availH / n))
    local weights = {}
    for i, e in ipairs(list) do weights[i] = math.max(e.Weight or 1, 0.01) end
    local hs = Distribute(weights, availH, minH)
    local x = (side == "left") and 0 or (scr.X - W)
    local y = top
    for i, e in ipairs(list) do
     local h = hs[i]
     e.gui.AnchorPoint = Vector2.new(0, 0)
     e.gui.Position = UDim2.new(0, x, 0, y)
     e.gui.Size = UDim2.new(0, W, 0, h)
     placed[e] = true
     local ds = e.GetSplitter and e.GetSplitter()
     if ds then
      ds.Visible = true
      ds.Position = (side == "left") and UDim2.new(1, 0, 0, 0) or UDim2.new(0, -6, 0, 0)
     end
     if i < n then
      splitIdx += 1
      local sp = GetSplitter(splitIdx)
      sp.a, sp.b = e, list[i + 1]
      sp.gui.Visible = true
      sp.gui.Position = UDim2.new(0, x, 0, y + h - 3)
      sp.gui.Size = UDim2.new(0, W, 0, 7)
     end
     y += h
    end
   end
  end

  for i = splitIdx + 1, #splitters do
   splitters[i].gui.Visible = false
   splitters[i].a, splitters[i].b = nil, nil
  end
  for _, e in ipairs(Dock.Entries) do
   if not placed[e] then
    local ds = e.GetSplitter and e.GetSplitter()
    if ds then ds.Visible = false end
   end
  end

  if config.LayoutSource then config.LayoutSource() end
 end
 config.LayoutDocks = Dock.Layout

 -- put a panel on a side. target + zone ("top" / "bottom") place it next to another docked panel
 function Dock.Place(e, side, target, zone)
  for _, s in ipairs(SIDES) do
   local i = IndexOf(Dock.Stacks[s], e)
   if i then table.remove(Dock.Stacks[s], i) end
  end
  e.SetSide(side)
  local st = Dock.Stacks[side]
  local at = #st + 1
  if target and zone then
   local ti = IndexOf(st, target)
   if ti then at = (zone == "top") and ti or ti + 1 end
  end
  table.insert(st, at, e)
  e.Weight = 1
  local ee, pe = Dock.ByGui[config.main], Dock.ByGui[config.pmain]
  if ee and pe then
   local a, b = IndexOf(st, ee), IndexOf(st, pe)
   if a and b then config.PDock.Order = (a < b) and "below" or "above" end
  end
  Dock.Layout()
 end

 local function DropZone(gui, cur)
  local ap, as = gui.AbsolutePosition, gui.AbsoluteSize
  if cur.X < ap.X or cur.X > ap.X + as.X or cur.Y < ap.Y or cur.Y > ap.Y + as.Y then return nil, false end
  local z = math.clamp(as.Y * 0.25, 40, 140)
  if cur.Y <= ap.Y + z then return "top", true end
  if cur.Y >= ap.Y + as.Y - z then return "bottom", true end
  return nil, true
 end

 function Dock.Resolve(dragged, cur)
  if not cur then return nil end
  Dock.Reconcile()
  local scr = config.window.AbsoluteSize
  for _, side in ipairs(SIDES) do
   for _, e in ipairs(VisibleOn(side)) do
    if e.gui ~= dragged then
     local zone, inside = DropZone(e.gui, cur)
     if inside then
      if zone then return side, zone, e end
      return nil
     end
    end
   end
  end
  local ap, as = dragged.AbsolutePosition, dragged.AbsoluteSize
  local side
  if ap.X <= 40 then side = "left"
  elseif scr.X - (ap.X + as.X) <= 40 then side = "right" end
  if not side then return nil end
  local best, bestD = nil, math.huge
  for _, e in ipairs(VisibleOn(side)) do
   if e.gui ~= dragged then
    local oap, oas = e.gui.AbsolutePosition, e.gui.AbsoluteSize
    local d = 0
    if cur.Y < oap.Y then d = oap.Y - cur.Y elseif cur.Y > oap.Y + oas.Y then d = cur.Y - (oap.Y + oas.Y) end
    if d < bestD then best, bestD = e, d end
   end
  end
  if not best then return side, nil, nil end
  local oap, oas = best.gui.AbsolutePosition, best.gui.AbsoluteSize
  return side, (cur.Y < oap.Y + oas.Y / 2) and "top" or "bottom", best
 end

 function Dock.ShowHint(dragged, target, side, zone)
  if not side then config.dockHint.Visible = false; return end
  Dock.Reconcile()
  local scr = config.window.AbsoluteSize
  local top = TopInset()
  local availH = math.max(1, scr.Y - top)

  -- panels already on this side (the dragged one is not docked yet)
  local list = {}
  for _, e in ipairs(VisibleOn(side)) do
   if e.gui ~= dragged then list[#list + 1] = e end
  end

  -- where the dragged panel would land in the stack
  local idx = #list + 1
  if target and zone then
   local ti = IndexOf(list, target)
   if ti then idx = (zone == "top") and ti or ti + 1 end
  end

  -- same width and height maths as Dock.Layout, so the hint matches the real result
  local W = Dock.Width[side] or (list[1] and list[1].gui.AbsoluteSize.X) or dragged.AbsoluteSize.X
  W = math.max(1, math.floor(W + 0.5))
  local weights = {}
  for i = 1, #list + 1 do
   local e = (i < idx) and list[i] or (i > idx and list[i - 1]) or nil
   weights[i] = e and math.max(e.Weight or 1, 0.01) or 1
  end
  local n = #weights
  local hs = Distribute(weights, availH, math.min(MIN_H, math.floor(availH / n)))
  local y = top
  for i = 1, idx - 1 do y += hs[i] end

  config.dockHint.Position = UDim2.new(0, (side == "left") and 0 or (scr.X - W), 0, y)
  config.dockHint.Size = UDim2.new(0, W, 0, hs[idx])
  config.dockHint.Visible = true
 end

 Dock.Register(config.main, {
  GetSide = function() return config.DockSide end,
  SetSide = function(s) config.DockSide = s end,
  GetSplitter = function() return config.docksplitter end,
 })
end
