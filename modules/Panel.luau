do
 local Dock = config.DockMgr
 local ROW = config.ROW_H
 local HEADER_H = 28
 local THUMB, THUMB_HOVER, THUMB_DRAG = Color3.fromRGB(90, 90, 90), Color3.fromRGB(120, 120, 120), Color3.fromRGB(140, 140, 140)
 local panelCount = 0

 local Panel = {}
 Panel.__index = Panel
 local Row = {}
 Row.__index = Row

 local function Vec(v, dx, dy)
  local t = typeof(v)
  if t == "Vector2" then return v.X, v.Y end
  if t == "UDim2" then return v.X.Offset, v.Y.Offset end
  if t == "table" then return tonumber(v[1] or v.X or v.x) or dx, tonumber(v[2] or v.Y or v.y) or dy end
  return dx, dy
 end

 local function TextW(text)
  local ok, v = pcall(function()
   return config.SV.TextSrv:GetTextSize(text, 21, Enum.Font.SourceSans, Vector2.new(10000, ROW))
  end)
  if ok and v then return v.X end
  return #text * 9
 end

 local function TopWindowAt(mp)
  for i = #config.WinOrder, 1, -1 do
   local w = config.WinOrder[i]
   if w.Visible then
    local ap, as = w.AbsolutePosition, w.AbsoluteSize
    if mp.X >= ap.X and mp.X <= ap.X + as.X and mp.Y >= ap.Y and mp.Y <= ap.Y + as.Y then return w end
   end
  end
  return nil
 end

 local function ProxyHit(target, padL, padT, padR, padB)
  local hit = Instance.new("TextButton")
  hit.Name = RandomString()
  hit.Text = ""
  hit.AutoButtonColor = false
  hit.BackgroundTransparency = 1
  hit.BorderSizePixel = 0
  hit.Active = true
  hit.Visible = false
  hit.Archivable = false
  hit.Parent = config.window
  local conn
  conn = config.SV.RunSrv.Heartbeat:Connect(function()
   if not target:IsDescendantOf(config.window) then
    conn:Disconnect()
    hit:Destroy()
    return
   end
   local top, shown = target, true
   while top.Parent and top.Parent ~= config.window do
    if top:IsA("GuiObject") and not top.Visible then shown = false end
    top = top.Parent
   end
   if top:IsA("GuiObject") and not top.Visible then shown = false end
   local as = target.AbsoluteSize
   if not shown or top.Parent ~= config.window or as.X <= 0 or as.Y <= 0 then
    hit.Visible = false
    return
   end
   local ap = target.AbsolutePosition - config.window.AbsolutePosition
   hit.Position = UDim2.fromOffset(math.floor(ap.X - padL), math.floor(ap.Y - padT))
   hit.Size = UDim2.fromOffset(math.ceil(as.X + padL + padR), math.ceil(as.Y + padT + padB))
   hit.ZIndex = top:IsA("GuiObject") and top.ZIndex + 1 or 2
   hit.Visible = true
  end)
  return hit
 end

 local function MakeBar(parent, isH, style, api)
  local rail = style == "Rail"
  local W = rail and 18 or 24
  local b = { Thickness = W }

  local bar = Instance.new("Frame")
  bar.Name = RandomString()
  bar.BorderSizePixel = 0
  bar.Active = true
  bar.Visible = false
  bar.ZIndex = 9
  bar.Archivable = false
  if rail then
   bar.BackgroundColor3 = Color3.fromRGB(34, 34, 38)
  else
   bar.BackgroundTransparency = 1
  end
  bar.Parent = parent
  b.Gui = bar

  local track = bar
  local arrows = {}
  if rail then
   local function Arrow(first)
    local btn = Instance.new("TextButton")
    btn.Name = RandomString()
    btn.Size = UDim2.new(0, W, 0, W)
    if isH then
     btn.Position = first and UDim2.new(0, 0, 0, 0) or UDim2.new(1, -W, 0, 0)
    else
     btn.Position = first and UDim2.new(0, 0, 0, 0) or UDim2.new(0, 0, 1, -W)
    end
    btn.BackgroundColor3 = Color3.fromRGB(52, 52, 57)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.ZIndex = 10
    btn.Archivable = false
    btn.Parent = bar
    BorderStroke(btn, 1, 24, 24, 27)
    local c = Instance.new("ImageLabel")
    c.Name = RandomString()
    c.Size = UDim2.new(0, 9, 0, 9)
    c.AnchorPoint = Vector2.new(0.5, 0.5)
    c.Position = UDim2.new(0.5, 0, 0.5, 0)
    c.BackgroundTransparency = 1
    c.Image = config.IMG.Caret
    if isH then c.Rotation = first and 180 or 0 else c.Rotation = first and -90 or 90 end
    c.ZIndex = 11
    c.Archivable = false
    c.Parent = btn
    return btn
   end
   arrows[1], arrows[2] = Arrow(true), Arrow(false)
   track = Instance.new("Frame")
   track.Name = RandomString()
   track.BackgroundTransparency = 1
   track.BorderSizePixel = 0
   track.ZIndex = 10
   track.Archivable = false
   if isH then
    track.Size = UDim2.new(1, -W * 2, 1, 0)
    track.Position = UDim2.new(0, W, 0, 0)
   else
    track.Size = UDim2.new(1, 0, 1, -W * 2)
    track.Position = UDim2.new(0, 0, 0, W)
   end
   track.Parent = bar
  end

  local thumb = Instance.new("Frame")
  thumb.Name = RandomString()
  thumb.BackgroundTransparency = 1
  thumb.BorderSizePixel = 0
  thumb.Active = false
  thumb.ZIndex = rail and 11 or 10
  thumb.Archivable = false
  thumb.Size = isH and UDim2.new(0.2, 0, 1, 0) or UDim2.new(1, 0, 0.2, 0)
  thumb.Parent = track

  local vis = Instance.new("Frame")
  vis.Name = RandomString()
  vis.BackgroundColor3 = THUMB
  vis.BorderSizePixel = 0
  vis.Active = false
  vis.ZIndex = rail and 11 or 10
  vis.Archivable = false
  if rail then
   vis.Size = isH and UDim2.new(1, 0, 1, -2) or UDim2.new(1, -2, 1, 0)
   vis.Position = isH and UDim2.new(0, 0, 0, 1) or UDim2.new(0, 1, 0, 0)
  else
   vis.Size = isH and UDim2.new(1, 0, 0, 12) or UDim2.new(0, 12, 1, 0)
   vis.Position = isH and UDim2.new(0, 0, 1, -14) or UDim2.new(1, -14, 0, 0)
   RoundCorner(vis, 1, 0)
  end
  vis.Parent = thumb

  local dragging, hovering, startPos, startOff = false, false, nil, 0
  local function Paint()
   if dragging then
    vis.BackgroundColor3 = THUMB_DRAG
   elseif hovering then
    vis.BackgroundColor3 = rail and THUMB_HOVER or THUMB_DRAG
   else
    vis.BackgroundColor3 = THUMB
   end
  end

  local hit
  if rail then
   hit = ProxyHit(thumb, isH and 0 or 14, isH and 14 or 0, 0, 0)
   hit.MouseEnter:Connect(function() hovering = true; Paint() end)
   hit.MouseLeave:Connect(function() hovering = false; Paint() end)
  else
   hit = config.WidenHit(thumb, isH)
   bar.MouseEnter:Connect(function() hovering = true; Paint() end)
   bar.MouseLeave:Connect(function() hovering = false; Paint() end)
  end

  hit.InputBegan:Connect(function(inp)
   if not config.Fresh(inp) then return end
   if not IsPress(inp) then return end
   if api.GetMax() <= 0 then return end
   dragging = true
   startPos = inp.Position
   startOff = api.GetOffset()
   Paint()
  end)
  api.Track(config.SV.UserInput.InputChanged:Connect(function(inp)
   if not dragging then return end
   if not config.Held(inp) then dragging = false; Paint(); return end
   if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
   local m = api.GetMax()
   local ts = track.AbsoluteSize
   local trackLen = isH and ts.X or ts.Y
   local frac = isH and thumb.Size.X.Scale or thumb.Size.Y.Scale
   local usable = trackLen * (1 - frac)
   local delta = isH and (inp.Position.X - startPos.X) or (inp.Position.Y - startPos.Y)
   if usable > 0 and m > 0 then api.Set(startOff + delta / usable * m) end
  end))
  api.Track(config.SV.UserInput.InputEnded:Connect(function(inp)
   if IsPress(inp) and dragging then
    dragging = false
    Paint()
   end
  end))

  if rail then
   local holdToken = 0
   for i, btn in ipairs(arrows) do
    local dir = (i == 1) and -1 or 1
    local ah = ProxyHit(btn, 0, 0, 0, 0)
    ah.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(70, 70, 76) end)
    ah.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(52, 52, 57) end)
    ah.InputBegan:Connect(function(inp)
     if not IsPress(inp) then return end
     if not config.Fresh(inp) then return end
     holdToken += 1
     local my = holdToken
     api.Set(api.GetOffset() + dir * ROW)
     task.spawn(function()
      task.wait(0.4)
      while holdToken == my do
       api.Set(api.GetOffset() + dir * ROW)
       task.wait(0.05)
      end
     end)
    end)
   end
   api.Track(config.SV.UserInput.InputEnded:Connect(function(inp)
    if IsPress(inp) then holdToken += 1 end
   end))
  end

  function b.Update(viewLen, contentLen, offset)
   if contentLen > viewLen + 0.5 and viewLen > 0 then
    bar.Visible = true
    local frac = math.clamp(viewLen / contentLen, 0.05, 0.85)
    local maxOff = contentLen - viewLen
    local pos = maxOff > 0 and math.clamp((offset / maxOff) * (1 - frac), 0, 1 - frac) or 0
    if isH then
     thumb.Size = UDim2.new(frac, 0, 1, 0)
     thumb.Position = UDim2.new(pos, 0, 0, 0)
    else
     thumb.Size = UDim2.new(1, 0, frac, 0)
     thumb.Position = UDim2.new(0, 0, pos, 0)
    end
   else
    bar.Visible = false
   end
  end

  return b
 end

 function Panel:_Dirty()
  if self._dirty or self._destroyed then return end
  self._dirty = true
  task.defer(function()
   self._dirty = false
   if not self._destroyed then self:Refresh() end
  end)
 end

 function Panel:Refresh()
  if self._destroyed then return end
  local bodyS = self.Body.AbsoluteSize
  if bodyS.X <= 0 or bodyS.Y <= 0 then return end
  local barW, baseBottom = self._barW, self._baseBottom

  local viewW = math.max(0, bodyS.X - barW)
  local natW = self._customW
  local needH = self.HorizontalScroll and natW > viewW
  local bottom = needH and barW or baseBottom
  local viewH = math.max(0, bodyS.Y - bottom)
  local canvasW = self.HorizontalScroll and math.max(viewW, natW) or viewW
  local canvasH = self._customH

  self._maxX = math.max(0, canvasW - viewW)
  self._maxY = math.max(0, canvasH - viewH)
  self._sx = math.clamp(self._sx, 0, self._maxX)
  self._sy = math.clamp(self._sy, 0, self._maxY)

  self.Viewport.Size = UDim2.new(1, -barW, 1, -bottom)
  self.Content.Size = UDim2.new(0, canvasW, 0, canvasH)
  self.Content.Position = UDim2.fromOffset(-self._sx, -self._sy)

  self.VBar.Gui.Size = UDim2.new(0, barW, 1, -bottom)
  self.VBar.Gui.Position = UDim2.new(1, -barW, 0, 0)
  self.VBar.Update(viewH, canvasH, self._sy)
  if self.HBar then
   self.HBar.Gui.Size = UDim2.new(1, -barW, 0, barW)
   self.HBar.Gui.Position = UDim2.new(0, 0, 1, -barW)
   self.HBar.Update(viewW, canvasW, self._sx)
  end
 end

 function Panel:SetCanvasSize(w, h)
  self._customW = math.max(0, tonumber(w) or 0)
  self._customH = math.max(0, tonumber(h) or 0)
  self:Refresh()
  return self
 end

 function Panel:ScrollTo(y, x)
  if y then self._sy = y end
  if x then self._sx = x end
  self:Refresh()
  return self
 end

 function Panel:SetTitle(text)
  self.Title = tostring(text)
  self.TitleLabel.Text = self.Title
  return self
 end

 function Panel:IsOpen() return self.Frame.Visible end
 function Panel:IsDocked() return self._side ~= nil end
 function Panel:GetDockSide() return self._side end
 function Panel:BringToFront() BringToFront(self.Frame); return self end

 function Panel:Open()
  if self._destroyed or self.Frame.Visible then return self end
  self.Frame.Visible = true
  Dock.Layout()
  self:Refresh()
  BringToFront(self.Frame)
  return self
 end

 function Panel:Close()
  if self._destroyed or not self.Frame.Visible then return self end
  self.Frame.Visible = false
  Dock.Layout()
  if self.OnClose then pcall(self.OnClose, self) end
  return self
 end

 function Panel:Toggle()
  if self.Frame.Visible then return self:Close() end
  return self:Open()
 end

 function Panel:_SetSide(side)
  if self._side == side then return end
  self._side = side
  if self.OnDock then pcall(self.OnDock, self, side) end
 end

 function Panel:Dock(side, where)
  if self._destroyed then return self end
  side = tostring(side):lower()
  if side ~= "left" and side ~= "right" then return self end
  local target, zone
  if where == "top" then
   Dock.Reconcile()
   for _, e in ipairs(Dock.Stacks[side]) do
    if e ~= self._entry and e.gui.Visible then target, zone = e, "top" break end
   end
  end
  Dock.Place(self._entry, side, target, zone)
  return self
 end

 function Panel:Undock()
  if not self._side then return self end
  local f = self.Frame
  local px, py = f.Position.X.Offset, f.Position.Y.Offset
  local w = f.Size.X.Offset
  self:_SetSide(nil)
  f.AnchorPoint = Vector2.new(0, 0)
  f.Position = UDim2.new(0, px, 0, py)
  f.Size = UDim2.new(0, w, 0, self._floatH)
  self.DockSplitter.Visible = false
  ClampPanelTop(f)
  Dock.Layout()
  return self
 end

 function Panel:Destroy()
  if self._destroyed then return end
  self._destroyed = true
  for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
  Dock.Unregister(self.Frame)
  for i, w in ipairs(config.WinOrder) do
   if w == self.Frame then table.remove(config.WinOrder, i) break end
  end
  for i, w in ipairs(config.WinOrder) do w.ZIndex = 1 + i end
  if self._menuButton then pcall(function() self._menuButton:Destroy() end) end
  config.dockHint.Visible = false
  self.Frame:Destroy()
  Dock.Layout()
 end

 function Explorer.CreatePanel(a, b)
  local cfg = (a == Explorer) and b or a
  cfg = type(cfg) == "table" and cfg or {}
  panelCount += 1

  local scr = config.window.AbsoluteSize
  local W, H = Vec(cfg.Size, config.DT, 320)
  W, H = math.max(W, 160), math.max(H, 160)
  local px, py = Vec(cfg.Position, nil, nil)
  if not px then
   local k = (panelCount - 1) % 6
   px = (scr.X > 0 and math.floor((scr.X - W) / 2) or 60) + k * 24
   py = TopInset() + 40 + k * 24
  end

  local styleName = tostring(cfg.ScrollBar or "Rounded"):lower()
  local style = (styleName == "rail") and "Rail" or "Rounded"

  local self = setmetatable({
   Title = tostring(cfg.Name or "Panel"),
   OnClose = cfg.OnClose, OnDock = cfg.OnDock,
   HorizontalScroll = cfg.HorizontalScroll == true,
   ScrollBarStyle = style,
   _conns = {},
   _sx = 0, _sy = 0, _maxX = 0, _maxY = 0, _customW = 0, _customH = 0,
   _barW = (style == "Rail") and 18 or 24,
   _baseBottom = (style == "Rail") and 8 or 0,
   _floatH = H, _side = nil, _dirty = false, _destroyed = false,
  }, Panel)
  local function Track(c) self._conns[#self._conns + 1] = c; return c end

  local frame = Instance.new("Frame")
  frame.Name = RandomString()
  frame.Size = UDim2.new(0, W, 0, H)
  frame.Position = UDim2.new(0, px, 0, py)
  frame.BackgroundColor3 = config.COLORS.PRIMARY
  frame.BackgroundTransparency = config.NT
  frame.Active = true
  frame.BorderSizePixel = 0
  frame.ZIndex = 2
  frame.Archivable = false
  frame.Visible = cfg.Visible ~= false
  frame.Parent = config.window
  ClampPanelTop(frame)
  RegisterWindow(frame)
  self.Frame = frame

  local dockSplitter = Instance.new("Frame")
  dockSplitter.Name = RandomString()
  dockSplitter.Size = UDim2.new(0, 6, 1, 0)
  dockSplitter.BackgroundColor3 = config.COLORS.RESIZER
  dockSplitter.BorderSizePixel = 0
  dockSplitter.ZIndex = 8
  dockSplitter.Visible = false
  dockSplitter.Active = true
  dockSplitter.Archivable = false
  dockSplitter.Parent = frame
  self.DockSplitter = dockSplitter

  local hdr = Instance.new("Frame")
  hdr.Name = RandomString()
  hdr.Size = UDim2.new(1, 0, 0, HEADER_H)
  hdr.BackgroundColor3 = config.COLORS.HEADER
  hdr.BorderSizePixel = 0
  hdr.Active = true
  hdr.ZIndex = 3
  hdr.Archivable = false
  hdr.Parent = frame
  self.Header = hdr

  local accent = Instance.new("Frame")
  accent.Name = RandomString()
  accent.Size = UDim2.new(1, 0, 0, 1.5)
  accent.Position = UDim2.new(0, 0, 1, -1.5)
  accent.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
  accent.BorderSizePixel = 0
  accent.ZIndex = 3
  accent.Archivable = false
  accent.Parent = hdr

  local title = Instance.new("TextLabel")
  title.Name = RandomString()
  title.Size = UDim2.new(1, -70, 0, HEADER_H)
  title.Position = UDim2.new(0, 35, 0, 0)
  title.BackgroundTransparency = 1
  title.Text = self.Title
  title.TextColor3 = config.COLORS.TEXT_BRIGHT
  title.FontFace = config.FONT.GothamRegular
  title.TextSize = 12
  title.TextTruncate = Enum.TextTruncate.AtEnd
  title.TextXAlignment = Enum.TextXAlignment.Center
  title.ZIndex = 3
  title.Archivable = false
  title.Parent = hdr
  self.TitleLabel = title

  local closeBtn = Instance.new("TextButton")
  closeBtn.Name = RandomString()
  closeBtn.Size = UDim2.new(0, 28, 0, 28)
  closeBtn.Position = UDim2.new(1, -30, 0, 1)
  closeBtn.BackgroundTransparency = 1
  closeBtn.Text = ""
  closeBtn.AutoButtonColor = false
  closeBtn.BorderSizePixel = 0
  closeBtn.ZIndex = 3
  closeBtn.Archivable = false
  closeBtn.Parent = hdr
  MakeCloseImage(closeBtn, 12, 4)
  self.CloseButton = closeBtn

  local pinBtn = Instance.new("TextButton")
  pinBtn.Name = RandomString()
  pinBtn.Size = UDim2.new(0, 22, 0, 22)
  pinBtn.Position = UDim2.new(1, -49, 0, 3)
  pinBtn.BackgroundTransparency = 1
  pinBtn.AutoButtonColor = false
  pinBtn.Text = ""
  pinBtn.BorderSizePixel = 0
  pinBtn.ZIndex = 3
  pinBtn.Archivable = false
  pinBtn.Parent = hdr
  RoundCorner(pinBtn, 0, 6)
  MakePinImage(pinBtn, 22, 4)
  self.PinButton = pinBtn

  -- body = everything under the header
  local body = Instance.new("Frame")
  body.Name = RandomString()
  body.Size = UDim2.new(1, 0, 1, -HEADER_H)
  body.Position = UDim2.new(0, 0, 0, HEADER_H)
  body.BackgroundTransparency = 1
  body.ZIndex = 3
  body.Archivable = false
  body.Parent = frame
  self.Body = body

  local viewport = Instance.new("Frame")
  viewport.Name = RandomString()
  viewport.Size = UDim2.new(1, -self._barW, 1, -self._baseBottom)
  viewport.BackgroundTransparency = 1
  viewport.ClipsDescendants = true
  viewport.ZIndex = 3
  viewport.Archivable = false
  viewport.Parent = body
  self.Viewport = viewport

  local content = Instance.new("Frame")
  content.Name = RandomString()
  content.Size = UDim2.new(1, 0, 0, 0)
  content.BackgroundTransparency = 1
  content.BorderSizePixel = 0
  content.ZIndex = 3
  content.Archivable = false
  content.Parent = viewport
  self.Content = content

  local function BarApi(isH)
   return {
    GetOffset = function() return isH and self._sx or self._sy end,
    GetMax = function() return isH and self._maxX or self._maxY end,
    Set = function(v)
     if isH then self._sx = v else self._sy = v end
     self:Refresh()
    end,
    Track = Track,
   }
  end
  self.VBar = MakeBar(body, false, style, BarApi(false))
  if self.HorizontalScroll then self.HBar = MakeBar(body, true, style, BarApi(true)) end

  Track(body:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_Dirty() end))
  Track(frame:GetPropertyChangedSignal("Visible"):Connect(function()
   Dock.Layout()
   if frame.Visible then self:_Dirty() end
  end))

  Track(config.SV.UserInput.InputChanged:Connect(function(input)
   if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
   if not frame.Visible then return end
   local delta = input.Position.Z
   if delta == 0 then return end
   local mp = config.SV.UserInput:GetMouseLocation()
   local ap, as = frame.AbsolutePosition, frame.AbsoluteSize
   if mp.X < ap.X or mp.X > ap.X + as.X or mp.Y < ap.Y or mp.Y > ap.Y + as.Y then return end
   local topW = TopWindowAt(mp)
   if topW and topW ~= frame then return end
   local shift = config.SV.UserInput:IsKeyDown(Enum.KeyCode.LeftShift) or config.SV.UserInput:IsKeyDown(Enum.KeyCode.RightShift)
   if shift and self.HorizontalScroll then
    self._sx = self._sx - delta * ROW * 3
   else
    self._sy = self._sy - delta * ROW * 3
   end
   self:Refresh()
  end))

  self._entry = Dock.Register(frame, {
   GetSide = function() return self._side end,
   SetSide = function(s) self:_SetSide(s) end,
   GetSplitter = function() return dockSplitter end,
  })

  closeBtn.Activated:Connect(function() self:Close() end)
  pinBtn.Activated:Connect(function()
   if self._side then self:Undock() else self:Dock(NearestSide(frame)) end
  end)

  MakeDraggable(frame, hdr, {
   BlockCheck = function() return Explorer.PanelResizing[frame] end,
   threshold = 4,
   OnBegin = function() BringToFront(frame) end,
   OnDrag = function(cursor)
    if self._side then self:Undock() end
    local side, zone, target = Dock.Resolve(frame, cursor)
    Dock.ShowHint(frame, target, side, zone)
   end,
   OnEnd = function(didDrag, cursor)
    config.dockHint.Visible = false
    if not didDrag then return end
    local side, zone, target = Dock.Resolve(frame, cursor)
    if not side then return end
    Dock.Place(self._entry, side, target, zone)
   end,
  })

  local EDGE = config.EDGE
  local function OnResize(newSize)
   if self._side then
    Dock.Width[self._side] = newSize.X.Offset
    Dock.Layout()
   else
    self._floatH = newSize.Y.Offset
   end
  end
  local function NotRight() return self._side == "right" end
  local function NotLeft() return self._side == "left" end
  local function WhenDocked() return self._side ~= nil end
  MakeResizeHandler(220, 160, "right", 1, 0, 3 - EDGE * 2, EDGE, 0, 1, EDGE * 2, -EDGE * 2, 8, frame, NotRight, OnResize)
  MakeResizeHandler(220, 160, "left", 0, 0, -3, EDGE, 0, 1, EDGE * 2, -EDGE * 2, 8, frame, NotLeft, OnResize)
  MakeResizeHandler(220, 160, "bottom", 0, 1, EDGE, 0, 1, 0, -EDGE * 2, EDGE * 2, 8, frame, WhenDocked, OnResize)
  MakeResizeHandler(220, 160, "top", 0, 0, EDGE, -EDGE * 2, 1, 0, -EDGE * 2, EDGE * 2, 8, frame, WhenDocked, OnResize)
  MakeResizeHandler(220, 160, "top_left", 0, 0, -3, -EDGE * 2, 0, 0, EDGE * 2, EDGE * 2, 9, frame, WhenDocked, OnResize)
  MakeResizeHandler(220, 160, "top_right", 1, 0, 3 - EDGE * 2, -EDGE * 2, 0, 0, EDGE * 2, EDGE * 2, 9, frame, WhenDocked, OnResize)
  MakeResizeHandler(220, 160, "bottom_left", 0, 1, -3, 0, 0, 0, EDGE * 2, EDGE * 2, 9, frame, WhenDocked, OnResize)
  MakeResizeHandler(220, 160, "bottom_right", 1, 1, 3 - EDGE * 2, 0, 0, 0, EDGE * 2, EDGE * 2, 9, frame, WhenDocked, OnResize)

  if cfg.MenuButton and Explorer.AddMenuButton then
   local label = type(cfg.MenuButton) == "string" and cfg.MenuButton or self.Title
   self._menuButton = Explorer.AddMenuButton(label, function() self:Toggle() end)
  end

  if cfg.Dock then self:Dock(cfg.Dock) end
  self:_Dirty()
  return self
 end
end
