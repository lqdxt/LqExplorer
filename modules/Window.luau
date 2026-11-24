do
 local UIS = config.SV.UserInput
 local TITLE_H = 35
 local TITLE_TEXT = Color3.fromRGB(70, 70, 70)
 local UI = {}
 Explorer.UI = UI
 Explorer.WindowTitleHeight = TITLE_H

 function UI.New(class, props, parent)
  local o = Instance.new(class)
  o.Name = RandomString()
  o.Archivable = false
  if o:IsA("GuiObject") then o.BorderSizePixel = 0 end
  if o:IsA("GuiButton") then o.AutoButtonColor = false; o.Text = "" end
  if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
   o.Font = Enum.Font.SourceSans
   o.TextSize = 17
   o.TextColor3 = Color3.fromRGB(205, 205, 205)
  end
  for k, v in pairs(props) do o[k] = v end
  o.Parent = parent
  return o
 end
 local New = UI.New

 function UI.IsPress(i)
  return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
 end
 local IsPress = UI.IsPress

 function UI.Pointer(i)
  return Vector2.new(i.Position.X, i.Position.Y)
 end
 local Pointer = UI.Pointer

 local windows = {}
 local sharedGui
 local zCounter = 0

 local function GetGui()
  if sharedGui and sharedGui.Parent then return sharedGui end
  sharedGui = New("ScreenGui", {
   ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
   DisplayOrder = (config.window.DisplayOrder or 0) + 10, ClipToDeviceSafeArea = false,
  }, config.folder)
  return sharedGui
 end

 local function ViewportSize(gui)
  local s = gui.AbsoluteSize
  if s.X < 50 or s.Y < 50 then
   local ws = GetService("Workspace")
   s = (ws and ws.CurrentCamera and ws.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
  end
  return s
 end

 local function ParseXY(v, dx, dy)
  local t = typeof(v)
  if t == "Vector2" then return v.X, v.Y end
  if t == "UDim2" then return v.X.Offset, v.Y.Offset end
  if type(v) == "table" and v[1] and v[2] then return v[1], v[2] end
  return dx, dy
 end

 local Window = {}
 Window.__index = Window

 function Window:Track(conn)
  self._conns[#self._conns + 1] = conn
  return conn
 end

 function Window:Focus()
  if self._closed then return end
  zCounter += 1
  self.Frame.ZIndex = zCounter
 end

 function Window:SetTitle(text)
  self.Title.Text = tostring(text)
 end

 function Window:IsOpen()
  return not self._closed
 end

 function Window:Close()
  if self._closed then return end
  self._closed = true
  if self.OnClose then
   local ok, err = pcall(self.OnClose, self)
   if not ok then warn("window OnClose error: " .. tostring(err)) end
  end
  for _, c in ipairs(self._conns) do c:Disconnect() end
  self._conns = {}
  windows[self] = nil
  self.Frame:Destroy()
  if next(windows) == nil and sharedGui then
   sharedGui:Destroy()
   sharedGui = nil
  end
 end

 UIS.InputBegan:Connect(function(inp)
  if not IsPress(inp) then return end
  local p = Pointer(inp)
  local best
  for w in pairs(windows) do
   local ap, as = w.Frame.AbsolutePosition, w.Frame.AbsoluteSize
   if p.X >= ap.X and p.X <= ap.X + as.X and p.Y >= ap.Y and p.Y <= ap.Y + as.Y then
    if not best or w.Frame.ZIndex > best.Frame.ZIndex then best = w end
   end
  end
  if best and best.Frame.ZIndex < zCounter then best:Focus() end
 end)

 function Explorer.CreateWindow(a, b)
  local cfg = (a == Explorer) and b or a
  cfg = type(cfg) == "table" and cfg or {}
  local gui = GetGui()
  local W, H = ParseXY(cfg.Size, 400, 300)
  H = math.max(H, TITLE_H + 1)
  local fit = cfg.Fit ~= false

  local self = setmetatable({ Gui = gui, OnClose = cfg.OnClose, Size = Vector2.new(W, H), _conns = {}, _closed = false }, Window)
  local function Track(c) return self:Track(c) end

  local function Fit()
   if not fit then return 1 end
   local vp = ViewportSize(gui)
   return math.max(0.4, math.min(1, (vp.X - 16) / W, (vp.Y - 16) / H))
  end
  local sc = Fit()
  self.Scale = sc

  local vp0 = ViewportSize(gui)
  local px, py = ParseXY(cfg.Position, math.floor((vp0.X - W * sc) / 2), math.floor((vp0.Y - H * sc) / 2))

  local dlg = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(W * sc, H * sc), Position = UDim2.fromOffset(px, py) }, gui)
  self.Frame = dlg
  local frame = New("Frame", { BackgroundColor3 = Color3.fromRGB(27, 28, 33), Size = UDim2.fromOffset(W, H), ClipsDescendants = true, Active = true }, dlg)
  local uiscale = Instance.new("UIScale")
  uiscale.Scale = sc
  uiscale.Parent = frame
  RoundCorner(frame, 0, 8)
  BorderStroke(frame, 1, 70, 72, 80)

  Track(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
   sc = Fit()
   self.Scale = sc
   uiscale.Scale = sc
   dlg.Size = UDim2.fromOffset(W * sc, H * sc)
  end))

  local titleBar = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, TITLE_H), Active = true }, frame)
  local titleRound = New("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.new(1, 0, 1, 0) }, titleBar)
  RoundCorner(titleRound, 0, 8)
  New("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0.5, 0) }, titleBar)
  local closable = cfg.Closable ~= false
  self.TitleBar = titleBar
  self.Title = New("TextLabel", {
   BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, closable and -58 or -24, 1, 0),
   Text = tostring(cfg.Name or "Window"), TextColor3 = TITLE_TEXT, TextSize = 17,
   TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
  }, titleBar)

  if closable then
   local closeBtn = New("TextButton", {
    BackgroundColor3 = Color3.fromRGB(232, 17, 35), BackgroundTransparency = 1,
    Position = UDim2.new(1, -46, 0, 0), Size = UDim2.fromOffset(46, TITLE_H),
   }, titleBar)
   local xLines = {}
   for _, rot in ipairs({ 45, -45 }) do
    xLines[#xLines + 1] = New("Frame", {
     BackgroundColor3 = Color3.fromRGB(40, 40, 40), AnchorPoint = Vector2.new(0.5, 0.5),
     Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(15, 1), Rotation = rot,
    }, closeBtn)
   end
   closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundTransparency = 0
    for _, l in ipairs(xLines) do l.BackgroundColor3 = Color3.fromRGB(255, 255, 255) end
   end)
   closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundTransparency = 1
    for _, l in ipairs(xLines) do l.BackgroundColor3 = Color3.fromRGB(40, 40, 40) end
   end)
   closeBtn.Activated:Connect(function() self:Close() end)
  end

  if cfg.Draggable ~= false then
   Track(titleBar.InputBegan:Connect(function(inp)
    if not IsPress(inp) then return end
    self:Focus()
    local startPtr = Vector2.new(inp.Position.X, inp.Position.Y)
    local startPos = Vector2.new(dlg.Position.X.Offset, dlg.Position.Y.Offset)
    local mc, ec
    local function stop()
     if mc then mc:Disconnect() end
     if ec then ec:Disconnect() end
    end
    mc = Track(UIS.InputChanged:Connect(function(i)
     if i.UserInputType == Enum.UserInputType.MouseMovement or i == inp then
      local d = Vector2.new(i.Position.X, i.Position.Y) - startPtr
      dlg.Position = UDim2.fromOffset(startPos.X + d.X, startPos.Y + d.Y)
     end
    end))
    ec = Track(UIS.InputEnded:Connect(function(i)
     if i == inp or (inp.UserInputType == Enum.UserInputType.MouseButton1 and i.UserInputType == Enum.UserInputType.MouseButton1) then stop() end
    end))
   end))
  end

  self.Content = New("Frame", {
   BackgroundTransparency = 1, Position = UDim2.fromOffset(0, TITLE_H), Size = UDim2.new(1, 0, 1, -TITLE_H),
  }, frame)

  windows[self] = true
  self:Focus()
  return self
 end
end
