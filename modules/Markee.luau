do
 local rect = Instance.new("Frame")
 rect.Name = RandomString()
 rect.BackgroundColor3 = Color3.fromRGB(70, 140, 255)
 rect.BackgroundTransparency = 0.8
 rect.BorderSizePixel = 0
 rect.ZIndex = 25
 rect.Visible = false
 rect.Archivable = false
 rect.Parent = config.scrolling
 local stroke = Instance.new("UIStroke")
 stroke.Color = Color3.fromRGB(70, 140, 255)
 stroke.Thickness = 1
 stroke.Parent = rect

 local M
 local DRAG_MIN = 4

 local function CursorOf(inp)
  local d = Explorer.Drag
  if d and d.CursorOf then return d.CursorOf(inp) end
  return Vector2.new(inp.Position.X, inp.Position.Y)
 end

 local function RowSpace(y)
  return (y - config.scrolling.AbsolutePosition.Y) / config.ROW_H + config.ScrollIndex
 end

 local function Stop()
  if M and M.hb then M.hb:Disconnect() end
  M = nil
  rect.Visible = false
 end

 local function Apply()
  if not M or not M.started then return end
  local as = config.scrolling.AbsoluteSize
  local curRow = RowSpace(M.cur.Y)
  local lo, hi = math.min(M.startRow, curRow), math.max(M.startRow, curRow)
  local y1 = (lo - config.ScrollIndex) * config.ROW_H
  local y2 = (hi - config.ScrollIndex) * config.ROW_H
  local top = math.clamp(y1, 0, as.Y)
  local bot = math.clamp(y2, 0, as.Y)
  rect.Position = UDim2.fromOffset(2, top)
  rect.Size = UDim2.new(1, -4, 0, math.max(1, bot - top))
  rect.Visible = true

  local rows = config.visiblerows
  local first = math.max(math.floor(lo) + 1, 1)
  local last = math.min(math.floor(hi) + 1, #rows)
  if first == M.lastFirst and last == M.lastLast then return end
  M.lastFirst, M.lastLast = first, last
  local list, seen = {}, {}
  if M.additive then
   for _, i in ipairs(M.base) do list[#list + 1] = i; seen[i] = true end
  end
  for i = first, last do
   local r = rows[i]
   if r and not seen[r.instance] and (config.SearchQuery == "" or r.match) then
    list[#list + 1] = r.instance
    seen[r.instance] = true
   end
  end
  Explorer.SetSelection(list, list[#list])
 end

 config.SV.UserInput.InputBegan:Connect(function(inp)
  if inp.UserInputType == Enum.UserInputType.Keyboard then
   if M and M.started and inp.KeyCode == Enum.KeyCode.Escape then
    Explorer.SetSelection(M.orig, M.orig[#M.orig])
    Stop()
   end
   return
  end
  if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  if M or not config.main.Visible then return end
  if config.InsertMenu or config.ContextMenu then return end
  local d = Explorer.Drag
  if d and (d.pending or d.active) then return end
  local cur = CursorOf(inp)
  if not PointIn(config.scrolling, cur) then return end
  if SearchNav and SearchNav.Visible and PointIn(SearchNav, cur) then return end
  local idx = math.floor((cur.Y - config.scrolling.AbsolutePosition.Y) / config.ROW_H) + 1 + config.ScrollIndex
  if idx <= #config.visiblerows then return end
  local ctrl = config.SV.UserInput:IsKeyDown(Enum.KeyCode.LeftControl) or config.SV.UserInput:IsKeyDown(Enum.KeyCode.RightControl)
  local shift = config.SV.UserInput:IsKeyDown(Enum.KeyCode.LeftShift) or config.SV.UserInput:IsKeyDown(Enum.KeyCode.RightShift)
  M = {
   startRow = RowSpace(cur.Y),
   startPos = cur,
   cur = cur,
   additive = ctrl or shift,
   base = Explorer.GetSelection(),
   orig = Explorer.GetSelection(),
   started = false,
  }
  local acc = 0
  M.hb = config.SV.RunSrv.Heartbeat:Connect(function(dt)
   if not M or not M.started then return end
   local ap, as = config.scrolling.AbsolutePosition, config.scrolling.AbsoluteSize
   local y = M.cur.Y
   local edge = 22
   local dir = 0
   if y < ap.Y + edge then dir = -1 elseif y > ap.Y + as.Y - edge then dir = 1 end
   if dir == 0 then acc = 0; return end
   acc += dt * 12
   local steps = math.floor(acc)
   if steps > 0 then
    acc -= steps
    local maxIdx = math.max(0, #config.visiblerows - 1)
    config.ScrollIndex = math.clamp(config.ScrollIndex + dir * steps, 0, maxIdx)
    RefreshTree()
    Apply()
   end
  end)
 end)

 config.SV.UserInput.InputChanged:Connect(function(inp)
  if not M then return end
  local t = inp.UserInputType
  if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end
  if not config.Held(inp) then Stop() return end
  M.cur = CursorOf(inp)
  if not M.started then
   if (M.cur - M.startPos).Magnitude < DRAG_MIN then return end
   M.started = true
   if not M.additive then M.base = {} end
  end
  Apply()
 end)

 config.SV.UserInput.InputEnded:Connect(function(inp)
  if not M then return end
  if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
   Stop()
  end
 end)
end
