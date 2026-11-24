do
local Drag = {
 pending = nil, active = false, list = nil, target = nil,
 startPos = nil, justDragged = false, hb = nil, cursor = Vector2.new(0, 0),
}
local DRAG_THRESHOLD = 6
local GHOST_MAX_W = 320

local dragGhost = Instance.new("Frame")
dragGhost.Name = RandomString()
dragGhost.Size = UDim2.new(0, 220, 0, config.ROW_H)
dragGhost.BackgroundColor3 = config.COLORS.SELECTED
dragGhost.BackgroundTransparency = 0.25
dragGhost.BorderSizePixel = 0
dragGhost.Visible = false
dragGhost.Active = false
dragGhost.ZIndex = 60
dragGhost.Archivable = false
dragGhost.Parent = config.window
local dragIcon, dragLabel, dragBadge
do
 local gc = Instance.new("UICorner")
 gc.CornerRadius = UDim.new(0, 8)
 gc.Parent = dragGhost
 local gs = Instance.new("UIStroke")
 gs.Color = config.COLORS.ACCENT
 gs.Thickness = 1
 gs.Parent = dragGhost
 dragIcon = Instance.new("ImageLabel")
 dragIcon.Name = RandomString()
 dragIcon.Size = UDim2.new(0, config.Positions.ICON_PX, 0, config.Positions.ICON_PX)
 dragIcon.Position = UDim2.new(0, 8, 0.5, -config.Positions.ICON_PX / 2)
 dragIcon.BackgroundTransparency = 1
 dragIcon.ZIndex = 61
 dragIcon.Active = false
 dragIcon.Parent = dragGhost
 dragLabel = Instance.new("TextLabel")
 dragLabel.Name = RandomString()
 dragLabel.Size = UDim2.new(1, -(8 + config.Positions.ICON_PX + 8 + 8), 1, 0)
 dragLabel.Position = UDim2.new(0, 8 + config.Positions.ICON_PX + 8, 0, 0)
 dragLabel.BackgroundTransparency = 1
 dragLabel.TextColor3 = config.COLORS.TEXT_BRIGHT
 dragLabel.TextXAlignment = Enum.TextXAlignment.Left
 dragLabel.Font = Enum.Font.SourceSans
 dragLabel.TextSize = 21
 dragLabel.TextTruncate = Enum.TextTruncate.AtEnd
 dragLabel.ZIndex = 61
 dragLabel.Active = false
 dragLabel.Parent = dragGhost
 dragBadge = Instance.new("TextLabel")
 dragBadge.Name = RandomString()
 dragBadge.AnchorPoint = Vector2.new(1, 0.5)
 dragBadge.Size = UDim2.new(0, 22, 0, 18)
 dragBadge.Position = UDim2.new(1, -6, 0.5, 0)
 dragBadge.BackgroundColor3 = config.COLORS.ACCENT
 dragBadge.TextColor3 = config.COLORS.TEXT_BRIGHT
 dragBadge.Font = Enum.Font.SourceSansBold
 dragBadge.TextSize = 16
 dragBadge.Visible = false
 dragBadge.ZIndex = 62
 dragBadge.Active = false
 dragBadge.Parent = dragGhost
 local bc = Instance.new("UICorner")
 bc.CornerRadius = UDim.new(1, 0)
 bc.Parent = dragBadge
end

local dropHL = Instance.new("Frame")
dropHL.Name = RandomString()
dropHL.BackgroundColor3 = config.COLORS.ACCENT
dropHL.BackgroundTransparency = 0.8
dropHL.BorderSizePixel = 0
dropHL.Visible = false
dropHL.Active = false
dropHL.ZIndex = 6
dropHL.Archivable = false
dropHL.Parent = config.scrolling
do
 local hc = Instance.new("UICorner")
 hc.CornerRadius = UDim.new(0, 8)
 hc.Parent = dropHL
 local hs = Instance.new("UIStroke")
 hs.Color = config.COLORS.ACCENT
 hs.Thickness = 1.5
 hs.Parent = dropHL
end

local function RawCursor(inp)
 if inp.UserInputType == Enum.UserInputType.Touch then
  local ok, gi = pcall(function() return config.SV.Gui:GetGuiInset() end)
  return Vector2.new(inp.Position.X, inp.Position.Y) + ((ok and gi) or Vector2.new(0, 0))
 end
 return config.SV.UserInput:GetMouseLocation()
end

local function DragCursor(inp)
 if Drag.anchor then
  return Drag.anchor + (Vector2.new(inp.Position.X, inp.Position.Y) - Drag.anchorInp)
 end
 return RawCursor(inp)
end

function Drag.Calibrate(inp, entry)
 Drag.anchor = nil
 local raw = RawCursor(inp)
 local ap = entry.AbsolutePosition
 local function Inside(y) return y >= ap.Y - 1 and y <= ap.Y + config.ROW_H + 1 end
 local ok, gi = pcall(function() return config.SV.Gui:GetGuiInset() end)
 local iy = (ok and gi and gi.Y) or 0
 local y
 if Inside(raw.Y) then y = raw.Y
 elseif iy ~= 0 and Inside(raw.Y + iy) then y = raw.Y + iy
 elseif iy ~= 0 and Inside(raw.Y - iy) then y = raw.Y - iy
 else y = ap.Y + config.ROW_H / 2 end
 y = math.clamp(y, ap.Y, ap.Y + config.ROW_H - 1)
 Drag.anchor = Vector2.new(raw.X, y)
 Drag.anchorInp = Vector2.new(inp.Position.X, inp.Position.Y)
end

local function DragWarn(where, err)
 warn(where .. ": " .. tostring(err))
end

local function DragTopLevel(list)
 local set, out = {}, {}
 for _, i in ipairs(list) do set[i] = true end
 for _, i in ipairs(list) do
  local cur, nested = i.Parent, false
  while cur do
   if set[cur] then nested = true; break end
   cur = cur.Parent
  end
  if not nested and i.Parent ~= Explorer.Root then out[#out + 1] = i end
 end
 return out
end

local function CanDropOn(list, target)
 if not target then return false end
 for _, src in ipairs(list) do
  local cur = target
  while cur do
   if cur == src then return false end
   cur = cur.Parent
  end
 end
 for _, src in ipairs(list) do
  if src.Parent ~= target then return true end
 end
 return false
end

local function DragTargetAt(cur)
 local ap, as = config.scrolling.AbsolutePosition, config.scrolling.AbsoluteSize
 if cur.X < ap.X or cur.X > ap.X + as.X or cur.Y < ap.Y or cur.Y > ap.Y + as.Y then return nil end
 local idx = math.floor((cur.Y - ap.Y) / config.ROW_H) + 1 + config.ScrollIndex
 local row = config.visiblerows[idx]
 if not row then return nil end
 return row.instance, idx
end

local function DragUpdate()
 local cur = Drag.cursor
 local g = Drag.grab or Vector2.new(20, config.ROW_H / 2)
 do
  local pos = dragGhost.Position
  local origin = dragGhost.AbsolutePosition - Vector2.new(pos.X.Offset, pos.Y.Offset)
  dragGhost.Position = UDim2.fromOffset(cur.X - g.X - origin.X, cur.Y - g.Y - origin.Y)
 end
 local target, idx = DragTargetAt(cur)
 if target and CanDropOn(Drag.list, target) then
  Drag.target = target
  dropHL.Position = UDim2.new(0, 0, 0, (idx - 1 - config.ScrollIndex) * config.ROW_H)
  dropHL.Size = UDim2.new(1, 0, 0, config.ROW_H)
  dropHL.Visible = true
 else
  Drag.target = nil
  dropHL.Visible = false
 end
end

local function DragStop()
 Drag.pending = nil
 Drag.active = false
 Drag.list = nil
 Drag.target = nil
 Drag.grab = nil
 dragGhost.Visible = false
 dropHL.Visible = false
 if Drag.hb then Drag.hb:Disconnect(); Drag.hb = nil end
end

local function DragBegin()
 local inst = Drag.pending.inst
 local list
 if Explorer.SelectedSet[inst] then
  list = DragTopLevel(Explorer.GetSelection())
 else
  list = DragTopLevel({ inst })
  if #list > 0 then Explorer.SetSelection(list, inst) end
 end
 if #list == 0 then Drag.pending = nil; return end
 Drag.list = list
 Drag.active = true
 if Explorer.CloseContextMenu then pcall(Explorer.CloseContextMenu) end
 do
  local first = list[1]
  ApplyIcon(dragIcon, first.ClassName)
  dragLabel.Text = first.Name
  dragBadge.Visible = #list > 1
  dragBadge.Text = tostring(#list)
  local pw = Drag.pending.rowWidth or 220
  dragGhost.Size = UDim2.new(0, math.clamp(pw, 160, GHOST_MAX_W), 0, config.ROW_H)
  local gx = (Drag.pending.grabX or 20)
  Drag.grab = Vector2.new(math.clamp(gx, 0, dragGhost.Size.X.Offset), math.clamp(Drag.pending.grabY or (config.ROW_H / 2), 0, config.ROW_H))
 end
 dragGhost.Visible = true
 if Drag.pending.CancelHold then Drag.pending.CancelHold() end

 local acc = 0
 Drag.hb = config.SV.RunSrv.Heartbeat:Connect(function(dt)
  if not Drag.active then return end
  local ap, as = config.scrolling.AbsolutePosition, config.scrolling.AbsoluteSize
  local y = Drag.cursor.Y
  local edge = 22
  local dir = 0
  if y < ap.Y + edge and y > ap.Y - 40 then dir = -1
  elseif y > ap.Y + as.Y - edge and y < ap.Y + as.Y + 40 then dir = 1 end
  if dir ~= 0 then
   acc += dt * 12
   local steps = math.floor(acc)
   if steps > 0 then
    acc -= steps
    config.ScrollIndex = math.max(0, config.ScrollIndex + dir * steps)
    RefreshTree()
    DragUpdate()
   end
  else
   acc = 0
  end
 end)
 DragUpdate()
end

config.SV.UserInput.InputChanged:Connect(function(inp)
 local p = Drag.pending
 if not p then return end
 if not config.Held(inp) then
  if Drag.active then DragStop() else Drag.pending = nil end
  return
 end
 local okc, errc = pcall(function()
 local t = inp.UserInputType
 if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end
 Drag.cursor = DragCursor(inp)
 if not Drag.active then
  if (Vector2.new(inp.Position.X, inp.Position.Y) - Drag.startPos).Magnitude < DRAG_THRESHOLD then return end
  DragBegin()
  if not Drag.active then return end
 end
 DragUpdate()
 end)
 if not okc then DragWarn("move", errc); DragStop() end
end)

config.SV.UserInput.InputEnded:Connect(function(inp)
 if not IsPress(inp) then return end
 if not Drag.pending then return end
 if Drag.active then
  local target, list = Drag.target, Drag.list
  Drag.justDragged = true
  task.delay(0.2, function() Drag.justDragged = false end)
  DragStop()
  if target and list and CanDropOn(list, target) and Explorer.MoveInstances then
   local okm, errm = pcall(Explorer.MoveInstances, list, target)
   if not okm then DragWarn("drop", errm) end
  end
 else
  Drag.pending = nil
 end
end)

config.SV.UserInput.InputBegan:Connect(function(inp)
 if Drag.active and inp.KeyCode == Enum.KeyCode.Escape then
  Drag.justDragged = true
  task.delay(0.2, function()
   Drag.justDragged = false
  end)
  DragStop()
 end
end)
Drag.CursorOf = DragCursor
Explorer.Drag = Drag
end
