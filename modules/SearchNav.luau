local SearchNav
do
 local NAVH = 24
 local BASE_Y = 65
 local nav = Instance.new("Frame")
 nav.Name = RandomString()
 nav.Size = UDim2.new(1, 0, 0, NAVH)
 nav.Position = UDim2.new(0, 0, 0, BASE_Y)
 nav.BackgroundTransparency = 1
 nav.BorderSizePixel = 0
 nav.ZIndex = 4
 nav.Visible = false
 nav.Archivable = false
 nav.Parent = config.main
 SearchNav = nav

 local label = Instance.new("TextLabel")
 label.Name = RandomString()
 label.Position = UDim2.fromOffset(12, 0)
 label.Size = UDim2.new(1, -130, 1, 0)
 label.BackgroundTransparency = 1
 label.Text = ""
 label.TextColor3 = config.COLORS.TEXT
 label.Font = Enum.Font.SourceSans
 label.TextSize = 15
 label.TextXAlignment = Enum.TextXAlignment.Left
 label.ZIndex = 5
 label.Archivable = false
 label.Parent = nav

 local function Btn(imgKey, fromRight)
  local b = Instance.new("ImageButton")
  b.Name = RandomString()
  b.AnchorPoint = Vector2.new(1, 0.5)
  b.Position = UDim2.new(1, -fromRight, 0.5, 0)
  b.Size = UDim2.fromOffset(20, 20)
  b.BackgroundTransparency = 1
  b.Image = config.IMG[imgKey] or ""
  b.ImageColor3 = Color3.fromRGB(140, 140, 140)
  b.ScaleType = Enum.ScaleType.Fit
  b.AutoButtonColor = false
  b.BorderSizePixel = 0
  b.ZIndex = 5
  b.Archivable = false
  b.Parent = nav
  b.MouseEnter:Connect(function() b.ImageColor3 = Color3.fromRGB(200, 200, 200) end)
  b.MouseLeave:Connect(function() b.ImageColor3 = Color3.fromRGB(140, 140, 140) end)
  return b
 end
 -- left to right: back, forward, select all, refresh
 local refB = Btn("Refresh", 10)
 local allB = Btn("Select", 36)
 local nextB = Btn("SearchForward", 62)
 local prevB = Btn("SearchBack", 88)

 local function Hits()
  local hits = {}
  for i, row in ipairs(config.visiblerows) do
   if row.match then hits[#hits + 1] = i end
  end
  return hits
 end

 local shown = false
 local function SetLayout(show)
  if show == shown then return end
  shown = show
  nav.Visible = show
  local off = BASE_Y + (show and NAVH or 0)
  config.body.Position = UDim2.new(0, 0, 0, off)
  config.body.Size = UDim2.new(1, 0, 1, -off)
  RefreshTree()
 end

 local function Update()
  local show = config.SearchQuery ~= ""
  SetLayout(show)
  if not show then return end
  local n = #Hits()
  label.Text = n == 0 and "No matches" or (n .. (n == 1 and " match" or " matches"))
 end
 Explorer.SearchNavUpdate = Update

 function Explorer.SearchStep(dir)
  local hits = Hits()
  if #hits == 0 then return end
  if dir < 0 then
   config.SearchCursor = ((config.SearchCursor - 2) % #hits) + 1
  else
   config.SearchCursor = (config.SearchCursor % #hits) + 1
  end
  SelectRowAt(hits[config.SearchCursor])
 end

 function Explorer.SearchSelectAll()
  local list = {}
  for _, row in ipairs(config.visiblerows) do
   if row.match then list[#list + 1] = row.instance end
  end
  if #list == 0 then return end
  Explorer.SetSelection(list, list[#list])
 end

 function Explorer.SearchRefresh()
  if config.SearchQuery == "" then return end
  config.SearchPred = Explorer.CompileSearch(config.searchbar.Text)
  config.SearchCursor = 0
  Explorer.SearchOpen = setmetatable({}, {__mode = "k"})
  if Explorer.ResetDeepLoad then Explorer.ResetDeepLoad() end
  Explorer.ScanTree()
  RefreshTree()
  if Explorer.EnsureDeepLoad then Explorer.EnsureDeepLoad() end
  Update()
 end

 prevB.Activated:Connect(function() Explorer.SearchStep(-1) end)
 nextB.Activated:Connect(function() Explorer.SearchStep(1) end)
 allB.Activated:Connect(function() Explorer.SearchSelectAll() end)
 refB.Activated:Connect(function() Explorer.SearchRefresh() end)

 task.spawn(function()
  while nav.Parent do
   task.wait(0.2)
   pcall(Update)
  end
 end)
end
