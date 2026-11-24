 do
  local UIS = config.SV.UserInput
  local New, IsPress, Pointer = Explorer.UI.New, Explorer.UI.IsPress, Explorer.UI.Pointer
  local W, H = 700, 470
  local TAB_W, SEARCH_H, FOOT_H, ROW_H, HEAD_H, SB_W = 150, 32, 40, 24, 22, 12
  local VSPLIT = 0.46

  local C_SIDE = Color3.fromRGB(21, 22, 26)
  local C_PANEL = Color3.fromRGB(32, 33, 38)
  local C_HEAD = Color3.fromRGB(45, 46, 52)
  local C_HOVER = Color3.fromRGB(46, 47, 54)
  local C_LINE = Color3.fromRGB(50, 52, 60)
  local C_BTN = Color3.fromRGB(57, 59, 66)
  local C_BTN_HOVER = Color3.fromRGB(70, 73, 81)
  local C_FIELD = Color3.fromRGB(21, 22, 26)
  local C_TEXT = Color3.fromRGB(205, 205, 205)
  local C_DIM = Color3.fromRGB(105, 105, 110)
  local C_ACCENT = Color3.fromRGB(0, 92, 177)
  local C_CHECK = Color3.fromRGB(45, 150, 235)

  local current

  function Explorer.OpenSettings(cfg)
   cfg = cfg or {}
   if current then current() return end

   local win = Explorer:CreateWindow({ Name = "Settings", Size = Vector2.new(W, H) })
   local content = win.Content
   local function Conn(c) return win:Track(c) end
   local function Hover(obj, on, off, prop)
    prop = prop or "BackgroundColor3"
    obj.MouseEnter:Connect(function() obj[prop] = on end)
    obj.MouseLeave:Connect(function() obj[prop] = off end)
   end

   local tabs = cfg.Tabs or {}
   for _, tab in ipairs(tabs) do
    for _, cat in ipairs(tab.cats) do
     cat.lname = cat.name:lower()
     for _, it in ipairs(cat.items) do
      it.lname = it.name:lower()
      if it.default == nil then it.default = it.value end
     end
    end
   end

   local active = 1
   local filter = ""
   local SelectTab, Apply, SyncBar
   local closeDrop

   local searchBar = New("Frame", { BackgroundColor3 = C_FIELD, Size = UDim2.new(1, 0, 0, SEARCH_H) }, content)
   New("Frame", { BackgroundColor3 = C_LINE, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1) }, searchBar)
   do
    local lens = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(10, 10) }, searchBar)
    RoundCorner(lens, 1, 0)
    New("UIStroke", { Color = Color3.fromRGB(175, 175, 175), Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, lens)
    New("Frame", {
     BackgroundColor3 = Color3.fromRGB(175, 175, 175), AnchorPoint = Vector2.new(0.5, 0.5),
     Position = UDim2.fromOffset(20, 20), Size = UDim2.fromOffset(7, 2), Rotation = 45,
    }, searchBar)
   end
   local searchBox = New("TextBox", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -40, 1, 0),
    Text = "", PlaceholderText = "Search...", PlaceholderColor3 = Color3.fromRGB(130, 130, 135),
    ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
   }, searchBar)

   local side = New("Frame", {
    BackgroundColor3 = C_SIDE, Position = UDim2.fromOffset(0, SEARCH_H), Size = UDim2.new(0, TAB_W, 1, -(SEARCH_H + FOOT_H)),
   }, content)
   for i, tab in ipairs(tabs) do
    local btn = New("TextButton", {
     BackgroundColor3 = C_HOVER, BackgroundTransparency = 1,
     Position = UDim2.fromOffset(0, 4 + (i - 1) * 28), Size = UDim2.new(1, 0, 0, 26),
    }, side)
    tab.btn = btn
    tab.label = New("TextLabel", {
     BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -10, 1, 0),
     Text = tab.name, TextXAlignment = Enum.TextXAlignment.Left,
    }, btn)
    btn.MouseEnter:Connect(function() if active ~= i then btn.BackgroundTransparency = 0 end end)
    btn.MouseLeave:Connect(function() if active ~= i then btn.BackgroundTransparency = 1 end end)
    btn.Activated:Connect(function() SelectTab(i) end)
   end

   local panel = New("Frame", {
    BackgroundColor3 = C_PANEL, ClipsDescendants = true,
    Position = UDim2.fromOffset(TAB_W, SEARCH_H), Size = UDim2.new(1, -TAB_W, 1, -(SEARCH_H + FOOT_H)),
   }, content)
   local scroll = New("ScrollingFrame", {
    BackgroundTransparency = 1, Size = UDim2.new(1, -SB_W, 1, 0), ScrollBarThickness = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never,
   }, panel)
   local emptyLabel = New("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, -SB_W, 0, 24),
    Text = "No settings match your search", TextColor3 = C_DIM, Visible = false,
   }, panel)

   local bar = New("Frame", {
    BackgroundColor3 = Color3.fromRGB(34, 34, 38), Position = UDim2.new(1, -SB_W, 0, 0),
    Size = UDim2.new(0, SB_W, 1, 0), Active = true, Visible = false, ZIndex = 9,
   }, panel)
   local function ArrowBtn(up)
    local b = New("TextButton", {
     BackgroundColor3 = Color3.fromRGB(52, 52, 57), ZIndex = 10,
     Size = UDim2.fromOffset(SB_W, SB_W),
     Position = up and UDim2.fromOffset(0, 0) or UDim2.new(0, 0, 1, -SB_W),
    }, bar)
    BorderStroke(b, 1, 24, 24, 27)
    New("ImageLabel", {
     BackgroundTransparency = 1, Size = UDim2.fromOffset(9, 9), AnchorPoint = Vector2.new(0.5, 0.5),
     Position = UDim2.fromScale(0.5, 0.5), Image = config.IMG.Caret, Rotation = up and -90 or 90, ZIndex = 11,
    }, b)
    Hover(b, Color3.fromRGB(70, 70, 76), Color3.fromRGB(52, 52, 57))
    return b
   end
   local upBtn, downBtn = ArrowBtn(true), ArrowBtn(false)
   local track = New("Frame", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(0, SB_W), Size = UDim2.new(1, 0, 1, -SB_W * 2), ZIndex = 10,
   }, bar)
   local thumb = New("TextButton", {
    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0.2, 0), ZIndex = 11,
   }, track)
   local vis = New("Frame", {
    BackgroundColor3 = Color3.fromRGB(90, 90, 90), Position = UDim2.fromOffset(1, 0), Size = UDim2.new(1, -2, 1, 0), ZIndex = 11,
   }, thumb)
   local hovering, dragging = false, false
   local function Paint()
    vis.BackgroundColor3 = dragging and Color3.fromRGB(140, 140, 140) or hovering and Color3.fromRGB(120, 120, 120) or Color3.fromRGB(90, 90, 90)
   end
   thumb.MouseEnter:Connect(function() hovering = true Paint() end)
   thumb.MouseLeave:Connect(function() hovering = false Paint() end)

   SyncBar = function()
    local view, canvas = scroll.AbsoluteWindowSize.Y, scroll.AbsoluteCanvasSize.Y
    if canvas <= view + 0.5 or view <= 0 then bar.Visible = false return end
    bar.Visible = true
    local frac = math.clamp(view / canvas, 0.05, 0.85)
    local maxOff = canvas - view
    local pos = math.clamp(scroll.CanvasPosition.Y / maxOff * (1 - frac), 0, 1 - frac)
    thumb.Size = UDim2.new(1, 0, frac, 0)
    thumb.Position = UDim2.new(0, 0, pos, 0)
   end
   Conn(scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(SyncBar))
   Conn(scroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(SyncBar))
   Conn(scroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(SyncBar))

   Conn(thumb.InputBegan:Connect(function(inp)
    if not IsPress(inp) then return end
    dragging = true
    Paint()
    local startY, startCanvas = Pointer(inp).Y, scroll.CanvasPosition.Y
    local mc, ec
    local function stop()
     dragging = false
     Paint()
     if mc then mc:Disconnect() end
     if ec then ec:Disconnect() end
    end
    mc = Conn(UIS.InputChanged:Connect(function(i)
     if i.UserInputType == Enum.UserInputType.MouseMovement or i == inp then
      local view, canvas = scroll.AbsoluteWindowSize.Y, scroll.AbsoluteCanvasSize.Y
      local travel = track.AbsoluteSize.Y - thumb.AbsoluteSize.Y
      if travel > 0 then
       scroll.CanvasPosition = Vector2.new(0, startCanvas + (Pointer(i).Y - startY) / travel * (canvas - view))
      end
     end
    end))
    ec = Conn(UIS.InputEnded:Connect(function(i)
     if i == inp or (inp.UserInputType == Enum.UserInputType.MouseButton1 and i.UserInputType == Enum.UserInputType.MouseButton1) then stop() end
    end))
   end))
   Conn(track.InputBegan:Connect(function(inp)
    if not IsPress(inp) then return end
    local frac = (Pointer(inp).Y - track.AbsolutePosition.Y) / math.max(1, track.AbsoluteSize.Y)
    scroll.CanvasPosition = Vector2.new(0, frac * scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteWindowSize.Y / 2)
   end))
   for i, btn in ipairs({ upBtn, downBtn }) do
    local dir = i == 1 and -1 or 1
    local token = 0
    Conn(btn.InputBegan:Connect(function(inp)
     if not IsPress(inp) then return end
     token += 1
     local my = token
     scroll.CanvasPosition += Vector2.new(0, dir * ROW_H)
     task.spawn(function()
      task.wait(0.4)
      while token == my and content.Parent do
       scroll.CanvasPosition += Vector2.new(0, dir * ROW_H)
       task.wait(0.05)
      end
     end)
    end))
    Conn(UIS.InputEnded:Connect(function(inp) if IsPress(inp) then token += 1 end end))
   end

   local function BuildRow(parent, item, order)
    local row = New("Frame", { BackgroundColor3 = C_HOVER, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, ROW_H), LayoutOrder = order }, parent)
    New("Frame", { BackgroundColor3 = C_LINE, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1) }, row)
    New("TextLabel", {
     BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 0), Size = UDim2.new(VSPLIT, -22, 1, 0),
     Text = item.name, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    local cell = New("Frame", { BackgroundColor3 = C_FIELD, BackgroundTransparency = 1, Position = UDim2.new(VSPLIT, 0, 0, 0), Size = UDim2.new(1 - VSPLIT, 0, 1, -1) }, row)
    New("Frame", { BackgroundColor3 = C_LINE, Size = UDim2.new(0, 1, 1, 0), ZIndex = 2 }, cell)
    row.MouseEnter:Connect(function() row.BackgroundTransparency = 0 end)
    row.MouseLeave:Connect(function() row.BackgroundTransparency = 1 end)

    local function Set(v, silent)
     item.value = v
     if item.refresh then item.refresh() end
     if not silent and item.onChange then
      local ok, err = pcall(item.onChange, v)
      if not ok then warn("setting callback error: " .. tostring(err)) end
     end
    end
    item.set = Set
    local t = item.type

    if t == "toggle" then
     local box = New("Frame", { BackgroundColor3 = C_FIELD, Position = UDim2.fromOffset(8, 4), Size = UDim2.fromOffset(14, 14) }, cell)
     RoundCorner(box, 0, 2)
     BorderStroke(box, 1, 85, 87, 95)
     local check = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, box)
     New("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(4.3, 8.3), Size = UDim2.fromOffset(2, 4), Rotation = -45 }, check)
     New("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(8.4, 6.6), Size = UDim2.fromOffset(2, 8), Rotation = 45 }, check)
     local hit = New("TextButton", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, cell)
     hit.Activated:Connect(function() Set(not item.value) end)
     item.refresh = function()
      box.BackgroundColor3 = item.value and C_CHECK or C_FIELD
      check.Visible = item.value and true or false
     end
    elseif t == "text" or t == "number" then
     local box = New("TextBox", {
      BackgroundTransparency = 1, Position = UDim2.fromOffset(7, 0), Size = UDim2.new(1, -9, 1, 0),
      Text = "", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
     }, cell)
     box.Focused:Connect(function() cell.BackgroundTransparency = 0 end)
     box.FocusLost:Connect(function()
      cell.BackgroundTransparency = 1
      if t == "number" then
       local n = tonumber(box.Text)
       if n then Set(n) else item.refresh() end
      else
       Set(box.Text)
      end
     end)
     item.refresh = function() box.Text = tostring(item.value) end
    elseif t == "choice" then
     local btn = New("TextButton", {
      BackgroundTransparency = 1, Position = UDim2.fromOffset(7, 0), Size = UDim2.new(1, -9, 1, 0),
      TextXAlignment = Enum.TextXAlignment.Left,
     }, cell)
     btn.Activated:Connect(function()
      local idx = table.find(item.options, item.value) or 0
      Set(item.options[idx % #item.options + 1])
     end)
     item.refresh = function() btn.Text = tostring(item.value) end
    elseif t == "dropdown" then
     local btn = New("TextButton", {
      BackgroundTransparency = 1, Position = UDim2.fromOffset(7, 0), Size = UDim2.new(1, -24, 1, 0),
      TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
     }, cell)
     New("ImageLabel", {
      BackgroundTransparency = 1, Size = UDim2.fromOffset(9, 9), Position = UDim2.new(1, -16, 0.5, -5),
      Image = config.IMG.Caret, Rotation = 90,
     }, cell)
     local hit = New("TextButton", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2 }, cell)
     hit.Activated:Connect(function()
      local wasOpen = item.popup ~= nil
      if closeDrop then closeDrop() end
      if wasOpen then return end
      local opts, OH = item.options or {}, 22
      local layer = New("TextButton", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 50, AutoButtonColor = false, Text = "" }, content)
      local pop = New("Frame", {
       BackgroundColor3 = C_FIELD, ZIndex = 51,
       Position = UDim2.fromOffset(cell.AbsolutePosition.X - content.AbsolutePosition.X, cell.AbsolutePosition.Y - content.AbsolutePosition.Y + cell.AbsoluteSize.Y),
       Size = UDim2.fromOffset(cell.AbsoluteSize.X, #opts * OH),
      }, layer)
      BorderStroke(pop, 1, 85, 87, 95)
      for i, opt in ipairs(opts) do
       local ob = New("TextButton", {
        BackgroundColor3 = opt == item.value and C_ACCENT or C_FIELD, ZIndex = 52,
        Position = UDim2.fromOffset(0, (i - 1) * OH), Size = UDim2.new(1, 0, 0, OH),
        Text = "  " .. tostring(opt), TextXAlignment = Enum.TextXAlignment.Left,
       }, pop)
       local base = ob.BackgroundColor3
       Hover(ob, C_BTN_HOVER, base)
       ob.Activated:Connect(function()
        closeDrop()
        Set(opt)
       end)
      end
      item.popup = layer
      layer.Activated:Connect(function() closeDrop() end)
      closeDrop = function()
       item.popup = nil
       closeDrop = nil
       layer:Destroy()
      end
     end)
     item.refresh = function() btn.Text = tostring(item.value) end
    elseif t == "color" then
     local sw = New("Frame", { Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(9, 9) }, cell)
     BorderStroke(sw, 1, 90, 92, 100)
     local lbl = New("TextLabel", {
      BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -26, 1, 0),
      TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
     }, cell)
     local hit = New("TextButton", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, cell)
     hit.Activated:Connect(function()
      if Explorer.OpenColorPicker then
       Explorer.OpenColorPicker({ color = item.value, OnAccept = function(c) Set(c) end })
      end
     end)
     item.refresh = function()
      local c = item.value
      sw.BackgroundColor3 = c
      lbl.Text = `[{math.floor(c.R * 255 + 0.5)}, {math.floor(c.G * 255 + 0.5)}, {math.floor(c.B * 255 + 0.5)}]`
     end
    end
    item.refresh()
    item.row = row
   end

   for ti, tab in ipairs(tabs) do
    local page = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = ti == 1 }, scroll)
    New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, page)
    tab.page = page
    for ci, cat in ipairs(tab.cats) do
     local holder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = ci }, page)
     New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, holder)
     local head = New("TextButton", { BackgroundColor3 = C_HEAD, Size = UDim2.new(1, 0, 0, HEAD_H), LayoutOrder = 0 }, holder)
     cat.head = head
     cat.arrow = New("ImageLabel", {
      BackgroundTransparency = 1, Size = UDim2.fromOffset(9, 9), Position = UDim2.new(0, 6, 0.5, -5),
      Image = config.IMG.Caret, Rotation = 90,
     }, head)
     New("TextLabel", {
      BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -20, 1, 0),
      Text = cat.name, Font = Enum.Font.SourceSansBold, TextXAlignment = Enum.TextXAlignment.Left,
     }, head)
     Hover(head, Color3.fromRGB(55, 57, 64), C_HEAD)
     local body = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 }, holder)
     New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, body)
     cat.body = body
     for ii, it in ipairs(cat.items) do BuildRow(body, it, ii) end
     head.Activated:Connect(function()
      if filter ~= "" then return end
      cat.collapsed = not cat.collapsed
      Apply()
     end)
    end
   end

   Conn(scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    if closeDrop then closeDrop() end
   end))

   SelectTab = function(i)
    if closeDrop then closeDrop() end
    active = i
    for ti, tab in ipairs(tabs) do
     tab.page.Visible = ti == i
     tab.btn.BackgroundColor3 = ti == i and C_ACCENT or C_HOVER
     tab.btn.BackgroundTransparency = ti == i and 0 or 1
    end
    scroll.CanvasPosition = Vector2.zero
    task.defer(SyncBar)
   end

   Apply = function()
    local q = searchBox.Text:lower():match("^%s*(.-)%s*$")
    filter = q
    local total, first = 0, nil
    for ti, tab in ipairs(tabs) do
     local tm = 0
     for _, cat in ipairs(tab.cats) do
      local catHit = q ~= "" and cat.lname:find(q, 1, true) ~= nil
      local cm = 0
      for _, it in ipairs(cat.items) do
       local m = q == "" or catHit or it.lname:find(q, 1, true) ~= nil
       it.row.Visible = m
       if m then cm += 1 end
      end
      cat.head.Visible = q == "" or cm > 0
      local expanded = (q ~= "" and cm > 0) or (q == "" and not cat.collapsed)
      cat.body.Visible = expanded
      cat.arrow.Rotation = expanded and 90 or 0
      tm += cm
     end
     tab.matches = tm
     total += tm
     if tm > 0 and not first then first = ti end
     tab.label.TextColor3 = (q ~= "" and tm == 0) and C_DIM or C_TEXT
    end
    emptyLabel.Visible = q ~= "" and total == 0
    if q ~= "" and first and tabs[active].matches == 0 then SelectTab(first) end
    task.defer(SyncBar)
   end
   Conn(searchBox:GetPropertyChangedSignal("Text"):Connect(Apply))

   local footer = New("Frame", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -FOOT_H), Size = UDim2.new(1, 0, 0, FOOT_H),
   }, content)
   New("Frame", { BackgroundColor3 = C_LINE, Size = UDim2.new(1, 0, 0, 1) }, footer)
   local function FooterBtn(text, x, xs, w, onClick)
    local b = New("TextButton", {
     BackgroundColor3 = C_BTN, Position = UDim2.new(xs, x, 0, 8), Size = UDim2.fromOffset(w, 26), Text = text,
    }, footer)
    RoundCorner(b, 0, 2)
    Hover(b, C_BTN_HOVER, C_BTN)
    b.Activated:Connect(onClick)
    return b
   end
   FooterBtn("Reset All Settings", 8, 0, 140, function()
    for _, tab in ipairs(tabs) do
     for _, cat in ipairs(tab.cats) do
      for _, it in ipairs(cat.items) do it.set(it.default) end
     end
    end
   end)
   local function Close() win:Close() end
   FooterBtn("Close", -88, 1, 80, Close)
   win.OnClose = function()
    if current == Close then current = nil end
   end
   current = Close

   SelectTab(1)
   Apply()
  end
 end
