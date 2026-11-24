do
 local VState = {
  RotationX = -0.26, RotationY = 0, Distance = 10,
  Dragging = false, AutoRotation = true, CameraLocked = false,
  Model = nil, OriginalInstance = nil,
  LastPosition = Vector2.zero, Touches = {}, ZoomActive = false,
  ZoomStartDistance = 10, ActiveInput = nil,
  conn = nil,
 }
 local viewerPositioned = false

 local viewerPanel = Instance.new("Frame")
 viewerPanel.Name = RandomString()
 viewerPanel.Size = UDim2.new(0, 300, 0, 260)
 viewerPanel.Position = UDim2.new(0, 60, 0, 60)
 viewerPanel.BackgroundColor3 = config.COLORS.PRIMARY
 viewerPanel.BackgroundTransparency = config.NT
 viewerPanel.BorderSizePixel = 0
 viewerPanel.Active = true
 viewerPanel.Visible = false
 viewerPanel.ZIndex = 2
 viewerPanel.Archivable = false
 viewerPanel.Parent = config.window
 RegisterWindow(viewerPanel)

 local vhdr = Instance.new("Frame")
 vhdr.Name = RandomString()
 vhdr.Size = UDim2.new(1, 0, 0, 28)
 vhdr.BackgroundColor3 = config.COLORS.HEADER
 vhdr.BorderSizePixel = 0
 vhdr.Active = true
 vhdr.ZIndex = 3
 vhdr.Archivable = false
 vhdr.Parent = viewerPanel

 local vAccent = Instance.new("Frame")
 vAccent.Name = RandomString()
 vAccent.Size = UDim2.new(1, 0, 0, 1.5)
 vAccent.Position = UDim2.new(0, 0, 1, -1.5)
 vAccent.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
 vAccent.BorderSizePixel = 0
 vAccent.ZIndex = 3
 vAccent.Archivable = false
 vAccent.Parent = vhdr

 local vtitle = Instance.new("TextLabel")
 vtitle.Name = RandomString()
 vtitle.Size = UDim2.new(1, -100, 1, 0)
 vtitle.Position = UDim2.new(0, 35, 0, 0)
 vtitle.BackgroundTransparency = 1
 vtitle.Text = "3D Preview"
 vtitle.TextColor3 = config.COLORS.TEXT_BRIGHT
 vtitle.FontFace = config.FONT.GothamRegular
 vtitle.TextSize = 12
 vtitle.TextTruncate = Enum.TextTruncate.AtEnd
 vtitle.TextXAlignment = Enum.TextXAlignment.Center
 vtitle.ZIndex = 3
 vtitle.Archivable = false
 vtitle.Parent = vhdr

 local vclose = Instance.new("TextButton")
 vclose.Name = RandomString()
 vclose.Size = UDim2.new(0, 28, 0, 28)
 vclose.Position = UDim2.new(1, -30, 0, 0)
 vclose.BackgroundTransparency = 1
 vclose.Text = ""
 vclose.AutoButtonColor = false
 vclose.BorderSizePixel = 0
 vclose.ZIndex = 3
 vclose.Archivable = false
 vclose.Parent = vhdr
 MakeCloseImage(vclose, 12, 4)

 local vrotate = Instance.new("ImageButton")
 vrotate.Name = RandomString()
 vrotate.Size = UDim2.new(0, 22, 0, 22)
 vrotate.Position = UDim2.new(1, -58, 0, 3)
 vrotate.BackgroundColor3 = Color3.fromRGB(40, 80, 60)
 vrotate.BackgroundTransparency = 0.7
 vrotate.AutoButtonColor = false
 vrotate.Image = ""
 vrotate.ImageColor3 = Color3.fromRGB(140, 220, 180)
 vrotate.BorderSizePixel = 0
 vrotate.ZIndex = 3
 vrotate.Archivable = false
 vrotate.Parent = vhdr
 RoundCorner(vrotate, 0, 6)

 Explorer.ApplyImage(vrotate, "Rotation")

 local vbody = Instance.new("Frame")
 vbody.Name = RandomString()
 vbody.Size = UDim2.new(1, 0, 1, -28)
 vbody.Position = UDim2.new(0, 0, 0, 28)
 vbody.BackgroundTransparency = 1
 vbody.ZIndex = 3
 vbody.Archivable = false
 vbody.Parent = viewerPanel

 local viewport = Instance.new("ViewportFrame")
 viewport.Name = RandomString()
 viewport.Size = UDim2.new(1, -16, 1, -44)
 viewport.Position = UDim2.new(0, 8, 0, 8)
 viewport.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
 viewport.BorderSizePixel = 0
 viewport.Active = true
 viewport.ZIndex = 3
 viewport.Archivable = false
 viewport.Parent = vbody
 RoundCorner(viewport, 0, 6)

 local vpath = Instance.new("TextLabel")
 vpath.Name = RandomString()
 vpath.Size = UDim2.new(1, -16, 0, 18)
 vpath.Position = UDim2.new(0, 8, 1, -26)
 vpath.BackgroundTransparency = 1
 vpath.Text = ""
 vpath.TextColor3 = config.COLORS.TEXT_DIM
 vpath.FontFace = config.FONT.GothamMedium
 vpath.TextSize = 10
 vpath.TextXAlignment = Enum.TextXAlignment.Left
 vpath.TextTruncate = Enum.TextTruncate.AtEnd
 vpath.ZIndex = 3
 vpath.Archivable = false
 vpath.Parent = vbody

 local function SafeClone(inst)
  local was = true
  pcall(function() was = inst.Archivable end)
  if was == false then pcall(function() inst.Archivable = true end) end
  local ok, c = pcall(function() return inst:Clone() end)
  if was == false then pcall(function() inst.Archivable = false end) end
  if ok and c then return c end
  return nil
 end

 local StopViewer
 StopViewer = function()
  if VState.conn then VState.conn:Disconnect(); VState.conn = nil end
  if VState.Model then VState.Model:Destroy(); VState.Model = nil end
  viewport:ClearAllChildren()
  VState.OriginalInstance = nil
  vtitle.Text = "3D Preview"
  vpath.Text = ""
  viewerPanel.Visible = false
 end

 local function ShowViewerError(msg)
  VState.Model = nil
  viewport:ClearAllChildren()
  vtitle.Text = "3D Preview - Error"
  vpath.Text = msg
  viewerPanel.Visible = true
  BringToFront(viewerPanel)
 end

 local function SmartPosition()
  if viewerPositioned then return end
  viewerPositioned = true
  local scr = config.window.AbsoluteSize
  local w, h = viewerPanel.Size.X.Offset, viewerPanel.Size.Y.Offset
  local leftBound, rightBound = 0, scr.X
  local function Claim(gui, side)
   if not gui or not gui.Visible then return end
   if side == "left" then
    leftBound = math.max(leftBound, gui.AbsolutePosition.X + gui.AbsoluteSize.X)
   elseif side == "right" then
    rightBound = math.min(rightBound, gui.AbsolutePosition.X)
   end
  end
  for _, d in ipairs(config.DockMgr.Docked()) do Claim(d.gui, d.side) end
  local availableW = rightBound - leftBound
  local x
  if availableW >= w + 20 then
   x = leftBound + (availableW - w) / 2
  else
   x = scr.X - w - 40
  end
  x = math.clamp(x, 4, math.max(4, scr.X - w - 4))
  local y = math.clamp(scr.Y / 2 - h / 2, TopInset() + 4, math.max(TopInset() + 4, scr.Y - h - 4))
  viewerPanel.Position = UDim2.new(0, x, 0, y)
  ClampPanelTop(viewerPanel)
 end

 local function ViewModel(inst)
  if not inst or not inst.Real then return end
  StopViewer()
  SmartPosition()
  local real = inst.Real

  local ok, err = pcall(function()
   local isBasePart, isModel = false, false
   pcall(function() isBasePart = real:IsA("BasePart") end)
   pcall(function() isModel = real:IsA("Model") end)

   local built
   if isBasePart and not isModel then
    built = Instance.new("Model")
    local clone = SafeClone(real)
    if not clone then error("could not clone (Archivable blocked)") end
    clone.Parent = built
    built.PrimaryPart = clone
    built:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
   elseif isModel then
    built = SafeClone(real)
    if not built then error("could not clone (Archivable blocked)") end
    if #built:GetChildren() == 0 then
     built:Destroy()
     error("Model has no children")
    end
    if not built.PrimaryPart then
     local found = false
     for _, child in ipairs(built:GetDescendants()) do
      if child:IsA("BasePart") then
       built.PrimaryPart = child
       found = true
       break
      end
     end
     if not found then
      built:Destroy()
      error("no BasePart found")
     end
    end
    built:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
   else
    error("unsupported type: " .. real.ClassName)
   end

   built.Parent = viewport
   VState.Model = built
   VState.OriginalInstance = inst
   VState.RotationX, VState.RotationY = -0.26, 0
   VState.Distance = 10

   local camera = Instance.new("Camera")
   camera.FieldOfView = 60
   camera.Parent = viewport
   viewport.CurrentCamera = camera

   vtitle.Text = inst.Name .. " - 3D Preview"
   pcall(function() vpath.Text = "path: " .. inst:GetFullName() end)

   VState.conn = config.SV.RunSrv.RenderStepped:Connect(function(dt)
    if not VState.Model or not VState.Model.PrimaryPart or not camera.Parent then return end
    if not VState.Dragging and VState.AutoRotation then
     VState.RotationY = VState.RotationY + 0.4 * dt
    end
    local center = VState.Model.PrimaryPart.Position
    local rotation = CFrame.Angles(0, VState.RotationY, 0) * CFrame.Angles(VState.RotationX, 0, 0)
    local camCF = CFrame.new(center) * rotation * CFrame.new(0, 0, VState.Distance)
    camera.CFrame = CFrame.lookAt(camCF.Position, center)
   end)

   viewerPanel.Visible = true
   BringToFront(viewerPanel)
  end)

  if not ok then
   ShowViewerError(tostring(err):match(":%d+:%s*(.*)$") or tostring(err))
  end
 end

 viewport.InputBegan:Connect(function(inp)
  if not config.Fresh(inp) then return end
  if VState.CameraLocked then return end
  if inp.UserInputType == Enum.UserInputType.Touch then
   table.insert(VState.Touches, inp)
   if #VState.Touches == 2 then
    VState.ZoomActive = true
    local t1, t2 = VState.Touches[1], VState.Touches[2]
    local dx = t1.Position.X - t2.Position.X
    local dy = t1.Position.Y - t2.Position.Y
    VState.ZoomStartDistance = math.sqrt(dx*dx + dy*dy)
    VState.zoomStartDistance = VState.Distance
    VState.Dragging = false
   else
    VState.Dragging = true
    VState.ActiveInput = inp
    VState.LastPosition = inp.Position
   end
  elseif inp.UserInputType == Enum.UserInputType.MouseButton1 then
   VState.Dragging = true
   VState.ActiveInput = inp
   VState.LastPosition = inp.Position
  end
 end)

 viewport.InputChanged:Connect(function(inp)
  if VState.CameraLocked then return end
  if VState.ZoomActive then
   local t1, t2 = VState.Touches[1], VState.Touches[2]
   if t1 and t2 then
    local dx = t1.Position.X - t2.Position.X
    local dy = t1.Position.Y - t2.Position.Y
    local cur = math.sqrt(dx*dx + dy*dy)
    if cur > 0 then
     local scale = cur / VState.ZoomStartDistance
     VState.Distance = math.clamp(VState.zoomStartDistance / scale, 1, 300)
    end
   end
  elseif VState.Dragging and inp == VState.ActiveInput then
   if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement then
    local delta = inp.Position - VState.LastPosition
    VState.LastPosition = inp.Position
    VState.RotationY = VState.RotationY - delta.X * 0.01
    VState.RotationX = math.clamp(VState.RotationX - delta.Y * 0.01, -math.pi/2 + 0.1, math.pi/2 - 0.1)
   end
  end
 end)

 viewport.InputEnded:Connect(function(inp)
  if VState.CameraLocked then return end
  if inp.UserInputType == Enum.UserInputType.Touch then
   for i = #VState.Touches, 1, -1 do
    if VState.Touches[i] == inp then
     table.remove(VState.Touches, i)
     break
    end
   end
   if #VState.Touches < 2 then VState.ZoomActive = false end
   if #VState.Touches == 0 then
    VState.Dragging = false
    VState.ActiveInput = nil
   else
    VState.Dragging = true
    VState.ActiveInput = VState.Touches[1]
    VState.LastPosition = VState.ActiveInput.Position
   end
  elseif inp.UserInputType == Enum.UserInputType.MouseButton1 then
   VState.Dragging = false
   VState.ActiveInput = nil
  end
 end)

 config.SV.UserInput.InputChanged:Connect(function(inp)
  if not VState.Dragging or VState.CameraLocked or inp ~= VState.ActiveInput then return end
  if not config.Held(inp) then VState.Dragging = false; VState.ActiveInput = nil; return end
  if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  local delta = inp.Position - VState.LastPosition
  VState.LastPosition = inp.Position
  VState.RotationY = VState.RotationY - delta.X * 0.01
  VState.RotationX = math.clamp(VState.RotationX - delta.Y * 0.01, -math.pi/2 + 0.1, math.pi/2 - 0.1)
 end)

 viewport.MouseWheelForward:Connect(function()
  VState.Distance = math.max(1, VState.Distance - VState.Distance * 0.15)
 end)
 viewport.MouseWheelBackward:Connect(function()
  VState.Distance = math.min(300, VState.Distance + VState.Distance * 0.15)
 end)

 vrotate.Activated:Connect(function()
  VState.AutoRotation = not VState.AutoRotation
  if VState.AutoRotation then
   vrotate.BackgroundColor3 = Color3.fromRGB(40, 80, 60)
   vrotate.ImageColor3 = Color3.fromRGB(140, 220, 180)
  else
   vrotate.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
   vrotate.ImageColor3 = Color3.fromRGB(120, 120, 120)
  end
 end)

 vclose.Activated:Connect(StopViewer)

 MakeDraggable(viewerPanel, vhdr, { threshold = 4 })

 local EDGE = config.EDGE
 MakeResizeHandler(200, 180, "right", 1, 0, 0, EDGE, 0, 1, EDGE * 2, -EDGE * 2, 8, viewerPanel)
 MakeResizeHandler(200, 180, "left", 0, 0, -EDGE * 2, EDGE, 0, 1, EDGE * 2, -EDGE * 2, 8, viewerPanel)
 MakeResizeHandler(200, 180, "bottom", 0, 1, EDGE, 0, 1, 0, -EDGE * 2, EDGE * 2, 8, viewerPanel)
 MakeResizeHandler(200, 180, "top", 0, 0, EDGE, -EDGE * 2, 1, 0, -EDGE * 2, EDGE * 2, 8, viewerPanel)
 MakeResizeHandler(200, 180, "top_left", 0, 0, -EDGE * 2, -EDGE * 2, 0, 0, EDGE * 2, EDGE * 2, 9, viewerPanel)
 MakeResizeHandler(200, 180, "top_right", 1, 0, 0, -EDGE * 2, 0, 0, EDGE * 2, EDGE * 2, 9, viewerPanel)
 MakeResizeHandler(200, 180, "bottom_left", 0, 1, -EDGE * 2, 0, 0, 0, EDGE * 2, EDGE * 2, 9, viewerPanel)
 MakeResizeHandler(200, 180, "bottom_right", 1, 1, 0, 0, 0, 0, EDGE * 2, EDGE * 2, 9, viewerPanel)

 Explorer.ViewModel = ViewModel
 Explorer.StopViewer = StopViewer
 Explorer.IsViewerOpen = function() return viewerPanel.Visible end
 Explorer.ViewerPanel = viewerPanel
end
