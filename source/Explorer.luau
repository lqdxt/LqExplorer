local config = {
 ROW_H = 25,
 ScrollIndex = 0,
 ScrollHOffset = 0,
 TreeContentWidth = 0,
 DOUBLE_CLICK = 0.38,
 EDGE = 8,
 IsMinimized = false,
 NT = 0,
 LastClickedTime = {},
 SearchQuery = "",
 SearchPred = nil,
 SearchCursor = 0,
 Anchor = nil,
 IncrementNames = true,
 ExpandOnSelect = true,
 SelectAfterInsert = true,
 ShowHierarchyHighlights = true,
 ShowHiddenServices = true,
 ContextMenu = nil,
 ContextMenuTarget = nil,
 NormalSize = UDim2.new(0, 340, 0, 280),
 MinimizedSize = UDim2.new(0, 340, 0, 44),
 DockSide = nil,
 entries = {},
 pooldata = {},
 visiblerows = {},
 guideLines = {},
}

local function MakeFolder(tree)
 if not makefolder or not isfolder then return end
 for _, folder in ipairs(tree) do
  local current = ""
  for seg in folder:gsub("\\", "/"):gmatch("[^/]+") do
   current = current == "" and seg or (current .. "/" .. seg)
   if not isfolder(current) then
    pcall(makefolder, current)
   end
  end
 end
end

MakeFolder({
 "LqExplorer",
 "LqExplorer/images",
})

config.ServiceCache = {}
local function GetService(name)
 if config.ServiceCache[name] then return config.ServiceCache[name] end
 local ok, svc = pcall(game.GetService, game, name)
 if ok then
  config.ServiceCache[name] = svc
  return svc
 end
 return nil
end

cloneref = cloneref or function(ref)
 if not getreg then return ref end
 
 local InstanceList
 
 local a = Instance.new("Part")
 for _, c in pairs(getreg()) do
  if type(c) == "table" and #c then
   if rawget(c, "__mode") == "kvs" then
    for d, e in pairs(c) do
     if e == a then
      InstanceList = c
      break
     end
    end
   end
  end
 end
 local f = {}
 function f.Invalidate(g: any): any
  if not InstanceList then
   return
  end
  for b, c in pairs(InstanceList) do
   if c == g then
    InstanceList[b] = nil
    return g
   end
  end
  return nil
 end
 return f.Invalidate
end

config.SV = {
 UserInput = cloneref(GetService("UserInputService")),
 Tween = cloneref(GetService("TweenService")),
 TextSrv = cloneref(GetService("TextService")),
 CoreGui = cloneref(GetService("CoreGui")),
 RunSrv = cloneref(GetService("RunService")),
 ContextAction = cloneref(GetService("ContextActionService")),
 Gui = cloneref(GetService("GuiService")),
 Http = cloneref(GetService("HttpService")),
}

local function RandomString()
 local n = math.random(35, 45)
 local t = {}
 for i = 1, n do t[i] = string.char(math.random(32, 126)) end
 return table.concat(t)
end

local function RoundPx(n) return math.floor(n + 0.5) end

config.Frame = 0
config.LastPressFrame = -1
config.SV.RunSrv.Heartbeat:Connect(function() config.Frame += 1 end)
config.SV.UserInput.InputBegan:Connect(function(inp)
 if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
  config.LastPressFrame = config.Frame
 end
end)
config.Fresh = function(inp)
 local f = config.Frame
 config.SV.RunSrv.Heartbeat:Wait()
 return math.abs(config.LastPressFrame - f) <= 2
end
config.WidenHit = function(thumb, horizontal)
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
  if not thumb:IsDescendantOf(config.window) then
   conn:Disconnect()
   hit:Destroy()
   return
  end
  local top, shown = thumb, true
  while top.Parent and top.Parent ~= config.window do
   if top:IsA("GuiObject") and not top.Visible then shown = false end
   top = top.Parent
  end
  if top:IsA("GuiObject") and not top.Visible then shown = false end
  local as = thumb.AbsoluteSize
  if not shown or top.Parent ~= config.window or as.X <= 0 or as.Y <= 0 then
   hit.Visible = false
   return
  end
  local ap = thumb.AbsolutePosition - config.window.AbsolutePosition
  local x, y, w, h
  if horizontal then
   x, y, w, h = ap.X - 10, ap.Y - 28, as.X + 20, as.Y + 28
  else
   x, y, w, h = ap.X - 28, ap.Y - 10, as.X + 28, as.Y + 20
  end
  hit.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
  hit.Size = UDim2.fromOffset(math.ceil(w), math.ceil(h))
  hit.ZIndex = top:IsA("GuiObject") and top.ZIndex + 1 or 2
  hit.Visible = true
 end)
 return hit
end
config.Held = function(inp)
 if inp.UserInputType == Enum.UserInputType.MouseMovement then
  return config.SV.UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
 end
 return true
end
local function IsPress(inp)
 return inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch
end

local function AbsOf(inp, gui)
 local p = Vector2.new(inp.Position.X, inp.Position.Y)
 local gi = Vector2.new(0, 0)
 if config.SV.Gui then
  local ok, v = pcall(function() return config.SV.Gui:GetGuiInset() end)
  if ok and v then gi = v end
 end
 if gui then
  local ap, as = gui.AbsolutePosition, gui.AbsoluteSize
  local lo, hi = ap.Y - p.Y, ap.Y + as.Y - p.Y
  if gi.Y >= lo - 2 and gi.Y <= hi + 2 then return p + gi end
  if 0 >= lo - 2 and 0 <= hi + 2 then return p end
 end
 return p + gi
end

config.COLORS = {
 PRIMARY = Color3.fromRGB(28,29,35),
 SECONDARY = Color3.fromRGB(61,64,71),
 RESIZER = Color3.fromRGB(63,67,75),
 SELECTED = Color3.fromRGB(0,51,225),
 SELECTED_HOVER = Color3.fromRGB(45,91,242),
 HEADER = Color3.fromRGB(43,44,50),
 TEXT = Color3.fromRGB(200,200,200),
 TEXT_BRIGHT = Color3.fromRGB(220,220,220),
 TEXT_DIM = Color3.fromRGB(100,100,100),
 WHITE = Color3.fromRGB(255,255,255),
 CLOSE_TEXT = Color3.fromRGB(255,80,80),
 CLOSE_BG = Color3.fromRGB(255,60,60),
 SCROLL = Color3.fromRGB(70,70,70),
 ACCENT = Color3.fromRGB(100,160,255),
}

config.FONT = {
 GothamBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
 GothamMedium = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
 GothamRegular = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
}

local function ComputeResponsiveWidth(w)
 return math.clamp(math.floor(w * 0.3), 100, 500)
end

local Explorer
local VirtualInstance = {}
config.LAZY_TABLES = { Attributes = true, Properties = true, Metadata = true }
VirtualInstance.__index = function(t, k)
 local m = VirtualInstance[k]
 if m ~= nil then return m end
 if config.LAZY_TABLES[k] then
  local n = {}
  rawset(t, k, n)
  return n
 end
 return nil
end

function VirtualInstance.new(className, name, parent)
 local self = setmetatable({
  Name = name or className or "Instance",
  ClassName = className or "Instance",
  Parent = nil,
  Children = {},
 }, VirtualInstance)
 if parent then self:SetParent(parent) end
 return self
end

function VirtualInstance:SetParent(parent)
 local old = self.Parent
 if old then
  local ch = old.Children
  for i = #ch, 1, -1 do
   if ch[i] == self then table.remove(ch, i) break end
  end
  old._sorted = nil
 end
 self.Parent = parent
 if parent then
  table.insert(parent.Children, self)
  parent._sorted = nil
 end
end

function VirtualInstance:Destroy()
 self:SetParent(nil)
 for _, c in ipairs(self.Children) do c.Parent = nil end
 self.Children = {}
 self._sorted = nil
 Explorer.Expanded[self] = nil
end

function VirtualInstance:GetFullName()
 local parts, cur = {}, self
 while cur and cur ~= Explorer.Root do
  table.insert(parts, 1, cur.Name)
  cur = cur.Parent
 end
 return table.concat(parts, ".")
end

config.Root = setmetatable({
 Name = "<root>",
 ClassName = "Root",
 Parent = nil,
 Children = {},
}, VirtualInstance)

config.NATURAL_SORT = false
config.CLASS_PRIORITY = { Camera = 1, Terrain = 2 }

local function PadNum(d)
 return string.rep("0", 10 - #d) .. d
end

local function RefreshKey(n)
 local name, cls = n.Name, n.ClassName
 local md = rawget(n, "Metadata")
 local o = md and md.Order
 if n._skName ~= name or n._skCls ~= cls or n._skOrd ~= o then
  n._skName, n._skCls, n._skOrd = name, cls, o
  if o then
   n._sk = "\1" .. string.format("%08d", o)
  else
   local nm = tostring(name):lower()
   if config.NATURAL_SORT then
    nm = nm:gsub("%d+", function(d) return #d <= 10 and PadNum(d) or d end)
   end
   n._sk = tostring(config.CLASS_PRIORITY[cls] or 3) .. nm
  end
 end
 return n._sk
end

local function SortedChildren(inst)
 local kids = inst.Children
 local n = #kids
 local cache = inst._sorted
 if cache and inst._live and #cache == n then return cache end
 if cache and #cache == n then
  local ok, prev = true, nil
  for i = 1, n do
   local k = RefreshKey(cache[i])
   if prev and k < prev then ok = false break end
   prev = k
  end
  if ok then return cache end
 end
 local keys, map = table.create(n), {}
 for i = 1, n do
  local c = kids[i]
  local k = RefreshKey(c) .. "\0" .. string.format("%08d", i)
  keys[i] = k
  map[k] = c
 end
 table.sort(keys)
 local out = table.create(n)
 for i = 1, n do out[i] = map[keys[i]] end
 inst._sorted = out
 inst._live = nil
 return out
end

Explorer = {
 Root = config.Root,
 SelectedSet = {},
 Clipboard = {},
 Expanded = setmetatable({}, {__mode="k"}),
 SearchOpen = setmetatable({}, {__mode="k"}),
 Selected = nil,
 ContextItems = {},
 UserIcons = {},
 Settings = {},
 Images = (function()
  local base = "https://raw.githubusercontent.com/lqdxt/LqExplorer/main/images/"
  local function Img(file) return { Url = base .. file, File = file } end
  return {
   ClassIcons = Img("studio-icon-map.png"),
   Caret = Img("caret-small-right.png"),
   Options = Img("three-dots-horizontal.png"),
   History = Img("clock-spin-reverse.png"),
   Rotation = Img("arrow-spin-counter-clockwise.png"),
   ZoomIn = Img("magnifying-glass-plus.png"),
   ZoomOut = Img("magnifying-glass-minus.png"),
  }
 end)(),
 OnSelectCb = nil,
 OnDoubleClickCb = nil,
 OnRightClickCb = nil,
 PanelResizing = setmetatable({}, {__mode="k"}),
}

config.Positions = {
 ARROW_X = math.floor(config.ROW_H * 0.4 + 0.5),
 ICON_X = math.floor(config.ROW_H * 1 + 0.5),
 TEXT_X = math.floor(config.ROW_H * 2.25 + 0.5),
 INDENT = math.floor(config.ROW_H * 0.67 + 0.5),
 ICON_PX = math.floor(config.ROW_H * 0.9 + 0.5),
}

local function RoundCorner(inst, scale, radius)
 local c = Instance.new("UICorner")
 c.Name = RandomString()
 c.CornerRadius = UDim.new(scale, radius)
 c.Archivable = false
 c.Parent = inst
 return c
end

local function BorderStroke(inst, thickness, R, G, B)
 local s = Instance.new("UIStroke")
 s.Name = RandomString()
 s.Thickness = thickness or 1.5
 s.Color = (R and G and B) and Color3.fromRGB(R, G, B) or Color3.fromRGB(60, 60, 60)
 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
 s.Archivable = false
 s.Parent = inst
 return s
end

local function DropStroke(inst)
 local st = Instance.new("UIStroke")
 st.Color = Color3.fromRGB(0, 0, 0)
 st.Thickness = 1
 st.Archivable = false
 st.Parent = inst
 return st
end

config.AssetCache = {}

function Explorer.GetImage(name)
 local v = Explorer.Images[name]
 if type(v) == "table" then
  return Explorer.GetAsset(v.Url, "LqExplorer/images/" .. v.File)
 end
 return v
end

function Explorer.ApplyImage(gui, name)
 task.spawn(function()
  local ok, asset = pcall(Explorer.GetImage, name)
  if ok and asset and gui.Parent then gui.Image = asset end
 end)
end

function Explorer.GetAsset(url, name)
 if config.AssetCache[name] then return config.AssetCache[name] end

 local content
 if isfile and isfile(name) then
  content = readfile(name)
 end

 if not content then
  content = game:HttpGet(url)
  local dir = name:match("^(.*)/[^/]+$")
  if dir and dir ~= "" and makefolder then
   local built = ""
   for seg in dir:gmatch("[^/]+") do
    built = built == "" and seg or (built .. "/" .. seg)
    pcall(makefolder, built)
   end
  end
  if writefile then pcall(writefile, name, content) end
 end

 local asset = getcustomasset(name)
 config.AssetCache[name] = asset
 return asset
end

local function MakeCheckBox(parent, size, z)
 local box = Instance.new("Frame")
 box.Name = RandomString()
 box.Size = UDim2.new(0, size, 0, size)
 box.BackgroundColor3 = Color3.fromRGB(20, 21, 26)
 box.BorderSizePixel = 0
 box.ZIndex = z
 box.Archivable = false
 box.Parent = parent
 BorderStroke(box, 1, 90, 90, 90)
 local arms = {}
 local s = size / 16
 local function Arm(len, cx, cy, rot)
  local f = Instance.new("Frame")
  f.Name = RandomString()
  f.Size = UDim2.new(0, math.max(1, math.floor(2 * s + 0.5)), 0, len * s)
  f.AnchorPoint = Vector2.new(0.5, 0.5)
  f.Position = UDim2.new(0, cx * s, 0, cy * s)
  f.Rotation = rot
  f.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
  f.BorderSizePixel = 0
  f.ZIndex = z + 1
  f.Visible = false
  f.Archivable = false
  f.Parent = box
  arms[#arms + 1] = f
 end
 Arm(5.5, 4.75, 10, -45)
 Arm(10, 9.75, 8.5, 45)
 local function Set(on)
  box.BackgroundColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(20, 21, 26)
  for _, a in ipairs(arms) do a.Visible = on and true or false end
 end
 return box, Set
end

local function MakeStudioCheckBox(parent, size, z)
 local box = Instance.new("Frame")
 box.Name = RandomString()
 box.Size = UDim2.new(0, size, 0, size)
 box.BackgroundColor3 = Color3.fromRGB(59, 91, 243)
 box.BackgroundTransparency = 1
 box.BorderSizePixel = 0
 box.ZIndex = z
 box.Archivable = false
 box.Parent = parent
 RoundCorner(box, 0, 4)
 local stroke = BorderStroke(box, 1.5, 215, 215, 220)
 local arms = {}
 local s = size / 16
 local function Arm(len, cx, cy, rot)
  local f = Instance.new("Frame")
  f.Name = RandomString()
  f.Size = UDim2.new(0, 2, 0, math.floor(len * s + 0.5))
  f.AnchorPoint = Vector2.new(0.5, 0.5)
  f.Position = UDim2.new(0, math.floor(cx * s + 0.5), 0, math.floor(cy * s + 0.5))
  f.Rotation = rot
  f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
  f.BorderSizePixel = 0
  f.ZIndex = z + 1
  f.Visible = false
  f.Archivable = false
  f.Parent = box
  arms[#arms + 1] = f
 end
 Arm(4.8, 5.1, 10.1, -45)
 Arm(9.8, 9.6, 8, 40.6)
 local function Set(on)
  on = on and true or false
  box.BackgroundTransparency = on and 0 or 1
  stroke.Color = on and Color3.fromRGB(59, 91, 243) or Color3.fromRGB(215, 215, 220)
  for _, a in ipairs(arms) do a.Visible = on end
 end
 return box, Set
end

local function MakePinIcon(parent, size, z, color)
 local box = Instance.new("Frame")
 box.Name = RandomString()
 box.Size = UDim2.new(0, size, 0, size)
 box.AnchorPoint = Vector2.new(0.5, 0.5)
 box.Position = UDim2.new(0.5, 0, 0.5, 0)
 box.BackgroundTransparency = 1
 box.Active = false
 box.ZIndex = z
 box.Archivable = false
 box.Parent = parent
 local s = size / 16
 local function Px(v) return math.floor(v * s + 0.5) end
 local function MakeRect(x, y, w, h, rot, anchored)
  local f = Instance.new("Frame")
  f.Name = RandomString()
  f.Size = UDim2.new(0, w, 0, h)
  if anchored then
   f.AnchorPoint = Vector2.new(0.5, 0.5)
  end
  f.Position = UDim2.new(0, x, 0, y)
  f.Rotation = rot or 0
  f.BackgroundColor3 = color
  f.BorderSizePixel = 0
  f.Active = false
  f.ZIndex = z
  f.Archivable = false
  f.Parent = box
 end
 local t = math.max(1, math.floor(1.5 * s))
 local bl, bt, bb = Px(0), Px(6.5), Px(16)
 local br, bTopEnd, bRightTop = Px(9.5), Px(5), Px(11)
 MakeRect(bl, bt, t, bb - bt)
 MakeRect(bl, bb - t, br - bl, t)
 MakeRect(bl, bt, bTopEnd - bl, t)
 MakeRect(br - t, bRightTop, t, bb - bRightTop)
 local hl, ht, hp = Px(6), Px(2), Px(8)
 for j = 0, hp - 1 do
  MakeRect(hl, ht + j, j + 1, 1)
 end
 local len = 7 * s
 local mx, my = hl + hp / 2, ht + hp / 2
 local k = 0.70710678 * len / 2
 MakeRect(mx + k, my - k, t, len, 45, true)
 return box
end

local function MakeCloseIcon(parent, size, z, color)
 size = size - (size % 2)
 local box = Instance.new("Frame")
 box.Name = RandomString()
 box.Size = UDim2.new(0, size, 0, size)
 box.AnchorPoint = Vector2.new(0.5, 0.5)
 box.Position = UDim2.new(0.5, 0, 0.5, 0)
 box.BackgroundTransparency = 1
 box.Active = false
 box.ZIndex = z
 box.Archivable = false
 box.Parent = parent
 local len = math.floor(size * 1.41421356 + 0.5)
 local arms = {}
 for _, rot in ipairs({ 45, -45 }) do
  local f = Instance.new("Frame")
  f.Name = RandomString()
  f.Size = UDim2.new(0, len, 0, 2)
  f.AnchorPoint = Vector2.new(0.5, 0.5)
  f.Position = UDim2.new(0.5, 0, 0.5, 0)
  f.Rotation = rot
  f.BackgroundColor3 = color
  f.BorderSizePixel = 0
  f.Active = false
  f.ZIndex = z
  f.Archivable = false
  f.Parent = box
  arms[#arms + 1] = f
 end
 return box, arms
end

local function MakeChevron(parent, z)
 local c = Instance.new("Frame")
 c.Name = RandomString()
 c.Size = UDim2.new(0, 12, 0, 8)
 c.BackgroundTransparency = 1
 c.ZIndex = z
 c.Archivable = false
 c.Parent = parent
 for _, d in ipairs({ { 3.5, -45 }, { 8.5, 45 } }) do
  local f = Instance.new("Frame")
  f.Name = RandomString()
  f.Size = UDim2.new(0, 2, 0, 6)
  f.AnchorPoint = Vector2.new(0.5, 0.5)
  f.Position = UDim2.new(0, d[1], 0, 3.5)
  f.Rotation = d[2]
  f.BackgroundColor3 = Color3.fromRGB(190, 190, 190)
  f.BorderSizePixel = 0
  f.ZIndex = z
  f.Archivable = false
  f.Parent = c
 end
 return c
end

local function MakePlus(parent, z)
 local b = Instance.new("TextButton")
 b.Name = RandomString()
 b.Size = UDim2.new(0, 18, 0, 18)
 b.BackgroundTransparency = 1
 b.BorderSizePixel = 0
 b.AutoButtonColor = false
 b.Text = ""
 b.ZIndex = z
 b.Archivable = false
 b.Parent = parent
 local ring = Instance.new("Frame")
 ring.Name = RandomString()
 ring.Size = UDim2.new(0, 14, 0, 14)
 ring.Position = UDim2.new(0.5, -7, 0.5, -7)
 ring.BackgroundColor3 = Color3.fromRGB(190, 190, 190)
 ring.BorderSizePixel = 0
 ring.ZIndex = z + 1
 ring.Archivable = false
 ring.Parent = b
 RoundCorner(ring, 1, 0)
 for _, d in ipairs({ { 8, 2 }, { 2, 8 } }) do
  local bar = Instance.new("Frame")
  bar.Name = RandomString()
  bar.Size = UDim2.new(0, d[1], 0, d[2])
  bar.Position = UDim2.new(0.5, -d[1] / 2, 0.5, -d[2] / 2)
  bar.BackgroundColor3 = config.COLORS.PRIMARY
  bar.BorderSizePixel = 0
  bar.ZIndex = z + 1
  bar.Archivable = false
  bar.Parent = b
 end
 return b
end

local function MakeCross(parent, z)
 local b = Instance.new("TextButton")
 b.Name = RandomString()
 b.Size = UDim2.new(0, 18, 0, 18)
 b.BackgroundTransparency = 1
 b.BorderSizePixel = 0
 b.AutoButtonColor = false
 b.Text = ""
 b.ZIndex = z
 b.Archivable = false
 b.Parent = parent
 for _, rot in ipairs({ 45, -45 }) do
  local f = Instance.new("Frame")
  f.Name = RandomString()
  f.Size = UDim2.new(0, 2, 0, 11)
  f.AnchorPoint = Vector2.new(0.5, 0.5)
  f.Position = UDim2.new(0.5, 0, 0.5, 0)
  f.Rotation = rot
  f.BackgroundColor3 = Color3.fromRGB(190, 190, 190)
  f.BorderSizePixel = 0
  f.ZIndex = z + 1
  f.Archivable = false
  f.Parent = b
 end
 return b
end

local function MakeDots(parent, z)
 local b = Instance.new("TextButton")
 b.Name = RandomString()
 b.Size = UDim2.new(0, 18, 0, 18)
 b.BackgroundTransparency = 1
 b.BorderSizePixel = 0
 b.AutoButtonColor = false
 b.Text = ""
 b.ZIndex = z
 b.Archivable = false
 b.Parent = parent
 for i = 0, 2 do
  local d = Instance.new("Frame")
  d.Name = RandomString()
  d.Size = UDim2.new(0, 3, 0, 3)
  d.Position = UDim2.new(0.5, -1.5, 0.5, -7 + i * 5.5)
  d.BackgroundColor3 = Color3.fromRGB(190, 190, 190)
  d.BorderSizePixel = 0
  d.ZIndex = z + 1
  d.Archivable = false
  d.Parent = b
  RoundCorner(d, 1, 0)
 end
 return b
end

config.IMG = {}
for _, key in ipairs({ "ClassIcons", "Caret", "Options", "History", "Rotation", "ZoomIn", "ZoomOut" }) do
 local ok, asset = pcall(Explorer.GetImage, key)
 config.IMG[key] = (ok and asset) or ""
end
config.ICON_ID = config.IMG.ClassIcons
config.ICON_SIZE = Vector2.new(32, 32)
config.ICONS = {
 ["Accessory"]={1,1},
 ["Actor"]={1,2},
 ["AdGui"]={1,3},
 ["AdPortal"]={1,4},
 ["AirController"]={1,5},
 ["AlignOrientation"]={1,6},
 ["AlignPosition"]={1,7},
 ["AngularVelocity"]={1,8},
 ["Animation"]={1,9},
 ["AnimationConstraint"]={1,10},
 ["AnimationController"]={1,11},
 ["AnimationFromVideoCreatorService"]={1,12},
 ["Animator"]={1,13},
 ["ArcHandles"]={1,14},
 ["Atmosphere"]={1,15},
 ["Attachment"]={1,16},
 ["AudioAnalyzer"]={1,17},
 ["AudioChannelMixer"]={1,18},
 ["AudioChannelSplitter"]={2,1},
 ["AudioChorus"]={2,2},
 ["AudioCompressor"]={2,3},
 ["AudioDeviceInput"]={2,4},
 ["AudioDeviceOutput"]={2,5},
 ["AudioDistortion"]={2,6},
 ["AudioEcho"]={2,7},
 ["AudioEmitter"]={2,8},
 ["AudioEqualizer"]={2,9},
 ["AudioFader"]={2,10},
 ["AudioFilter"]={2,11},
 ["AudioFlanger"]={2,12},
 ["AudioGate"]={2,13},
 ["AudioLimiter"]={2,14},
 ["AudioListener"]={2,15},
 ["AudioPitchShifter"]={2,16},
 ["AudioPlayer"]={2,17},
 ["AudioRecorder"]={2,18},
 ["AudioReverb"]={3,1},
 ["AudioTextToSpeech"]={3,2},
 ["CoreScripts"] = {3,3},
 ["AvatarEditorService"]={3,4},
 ["AvatarSettings"]={3,5},
 ["Backpack"]={3,6},
 ["BallSocketConstraint"]={3,7},
 ["Beam"]={3,9},
 ["BillboardGui"]={3,10},
 ["BindableEvent"]={3,11},
 ["BindableFunction"]={3,12},
 ["BlockMesh"]={3,13},
 ["BloomEffect"]={3,14},
 ["BlurEffect"]={3,15},
 ["BodyAngularVelocity"]={3,16},
 ["BodyColors"]={3,17},
 ["BodyForce"]={3,18},
 ["BodyGyro"]={4,1},
 ["BodyPosition"]={4,2},
 ["BodyThrust"]={4,3},
 ["BodyVelocity"]={4,4},
 ["Bone"]={4,5},
 ["BoolValue"]={4,6},
 ["BoxHandleAdornment"]={4,7},
 ["Breakpoint"]={4,8},
 ["BrickColorValue"]={4,9},
 ["BubbleChatConfiguration"]={4,10},
 ["CalloutService"]={4,11},
 ["Camera"]={4,12},
 ["CanvasGroup"]={4,13},
 ["CFrameValue"]={4,14},
 ["ChannelTabsConfiguration"]={4,15},
 ["CharacterMesh"]={4,17},
 ["Chat"]={4,18},
 ["ChatInputBarConfiguration"]={5,1},
 ["ChatWindowConfiguration"]={5,2},
 ["ChorusSoundEffect"]={5,3},
 ["ClickDetector"]={5,6},
 ["ClientReplicator"]={5,7},
 ["ClimbController"]={5,8},
 ["Clouds"]={5,9},
 ["ColorCorrectionEffect"]={5,11},
 ["CompressorSoundEffect"]={5,12},
 ["ConeHandleAdornment"]={5,13},
 ["Configuration"]={5,14},
 ["ContextActionService"]={5,16},
 ["Controller"]={5,17},
 ["CoreGui"]={5,18},
 ["CornerWedgePart"]={6,1},
 ["CylinderHandleAdornment"]={6,2},
 ["CylindricalConstraint"]={6,3},
 ["Decal"]={6,4},
 ["DepthOfFieldEffect"]={6,5},
 ["Dialog"]={6,6},
 ["DialogChoice"]={6,7},
 ["DistortionSoundEffect"]={6,8},
 ["EqualizerSoundEffect"]={6,15},
 ["Explosion"]={6,17},
 ["FaceControls"]={6,18},
 ["Fire"]={7,3},
 ["FlangeSoundEffect"]={7,4},
 ["Folder"]={7,5},
 ["ForceField"]={7,6},
 ["Frame"]={7,7},
 ["GameSettings"]={7,9},
 ["Handles"]={7,11},
 ["HapticEffect"]={7,12},
 ["HapticService"]={7,13},
 ["HeightmapImporterService"]={7,14},
 ["Highlight"]={7,15},
 ["HingeConstraint"]={7,16},
 ["Humanoid"]={7,17},
 ["HumanoidDescription"]={7,18},
 ["IKControl"]={8,1},
 ["ImageButton"]={8,2},
 ["ImageHandleAdornment"]={8,3},
 ["ImageLabel"]={8,4},
 ["InputAction"]={8,5},
 ["InputBinding"]={8,6},
 ["InputContext"]={8,7},
 ["IntersectOperation"]={8,8},
 ["Lighting"]={8,11},
 ["LineForce"]={8,12},
 ["LinearVelocity"]={8,13},
 ["LineHandleAdornment"]={8,14},
 ["LocalizationService"]={8,16},
 ["LocalizationTable"]={8,17},
 ["LocalScript"]={8,18},
 ["MaterialService"]={9,1},
 ["MaterialVariant"]={9,2},
 ["MemoryStoreService"]={9,3},
 ["MeshPart"]={9,4},
 ["MessagingService"]={9,6},
 ["Model"]={9,8},
 ["ModuleScript"]={9,11},
 ["Motor6D"]={9,12},
 ["NegateOperation"]={9,13},
 ["NetworkClient"]={9,14},
 ["NoCollisionConstraint"]={9,15},
 ["Plugin"]={9,16},
 ["PackageLink"]={9,17},
 ["Pants"]={9,18},
 ["Part"]={10,1},
 ["ParticleEmitter"]={10,2},
 ["Path2D"]={10,3},
 ["PathfindingLink"]={10,4},
 ["PathfindingModifier"]={10,5},
 ["PathfindingService"]={10,6},
 ["PitchShiftSoundEffect"]={10,7},
 ["File"]={10,8},
 ["Instance"]={10,9},
 ["Plane"]={10,10},
 ["PlaneConstraint"]={10,11},
 ["Player"]={10,12},
 ["Players"]={10,13},
 ["PluginGuiService"]={10,14},
 ["PointLight"]={10,15},
 ["PrismaticConstraint"]={10,16},
 ["ProximityPrompt"]={10,18},
 ["PublishService"]={11,1},
 ["RemoteEvent"]={11,3},
 ["RemoteFunction"]={11,4},
 ["RenderingTest"]={11,5},
 ["ReplicatedFirst"]={11,6},
 ["ScriptService"]={11,7},
 ["ReplicatedStorage"]={11,8},
 ["ReverbSoundEffect"]={11,9},
 ["RigidConstraint"]={11,10},
 ["RobloxPluginGuiService"]={11,11},
 ["RocketPropulsion"]={11,12},
 ["RodConstraint"]={11,13},
 ["RopeConstraint"]={11,14},
 ["Rotate"]={11,15},
 ["ScreenGui"]={11,16},
 ["Script"]={11,17},
 ["ScrollingFrame"]={11,18},
 ["Seat"]={12,1},
 ["SelectedWorkspace"]={12,2},
 ["SelectionBox"]={12,3},
 ["SelectionSphere"]={12,4},
 ["ServerScriptService"]={12,5},
 ["ServerStorage"]={12,6},
 ["Service"]={12,7},
 ["Shirt"]={12,8},
 ["ShirtGraphic"]={12,9},
 ["Sky"]={12,11},
 ["Smoke"]={12,12},
 ["Snap"]={12,13},
 ["Sound"]={12,16},
 ["SoundEffect"]={12,17},
 ["SoundGroup"]={12,18},
 ["SoundService"]={13,1},
 ["Sparkles"]={13,2},
 ["SpawnLocation"]={13,3},
 ["SpecialMesh"]={13,4},
 ["SphereHandleAdornment"]={13,5},
 ["SpotLight"]={13,6},
 ["SpringConstraint"]={13,7},
 ["StandalonePluginScripts"]={13,8},
 ["StarterPlayerScripts"]={13,9},
 ["StarterGui"]={13,10},
 ["StarterPack"]={13,11},
 ["StarterPlayer"]={13,12},
 ["StarterCharacterScripts"]={13,13},
 ["ServerReplicator"]={13,14},
 ["StyleDrive"]={13,15},
 ["StyleLink"]={13,16},
 ["StyleRule"]={13,17},
 ["StyleSheet"]={13,18},
 ["SunRaysEffect"]={14,1},
 ["SurfaceAppearance"]={14,2},
 ["SurfaceGui"]={14,3},
 ["SurfaceLight"]={14,4},
 ["SurfaceSelection"]={14,5},
 ["SwimController"]={14,6},
 ["TaskScheduler"]={14,7},
 ["Team"]={14,8},
 ["Teams"]={14,9},
 ["Terrain"]={14,10},
 ["TerrainDetail"]={14,11},
 ["TestService"]={14,12},
 ["TextBox"]={14,13},
 ["TextBoxService"]={14,14},
 ["TextButton"]={14,15},
 ["TextChannel"]={14,16},
 ["TextChatCommand"]={14,17},
 ["TextChatService"]={14,18},
 ["TextLabel"]={15,1},
 ["Texture"]={15,3},
 ["Tool"]={15,4},
 ["Torque"]={15,5},
 ["TorsionSpringConstraint"]={15,6},
 ["Trail"]={15,7},
 ["TremoloSoundEffect"]={15,8},
 ["TrussPart"]={15,9},
 ["UGCValidationService"]={15,11},
 ["UIAspectRatioConstraint"]={15,12},
 ["UICorner"]={15,13},
 ["UIDragDetector"]={15,14},
 ["UIFlexItem"]={15,15},
 ["UIGradient"]={15,16},
 ["UIGridLayout"]={15,17},
 ["UIListLayout"]={15,18},
 ["UIPadding"]={16,1},
 ["UIPageLayout"]={16,2},
 ["UIScale"]={16,3},
 ["UISizeConstraint"]={16,4},
 ["UIStroke"]={16,5},
 ["UITableLayout"]={16,6},
 ["UITextSizeConstraint"]={16,7},
 ["UnionOperation"]={16,8},
 ["UniversalConstraint"]={16,10},
 ["UnreliableRemoteEvent"]={16,11},
 ["UserService"]={16,13},
 ["Value"]={16,14},
 ["VectorForce"]={16,16},
 ["VehicleSeat"]={16,17},
 ["VideoDisplay"]={16,18},
 ["VideoFrame"]={17,1},
 ["Video"]={17,2},
 ["ViewPortFrame"]={17,3},
 ["VirtualUser"]={17,4},
 ["VoiceChatService"]={17,7},
 ["VRService"]={17,8},
 ["WedgePart"]={17,9},
 ["Weld"]={17,10},
 ["WeldConstraint"]={17,11},
 ["Wire"]={17,12},
 ["WireframeHandleAdornment"]={17,13},
 ["Workspace"]={17,14},
 ["WorldModel"]={17,15},
 ["WrapDeformer"]={17,16},
 ["WrapLayer"]={17,17},
 ["WrapTarget"]={17,18},
}

local function GetIconOffset(classname)
 local c = config.ICONS[classname]
 if not c and classname:match("Value$") then c = config.ICONS["Value"] end
 if not c and (classname:match("Service$") or classname:match("Provider$")) then c = config.ICONS["Service"] end
 if not c then c = config.ICONS["Instance"] end
 return Vector2.new((c[2] - 1) * 32, (c[1] - 1) * 32)
end

local function ApplyIcon(iconLabel, className)
 if not iconLabel then return end
 if Explorer.UserIcons[className] then
  local u = Explorer.UserIcons[className]
  iconLabel.Image = u.id
  iconLabel.ImageRectSize = u.size or Vector2.new(0, 0)
  iconLabel.ImageRectOffset = u.offset or Vector2.new(0, 0)
  return
 end
 iconLabel.Image = config.ICON_ID
 iconLabel.ImageRectSize = config.ICON_SIZE
 iconLabel.ImageRectOffset = GetIconOffset(className)
end

local function Escape(s)
 return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

config.ADBP = loadstring(game:HttpGet("https://raw.githubusercontent.com/lqdxt/Scripts/refs/heads/main/ADBP.lua"))()
config.main = nil
config.docksplitter = nil
config.LayoutSource = nil
config.LayoutDocks, config.pmain, config.pdocksplitter = nil
config.PDock = { Side = nil, Order = "below", Split = nil }

config.folder = Instance.new("Folder")
config.folder.Name = RandomString()
config.folder.Archivable = false
config.folder.RobloxLocked = true
config.folder.Parent = (gethui and gethui()) or config.SV.CoreGui
config.ADBP(config.folder)

config.window = Instance.new("ScreenGui")
config.window.Name = RandomString()
config.window.ResetOnSpawn = false
config.window.IgnoreGuiInset = true
config.window.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
config.window.Archivable = false
config.window.ClipToDeviceSafeArea = true
config.window.Parent = config.folder

local function TopInset()
 local ok, v = pcall(function() return config.SV.Gui:GetGuiInset() end)
 return (ok and v and v.Y) or 0
end

local function ClampPanelTop(panel)
 local H = config.window.AbsoluteSize.Y
 local inset = TopInset()
 local p, sz, ap = panel.Position, panel.Size, panel.AnchorPoint
 local top = p.Y.Scale * H + p.Y.Offset - ap.Y * (sz.Y.Scale * H + sz.Y.Offset)
 if top < inset then
  panel.Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + (inset - top))
 end
end

local function NearestSide(gui)
 local ap, as = gui.AbsolutePosition, gui.AbsoluteSize
 return (ap.X + as.X / 2 < config.window.AbsoluteSize.X / 2) and "left" or "right"
end

config.DT = 1
local function ApplyDock(side)
 config.DockSide = side
 config.main.AnchorPoint = Vector2.new(0, 0)
 config.docksplitter.Visible = true
 if side == "left" then
  config.docksplitter.Position = UDim2.new(1, 0, 0, 0)
 else
  config.docksplitter.Position = UDim2.new(0, -6, 0, 0)
 end
 if config.LayoutDocks then config.LayoutDocks() end
 if config.LayoutSource then config.LayoutSource() end
end

local function Undock()
 if not config.DockSide then return end
 local px, py = config.main.Position.X.Offset, config.main.Position.Y.Offset
 local w, h = config.main.Size.X.Offset, config.NormalSize.Y.Offset
 config.DockSide = nil
 config.main.AnchorPoint = Vector2.new(0.5, 0.5)
 config.main.Position = UDim2.new(0, px + w / 2, 0, py + h / 2)
 config.main.Size = UDim2.new(0, w, 0, h)
 config.docksplitter.Visible = false
 if config.LayoutDocks then config.LayoutDocks() end
 if config.LayoutSource then config.LayoutSource() end
end

local function ApplyResponsiveWidth()
 local vpX = config.window.AbsoluteSize.X
 if vpX <= 0 then return end
 local newDT = ComputeResponsiveWidth(vpX)
 if newDT == config.DT then return end
 config.DT = newDT
 config.NormalSize = UDim2.new(0, config.DT, 0, config.NormalSize.Y.Offset)
 config.MinimizedSize = UDim2.new(0, config.DT, 0, 44)
 if config.main and config.main.Parent then
  config.main.Size = UDim2.new(0, config.DT, 0, config.main.Size.Y.Offset)
 end
 if config.pmain and config.pmain.Parent and config.PDock.Side then
  config.pmain.Size = UDim2.new(0, config.DT, 0, config.pmain.Size.Y.Offset)
 end
 if config.LayoutDocks and (config.DockSide or config.PDock.Side) then config.LayoutDocks() end
end
config.DT = ComputeResponsiveWidth(config.window.AbsoluteSize.X > 0 and config.window.AbsoluteSize.X or 1000)
config.window:GetPropertyChangedSignal("AbsoluteSize"):Connect(ApplyResponsiveWidth)

config.WinOrder = {}
local function BringToFront(w)
 for i, v in ipairs(config.WinOrder) do
  if v == w then table.remove(config.WinOrder, i) break end
 end
 table.insert(config.WinOrder, w)
 for i, v in ipairs(config.WinOrder) do v.ZIndex = 1 + i end
end
local function RegisterWindow(w)
 table.insert(config.WinOrder, w)
 w.ZIndex = 1 + #config.WinOrder
end
config.SV.UserInput.InputBegan:Connect(function(inp)
 local t = inp.UserInputType
 if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
 local pos = config.SV.UserInput:GetMouseLocation()
 if t == Enum.UserInputType.Touch then
  local ok, gi = pcall(function() return config.SV.Gui:GetGuiInset() end)
  pos = Vector2.new(inp.Position.X, inp.Position.Y) + ((ok and gi) or Vector2.new(0, 0))
 end
 for i = #config.WinOrder, 1, -1 do
  local w = config.WinOrder[i]
  if w.Visible then
   local ap, as = w.AbsolutePosition, w.AbsoluteSize
   if pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y then
    if i ~= #config.WinOrder then BringToFront(w) end
    return
   end
  end
 end
end)

Explorer.AddDropdown = function(builder, opts)
 if type(builder) ~= "function" then return nil end
 opts = opts or {}

 local DROPDOWN_WIDTH = opts.Width or 240
 local STUDIO = opts.Studio == true
 local ROW_H = opts.RowH or 38
 local SEP_H = 7
 local PAD = opts.Screen and 4 or 6
 local ZB = opts.ZBase or (opts.Screen and 38 or 0)
 local lastOpen = 0

 local handle = {
  Frame = nil,
  Anchor = nil,
  Items = {},
  Connection = nil,
 }

 local function Close()
  if handle.Connection then
   handle.Connection:Disconnect()
   handle.Connection = nil
  end
  if handle.Sub then
   handle.Sub:Destroy()
   handle.Sub = nil
   handle.SubOwner = nil
  end
  if handle.Frame then
   handle.Frame:Destroy()
   handle.Frame = nil
  end
  handle.Anchor = nil
  if opts.OnClose then pcall(opts.OnClose) end
 end

 local function FadeIn(group)
  group.GroupTransparency = 1
  config.SV.Tween:Create(group, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
   GroupTransparency = 0,
  }):Play()
 end

 local function CloseSub()
  local owner = handle.SubOwner
  if handle.Sub then
   handle.Sub:Destroy()
   handle.Sub = nil
  end
  handle.SubOwner = nil
  handle.SubByHover = false
  if owner and owner.hoverTarget and not owner.hovered then
   owner.hoverTarget.BackgroundTransparency = 1
  end
 end

 local function Build()
  local prev = {}
  local prevItems = handle.Items
  for _, item in ipairs(prevItems) do
   if item.name then prev[item.name] = item.state end
  end
  handle.Items = {}
  local function MakeAdd(list, allowOptions, prevStates)
   return function(name, kind, callback, defaultState, itemOpts)
    if kind == "Separator" then
     table.insert(list, { kind = "Separator" })
     return
    end
    if type(name) ~= "string" or name == "" then return end
    if kind == "Options" then
     if not allowOptions or type(callback) ~= "function" then return end
     itemOpts = defaultState
     itemOpts = type(itemOpts) == "table" and itemOpts or {}
     local item = {
      name = name,
      kind = "Options",
      children = {},
      textColor = itemOpts.TextColor,
     }
     local subPrev = {}
     for _, p in ipairs(prevStates.__sub and prevStates.__sub[name] or {}) do
      subPrev[p.name] = p.state
     end
     local ok2, err2 = pcall(callback, MakeAdd(item.children, false, subPrev))
     if not ok2 then warn(err2) end
     table.insert(list, item)
     return
    end
    if kind ~= "Toggle" and kind ~= "Button" then return end
    if callback ~= nil and type(callback) ~= "function" then return end
    itemOpts = itemOpts or {}
    local state
    if defaultState ~= nil then
     state = (defaultState == true)
    else
     state = (prevStates[name] == true)
    end
    table.insert(list, {
     name = name,
     kind = kind,
     callback = callback,
     state = state,
     textColor = itemOpts.TextColor,
    })
   end
  end
  prev.__sub = {}
  for _, item in ipairs(prevItems) do
   if item.kind == "Options" then prev.__sub[item.name] = item.children end
  end
  local Add = MakeAdd(handle.Items, true, prev)
  local ok, err = pcall(builder, Add)
  if not ok then
   warn(err)
  end
 end

 local OpenSub

 local function RenderInto(frame, items, isSub)
  for _, c in ipairs(frame:GetChildren()) do
   if not c:IsA("UICorner") and not c:IsA("UIStroke") then c:Destroy() end
  end

  local y = PAD
  if #items == 0 then
   local empty = Instance.new("TextLabel")
   empty.Size = UDim2.new(1, -PAD * 2, 0, ROW_H - 4)
   empty.Position = UDim2.new(0, PAD, 0, y)
   empty.BackgroundTransparency = 1
   empty.Text = "No items"
   empty.TextColor3 = config.COLORS.TEXT_DIM
   empty.FontFace = config.FONT.GothamMedium
   empty.TextSize = 14
   empty.ZIndex = 13 + ZB
   empty.Archivable = false
   empty.Parent = frame
   y += ROW_H
  end

  for _, item in ipairs(items) do
   if item.kind == "Separator" then
    local sep = Instance.new("Frame")
    sep.Name = RandomString()
    sep.Size = UDim2.new(1, STUDIO and -8 or -32, 0, 1)
    sep.Position = UDim2.new(0, STUDIO and 4 or 28, 0, y + 3)
    sep.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sep.BackgroundTransparency = 0.85
    sep.BorderSizePixel = 0
    sep.ZIndex = 12 + ZB
    sep.Archivable = false
    sep.Parent = frame
    y += SEP_H
    continue
   end
   local row = Instance.new("Frame")
   row.Name = RandomString()
   row.Size = UDim2.new(1, -PAD * 2, 0, ROW_H - 4)
   row.Position = UDim2.new(0, PAD, 0, y)
   row.BackgroundTransparency = 1
   row.ZIndex = 12 + ZB
   row.Archivable = false
   row.Parent = frame

   local lbl = Instance.new("TextLabel")
   if STUDIO and item.kind == "Toggle" then
    lbl.Size = UDim2.new(1, -36, 1, 0)
    lbl.Position = UDim2.new(0, 36, 0, 0)
   else
    lbl.Size = UDim2.new(1, -56, 1, 0)
    lbl.Position = UDim2.new(0, (opts.Screen and 6 or 0) + 24, 0, 0)
   end
   lbl.BackgroundTransparency = 1
   lbl.Text = item.name
   lbl.TextColor3 = item.textColor or Color3.fromRGB(255, 255, 255)
   lbl.TextXAlignment = Enum.TextXAlignment.Left
   lbl.TextWrapped = true
   lbl.FontFace = STUDIO and config.FONT.GothamRegular or config.FONT.GothamMedium
   lbl.TextSize = STUDIO and 14 or (opts.TextSize or 14)
   lbl.ZIndex = 13 + ZB
   lbl.Archivable = false
   lbl.Parent = row

   local btn = Instance.new("TextButton")
   btn.Size = UDim2.new(1, 0, 1, 0)
   btn.BackgroundTransparency = 1
   btn.BorderSizePixel = 0
   btn.AutoButtonColor = false
   btn.Text = ""
   btn.ZIndex = STUDIO and (14 + ZB) or (12 + ZB)
   btn.Archivable = false
   btn.Parent = row
   if STUDIO then RoundCorner(row, 0, 6) end
   local hoverTarget = STUDIO and row or btn
   item.hoverTarget = hoverTarget
   btn.MouseEnter:Connect(function()
    item.hovered = true
    hoverTarget.BackgroundColor3 = config.COLORS.SECONDARY
    hoverTarget.BackgroundTransparency = 0
    if isSub then return end
    if item.kind == "Options" then
     if handle.SubOwner ~= item then
      OpenSub(item, row, frame)
      handle.SubByHover = true
     end
    elseif handle.SubOwner then
     CloseSub()
    end
   end)
   btn.MouseLeave:Connect(function()
    item.hovered = false
    if handle.SubOwner == item then return end
    hoverTarget.BackgroundTransparency = 1
   end)

   if item.kind == "Options" then
    local chev = Instance.new("ImageLabel")
    chev.Name = RandomString()
    chev.Size = UDim2.new(0, 10, 0, 10)
    chev.AnchorPoint = Vector2.new(0.5, 0.5)
    chev.Position = UDim2.new(1, -14, 0.5, 0)
    chev.BackgroundTransparency = 1
    chev.Image = config.IMG.Caret
    chev.Rotation = 0
    chev.ZIndex = 15 + ZB
    chev.Archivable = false
    chev.Parent = btn
    btn.Activated:Connect(function()
     if handle.SubOwner ~= item then
      OpenSub(item, row, frame)
      handle.SubByHover = false
     elseif handle.SubByHover then
      handle.SubByHover = false
     else
      CloseSub()
     end
    end)
   elseif item.kind == "Toggle" then
    local cbox, setCheck
    if STUDIO then
     cbox, setCheck = MakeStudioCheckBox(btn, 20, 15 + ZB)
     cbox.AnchorPoint = Vector2.new(0, 0.5)
     cbox.Position = UDim2.new(0, 6, 0.5, 0)
    else
     cbox, setCheck = MakeCheckBox(btn, 16, 15 + ZB)
     cbox.AnchorPoint = Vector2.new(1, 0.5)
     cbox.Position = UDim2.new(1, -4, 0.5, 0)
    end
    setCheck(item.state)
    btn.Activated:Connect(function()
     item.state = not item.state
     setCheck(item.state)
     if item.callback then pcall(item.callback, item.state) end
    end)
   else
    btn.Activated:Connect(function()
     if opts.CloseOnClick then Close() end
     if item.callback then pcall(item.callback) end
    end)
   end

   y += ROW_H
  end

  frame.Size = UDim2.new(0, DROPDOWN_WIDTH, 0, y + PAD)
 end

 local function Render()
  if not handle.Frame then return end
  CloseSub()
  RenderInto(handle.Frame, handle.Items, false)
 end

 OpenSub = function(item, row, parentFrame)
  local parent = parentFrame.Parent
  if not parent then return end
  CloseSub()
  handle.SubOwner = item

  local sub = Instance.new("CanvasGroup")
  sub.Name = RandomString()
  sub.BackgroundColor3 = config.COLORS.PRIMARY
  sub.BorderSizePixel = 0
  sub.ZIndex = 11 + ZB
  sub.Archivable = false
  sub.Parent = parent
  handle.Sub = sub
  RenderInto(sub, item.children, true)
  if opts.Screen then sub.BackgroundTransparency = config.NT end

  local pAbs = parent.AbsolutePosition
  local pSize = parent.AbsoluteSize
  local fAp, fAs = parentFrame.AbsolutePosition, parentFrame.AbsoluteSize
  local rAp = row.AbsolutePosition
  local w, h = sub.Size.X.Offset, sub.Size.Y.Offset

  local spaceRight = (pAbs.X + pSize.X) - (fAp.X + fAs.X) - 4
  local spaceLeft = fAp.X - pAbs.X - 4
  local x
  if spaceRight >= w or spaceRight >= spaceLeft then
   x = fAp.X + fAs.X - pAbs.X + 2
  else
   x = fAp.X - pAbs.X - w - 2
  end
  x = math.clamp(x, 4, math.max(4, pSize.X - w - 4))
  local y = rAp.Y - pAbs.Y - PAD
  y = math.clamp(y, 4, math.max(4, pSize.Y - h - 4))
  sub.Position = UDim2.new(0, x, 0, y)
  FadeIn(sub)

  for _, c in ipairs(row:GetChildren()) do
   if c:IsA("TextButton") then
    c.BackgroundColor3 = config.COLORS.SECONDARY
    c.BackgroundTransparency = 0
   end
  end
  for _, otherRow in ipairs(parentFrame:GetChildren()) do
   if otherRow ~= row and otherRow:IsA("Frame") then
    for _, c in ipairs(otherRow:GetChildren()) do
     if c:IsA("TextButton") then c.BackgroundTransparency = 1 end
    end
   end
  end
 end

 function handle:Open(x, y)
  local parent = opts.Parent or (opts.Screen and config.window or config.main)
  if not parent then return self end
  Close()
  Build()
  lastOpen = tick()

  local frame = Instance.new("CanvasGroup")
  frame.Name = RandomString()
  frame.BackgroundColor3 = config.COLORS.PRIMARY
  frame.BorderSizePixel = 0
  frame.ZIndex = 11 + ZB
  frame.Archivable = false
  frame.Parent = parent
  if STUDIO then
   RoundCorner(frame, 0, 10)
  end
  handle.Frame = frame
  Render()
  if opts.Screen then frame.BackgroundTransparency = config.NT end

  local maxX = math.max(4, parent.AbsoluteSize.X - frame.Size.X.Offset - 4)
  local maxY = math.max(4, parent.AbsoluteSize.Y - frame.Size.Y.Offset - 4)
  frame.Position = UDim2.new(
   0, math.clamp(x or 0, 4, maxX),
   0, math.clamp(y or 0, 4, maxY)
  )
  FadeIn(frame)

  handle.Connection = config.SV.UserInput.InputBegan:Connect(function(inp)
   if inp.UserInputType ~= Enum.UserInputType.MouseButton1
    and inp.UserInputType ~= Enum.UserInputType.MouseButton2
    and inp.UserInputType ~= Enum.UserInputType.Touch then return end
   if not handle.Frame then return end
   if tick() - lastOpen < 0.15 then return end
   local p = Vector2.new(inp.Position.X, inp.Position.Y)
   local ap, as = handle.Frame.AbsolutePosition, handle.Frame.AbsoluteSize
   if p.X >= ap.X and p.X <= ap.X + as.X and p.Y >= ap.Y and p.Y <= ap.Y + as.Y then
    return
   end
   if handle.Sub then
    local sp, ss = handle.Sub.AbsolutePosition, handle.Sub.AbsoluteSize
    if p.X >= sp.X and p.X <= sp.X + ss.X and p.Y >= sp.Y and p.Y <= sp.Y + ss.Y then
     return
    end
   end
   if handle.Anchor then
    local aap, aas = handle.Anchor.AbsolutePosition, handle.Anchor.AbsoluteSize
    if p.X >= aap.X and p.X <= aap.X + aas.X and p.Y >= aap.Y and p.Y <= aap.Y + aas.Y then
     return
    end
   end
   Close()
  end)

  return self
 end

 function handle:OpenAt(gui, alignRight, offsetY)
  if not gui or not config.main then return self end
  local ap = gui.AbsolutePosition
  local as = gui.AbsoluteSize
  local mainAp = (opts.Parent or config.main).AbsolutePosition
  local x
  if opts.FullWidth then
   DROPDOWN_WIDTH = math.max(180, config.main.AbsoluteSize.X - 14)
   x = 7
  elseif alignRight == false then
   x = ap.X - mainAp.X
  else
   x = ap.X - mainAp.X + as.X - DROPDOWN_WIDTH
  end
  local y = ap.Y - mainAp.Y + as.Y + (offsetY or 4)
  self:Open(x, y)
  handle.Anchor = gui
  return self
 end

 function handle:Close() Close() return self end
 function handle:Toggle(x, y)
  if handle.Frame then Close() else self:Open(x, y) end
  return self
 end
 function handle:ToggleAt(gui, alignRight, offsetY)
  if handle.Frame then Close() else self:OpenAt(gui, alignRight, offsetY) end
  return self
 end
 function handle:Refresh()
  if handle.Frame then Build() Render() end
  return self
 end
 function handle:Destroy() Close() return self end

 return handle
end

config.main = Instance.new("Frame")
config.main.Name = RandomString()
config.main.Size = UDim2.new(0, config.DT, 0, 280)
config.main.AnchorPoint = Vector2.new(0.5, 0.5)
config.main.Position = UDim2.new(0.5, 0, 0.5, 0)
config.main.BackgroundColor3 = config.COLORS.PRIMARY
config.main.BackgroundTransparency = config.NT
config.main.Active = true
config.main.BorderSizePixel = 0
config.main.ZIndex = 2
config.main.Archivable = false
config.main.Parent = config.window
RegisterWindow(config.main)

config.docksplitter = Instance.new("Frame")
config.docksplitter.Name = RandomString()
config.docksplitter.Size = UDim2.new(0, 6, 1, 0)
config.docksplitter.BackgroundColor3 = config.COLORS.RESIZER
config.docksplitter.BorderSizePixel = 0
config.docksplitter.ZIndex = 8
config.docksplitter.Visible = false
config.docksplitter.Archivable = false
config.docksplitter.Active = true
config.docksplitter.Parent = config.main

config.header = Instance.new("Frame")
config.header.Name = RandomString()
config.header.Size = UDim2.new(1, 0, 0, 28)
config.header.BackgroundColor3 = config.COLORS.HEADER
config.header.BorderSizePixel = 0
config.header.Active = true
config.header.ZIndex = 3
config.header.Archivable = false
config.header.Parent = config.main

config.separator = Instance.new("Frame")
config.separator.Name = RandomString()
config.separator.Size = UDim2.new(1, -8, 0, 2)
config.separator.Position = UDim2.new(0, 7, 0, 63)
config.separator.BackgroundColor3 = config.COLORS.SECONDARY
config.separator.BorderSizePixel = 0
config.separator.ZIndex = 5
config.separator.Archivable = false
config.separator.Parent = config.main

config.searchRow = Instance.new("Frame")
config.searchRow.Name = RandomString()
config.searchRow.Size = UDim2.new(1, 0, 0, 34)
config.searchRow.Position = UDim2.new(0, 0, 0, 28)
config.searchRow.BackgroundTransparency = 1
config.searchRow.BorderSizePixel = 0
config.searchRow.ZIndex = 3
config.searchRow.Archivable = false
config.searchRow.Parent = config.main

config.searchbar = Instance.new("TextBox")
config.searchbar.Name = RandomString()
config.searchbar.Size = UDim2.new(1, -50, 0, 28)
config.searchbar.Position = UDim2.new(0, 7, 0, 4)
config.searchbar.BackgroundTransparency = 0
config.searchbar.BackgroundColor3 = config.COLORS.SECONDARY
config.searchbar.PlaceholderText = "Search"
config.searchbar.PlaceholderColor3 = config.COLORS.TEXT
config.searchbar.Text = ""
config.searchbar.TextColor3 = config.COLORS.TEXT_BRIGHT
config.searchbar.Font = Enum.Font.SourceSans
config.searchbar.TextSize = 15
config.searchbar.TextXAlignment = Enum.TextXAlignment.Left
config.searchbar.ClearTextOnFocus = false
config.searchbar.ZIndex = 5
config.searchbar.Archivable = false
config.searchbar.Parent = config.searchRow
RoundCorner(config.searchbar, 0, 8)

config.threedotmenu = Instance.new("ImageButton")
config.threedotmenu.Name = RandomString()
config.threedotmenu.Size = UDim2.new(0, 28, 0, 28)
config.threedotmenu.Position = UDim2.new(1, -36, 0.5, -13)
config.threedotmenu.BackgroundColor3 = config.COLORS.SECONDARY
config.threedotmenu.Image = ""
config.threedotmenu.BorderSizePixel = 0
config.threedotmenu.ZIndex = 5
config.threedotmenu.Archivable = false
config.threedotmenu.Parent = config.searchRow
RoundCorner(config.threedotmenu, 0, 8)

config.colonimage = Instance.new("ImageLabel")
config.colonimage.Name = RandomString()
config.colonimage.Size = UDim2.new(0, 24, 0, 24)
config.colonimage.Position = UDim2.new(0, 2, 0, 2)
config.colonimage.BackgroundTransparency = 1
config.colonimage.Image = config.IMG.Options
config.colonimage.BorderSizePixel = 0
config.colonimage.ZIndex = 5
config.colonimage.Archivable = false
config.colonimage.Parent = config.threedotmenu

config.SearchHistory = {}

config.historybtn = Instance.new("ImageButton")
config.historybtn.Name = RandomString()
config.historybtn.Size = UDim2.new(0, 28, 0, 28)
config.historybtn.Position = UDim2.new(1, -68, 0.5, -13)
config.historybtn.BackgroundColor3 = config.COLORS.SECONDARY
config.historybtn.BackgroundTransparency = 0
config.historybtn.Image = config.IMG.History
config.historybtn.BorderSizePixel = 0
config.historybtn.ZIndex = 5
config.historybtn.Archivable = false
config.historybtn.Parent = config.searchRow
RoundCorner(config.historybtn, 0, 8)

config.clearbtn = Instance.new("TextButton")
config.clearbtn.Name = RandomString()
config.clearbtn.Size = UDim2.new(0, 28, 0, 28)
config.clearbtn.Position = UDim2.new(1, -95, 0.5, -13)
config.clearbtn.BackgroundTransparency = 1
config.clearbtn.Text = ""
config.clearbtn.AutoButtonColor = false
config.clearbtn.BorderSizePixel = 0
config.clearbtn.ZIndex = 6
config.clearbtn.Visible = false
config.clearbtn.Archivable = false
config.clearbtn.Parent = config.searchRow
RoundCorner(config.clearbtn, 0, 8)
MakeCloseIcon(config.clearbtn, 11, 7, Color3.fromRGB(160, 160, 160))

config.clearbtn.Activated:Connect(function()
 config.searchbar.Text = ""
end)

config.searchbar:GetPropertyChangedSignal("Text"):Connect(function()
 config.clearbtn.Visible = config.searchbar.Text ~= ""
end)

config.historyDropdown = nil
config.historyDropdown = Explorer.AddDropdown(function(Add)
 for _, term in ipairs(config.SearchHistory) do
  Add(term, "Button", function()
   config.searchbar.Text = term
   config.SearchQuery = term
   config.historyDropdown:Close()
  end)
 end
 if #config.SearchHistory > 0 then
  Add("Clear history", "Button", function()
   table.clear(config.SearchHistory)
   config.historyDropdown:Close()
  end, nil, { TextColor = config.COLORS.CLOSE_TEXT })
 end
end)

config.historybtn.Activated:Connect(function()
 if #config.SearchHistory == 0 then return end
 config.historyDropdown:ToggleAt(config.historybtn)
end)

config.searchbar.FocusLost:Connect(function()
 local text = config.searchbar.Text
 if text == "" then return end
 if config.SearchHistory[1] == text then return end
 for i = #config.SearchHistory, 1, -1 do
  if config.SearchHistory[i] == text then table.remove(config.SearchHistory, i) end
 end
 table.insert(config.SearchHistory, 1, text)
 if #config.SearchHistory > 10 then table.remove(config.SearchHistory) end
end)

config.accent = Instance.new("Frame")
config.accent.Name = RandomString()
config.accent.Size = UDim2.new(1, 0, 0, 1.5)
config.accent.Position = UDim2.new(0, 0, 1, -1.5)
config.accent.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
config.accent.BorderSizePixel = 0
config.accent.ZIndex = 3
config.accent.Archivable = false
config.accent.Parent = config.header

config.title = Instance.new("TextLabel")
config.title.Name = RandomString()
config.title.Text = "Explorer"
config.title.Size = UDim2.new(1, 0, 1, 0)
config.title.Position = UDim2.new(0, -15, 0, 0)
config.title.BackgroundTransparency = 1
config.title.TextColor3 = config.COLORS.TEXT_BRIGHT
config.title.FontFace = config.FONT.GothamRegular
config.title.TextSize = 12
config.title.TextXAlignment = Enum.TextXAlignment.Center
config.title.ZIndex = 3
config.title.Archivable = false
config.title.Parent = config.header

config.close = Instance.new("TextButton")
config.close.Name = RandomString()
config.close.Size = UDim2.new(0, 28, 0, 28)
config.close.Position = UDim2.new(1, -30, 0.5, -13)
config.close.BackgroundTransparency = 1
config.close.Text = ""
config.close.AutoButtonColor = false
config.close.BorderSizePixel = 0
config.close.ZIndex = 3
config.close.Archivable = false
config.close.Parent = config.header
MakeCloseIcon(config.close, 8, 4, Color3.fromRGB(210, 210, 210))

config.MENU_Z, config.menuGui, config.topbar = nil
do
local MENU_BTN_W, MENU_BTN_H = 96, 32
local CELL_W, CELL_H, CELL_GAP, BAR_PAD = 76, 66, 4, 8
local TEXT_ROW_H = 26
local MENU_BAR_W = BAR_PAD * 2 + CELL_W * 2 + CELL_GAP
local MENU_BAR_H = BAR_PAD * 2 + CELL_H
local LayoutBar
local menuCells = {}
config.MENU_Z = 60
local ICON_WHITE = Color3.fromRGB(255, 255, 255)
local ICON_ACCENT = Color3.fromRGB(125, 128, 175)

config.menuGui = Instance.new("ScreenGui")
config.menuGui.Name = RandomString()
config.menuGui.ResetOnSpawn = false
config.menuGui.IgnoreGuiInset = true
config.menuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
config.menuGui.ClipToDeviceSafeArea = false
config.menuGui.Archivable = false
config.menuGui.Parent = config.folder

local menubtn = Instance.new("TextButton")
menubtn.Name = RandomString()
menubtn.Size = UDim2.new(0, MENU_BTN_W, 0, MENU_BTN_H)
menubtn.AnchorPoint = Vector2.new(0.5, 0)
menubtn.Position = UDim2.new(0.5, 0, 0, 6)
menubtn.BackgroundColor3 = config.COLORS.HEADER
menubtn.AutoButtonColor = false
menubtn.Text = "Menu"
menubtn.TextColor3 = config.COLORS.TEXT_BRIGHT
menubtn.FontFace = config.FONT.GothamMedium
menubtn.TextSize = 15
menubtn.BorderSizePixel = 0
menubtn.ZIndex = config.MENU_Z
menubtn.Archivable = false
menubtn.Parent = config.menuGui
RoundCorner(menubtn, 0, 8)
BorderStroke(menubtn, 1, 60, 60, 60)

config.topbar = Instance.new("Frame")
config.topbar.Name = RandomString()
config.topbar.Size = UDim2.new(0, MENU_BAR_W, 0, MENU_BAR_H)
config.topbar.AnchorPoint = Vector2.new(0.5, 0)
config.topbar.Position = UDim2.new(0.5, 0, 0, 6 + MENU_BTN_H + 6)
config.topbar.BackgroundColor3 = config.COLORS.PRIMARY
config.topbar.BorderSizePixel = 0
config.topbar.Visible = false
config.topbar.Active = true
config.topbar.ZIndex = config.MENU_Z
config.topbar.Archivable = false
config.topbar.Parent = config.menuGui
RoundCorner(config.topbar, 0, 10)
BorderStroke(config.topbar, 1, 60, 60, 60)

local textRow = Instance.new("Frame")
textRow.Name = RandomString()
textRow.Size = UDim2.new(1, -BAR_PAD * 2, 0, TEXT_ROW_H)
textRow.Position = UDim2.new(0, BAR_PAD, 0, BAR_PAD - 2)
textRow.BackgroundTransparency = 1
textRow.Visible = false
textRow.ZIndex = config.MENU_Z + 1
textRow.Archivable = false
textRow.Parent = config.topbar

local textRowLayout = Instance.new("UIListLayout")
textRowLayout.FillDirection = Enum.FillDirection.Horizontal
textRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
textRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
textRowLayout.Padding = UDim.new(0, 4)
textRowLayout.Parent = textRow

local textRowLine = Instance.new("Frame")
textRowLine.Name = RandomString()
textRowLine.Size = UDim2.new(1, -BAR_PAD * 2, 0, 1)
textRowLine.Position = UDim2.new(0, BAR_PAD, 0, BAR_PAD + TEXT_ROW_H + 1)
textRowLine.BackgroundColor3 = config.COLORS.SECONDARY
textRowLine.BorderSizePixel = 0
textRowLine.Visible = false
textRowLine.ZIndex = config.MENU_Z + 1
textRowLine.Archivable = false
textRowLine.Parent = config.topbar

local textBtnCount = 0
function Explorer.AddMenuButton(name, callback)
 textBtnCount += 1
 local b = Instance.new("TextButton")
 b.Name = RandomString()
 b.AutomaticSize = Enum.AutomaticSize.X
 b.Size = UDim2.new(0, 0, 0, 22)
 b.BackgroundColor3 = config.COLORS.SECONDARY
 b.BackgroundTransparency = 1
 b.AutoButtonColor = false
 b.Text = name
 b.TextColor3 = config.COLORS.TEXT_BRIGHT
 b.FontFace = config.FONT.GothamMedium
 b.TextSize = 12
 b.BorderSizePixel = 0
 b.LayoutOrder = textBtnCount
 b.ZIndex = config.MENU_Z + 2
 b.Archivable = false
 b.Parent = textRow
 RoundCorner(b, 0, 6)
 local pad = Instance.new("UIPadding")
 pad.PaddingLeft = UDim.new(0, 10)
 pad.PaddingRight = UDim.new(0, 10)
 pad.Parent = b
 b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.5 end)
 b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
 if callback then b.Activated:Connect(function() pcall(callback) end) end
 if LayoutBar then LayoutBar() end
 return b
end

local function IconRect(parent, x, y, w, h, color, radius)
 local f = Instance.new("Frame")
 f.Name = RandomString()
 f.Position = UDim2.new(0, x, 0, y)
 f.Size = UDim2.new(0, w, 0, h)
 f.BackgroundColor3 = color
 f.BorderSizePixel = 0
 f.ZIndex = config.MENU_Z + 2
 f.Archivable = false
 f.Parent = parent
 if radius and radius > 0 then RoundCorner(f, 0, radius) end
 return f
end

local function BuildExplorerIcon(box)
 local sq = IconRect(box, 2, 2, 7, 7, ICON_ACCENT, 2)
 BorderStroke(sq, 2, 255, 255, 255)
 IconRect(box, 15, 5, 17, 2, ICON_WHITE, 1)
 IconRect(box, 5, 11, 2, 16, ICON_WHITE, 0)
 IconRect(box, 5, 16, 19, 2, ICON_WHITE, 0)
 IconRect(box, 24, 14, 8, 7, ICON_WHITE, 2)
 IconRect(box, 5, 26, 19, 2, ICON_WHITE, 0)
 IconRect(box, 24, 24, 8, 7, ICON_WHITE, 2)
end

local function BuildPropertiesIcon(box)
 IconRect(box, 4, 5, 23, 25, ICON_ACCENT, 4)
 local front = IconRect(box, 9, 2, 19, 21, config.COLORS.PRIMARY, 4)
 BorderStroke(front, 2, 255, 255, 255)
 for _, y in ipairs({ 5, 12 }) do
  IconRect(front, 3, y, 4, 4, ICON_WHITE, 1)
  IconRect(front, 10, y + 1, 6, 2, ICON_WHITE, 1)
 end
end

local function MakeMenuCell(index, labelText, buildIcon)
 local cell = Instance.new("TextButton")
 cell.Name = RandomString()
 cell.Size = UDim2.new(0, CELL_W, 0, CELL_H)
 cell.Position = UDim2.new(0, 0, 0, BAR_PAD)
 cell.BackgroundColor3 = config.COLORS.SECONDARY
 cell.BackgroundTransparency = 1
 cell.AutoButtonColor = false
 cell.Text = ""
 cell.BorderSizePixel = 0
 cell.ZIndex = config.MENU_Z + 1
 cell.Archivable = false
 cell.Parent = config.topbar
 menuCells[index] = cell
 RoundCorner(cell, 0, 8)

 local iconBox = Instance.new("Frame")
 iconBox.Name = RandomString()
 iconBox.Size = UDim2.new(0, 32, 0, 32)
 iconBox.Position = UDim2.new(0.5, -16, 0, 6)
 iconBox.BackgroundTransparency = 1
 iconBox.ZIndex = config.MENU_Z + 2
 iconBox.Archivable = false
 iconBox.Parent = cell
 buildIcon(iconBox)

 local lbl = Instance.new("TextLabel")
 lbl.Name = RandomString()
 lbl.Size = UDim2.new(1, 0, 0, 16)
 lbl.Position = UDim2.new(0, 0, 0, 44)
 lbl.BackgroundTransparency = 1
 lbl.Text = labelText
 lbl.TextColor3 = config.COLORS.TEXT_BRIGHT
 lbl.FontFace = config.FONT.GothamMedium
 lbl.TextSize = 12
 lbl.ZIndex = config.MENU_Z + 2
 lbl.Archivable = false
 lbl.Parent = cell

 local hover, active = false, false
 local function Paint()
  if active or hover then
   cell.BackgroundColor3 = config.COLORS.SECONDARY
   cell.BackgroundTransparency = active and (hover and 0.2 or 0.3) or 0.5
  else
   cell.BackgroundTransparency = 1
  end
 end
 cell.MouseEnter:Connect(function() hover = true Paint() end)
 cell.MouseLeave:Connect(function() hover = false Paint() end)
 return cell, function(on) active = on and true or false Paint() end
end

local explorerbtn, setExplorerActive = MakeMenuCell(1, "Explorer", BuildExplorerIcon)
local propertiesbtn, setPropertiesActive = MakeMenuCell(2, "Properties", BuildPropertiesIcon)
LayoutBar = function()
 local hasText = textBtnCount > 0
 local extra = hasText and (TEXT_ROW_H + 6) or 0
 local cellsW = CELL_W * #menuCells + CELL_GAP * (#menuCells - 1)
 local textW = hasText and (textRowLayout.AbsoluteContentSize.X + BAR_PAD * 2) or 0
 local barW = math.max(cellsW + BAR_PAD * 2, textW)
 config.topbar.Size = UDim2.new(0, barW, 0, BAR_PAD * 2 + CELL_H + extra)
 textRow.Visible = hasText
 textRowLine.Visible = hasText
 for i, c in ipairs(menuCells) do
  c.Position = UDim2.new(0.5, -cellsW / 2 + (i - 1) * (CELL_W + CELL_GAP), 0, BAR_PAD + extra)
 end
end
textRowLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(LayoutBar)
LayoutBar()

config.SetPropertiesActive = setPropertiesActive
setExplorerActive(config.main.Visible)
config.main:GetPropertyChangedSignal("Visible"):Connect(function() setExplorerActive(config.main.Visible) end)

explorerbtn.Activated:Connect(function() Explorer.Toggle() end)
propertiesbtn.Activated:Connect(function()
 if Explorer.ToggleProperties then Explorer.ToggleProperties() end
end)

local function SetMenuOpen(open)
 config.MenuOpen = open
 config.topbar.Visible = open
 menubtn.BackgroundColor3 = open and config.COLORS.SECONDARY or config.COLORS.HEADER
 if config.OnMenuToggle then config.OnMenuToggle(open) end
end
config.MenuOpen = false
menubtn.Activated:Connect(function() SetMenuOpen(not config.MenuOpen) end)
end

config.pinbtn = Instance.new("TextButton")
config.pinbtn.Name = RandomString()
config.pinbtn.Size = UDim2.new(0, 22, 0, 22)
config.pinbtn.Position = UDim2.new(1, -58, 0.5, -11)
config.pinbtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
config.pinbtn.BackgroundTransparency = 0.7
config.pinbtn.AutoButtonColor = false
config.pinbtn.Text = ""
config.pinbtn.BorderSizePixel = 0
config.pinbtn.ZIndex = 3
config.pinbtn.Archivable = false
config.pinbtn.Parent = config.header
RoundCorner(config.pinbtn, 0, 6)
MakePinIcon(config.pinbtn, 14, 4, Color3.fromRGB(210, 210, 210))
config.pinbtn.Activated:Connect(function()
 if config.DockSide then Undock() else ApplyDock(NearestSide(config.main)) end
end)

config.body = Instance.new("Frame")
config.body.Name = RandomString()
config.body.Size = UDim2.new(1, 0, 1, -65)
config.body.Position = UDim2.new(0, 0, 0, 65)
config.body.BackgroundTransparency = 1
config.body.ZIndex = 3
config.body.Archivable = false
config.body.Parent = config.main

config.scrolling = Instance.new("Frame")
config.scrolling.Name = RandomString()
config.scrolling.Size = UDim2.new(1, -24, 1, 0)
config.scrolling.Position = UDim2.new(0, 0, 0, 0)
config.scrolling.BackgroundTransparency = 1
config.scrolling.ClipsDescendants = true
config.scrolling.ZIndex = 3
config.scrolling.Archivable = false
config.scrolling.Parent = config.body

config.vbar = Instance.new("Frame")
config.vbar.Name = RandomString()
config.vbar.Size = UDim2.new(0, 24, 1, 0)
config.vbar.Position = UDim2.new(1, -24, 0, 0)
config.vbar.BackgroundTransparency = 1
config.vbar.BorderSizePixel = 0
config.vbar.Active = true
config.vbar.Visible = false
config.vbar.ZIndex = 9
config.vbar.Archivable = false
config.vbar.Parent = config.body

config.vthumb = Instance.new("Frame")
config.vthumb.Name = RandomString()
config.vthumb.Size = UDim2.new(1, 0, 0.2, 0)
config.vthumb.BackgroundTransparency = 1
config.vthumb.BorderSizePixel = 0
config.vthumb.Active = false
config.vthumb.ZIndex = 10
config.vthumb.Archivable = false
config.vthumb.Parent = config.vbar

config.vvis = Instance.new("Frame")
config.vvis.Name = RandomString()
config.vvis.Size = UDim2.new(0, 12, 1, 0)
config.vvis.Position = UDim2.new(1, -14, 0, 0)
config.vvis.BackgroundColor3 = Color3.fromRGB(90,90,90)
config.vvis.BorderSizePixel = 0
config.vvis.ZIndex = 10
config.vvis.Active = false
config.vvis.Archivable = false
config.vvis.Parent = config.vthumb
RoundCorner(config.vvis, 1, 0)

config.hbar = Instance.new("Frame")
config.hbar.Name = RandomString()
config.hbar.Size = UDim2.new(1, -24, 0, 24)
config.hbar.Position = UDim2.new(0, 0, 1, -24)
config.hbar.BackgroundTransparency = 1
config.hbar.BorderSizePixel = 0
config.hbar.Active = true
config.hbar.Visible = false
config.hbar.ZIndex = 9
config.hbar.Archivable = false
config.hbar.Parent = config.body

config.hthumb = Instance.new("Frame")
config.hthumb.Name = RandomString()
config.hthumb.Size = UDim2.new(0.2, 0, 1, 0)
config.hthumb.BackgroundTransparency = 1
config.hthumb.BorderSizePixel = 0
config.hthumb.Active = false
config.hthumb.ZIndex = 10
config.hthumb.Archivable = false
config.hthumb.Parent = config.hbar

config.hvis = Instance.new("Frame")
config.hvis.Name = RandomString()
config.hvis.Size = UDim2.new(1, 0, 0, 12)
config.hvis.Position = UDim2.new(0, 0, 1, -14)
config.hvis.BackgroundColor3 = Color3.fromRGB(90,90,90)
config.hvis.BorderSizePixel = 0
config.hvis.ZIndex = 10
config.hvis.Active = false
config.hvis.Archivable = false
config.hvis.Parent = config.hthumb
RoundCorner(config.hvis, 1, 0)

config.emptyLabel = Instance.new("TextLabel")
config.emptyLabel.Name = RandomString()
config.emptyLabel.Size = UDim2.new(1, 0, 0, 40)
config.emptyLabel.Position = UDim2.new(0, 0, 0, 40)
config.emptyLabel.BackgroundTransparency = 1
config.emptyLabel.Text = ""
config.emptyLabel.TextColor3 = config.COLORS.TEXT_DIM
config.emptyLabel.FontFace = config.FONT.GothamMedium
config.emptyLabel.TextSize = 11
config.emptyLabel.TextWrapped = true
config.emptyLabel.Visible = false
config.emptyLabel.ZIndex = 4
config.emptyLabel.Archivable = false
config.emptyLabel.Parent = config.scrolling

config.insertBtn = Instance.new("TextButton")
config.insertBtn.Name = RandomString()
config.insertBtn.Size = UDim2.new(0, 18, 0, 18)
config.insertBtn.BackgroundTransparency = 1
config.insertBtn.BorderSizePixel = 0
config.insertBtn.AutoButtonColor = false
config.insertBtn.Text = ""
config.insertBtn.Visible = false
config.insertBtn.ZIndex = 6
config.insertBtn.Archivable = false
config.insertBtn.Parent = config.scrolling

do
 local ring = Instance.new("Frame")
 ring.Size = UDim2.new(0, 14, 0, 14)
 ring.Position = UDim2.new(0.5, -7, 0.5, -7)
 ring.BackgroundColor3 = Color3.fromRGB(190, 190, 190)
 ring.BorderSizePixel = 0
 ring.ZIndex = 7
 ring.Archivable = false
 ring.Parent = config.insertBtn
 local rc = Instance.new("UICorner")
 rc.CornerRadius = UDim.new(1, 0)
 rc.Parent = ring
 for _, d in ipairs({ { 8, 2 }, { 2, 8 } }) do
  local bar = Instance.new("Frame")
  bar.Size = UDim2.new(0, d[1], 0, d[2])
  bar.Position = UDim2.new(0.5, -d[1] / 2, 0.5, -d[2] / 2)
  bar.BackgroundColor3 = config.COLORS.PRIMARY
  bar.BorderSizePixel = 0
  bar.ZIndex = 7
  bar.Archivable = false
  bar.Parent = config.insertBtn
 end
end

local function PlaceInsertBtn(row, slot)
 local w = config.SV.TextSrv:GetTextSize(row.instance.Name, 21, Enum.Font.SourceSans, Vector2.new(10000, 26)).X
 local x = config.Positions.TEXT_X + row.depth * config.Positions.INDENT + w + 6 - config.ScrollHOffset
 config.insertBtn.Position = UDim2.new(0, math.max(0, x), 0, (slot - 1) * config.ROW_H + (config.ROW_H - 18) / 2)
 config.insertBtn.Visible = true
end

local function MakeDraggable(panel, handle, opts)
 opts = opts or {}
 local state = { Dragging = false, activeInput = nil, dragStart = nil, startPos = nil, didDrag = false, inset = Vector2.new(0, 0), cursor = nil }

 handle.InputBegan:Connect(function(inp)
  if not config.Fresh(inp) then return end
  if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  if opts.BlockCheck and opts.BlockCheck() then return end
  state.inset = AbsOf(inp, handle) - Vector2.new(inp.Position.X, inp.Position.Y)
  state.cursor = nil
  if opts.OnBegin then opts.OnBegin(inp) end
  state.Dragging = true
  state.didDrag = false
  state.activeInput = inp
  state.dragStart = inp.Position
  state.startPos = panel.Position
 end)

 config.SV.UserInput.InputChanged:Connect(function(inp)
  if not state.Dragging then return end
  if not config.Held(inp) then
  	state.Dragging = false
  	state.activeInput = nil
  	if opts.OnEnd then opts.OnEnd(state.didDrag, state.cursor) end
  	return
  end
  local ai = state.activeInput
  if inp ~= ai and not (inp.UserInputType == Enum.UserInputType.MouseMovement and ai.UserInputType == Enum.UserInputType.MouseButton1) then return end
  if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  local delta = inp.Position - state.dragStart
  if opts.threshold and not state.didDrag and delta.Magnitude < opts.threshold then return end
  state.didDrag = true
  panel.Position = UDim2.new(
   state.startPos.X.Scale, state.startPos.X.Offset + delta.X,
   state.startPos.Y.Scale, state.startPos.Y.Offset + delta.Y
  )
  ClampPanelTop(panel)
  state.cursor = Vector2.new(inp.Position.X, inp.Position.Y) + state.inset
  if opts.OnDrag then opts.OnDrag(state.cursor) end
 end)

 config.SV.UserInput.InputEnded:Connect(function(inp)
  if inp ~= state.activeInput then return end
  if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  state.Dragging = false
  state.activeInput = nil
  if opts.OnEnd then opts.OnEnd(state.didDrag, state.cursor) end
 end)

 return state
end

local function MakeResizeHandler(min_w, min_h, edge, xS, yS, xO, yO, wS, hS, wO, hO, z, window, blockCheck, onResize)
 local isH = edge:find("left") or edge:find("right")
 local isV = edge:find("top") or edge:find("bottom")
 local signX = edge:find("left") and -1 or 1
 local signY = edge:find("top") and -1 or 1

 local h = Instance.new("TextButton")
 h.Name = RandomString()
 h.Position = UDim2.new(xS, xO, yS, yO)
 h.Size = UDim2.new(wS, wO, hS, hO)
 h.BackgroundTransparency = 1
 h.Text = ""
 h.ZIndex = z or 8
 h.Archivable = false
 h.Parent = window

 h.InputBegan:Connect(function(inp)
  if not config.Fresh(inp) then return end
  if Explorer.PanelResizing[window] then return end
  if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  if config.IsMinimized and isV and window == config.main then return end
  if blockCheck and blockCheck() then return end

  local pos = AbsOf(inp, h)
  local ap, as = h.AbsolutePosition, h.AbsoluteSize
  if pos.X < ap.X or pos.X > ap.X + as.X or pos.Y < ap.Y or pos.Y > ap.Y + as.Y then return end

  Explorer.PanelResizing[window] = true
  local startMouse = inp.Position
  local startW, startH = window.Size.X.Offset, window.Size.Y.Offset
  local startPosXScale, startPosXOffset = window.Position.X.Scale, window.Position.X.Offset
  local startPosYScale, startPosYOffset = window.Position.Y.Scale, window.Position.Y.Offset

  local relCon, movCon

  relCon = config.SV.UserInput.InputEnded:Connect(function(i)
   if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
   relCon:Disconnect()
   if movCon then movCon:Disconnect() end
   Explorer.PanelResizing[window] = nil
  end)

  movCon = config.SV.UserInput.InputChanged:Connect(function(i)
   if not Explorer.PanelResizing[window] then return end
   if not config.Held(i) then
   	if relCon then relCon:Disconnect() end
   	if movCon then movCon:Disconnect() end
   	Explorer.PanelResizing[window] = nil
   	return
   end
   if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end

   local dx = i.Position.X - startMouse.X
   local dy = i.Position.Y - startMouse.Y

   if isH then
    local newW = math.max(min_w, startW + dx * signX)
    local dW = newW - startW

    if window.AnchorPoint.X == 0 then
     if signX == -1 then
      window.Position = UDim2.new(startPosXScale, RoundPx(startPosXOffset - dW), window.Position.Y.Scale, window.Position.Y.Offset)
     end
    else
     window.Position = UDim2.new(
      startPosXScale, RoundPx(startPosXOffset + dW * 0.5 * signX),
      window.Position.Y.Scale, window.Position.Y.Offset
     )
    end
    window.Size = UDim2.new(0, RoundPx(newW), 0, window.Size.Y.Offset)
   end

   if isV then
    local newH = math.max(min_h, startH + dy * signY)
    if signY == -1 and window.Parent then
     local scrH = window.Parent.AbsoluteSize.Y
     local startTop = startPosYScale * scrH + startPosYOffset - window.AnchorPoint.Y * startH
     newH = math.max(min_h, math.min(newH, startH + math.max(0, startTop - TopInset())))
    end
    local dH = newH - startH

    if window.AnchorPoint.Y == 0 then
     if signY == -1 then
      window.Position = UDim2.new(window.Position.X.Scale, window.Position.X.Offset, startPosYScale, startPosYOffset - dH)
     end
    else
     window.Position = UDim2.new(
      window.Position.X.Scale, window.Position.X.Offset,
      startPosYScale, startPosYOffset + dH * 0.5 * signY
     )
    end
    window.Size = UDim2.new(0, window.Size.X.Offset, 0, newH)
   end

   if onResize then onResize(window.Size) end
  end)
 end)
end

local function SyncMainResize(newSize)
 local fW = newSize.X.Offset
 local fH = newSize.Y.Offset
 config.NormalSize = UDim2.new(0, fW, 0, fH)
 config.MinimizedSize = UDim2.new(0, fW, 0, 44)
 if config.DockSide and config.LayoutDocks then config.LayoutDocks() end
end

config.dockHint = Instance.new("Frame")
config.dockHint.Name = RandomString()
config.dockHint.BackgroundColor3 = config.COLORS.ACCENT
config.dockHint.BackgroundTransparency = 0.75
config.dockHint.BorderSizePixel = 0
config.dockHint.Visible = false
config.dockHint.ZIndex = 30
config.dockHint.Active = false
config.dockHint.Archivable = false
config.dockHint.Parent = config.window
BorderStroke(config.dockHint, 2, 100, 160, 255)

config.stackSplitter = Instance.new("TextButton")
config.stackSplitter.Name = RandomString()
config.stackSplitter.BackgroundColor3 = config.COLORS.RESIZER
config.stackSplitter.BorderSizePixel = 0
config.stackSplitter.AutoButtonColor = false
config.stackSplitter.Text = ""
config.stackSplitter.Visible = false
config.stackSplitter.ZIndex = 9
config.stackSplitter.Archivable = false
config.stackSplitter.Parent = config.window

local function IsStacked()
 return config.pmain ~= nil and config.PDock.Side ~= nil and config.PDock.Side == config.DockSide and config.main.Visible and config.pmain.Visible
end

config.LayoutDocks = function()
 local scr = config.window.AbsoluteSize
 if scr.X <= 0 or scr.Y <= 0 then return end
 local stacked = IsStacked()
 local ew = config.main.Size.X.Offset
 local pw = config.pmain and config.pmain.Size.X.Offset or ew
 local minH = 120
 local top = TopInset()
 if stacked then
  pw = ew
  if not config.PDock.WasStacked or config.PDock.LastOrder ~= config.PDock.Order then config.PDock.Split = nil end
  config.PDock.WasStacked, config.PDock.LastOrder = true, config.PDock.Order
  local availH = scr.Y - top
  local defaultSplit = top + math.floor(availH * 0.5)
  config.PDock.Split = math.clamp(config.PDock.Split or defaultSplit, top + minH, math.max(top + minH, scr.Y - minH))
 else
  config.PDock.WasStacked = false
 end
 local explorerOnTop = config.PDock.Order == "below"

 if config.DockSide then
  local y, h = top, scr.Y - top
  if stacked then
   if explorerOnTop then y, h = top, config.PDock.Split - top else y, h = config.PDock.Split, scr.Y - config.PDock.Split end
  end
  config.main.AnchorPoint = Vector2.new(0, 0)
  config.main.Position = UDim2.new(0, config.DockSide == "left" and 0 or scr.X - ew, 0, y)
  config.main.Size = UDim2.new(0, ew, 0, h)
 end

 if config.pmain and config.PDock.Side then
  local y, h = top, scr.Y - top
  if stacked then
   if explorerOnTop then y, h = config.PDock.Split, scr.Y - config.PDock.Split else y, h = top, config.PDock.Split - top end
  end
  config.pmain.AnchorPoint = Vector2.new(0, 0)
  config.pmain.Position = UDim2.new(0, config.PDock.Side == "left" and 0 or scr.X - pw, 0, y)
  config.pmain.Size = UDim2.new(0, pw, 0, h)
 end

 if config.pdocksplitter then
  config.pdocksplitter.Visible = config.PDock.Side ~= nil
  if config.PDock.Side == "left" then
   config.pdocksplitter.Position = UDim2.new(1, 0, 0, 0)
  else
   config.pdocksplitter.Position = UDim2.new(0, -6, 0, 0)
  end
 end

 config.stackSplitter.Visible = stacked
 if stacked then
  config.stackSplitter.Position = UDim2.new(0, config.DockSide == "left" and 0 or scr.X - ew, 0, config.PDock.Split - 3)
  config.stackSplitter.Size = UDim2.new(0, ew, 0, 7)
 end

 if config.LayoutSource then config.LayoutSource() end
end

do
 local dragging, startY, startSplit
 config.stackSplitter.InputBegan:Connect(function(inp)
  if not config.Fresh(inp) then return end
  if not IsPress(inp) then return end
  dragging = true
  startY = inp.Position.Y
  startSplit = config.PDock.Split or 0
 end)
 config.SV.UserInput.InputChanged:Connect(function(inp)
  if not dragging then return end
  if not config.Held(inp) then dragging = false return end
  if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  config.PDock.Split = startSplit + (inp.Position.Y - startY)
  config.LayoutDocks()
 end)
 config.SV.UserInput.InputEnded:Connect(function(inp)
  if IsPress(inp) then dragging = false end
 end)
end

local function DropZone(gui, cur)
 local ap, as = gui.AbsolutePosition, gui.AbsoluteSize
 if cur.X < ap.X or cur.X > ap.X + as.X or cur.Y < ap.Y or cur.Y > ap.Y + as.Y then return nil, false end
 local z = math.clamp(as.Y * 0.25, 40, 140)
 if cur.Y <= ap.Y + z then return "top", true end
 if cur.Y >= ap.Y + as.Y - z then return "bottom", true end
 return nil, true
end

local function ResolveDrop(dragged, other, otherSide, otherVisible, cur)
 if not cur then return nil end
 local scr = config.window.AbsoluteSize
 local otherDocked = otherSide ~= nil and otherVisible
 if otherDocked then
  local zone, inside = DropZone(other, cur)
  if inside then
   if zone then return otherSide, zone end
   return nil
  end
 end
 local ap, as = dragged.AbsolutePosition, dragged.AbsoluteSize
 local side
 if ap.X <= 40 then side = "left"
 elseif scr.X - (ap.X + as.X) <= 40 then side = "right" end
 if not side then return nil end
 local zone
 if otherDocked and otherSide == side then
  local oap, oas = other.AbsolutePosition, other.AbsoluteSize
  zone = (cur.Y < oap.Y + oas.Y / 2) and "top" or "bottom"
 end
 return side, zone
end

local function ShowHint(dragged, other, side, zone)
 if not side then config.dockHint.Visible = false return end
 local scr = config.window.AbsoluteSize
 if zone and other then
  local ap, as = other.AbsolutePosition, other.AbsoluteSize
  local h = as.Y / 2
  config.dockHint.Position = UDim2.new(0, ap.X, 0, zone == "top" and ap.Y or ap.Y + h)
  config.dockHint.Size = UDim2.new(0, as.X, 0, h)
 else
  local w = dragged.AbsoluteSize.X
  local inset = TopInset()
  config.dockHint.Position = UDim2.new(0, side == "left" and 0 or scr.X - w, 0, inset)
  config.dockHint.Size = UDim2.new(0, w, 1, -inset)
 end
 config.dockHint.Visible = true
end

MakeDraggable(config.main, config.header, {
 BlockCheck = function()
  return Explorer.PanelResizing[config.main]
 end,
 threshold = 4,
 OnBegin = function()
  if config.DockSide then Undock() end
 end,
 OnDrag = function(cursor)
  local side, zone = ResolveDrop(config.main, config.pmain, config.PDock.Side, config.pmain ~= nil and config.pmain.Visible, cursor)
  ShowHint(config.main, config.pmain, side, zone)
 end,
 OnEnd = function(didDrag, cursor)
  config.dockHint.Visible = false
  if not didDrag then return end
  local side, zone = ResolveDrop(config.main, config.pmain, config.PDock.Side, config.pmain ~= nil and config.pmain.Visible, cursor)
  if not side then return end
  if zone and config.PDock.Side == side and config.pmain and config.pmain.Visible then
   config.PDock.Order = (zone == "top") and "below" or "above"
  end
  ApplyDock(side)
 end,
})

MakeResizeHandler(220, 160, "right", 1,0, 3-config.EDGE*2, config.EDGE, 0,1, config.EDGE*2, -config.EDGE*2, 8, config.main, function() return config.DockSide == "right" end, SyncMainResize)
MakeResizeHandler(220, 160, "left", 0,0, -3, config.EDGE, 0,1, config.EDGE*2, -config.EDGE*2, 8, config.main, function() return config.DockSide == "left" end, SyncMainResize)
MakeResizeHandler(220, 160, "bottom", 0,1, config.EDGE, 0, 1,0, -config.EDGE*2, config.EDGE*2, 8, config.main, function() return config.DockSide ~= nil end, SyncMainResize)
MakeResizeHandler(220, 160, "top", 0,0, config.EDGE, -config.EDGE*2, 1,0, -config.EDGE*2, config.EDGE*2, 8, config.main, function() return config.DockSide ~= nil end, SyncMainResize)
MakeResizeHandler(220, 160, "top_left", 0,0, -3, -config.EDGE*2, 0,0, config.EDGE*2, config.EDGE*2, 9, config.main, function() return config.DockSide ~= nil end, SyncMainResize)
MakeResizeHandler(220, 160, "top_right", 1,0, 3-config.EDGE*2, -config.EDGE*2, 0,0, config.EDGE*2, config.EDGE*2, 9, config.main, function() return config.DockSide ~= nil end, SyncMainResize)
MakeResizeHandler(220, 160, "bottom_left", 0,1, -3, 0, 0,0, config.EDGE*2, config.EDGE*2, 9, config.main, function() return config.DockSide ~= nil end, SyncMainResize)
MakeResizeHandler(220, 160, "bottom_right", 1,1, 3-config.EDGE*2, 0, 0,0, config.EDGE*2, config.EDGE*2, 9, config.main, function() return config.DockSide ~= nil end, SyncMainResize)

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
 warn("[Explorer drag] " .. where .. ": " .. tostring(err))
end

local function DragTopLevel(list)
 local set, out = {}, {}
 for _, i in ipairs(list) do set[i] = true end
 for _, i in ipairs(list) do
  local cur, nested = i.Parent, false
  while cur do
   if set[cur] then nested = true break end
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
 if Drag.hb then Drag.hb:Disconnect() Drag.hb = nil end
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
 if #list == 0 then Drag.pending = nil return end
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
 if not okc then DragWarn("move", errc) DragStop() end
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

local function CreatePoolEntry(poolIndex)
 local entry = Instance.new("TextButton")
 entry.Name = RandomString()
 entry.Size = UDim2.new(0, 100, 0, config.ROW_H)
 entry.BackgroundColor3 = config.COLORS.SELECTED
 entry.BackgroundTransparency = 1
 entry.Text = ""
 entry.AutoButtonColor = false
 entry.Visible = false
 entry.ZIndex = 3
 entry.Archivable = false
 entry.Parent = config.scrolling

 local corner = Instance.new("UICorner")
 corner.CornerRadius = UDim.new(0, 8)
 corner.Parent = entry

 local bottomMask = Instance.new("Frame")
 bottomMask.Name = RandomString()
 bottomMask.BorderSizePixel = 0
 bottomMask.BackgroundColor3 = entry.BackgroundColor3
 bottomMask.BackgroundTransparency = 1
 bottomMask.ZIndex = entry.ZIndex
 bottomMask.Visible = false
 bottomMask.Archivable = false
 bottomMask.Parent = config.scrolling

 local toggle = Instance.new("ImageButton")
 toggle.Name = RandomString()
 toggle.Size = UDim2.new(0, 20, 0, 20)
 toggle.BackgroundTransparency = 1
 toggle.Image = ""
 toggle.ZIndex = 5
 toggle.Active = true
 toggle.AutoButtonColor = false
 toggle.Archivable = false
 toggle.Parent = config.scrolling

 local toggleIcon = Instance.new("ImageLabel")
 toggleIcon.Name = RandomString()
 toggleIcon.Size = UDim2.new(0, 10, 0, 10)
 toggleIcon.AnchorPoint = Vector2.new(0.5, 0.5)
 toggleIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
 toggleIcon.BackgroundTransparency = 1
 toggleIcon.Image = config.IMG.Caret
 toggleIcon.ZIndex = 5
 toggleIcon.Active = false
 toggleIcon.Archivable = false
 toggleIcon.Parent = toggle

 local icon = Instance.new("ImageLabel")
 icon.Name = RandomString()
 icon.Size = UDim2.new(0, config.Positions.ICON_PX, 0, config.Positions.ICON_PX)
 icon.BackgroundTransparency = 1
 icon.Image = config.ICON_ID
 icon.ImageRectSize = config.ICON_SIZE
 icon.ZIndex = 4
 icon.Archivable = false
 icon.Parent = config.scrolling

 local label = Instance.new("TextLabel")
 label.Name = RandomString()
 label.BackgroundTransparency = 1
 label.TextColor3 = config.COLORS.TEXT
 label.TextXAlignment = Enum.TextXAlignment.Left
 label.TextYAlignment = Enum.TextYAlignment.Center
 label.Font = Enum.Font.SourceSans
 label.TextSize = 21
 label.TextTruncate = Enum.TextTruncate.AtEnd
 label.ZIndex = 4
 label.Archivable = false
 label.Parent = config.scrolling

 local holdThread, holdStartPos
 local data = { inst = nil, row = nil, mask = bottomMask, holdTriggered = false, hovering = false, highlighted = false }

 local function OnHoverEnter()
  local inst = data.inst
  if not inst then return end
  data.hovering = true
  if not data.highlighted then
   corner.CornerRadius = UDim.new(0, 8)
   entry.BackgroundColor3 = config.COLORS.SECONDARY
   entry.BackgroundTransparency = 0.6
  elseif Explorer.SelectedSet[inst] then
   entry.BackgroundColor3 = config.COLORS.SELECTED_HOVER
   entry.BackgroundTransparency = 0
  else
   entry.BackgroundColor3 = config.COLORS.SELECTED
   entry.BackgroundTransparency = 0.7
  end
  bottomMask.BackgroundColor3 = entry.BackgroundColor3
  bottomMask.BackgroundTransparency = entry.BackgroundTransparency
  config.HoverInst = inst
  config.InsertTarget = inst
  PlaceInsertBtn(data.row, poolIndex)
 end
 local function OnHoverLeave()
  data.hovering = false
  if not data.highlighted then
   corner.CornerRadius = UDim.new(0, 0)
   entry.BackgroundColor3 = config.COLORS.SELECTED
   entry.BackgroundTransparency = 1
  else
   local sel = data.inst and Explorer.SelectedSet[data.inst] == true
   entry.BackgroundColor3 = config.COLORS.SELECTED
   entry.BackgroundTransparency = sel and 0 or 0.85
  end
  bottomMask.BackgroundColor3 = entry.BackgroundColor3
  bottomMask.BackgroundTransparency = entry.BackgroundTransparency
  config.HoverInst = nil
  task.defer(function()
   if not config.OverInsert and not config.HoverInst then config.insertBtn.Visible = false end
  end)
 end
 local inEntry, inMask, inToggle = false, false, false
 local function RefreshHover()
  local want = (inEntry or inMask) and not inToggle
  if want and not data.hovering then OnHoverEnter()
  elseif not want and data.hovering then OnHoverLeave() end
 end
 data.ClearMaskHover = function()
  if inMask then inMask = false; RefreshHover() end
 end
 entry.MouseEnter:Connect(function() inEntry = true; RefreshHover() end)
 entry.MouseLeave:Connect(function() inEntry = false; RefreshHover() end)
 bottomMask.MouseEnter:Connect(function() inMask = true; RefreshHover() end)
 bottomMask.MouseLeave:Connect(function() inMask = false; RefreshHover() end)
 toggle.MouseEnter:Connect(function() inToggle = true; RefreshHover() end)
 toggle.MouseLeave:Connect(function() inToggle = false; RefreshHover() end)
 config.pooldata[poolIndex] = data

 entry.InputBegan:Connect(function(inp)
  if not config.Fresh(inp) then return end
  local inst = data.inst
  if not inst then return end
  if inp.UserInputType == Enum.UserInputType.MouseButton2 then
   if OpenContextMenu then OpenContextMenu(inst, inp.Position.X, inp.Position.Y) end
   return
  end
  if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end

  holdStartPos = inp.Position
  if inst.Parent ~= Explorer.Root then
   Explorer.Drag.Calibrate(inp, entry)
   Explorer.Drag.pending = {
    inst = inst,
    grabX = Explorer.Drag.CursorOf(inp).X - entry.AbsolutePosition.X,
    rowWidth = entry.AbsoluteSize.X,
    grabY = Explorer.Drag.anchor and (Explorer.Drag.anchor.Y - entry.AbsolutePosition.Y) or (config.ROW_H / 2),
    CancelHold = function()
     if holdThread then task.cancel(holdThread) holdThread = nil end
    end,
   }
   Explorer.Drag.startPos = Vector2.new(inp.Position.X, inp.Position.Y)
   Explorer.Drag.cursor = Explorer.Drag.CursorOf(inp)
  end
  if holdThread then task.cancel(holdThread) end
  holdThread = task.delay(0.4, function()
   holdThread = nil
   if Explorer.Drag.active or Explorer.Drag.pending and Explorer.Drag.pending.moved then return end
   data.holdTriggered = true
   if OpenContextMenu then OpenContextMenu(inst, inp.Position.X, inp.Position.Y) end
  end)
 end)

 entry.InputChanged:Connect(function(inp)
  if not holdThread or not holdStartPos then return end
  if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  if (inp.Position - holdStartPos).Magnitude > 8 then
   task.cancel(holdThread)
   holdThread = nil
  end
 end)

 entry.InputEnded:Connect(function(inp)
  if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  if holdThread then task.cancel(holdThread) holdThread = nil end
 end)

 toggle.MouseButton1Down:Connect(function()
  local inst = data.inst
  if not inst then return end
  if not Explorer.HasChildren(inst) then return end

  local idx = Explorer.RowIndex and Explorer.RowIndex[inst]
  if not idx then return end
  local row = config.visiblerows[idx]
  if not row then return end
  local shift = config.SV.UserInput:IsKeyDown(Enum.KeyCode.LeftShift) or config.SV.UserInput:IsKeyDown(Enum.KeyCode.RightShift)
  if row.expanded then
   if shift then Explorer.CollapseAll(inst) else Explorer.CollapseRow(idx, row, inst) end
  else
   if shift then Explorer.ExpandAll(inst) else Explorer.ExpandRow(idx, row, inst) end
  end
 end)

 entry.Activated:Connect(function()
  if data.holdTriggered then
   data.holdTriggered = false
   return
  end
  if Explorer.Drag.justDragged then return end
  local inst = data.inst
  if not inst then return end
  Explorer.ClickSelect(inst)
  if not Explorer.Selected then return end

  local now = tick()
  local last = config.LastClickedTime[inst] or 0
  local isDouble = (now - last) < config.DOUBLE_CLICK
  config.LastClickedTime[inst] = now
  if Explorer.IsSourceOpen and Explorer.IsSourceOpen() and Explorer.IsScript(inst) and Explorer.Selected == inst then
   pcall(Explorer.OpenSource, inst)
  end
  if isDouble then
   config.LastClickedTime[inst] = 0
   if Explorer.IsScript(inst) then pcall(Explorer.OpenSource, inst) end
   if Explorer.OnDoubleClickCb then pcall(Explorer.OnDoubleClickCb, inst) end
  end
 end)

 return {
  entry = entry,
  toggle = toggle,
  icon = icon,
  label = label,
  mask = bottomMask,
  corner = corner,
 }
end

local function EnsurePoolSize(n)
 for i = #config.entries + 1, n do
  config.entries[i] = CreatePoolEntry(i)
 end
end

local function GetGuideLine(n)
 while #config.guideLines < n do
  local line = Instance.new("Frame")
  line.Name = RandomString()
  line.BorderSizePixel = 0
  line.BackgroundColor3 = config.COLORS.WHITE
  line.BackgroundTransparency = 0.9
  line.ZIndex = 3
  line.Archivable = false
  line.Parent = config.scrolling
  table.insert(config.guideLines, line)
 end
 return config.guideLines[n]
end

config.SUBCLASS = {
 basepart = {Part=1,MeshPart=1,UnionOperation=1,WedgePart=1,CornerWedgePart=1,TrussPart=1,SpawnLocation=1,Seat=1,VehicleSeat=1},
 luasourcecontainer = {Script=1,LocalScript=1,ModuleScript=1},
 guiobject = {Frame=1,TextLabel=1,TextButton=1,TextBox=1,ImageLabel=1,ImageButton=1,ScrollingFrame=1,ViewportFrame=1,CanvasGroup=1},
 guibutton = {TextButton=1,ImageButton=1},
 light = {PointLight=1,SpotLight=1,SurfaceLight=1},
 pvinstance = {Model=1,Part=1,MeshPart=1,UnionOperation=1,WedgePart=1,CornerWedgePart=1,TrussPart=1,SpawnLocation=1,Seat=1,VehicleSeat=1,WorldModel=1},
}

config.LCLS = {}
local function Lcls(c)
 local l = config.LCLS[c]
 if not l then l = c:lower() config.LCLS[c] = l end
 return l
end

local function IsA(inst, cls)
 local cn = inst.ClassName
 local c = Lcls(cn)
 if c == cls or cls == "instance" then return true end
 local set = config.SUBCLASS[cls]
 if set and set[cn] then return true end
 if cls == "valuebase" and c:match("value$") then return true end
 if cls == "constraint" and c:match("constraint$") then return true end
 if cls == "soundeffect" and c:match("soundeffect$") then return true end
 if cls == "posteffect" and c:match("effect$") and not c:match("soundeffect$") then return true end
 return false
end

local function HasTag(inst, tag)
 local t = rawget(inst, "Tags")
 if type(t) ~= "table" then return false end
 for k, v in pairs(t) do
  if type(k) == "string" and v == true and k:lower() == tag then return true end
  if type(v) == "string" and v:lower() == tag then return true end
 end
 return false
end

local function Lname(inst)
 local nm = inst.Name
 if inst._lnSrc ~= nm then
  inst._lnSrc = nm
  inst._ln = tostring(nm):lower()
 end
 return inst._ln
end

local function NormVal(v) return (tostring(v):lower():gsub("%s", "")) end
local function Unquote(v) return (v:gsub('"', "")) end

config.PredMeta = config.PredMeta or setmetatable({}, { __mode = "k" })
local PM = config.PredMeta
local function TagPred(f, cost, stable)
 PM[f] = { cost = cost, stable = stable }
 return f
end

local function Tokenize(str)
 str = str:gsub("%s*([<>=!~]+)%s*", "%1")
 local toks, n, cur, inQ = {}, 0, {}, false
 local cn = 0
 local function Push()
  if cn > 0 then
   n += 1
   toks[n] = table.concat(cur, "", 1, cn)
   cn = 0
  end
 end
 for i = 1, #str do
  local ch = str:sub(i, i)
  if ch == '"' then
   inQ = not inQ
   cn += 1 cur[cn] = ch
  elseif inQ then
   cn += 1 cur[cn] = ch
  elseif ch == "(" or ch == ")" then
   Push()
   n += 1
   toks[n] = ch
  elseif ch:match("%s") then
   Push()
  else
   cn += 1 cur[cn] = ch
  end
 end
 Push()
 return toks
end

local function ParentOf(n)
 local p = n.Parent
 if p == Explorer.Root then return nil end
 return p
end

local function MakeGetter(key)
 local k = key:lower()
 if k == "name" then return function(inst) return inst.Name end end
 if k == "classname" then return function(inst) return inst.ClassName end end
 local pKey, aKey
 return function(inst)
  local props = rawget(inst, "Properties")
  if props then
   if pKey ~= nil then
    local v = props[pKey]
    if v ~= nil then return v end
   end
   for pk, pv in pairs(props) do
    if tostring(pk):lower() == k then pKey = pk return pv end
   end
  end
  local attrs = rawget(inst, "Attributes")
  if attrs then
   if aKey ~= nil then
    local v = attrs[aKey]
    if v ~= nil then return v end
   end
   for ak, av in pairs(attrs) do
    if tostring(ak):lower() == k then aKey = ak return av end
   end
  end
  return nil
 end
end

local function MakeAtom(t)
 local key, op, val = t:match('^([%w_]+)([<>=!~]+)(.+)$')
 if key and not t:find('^"') then
  val = Unquote(val)
  local get = MakeGetter(key)
  local nval = NormVal(val)
  local nnum = tonumber(val)
  if op == "=" or op == "==" then
   return TagPred(function(inst)
    local pv = get(inst)
    return pv ~= nil and NormVal(pv):find(nval, 1, true) ~= nil
   end, 4, false)
  elseif op == "!=" or op == "~=" then
   return TagPred(function(inst)
    local pv = get(inst)
    return pv == nil or NormVal(pv):find(nval, 1, true) == nil
   end, 4, false)
  end
  local Cmp
  if op == "<" then Cmp = function(a, b) return a < b end
  elseif op == ">" then Cmp = function(a, b) return a > b end
  elseif op == "<=" then Cmp = function(a, b) return a <= b end
  elseif op == ">=" then Cmp = function(a, b) return a >= b end end
  return TagPred(function(inst)
   local a = tonumber(get(inst))
   if not a or not nnum or not Cmp then return false end
   return Cmp(a, nnum)
  end, 4, false)
 end

 local pfx, rest = t:match('^(%a+):(.*)$')
 if pfx then
  local p = pfx:lower()
  rest = Unquote(rest):lower()
  if p == "classname" or p == "class" then
   return TagPred(function(inst) return Lcls(inst.ClassName):find(rest, 1, true) ~= nil end, 1, true)
  elseif p == "is" then
   local memo = {}
   return TagPred(function(inst)
    local cn = inst.ClassName
    local r = memo[cn]
    if r == nil then r = IsA(inst, rest) memo[cn] = r end
    return r
   end, 1, true)
  elseif p == "tag" then
   return TagPred(function(inst) return HasTag(inst, rest) end, 2, false)
  elseif p == "name" then
   return TagPred(function(inst) return Lname(inst):find(rest, 1, true) ~= nil end, 1, true)
  end
 end

 if t:find(".", 1, true) and not t:find('"') then
  local segs = {}
  for part in (t .. "."):gmatch("([^%.]*)%.") do segs[#segs + 1] = part:lower() end
  local ok = #segs >= 2
  for _, sg in ipairs(segs) do if sg == "" then ok = false end end
  if ok then
   local function M(node, i)
    if i == 0 then return true end
    local sg = segs[i]
    if sg == "**" then
     local cur = node
     while cur do
      if M(ParentOf(cur), i - 1) then return true end
      cur = ParentOf(cur)
     end
     return false
    end
    if not node then return false end
    if sg ~= "*" and not Lname(node):find(sg, 1, true) then return false end
    return M(ParentOf(node), i - 1)
   end
   local n = #segs
   return TagPred(function(inst) return M(inst, n) end, 3, false)
  end
 end

 local q = Unquote(t):lower()
 return TagPred(function(inst) return Lname(inst):find(q, 1, true) ~= nil end, 1, true)
end

local function Combine(list, isAnd)
 local n = #list
 if n == 1 then return list[1] end
 for i = 2, n do
  local f = list[i]
  local c = PM[f].cost
  local j = i - 1
  while j >= 1 and PM[list[j]].cost > c do
   list[j + 1] = list[j]
   j -= 1
  end
  list[j + 1] = f
 end
 local cost, stable = 0, true
 for i = 1, n do
  local m = PM[list[i]]
  cost += m.cost
  if not m.stable then stable = false end
 end
 local F
 if n == 2 then
  local a, b = list[1], list[2]
  if isAnd then F = function(i) return a(i) and b(i) end
  else F = function(i) return a(i) or b(i) end end
 elseif isAnd then
  F = function(inst)
   for i = 1, n do
    if not list[i](inst) then return false end
   end
   return true
  end
 else
  F = function(inst)
   for i = 1, n do
    if list[i](inst) then return true end
   end
   return false
  end
 end
 return TagPred(F, cost, stable)
end

config.PredCounter = config.PredCounter or 0

function Explorer.CompileSearch(str)
 str = str:match("^%s*(.-)%s*$")
 if str == "" then return nil end
 local toks, pos = Tokenize(str), 1
 local ParseOr
 local function IsKw(t, kw) return t ~= nil and t:lower() == kw end
 local function ParsePrimary()
  local t = toks[pos]
  if not t or t == ")" or IsKw(t, "and") or IsKw(t, "or") then return nil end
  pos += 1
  if t == "(" then
   local e = ParseOr()
   if toks[pos] == ")" then pos += 1 end
   return e
  end
  return MakeAtom(t)
 end
 local function ParseAnd()
  local first = ParsePrimary()
  if not first then return nil end
  local list = { first }
  while true do
   local t = toks[pos]
   if not t or t == ")" or IsKw(t, "or") then break end
   if IsKw(t, "and") then pos += 1 end
   local right = ParsePrimary()
   if not right then break end
   list[#list + 1] = right
  end
  return Combine(list, true)
 end
 ParseOr = function()
  local first = ParseAnd() or TagPred(function() return true end, 0, true)
  local list = { first }
  while IsKw(toks[pos], "or") do
   pos += 1
   local right = ParseAnd()
   if not right then break end
   list[#list + 1] = right
  end
  return Combine(list, false)
 end
 local ok, pred = pcall(ParseOr)
 if not ok then
  local q = str:lower()
  pred = TagPred(function(inst) return Lname(inst):find(q, 1, true) ~= nil end, 1, true)
 end
 config.PredCounter += 1
 PM[pred].id = config.PredCounter
 return pred
end

local function ReadInfo(i) return i.Name, i.ClassName end

function Explorer.LoadChildren(v)
 if v.Loaded then return end
 local real = v.Real
 if not real then return end
 v.Loaded = true
 local okK, kids = pcall(real.GetChildren, real)
 if not okK or type(kids) ~= "table" then return end
 local list = v.Children
 local count = #list
 for i = 1, #kids do
  local c = kids[i]
  if c ~= config.folder then
   local ok, name, class = pcall(ReadInfo, c)
   if ok then
    count += 1
    list[count] = setmetatable({
     Name = tostring(name),
     ClassName = class or "Instance",
     Parent = v,
     Children = {},
     Real = c,
    }, VirtualInstance)
   end
  end
 end
 v._sorted = nil
end

function Explorer.HasChildren(inst)
 if inst.Children[1] ~= nil then return true end
 local real = inst.Real
 if real and not inst.Loaded then
  local h = inst.HasKids
  if h == nil then
   local ok, r = pcall(real.FindFirstChildWhichIsA, real, "Instance")
   h = ok and r ~= nil
   if h and r == config.folder then
    local ok2, k = pcall(real.GetChildren, real)
    h = ok2 and #k > 1
   end
   inst.HasKids = h
  end
  return h
 end
 return false
end

local function NameWidth(inst)
 local nm = inst.Name
 if inst._wSrc == nm then return inst._w end
 local w = config.SV.TextSrv:GetTextSize(nm, 13, Enum.Font.Gotham, Vector2.new(10000, 26)).X
 inst._wSrc, inst._w = nm, w
 return w
end

function Explorer.ScanTree()
 config.RowsRev = (config.RowsRev or 0) + 1
 local rows = {}
 config.visiblerows = rows
 local q = config.SearchQuery
 local pred = config.SearchPred
 local searching = q ~= ""

 local matchMemo, ancMemo = {}, {}
 local meta = searching and pred and config.PredMeta[pred] or nil
 local pid = meta and meta.stable and meta.id or nil

 local function Matches(inst)
  if not searching or not pred then return true end
  local m = matchMemo[inst]
  if m == nil then
   if pid then
    local nm = inst.Name
    if rawget(inst, "_mId") == pid and rawget(inst, "_mName") == nm then
     m = rawget(inst, "_mV")
    else
     m = pred(inst) == true
     inst._mId, inst._mName, inst._mV = pid, nm, m
    end
   else
    m = pred(inst) == true
   end
   matchMemo[inst] = m
  end
  return m
 end

 local function IsAncestorOfMatch(inst)
  local a = ancMemo[inst]
  if a ~= nil then return a end
  a = false
  local kids = inst.Children
  for i = 1, #kids do
   local c = kids[i]
   if Matches(c) or IsAncestorOfMatch(c) then a = true break end
  end
  ancMemo[inst] = a
  return a
 end

 local Expanded, SearchOpen = Explorer.Expanded, Explorer.SearchOpen

 local function Traverse(inst, depth, showAll)
  if inst.Real and not inst.Loaded then Explorer.LoadChildren(inst) end
  local kids = SortedChildren(inst)
  for i = 1, #kids do
   local child = kids[i]
   local m = Matches(child)
   local anc = (searching and IsAncestorOfMatch(child)) or false
   if not searching or m or anc or showAll then
    local expanded, childShowAll = false, false
    if not searching then
     expanded = Expanded[child] == true
    else
     local o = SearchOpen[child]
     if o ~= nil then
      expanded = o
      childShowAll = o and not anc
     else
      expanded = anc
     end
    end
    rows[#rows + 1] = {
     instance = child,
     depth = depth,
     expanded = expanded,
     searchLeaf = (searching and not anc),
     match = (searching and m),
    }
    if expanded then Traverse(child, depth + 1, childShowAll or (showAll and searching)) end
   end
  end
 end
 Traverse(Explorer.Root, 0)

 local index, nRows = {}, #rows
 local INDENT = config.Positions.INDENT
 local bestEst, bestRow = -1, nil
 for i = 1, nRows do
  local row = rows[i]
  local inst = row.instance
  index[inst] = i
  local est = row.depth * INDENT + #inst.Name * 8
  if est > bestEst then bestEst, bestRow = est, row end
 end
 Explorer.RowIndex = index
 config.TreeWidthBase = bestRow and (bestRow.depth * INDENT + 44 + NameWidth(bestRow.instance) + 60) or 0
 config.TreeWidthRow = bestRow
 config.emptyLabel.Visible = (nRows == 0)
end

local function AppendSubtree(out, inst, depth)
 if inst.Real and not inst.Loaded then Explorer.LoadChildren(inst) end
 local kids = SortedChildren(inst)
 local Expanded = Explorer.Expanded
 local n = #out
 for i = 1, #kids do
  local child = kids[i]
  local expanded = Expanded[child] == true
  n += 1
  out[n] = { instance = child, depth = depth, expanded = expanded, searchLeaf = false, match = false }
  if expanded then AppendSubtree(out, child, depth + 1) n = #out end
 end
end

local function FastRebuild(inst)
 config.RowsRev = (config.RowsRev or 0) + 1
 if config.SearchQuery ~= "" then return false end
 local index, rows = Explorer.RowIndex, config.visiblerows
 local idx = index and index[inst]
 local row = idx and rows[idx]
 if not row or row.instance ~= inst then return false end

 local expanded = Explorer.Expanded[inst] == true
 local depth = row.depth
 local oldN = #rows

 local last = idx
 while last < oldN and rows[last + 1].depth > depth do last += 1 end

 local fresh = {}
 if expanded then AppendSubtree(fresh, inst, depth + 1) end
 row.expanded = expanded

 local removed, added = last - idx, #fresh
 local widthRow = config.TreeWidthRow
 local lostWidthRow = false
 for i = idx + 1, last do
  local r = rows[i]
  if r == widthRow then lostWidthRow = true end
  index[r.instance] = nil
 end

 local delta = added - removed
 if delta ~= 0 then
  table.move(rows, last + 1, oldN, last + 1 + delta)
  if delta < 0 then
   for i = oldN + delta + 1, oldN do rows[i] = nil end
  end
 end
 if added > 0 then table.move(fresh, 1, added, idx + 1, rows) end

 local newN = oldN + delta
 for i = idx + 1, newN do index[rows[i].instance] = i end

 local INDENT = config.Positions.INDENT
 if lostWidthRow or not widthRow then
  local bestEst, bestRow = -1, nil
  for i = 1, newN do
   local r = rows[i]
   local est = r.depth * INDENT + #r.instance.Name * 8
   if est > bestEst then bestEst, bestRow = est, r end
  end
  config.TreeWidthRow = bestRow
  config.TreeWidthBase = bestRow and (bestRow.depth * INDENT + 44 + NameWidth(bestRow.instance) + 60) or 0
 else
  local bestEst = widthRow.depth * INDENT + #widthRow.instance.Name * 8
  local bestRow = nil
  for i = 1, added do
   local r = fresh[i]
   local est = r.depth * INDENT + #r.instance.Name * 8
   if est > bestEst then bestEst, bestRow = est, r end
  end
  if bestRow then
   config.TreeWidthRow = bestRow
   config.TreeWidthBase = bestRow.depth * INDENT + 44 + NameWidth(bestRow.instance) + 60
  end
 end
 config.emptyLabel.Visible = (newN == 0)
 return true
end

function Explorer.ExpandRow(idx, row, inst)
 Explorer.Expanded[inst] = true
 if config.SearchQuery ~= "" then Explorer.SearchOpen[inst] = true end
 if not FastRebuild(inst) then Explorer.ScanTree() end
 RefreshTree()
end

function Explorer.CollapseRow(idx, row, inst)
 Explorer.Expanded[inst] = nil
 if config.SearchQuery ~= "" then Explorer.SearchOpen[inst] = false end
 if not FastRebuild(inst) then Explorer.ScanTree() end
 RefreshTree()
end

function RefreshTree()
 if config.IsMinimized then return end

 local maxW = config.TreeWidthBase or 0
 do
  local vr = config.visiblerows
  local from = config.ScrollIndex + 1
  local to = math.min(#vr, from + math.ceil(config.body.AbsoluteSize.Y / config.ROW_H) + 2)
  for i = from, to do
   local row = vr[i]
   local needed = row.depth * config.Positions.INDENT + 44 + NameWidth(row.instance) + 60
   if needed > maxW then maxW = needed end
  end
 end
 config.TreeContentWidth = maxW

 local viewW = config.body.AbsoluteSize.X - 24
 local needH = config.TreeContentWidth > viewW
 local gutterH = needH and -24 or 0
 config.scrolling.Size = UDim2.new(1, -24, 1, gutterH)
 config.vbar.Size = UDim2.new(0, 24, 1, gutterH)
 local viewH = config.body.AbsoluteSize.Y + gutterH
 local visibleCount = math.max(1, math.ceil(viewH / config.ROW_H) + 1)
 EnsurePoolSize(visibleCount)

 local totalRows = #config.visiblerows
 local maxIndex = math.max(0, totalRows - math.floor(viewH / config.ROW_H))
 config.ScrollIndex = math.clamp(config.ScrollIndex, 0, maxIndex)

 local maxHOffset = math.max(0, config.TreeContentWidth - viewW)
 config.ScrollHOffset = math.clamp(config.ScrollHOffset, 0, maxHOffset)

 local rowW = math.max(viewW, config.TreeContentWidth)

 local highlightCache = {}
 if next(Explorer.SelectedSet) then
  for i = 0, #config.entries + 1 do
   local row = config.visiblerows[i + config.ScrollIndex]
   if row then
    local inst = row.instance
    local isSel = Explorer.SelectedSet[inst] == true
    local isDesc = false
    if config.ShowHierarchyHighlights then
     local cur = inst.Parent
     while cur do
      if Explorer.SelectedSet[cur] then isDesc = true break end
      cur = cur.Parent
     end
    end
    highlightCache[i] = isSel or isDesc
   end
  end
 end

 local absoluteIdx = 1 + config.ScrollIndex
 for i = 1, #config.entries do
  local e = config.entries[i]
  local data = config.pooldata[i]
  local row = config.visiblerows[absoluteIdx]
  if row then
   local inst = row.instance
   data.inst = inst
   data.row = row

   local depth = row.depth
   local indentation = depth * config.Positions.INDENT

   local hasKids = (not row.searchLeaf) and Explorer.HasChildren(inst)

   local isHighlighted = highlightCache[i] or false
   local isSelected = Explorer.SelectedSet[inst] == true
   data.highlighted = isHighlighted

   e.toggle.Position = UDim2.new(0, config.Positions.ARROW_X - 6 + indentation - config.ScrollHOffset, 0, (i-1)*config.ROW_H + (config.ROW_H-20)/2)
   e.toggle.Visible = hasKids
   e.toggle.Rotation = row.expanded and 90 or 0

   e.entry.Visible = true
   e.icon.Visible = true
   e.label.Visible = true
   e.entry.Position = UDim2.new(0, -config.ScrollHOffset, 0, (i-1)*config.ROW_H)
   e.entry.Size = UDim2.new(0, viewW + config.ScrollHOffset, 0, config.ROW_H)

   if isHighlighted then
    e.entry.BackgroundColor3 = config.COLORS.SELECTED
    e.entry.BackgroundTransparency = isSelected and 0 or 0.85
    if data.hovering then
     if isSelected then
      e.entry.BackgroundColor3 = config.COLORS.SELECTED_HOVER
     else
      e.entry.BackgroundTransparency = 0.7
     end
    end
    local prevHL = highlightCache[i-1] or false
    local nextHL = highlightCache[i+1] or false
    if not prevHL and not nextHL then
     e.corner.CornerRadius = UDim.new(0, 8)
     e.mask.Visible = false
    elseif not prevHL and nextHL then
     e.corner.CornerRadius = UDim.new(0, 8)
     e.mask.Visible = true
    elseif prevHL and nextHL then
     e.corner.CornerRadius = UDim.new(0, 0)
     e.mask.Visible = false
    else
     e.corner.CornerRadius = UDim.new(0, 8)
     e.mask.Visible = false
    end
    if not e.mask.Visible and data.ClearMaskHover then data.ClearMaskHover() end
    if e.mask.Visible then
     e.mask.BackgroundColor3 = e.entry.BackgroundColor3
     e.mask.BackgroundTransparency = e.entry.BackgroundTransparency
     e.mask.Position = UDim2.new(0, -config.ScrollHOffset, 0, (i-1)*config.ROW_H + config.ROW_H - 8)
     e.mask.Size = UDim2.new(0, viewW + config.ScrollHOffset, 0, 8)
    end
   else
    if data.hovering then
     e.entry.BackgroundColor3 = config.COLORS.SECONDARY
     e.entry.BackgroundTransparency = 0.6
     e.corner.CornerRadius = UDim.new(0, 8)
    else
     e.entry.BackgroundColor3 = config.COLORS.SELECTED
     e.entry.BackgroundTransparency = 1
     e.corner.CornerRadius = UDim.new(0, 0)
    end
    e.mask.Visible = false
    if data.ClearMaskHover then data.ClearMaskHover() end
   end

   e.icon.Position = UDim2.new(0, config.Positions.ICON_X + indentation - config.ScrollHOffset, 0, (i-1)*config.ROW_H + (config.ROW_H - config.Positions.ICON_PX)/2)
   local cls = inst.ClassName
   local userIcon = Explorer.UserIcons[cls]
   if data.iconCls ~= cls or data.iconUser ~= userIcon then
    data.iconCls, data.iconUser = cls, userIcon
    ApplyIcon(e.icon, cls)
   end

   e.label.Position = UDim2.new(0, config.Positions.TEXT_X + indentation - config.ScrollHOffset, 0, (i-1)*config.ROW_H)
   e.label.Size = UDim2.new(0, math.max(rowW, viewW) - config.Positions.TEXT_X - indentation - 8, 0, config.ROW_H)
   local newText = Escape(inst.Name):gsub("%s+", " ")
   if e.label.Text ~= newText then e.label.Text = newText end

   absoluteIdx = absoluteIdx + 1
  else
   e.entry.Visible = false
   e.toggle.Visible = false
   e.icon.Visible = false
   e.label.Visible = false
   e.mask.Visible = false
   data.inst = nil
   data.row = nil
  end
 end

 local runStack, stackTop, lineCount = {}, 0, 0
 local function EmitLine(depth, startIdx, endIdx)
  if endIdx <= startIdx then return end
  lineCount += 1
  local line = GetGuideLine(lineCount)
  line.Visible = true
  line.Position = UDim2.new(0, config.Positions.ARROW_X - 9 + depth*config.Positions.INDENT + 13 - config.ScrollHOffset, 0, startIdx*config.ROW_H)
  line.Size = UDim2.new(0, 1, 0, (endIdx - startIdx)*config.ROW_H)
 end

 local firstRow = config.visiblerows[1 + config.ScrollIndex]
 if firstRow then
  for d = 0, firstRow.depth - 1 do
   stackTop += 1
   local slot = runStack[stackTop]
   if not slot then slot = {} runStack[stackTop] = slot end
   slot.depth, slot.startIdx = d, 0
  end
 end

 for i = 1, #config.entries do
  local row = config.visiblerows[i + config.ScrollIndex]
  if row then
   local D = row.depth
   while stackTop > 0 and runStack[stackTop].depth >= D do
    local top = runStack[stackTop]
    EmitLine(top.depth, top.startIdx, i - 1)
    stackTop -= 1
   end
   if row.expanded then
    stackTop += 1
    local slot = runStack[stackTop]
    if not slot then slot = {} runStack[stackTop] = slot end
    slot.depth, slot.startIdx = D, i
   end
  end
 end
 while stackTop > 0 do
  local top = runStack[stackTop]
  EmitLine(top.depth, top.startIdx, #config.entries)
  stackTop -= 1
 end
 for k = lineCount + 1, #config.guideLines do
  config.guideLines[k].Visible = false
 end

 if totalRows * config.ROW_H > viewH then
  config.vbar.Visible = true
  local thumbFrac = math.clamp(math.floor(viewH / config.ROW_H) / totalRows, 0.05, 0.85)
  config.vthumb.Size = UDim2.new(1, 0, thumbFrac, 0)
  local posFrac = maxIndex > 0 and math.clamp((config.ScrollIndex / maxIndex) * (1 - thumbFrac), 0, 1 - thumbFrac) or 0
  config.vthumb.Position = UDim2.new(0, 0, posFrac, 0)
 else
  config.vbar.Visible = false
 end

 if config.TreeContentWidth > viewW then
  config.hbar.Visible = true
  local thumbFrac = math.clamp(viewW / config.TreeContentWidth, 0.05, 0.85)
  config.hthumb.Size = UDim2.new(thumbFrac, 0, 1, 0)
  local posFrac = maxHOffset > 0 and math.clamp((config.ScrollHOffset / maxHOffset) * (1 - thumbFrac), 0, 1 - thumbFrac) or 0
  config.hthumb.Position = UDim2.new(posFrac, 0, 0, 0)
 else
  config.hbar.Visible = false
 end

 local hi = config.HoverInst and Explorer.RowIndex and Explorer.RowIndex[config.HoverInst]
 local hrow = hi and (hi - config.ScrollIndex)
 if hrow and hrow >= 1 and hrow <= #config.entries then
  PlaceInsertBtn(config.visiblerows[hi], hrow)
 elseif not config.OverInsert then
  config.insertBtn.Visible = false
 end
end

config.SV.UserInput.InputChanged:Connect(function(input)
 if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
 if not config.main.Visible or config.IsMinimized then return end
 local delta = input.Position.Z
 if delta == 0 then return end
 local mp = config.SV.UserInput:GetMouseLocation()
 local ap = config.main.AbsolutePosition
 local as = config.main.AbsoluteSize
 if mp.X < ap.X or mp.X > ap.X + as.X or mp.Y < ap.Y or mp.Y > ap.Y + as.Y then return end
 local viewH = config.scrolling.AbsoluteSize.Y
 local maxIdx = math.max(0, #config.visiblerows - math.floor(viewH / config.ROW_H))
 config.ScrollIndex = math.clamp(config.ScrollIndex - delta * 3, 0, maxIdx)
 RefreshTree()
end)

local function Draggable(thumb, track, isHorizontal, vis)
 local dragging, startPos, startScroll
 local hovering = false
 local function Paint()
  vis.BackgroundColor3 = (dragging or hovering) and Color3.fromRGB(140,140,140) or Color3.fromRGB(90,90,90)
 end
 local function MaxScroll()
  if isHorizontal then return math.max(0, config.TreeContentWidth - config.scrolling.AbsoluteSize.X) end
  return math.max(0, #config.visiblerows - math.floor(config.scrolling.AbsoluteSize.Y / config.ROW_H))
 end
 local function Current() return isHorizontal and config.ScrollHOffset or config.ScrollIndex end
 local function Apply(v)
  local m = MaxScroll()
  if isHorizontal then
   config.ScrollHOffset = math.clamp(v, 0, m)
  else
   config.ScrollIndex = math.clamp(math.floor(v + 0.5), 0, m)
  end
  RefreshTree()
 end
 local function IsPress(inp)
  return inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch
 end

 thumb.Active = true
 config.WidenHit(thumb, isHorizontal).InputBegan:Connect(function(inp)
  if not config.Fresh(inp) then return end
  if not IsPress(inp) then return end
  if MaxScroll() <= 0 then return end
  dragging = true
  startPos = inp.Position
  startScroll = Current()
  Paint()
 end)
 track.MouseEnter:Connect(function() hovering = true Paint() end)
 track.MouseLeave:Connect(function() hovering = false Paint() end)

 config.SV.UserInput.InputChanged:Connect(function(inp)
  if not dragging then return end
  if not config.Held(inp) then dragging = false Paint() return end
  if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  local m = MaxScroll()
  local ts = track.AbsoluteSize
  local trackLen = isHorizontal and ts.X or ts.Y
  local thumbFrac = isHorizontal and thumb.Size.X.Scale or thumb.Size.Y.Scale
  local usable = trackLen * (1 - thumbFrac)
  local delta = isHorizontal and (inp.Position.X - startPos.X) or (inp.Position.Y - startPos.Y)
  if usable > 0 and m > 0 then
   Apply(startScroll + delta / usable * m)
  end
 end)
 config.SV.UserInput.InputEnded:Connect(function(inp)
  if IsPress(inp) and dragging then
   dragging = false
   Paint()
  end
 end)
end

Draggable(config.vthumb, config.vbar, false, config.vvis)
Draggable(config.hthumb, config.hbar, true, config.hvis)

config.scrolling:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
 if config.scrolling.Visible then RefreshTree() end
end)

config.searchOptionsDropdown = Explorer.AddDropdown(function(Add)
 Add("Select instance after insert", "Toggle", function(v)
  config.SelectAfterInsert = v
 end, config.SelectAfterInsert)
 Add("Increment names for new instances", "Toggle", function(v)
  config.IncrementNames = v
 end, config.IncrementNames)
 Add("Expand hierarchy when selecting", "Toggle", function(v)
  config.ExpandOnSelect = v
 end, config.ExpandOnSelect)
 Add("Show selection hierarchy highlights", "Toggle", function(v)
  config.ShowHierarchyHighlights = v
  RefreshTree()
 end, config.ShowHierarchyHighlights)
end, { Studio = true, FullWidth = true, RowH = 40 })

config.threedotmenu.Activated:Connect(function()
 config.searchOptionsDropdown:ToggleAt(config.threedotmenu)
end)

config.searchToken = 0
config.searchbar:GetPropertyChangedSignal("Text"):Connect(function()
 config.searchToken += 1
 local my = config.searchToken
 local text = config.searchbar.Text
 local function Apply()
  if my ~= config.searchToken then return end
  local trimmed = text:match("^%s*(.-)%s*$")
  if trimmed == config.SearchAppliedText then return end
  config.SearchAppliedText = trimmed
  config.SearchQuery = trimmed
  config.SearchPred = Explorer.CompileSearch(text)
  config.SearchCursor = 0
  Explorer.SearchOpen = setmetatable({}, {__mode="k"})
  Explorer.ScanTree()
  RefreshTree()
  if config.SearchQuery ~= "" and Explorer.EnsureDeepLoad then Explorer.EnsureDeepLoad() end
 end
 if text:match("^%s*$") then Apply() else task.delay(0.15, Apply) end
end)

config.contextItems = {}
config.contextDropdown = Explorer.AddDropdown(function(Add)
 for _, it in ipairs(config.contextItems) do
  if it == "SEPARATOR" then
   Add(nil, "Separator")
  elseif it.Options then
   Add(it[1], "Options", function(SubAdd)
    for _, o in ipairs(it.Options) do
     SubAdd(o[1], "Button", o[2])
    end
   end)
  else
   Add(it[1], "Button", it[3])
  end
 end
end, { Width = 240, RowH = 34, TextSize = 14, Screen = true, CloseOnClick = true, OnClose = function()
 config.ContextMenu = nil
 config.ContextMenuTarget = nil
end })

local function CloseContextMenu()
 if config.contextDropdown then config.contextDropdown:Close() end
end
Explorer.CloseContextMenu = CloseContextMenu

local function IsRootNode(inst)
 return inst == nil or inst.ClassName == "Root"
end
local function IsServiceNode(inst)
 return Explorer.Mode == "Game" and inst.Parent ~= nil
  and inst.Parent.ClassName == "Root" and inst.Parent.Name == "game"
end
local function IsArchivable(inst)
 if not inst.Real then return true end
 local ok, v = pcall(function() return inst.Real.Archivable end)
 return not ok or v ~= false
end
Explorer.Can = {
 Copy = function(inst) return not IsRootNode(inst) and not IsServiceNode(inst) and IsArchivable(inst) end,
 Cut = function(inst) return not IsRootNode(inst) and not IsServiceNode(inst) end,
 Duplicate = function(inst) return not IsRootNode(inst) and not IsServiceNode(inst) and IsArchivable(inst) end,
 Rename = function(inst) return not IsRootNode(inst) and not IsServiceNode(inst) end,
 Delete = function(inst) return not IsRootNode(inst) and not IsServiceNode(inst) end,
 Group = function(inst) return not IsRootNode(inst) and not IsServiceNode(inst) end,
 PasteInto = function(inst) return not (Explorer.Mode == "Game" and inst.ClassName == "Root" and inst.Name == "game") end,
}
local function AnySelected(fn)
 for _, i in ipairs(Explorer.GetSelection()) do
  if fn(i) then return true end
 end
 return false
end

function OpenContextMenu(inst, x, y)
 if Explorer.Drag and (Explorer.Drag.active or Explorer.Drag.justDragged) then return end
 if Explorer.OnRightClickCb then
  local ok, suppress = pcall(Explorer.OnRightClickCb, inst, x, y)
  if ok and suppress == true then return end
 end
 CloseContextMenu()

 if not Explorer.SelectedSet[inst] then
  Explorer.SetSelection({ inst }, inst)
 end
 local selCount = #Explorer.GetSelection()
 local items: any = {}
 local function AddItem(label, danger, fn)
  table.insert(items, { label, danger, fn })
 end
 local C = Explorer.Can
 if AnySelected(C.Cut) then AddItem("Cut", false, Explorer.Cut) end
 if AnySelected(C.Copy) then AddItem("Copy", false, Explorer.Copy) end
 if #Explorer.Clipboard > 0 and C.PasteInto(inst) then
  local blocked = false
  if Explorer.ClipboardCut then
   for _, src in ipairs(Explorer.Clipboard) do
    local cur = inst
    while cur do
     if cur == src then blocked = true break end
     cur = cur.Parent
    end
   end
  end
  if not blocked then AddItem("Paste Into", false, function() Explorer.Paste(inst) end) end
 end
 if AnySelected(C.Duplicate) then AddItem("Duplicate", false, Explorer.Duplicate) end
 AddItem("Insert", false, function() Explorer.OpenInsertMenu(inst, x, y) end)
 if selCount == 1 then
  if C.Rename(inst) then
   AddItem("Rename", false, function() Explorer.StartRename(inst) end)
  end
  if inst.Real and Explorer.ViewModel then
   local okPV, isPV = pcall(function()
    local real = inst.Real
    if not real:IsA("Model") then return false end
    return real:FindFirstChildWhichIsA("BasePart", true) ~= nil
   end)
   if okPV and isPV then
    AddItem("View 3D Model", false, function() Explorer.ViewModel(inst) end)
   end
  end
  if #inst.Children > 0 and (inst.ClassName == "Model" or inst.ClassName == "Folder") then
   AddItem("Ungroup", false, function() Explorer.Ungroup(inst) end)
  end
 end
 if AnySelected(C.Group) then
  AddItem("Group", false, function() Explorer.GroupSelection("Model") end)
  AddItem("Group As a Folder", false, function() Explorer.GroupSelection("Folder") end)
 end
 if inst ~= Explorer.Root and not IsRootNode(inst) and Explorer.HasChildren(inst) then
  table.insert(items, "SEPARATOR")
  local opt
  if Explorer.GetExpanded(inst) then
   opt = { "Collapse All", function() Explorer.CollapseAll(inst) end }
  else
   opt = { "Expand All", function() Explorer.ExpandAll(inst) end }
  end
  table.insert(items, { "Hierarchy", false, nil, Options = { opt } })
 end
 table.insert(items, "SEPARATOR")
 if not IsRootNode(inst) and setclipboard then
  AddItem("Copy Name", false, function() pcall(setclipboard, inst.Name) end)
  AddItem("Copy Path", false, function() pcall(setclipboard, inst:GetFullName()) end)
 end
 if #Explorer.ContextItems > 0 then
  table.insert(items, "SEPARATOR")
  for _, item in ipairs(Explorer.ContextItems) do
   table.insert(items, { item.label, item.danger or false, function() pcall(item.callback, inst) end })
  end
 end
 if AnySelected(C.Delete) then
  table.insert(items, "SEPARATOR")
  AddItem("Delete", true, Explorer.DeleteSelection)
 end

 config.contextItems = items
 config.contextDropdown:Open(x, y)
 config.ContextMenu = config.contextDropdown.Frame
 config.ContextMenuTarget = inst
 config.MenuTime = tick()
end

function Explorer.CreateInstance(className, name, parent)
 parent = parent or Explorer.Root
 local G = Explorer.Game
 local inst
 if G and G.IsGame(parent) then
  inst = G.Create(className, name or className, parent)
  if not inst then return nil end
  if inst.Parent and inst.Parent ~= Explorer.Root then Explorer.Expanded[inst.Parent] = true end
 else
  inst = VirtualInstance.new(className, Explorer.UniqueName(parent, name or className), parent)
 end
 Explorer.ScanTree()
 RefreshTree()
 return inst
end

function Explorer.DestroyInstance(inst)
 if not inst or inst == Explorer.Root then return end
 local G = Explorer.Game
 if G and G.IsGame(inst) and not G.Destroy(inst) then return end
 Explorer.SelectedSet[inst] = nil
 if Explorer.Selected == inst then
  Explorer.Selected = next(Explorer.SelectedSet)
  if Explorer.PropsOnSelect then Explorer.PropsOnSelect() end 
  if Explorer.OnSelectCb then pcall(Explorer.OnSelectCb, Explorer.Selected) end
 end
 Explorer.Expanded[inst] = nil
 inst:Destroy()
 Explorer.ScanTree()
 RefreshTree()
end

function Explorer.SetName(inst, name)
 local G = Explorer.Game
 if G and G.IsGame(inst) and inst.Real then
  if not G.Rename(inst, name) then return end
 else
  inst.Name = name
 end
 Explorer.ScanTree()
 RefreshTree()
 if Explorer.RefreshProperties then Explorer.RefreshProperties() end
end

function Explorer.SetClassName(inst, className)
 inst.ClassName = className
 Explorer.ScanTree()
 RefreshTree()
 if Explorer.RefreshProperties then Explorer.RefreshProperties() end
end

function Explorer.SetExpanded(inst, expanded)
 if expanded then Explorer.Expanded[inst] = true
 else Explorer.Expanded[inst] = nil end
 if config.SearchQuery ~= "" then Explorer.SearchOpen[inst] = expanded and true or false end
 if not FastRebuild(inst) then Explorer.ScanTree() end
 RefreshTree()
end

function Explorer.GetExpanded(inst)
 return Explorer.Expanded[inst] == true
end

function Explorer.SelectInstance(inst)
 Explorer.Selected = inst
 Explorer.SelectedSet = inst and { [inst] = true } or {}
 if config.ExpandOnSelect and inst and inst ~= Explorer.Root then
  local cur = inst.Parent
  while cur and cur ~= Explorer.Root do
   Explorer.Expanded[cur] = true
   cur = cur.Parent
  end
 end
 Explorer.ScanTree()
 RefreshTree()
  if Explorer.PropsOnSelect then Explorer.PropsOnSelect() end 
 if Explorer.OnSelectCb then pcall(Explorer.OnSelectCb, inst) end
end

function Explorer.GetSelected() return Explorer.Selected end

function Explorer.GetSelection()
 local list = {}
 for _, row in ipairs(config.visiblerows) do
  if Explorer.SelectedSet[row.instance] then list[#list + 1] = row.instance end
 end
 for inst in pairs(Explorer.SelectedSet) do
  if not table.find(list, inst) then list[#list + 1] = inst end
 end
 return list
end

function Explorer.SetSelection(list, primary)
 Explorer.SelectedSet = {}
 for _, i in ipairs(list) do Explorer.SelectedSet[i] = true end
 Explorer.Selected = primary or list[#list]
 RefreshTree()
 if Explorer.PropsOnSelect then Explorer.PropsOnSelect() end 
 if Explorer.OnSelectCb then pcall(Explorer.OnSelectCb, Explorer.Selected) end
end

function Explorer.ClickSelect(inst)
 local ctrl = config.SV.UserInput:IsKeyDown(Enum.KeyCode.LeftControl) or config.SV.UserInput:IsKeyDown(Enum.KeyCode.RightControl)
 local shift = config.SV.UserInput:IsKeyDown(Enum.KeyCode.LeftShift) or config.SV.UserInput:IsKeyDown(Enum.KeyCode.RightShift)
 local idx = Explorer.RowIndex and Explorer.RowIndex[inst]
 local aIdx = config.Anchor and Explorer.RowIndex and Explorer.RowIndex[config.Anchor]
 if shift and aIdx and idx then
  local a, b = math.min(aIdx, idx), math.max(aIdx, idx)
  local list = {}
  for i = a, b do list[#list + 1] = config.visiblerows[i].instance end
  Explorer.SetSelection(list, inst)
 elseif ctrl then
  local list = Explorer.GetSelection()
  local at = table.find(list, inst)
  if at then table.remove(list, at) else list[#list + 1] = inst end
  config.Anchor = inst
  Explorer.SetSelection(list, (not at) and inst or list[#list])
 else
  config.Anchor = inst
  Explorer.SetSelection({ inst }, inst)
 end
end

function Explorer.UniqueName(parent, base)
 if not config.IncrementNames then return base end
 local taken = {}
 for _, c in ipairs(parent.Children) do taken[c.Name] = true end
 if not taken[base] then return base end
 local root = base:gsub("%d+$", "")
 local n = 1
 while taken[root .. n] do n += 1 end
 return root .. n
end

function Explorer.AddTag(inst, tag)
 inst.Tags = inst.Tags or {}
 inst.Tags[tag] = true
 if Explorer.RefreshProperties then Explorer.RefreshProperties() end
end

local function CloneVirtual(inst, parent)
 local kids = table.clone(inst.Children)
 local c = VirtualInstance.new(inst.ClassName, Explorer.UniqueName(parent, inst.Name), nil)
 for k, v in pairs(inst.Properties) do c.Properties[k] = v end
 for k, v in pairs(inst.Attributes) do c.Attributes[k] = v end
 for k, v in pairs(inst.Metadata) do c.Metadata[k] = v end
 if inst.Real then c.Metadata.Real = inst.Real end
 if inst.Tags then c.Tags = table.clone(inst.Tags) end
 c:SetParent(parent)
 for _, ch in ipairs(kids) do CloneVirtual(ch, c) end
 return c
end

local function TopLevel(list)
 local set, out = {}, {}
 for _, i in ipairs(list) do set[i] = true end
 for _, i in ipairs(list) do
  local cur, nested = i.Parent, false
  while cur do
   if set[cur] then nested = true break end
   cur = cur.Parent
  end
  if not nested then out[#out + 1] = i end
 end
 return out
end

local function Reveal(inst)
 if not config.ExpandOnSelect then return end
 local cur = inst.Parent
 while cur and cur ~= Explorer.Root do
  Explorer.Expanded[cur] = true
  cur = cur.Parent
 end
end

local function FilterBy(list, fn)
 local out = {}
 for _, i in ipairs(list) do if fn(i) then out[#out + 1] = i end end
 return out
end

function Explorer.Copy()
 local list = TopLevel(FilterBy(Explorer.GetSelection(), Explorer.Can.Copy))
 if #list == 0 then return end
 Explorer.Clipboard = list
 Explorer.ClipboardCut = false
end

function Explorer.Cut()
 local list = TopLevel(FilterBy(Explorer.GetSelection(), Explorer.Can.Cut))
 if #list == 0 then return end
 Explorer.Clipboard = list
 Explorer.ClipboardCut = true
end

function Explorer.Paste(target)
 local parent = target or Explorer.Root
 if not Explorer.Can.PasteInto(parent) then return end
 local made = {}
 for _, src in ipairs(Explorer.Clipboard) do
  if Explorer.ClipboardCut then
   local cur, bad = parent, false
   while cur do
    if cur == src then bad = true break end
    cur = cur.Parent
   end
   if not bad and src.Parent then
    local G = Explorer.Game
    if G and G.IsGame(src) then
     if G.Move(src, parent) then made[#made + 1] = src end
    else
     src:SetParent(parent)
     made[#made + 1] = src
    end
   end
  elseif src.Parent then
   local G = Explorer.Game
   if G and G.IsGame(src) then
    local c = G.Clone(src, parent)
    if c then made[#made + 1] = c end
   else
    made[#made + 1] = CloneVirtual(src, parent)
   end
  end
 end
 if Explorer.ClipboardCut then
  Explorer.ClipboardCut = false
  Explorer.Clipboard = {}
 end
 if #made == 0 then return end
 if parent ~= Explorer.Root then Explorer.Expanded[parent] = true end
 Explorer.ScanTree()
 Explorer.SetSelection(made, made[#made])
end

function Explorer.MoveInstances(list, parent)
 if not parent then return end
 local G = Explorer.Game
 local moved = {}
 for _, src in ipairs(TopLevel(list)) do
  local cur, bad = parent, false
  while cur do
   if cur == src then bad = true break end
   cur = cur.Parent
  end
  if not bad and src.Parent and src.Parent ~= parent then
   if G and G.IsGame(src) then
    if G.Move(src, parent) then moved[#moved + 1] = src end
   else
    src:SetParent(parent)
    moved[#moved + 1] = src
   end
  end
 end
 if #moved == 0 then return end
 if parent ~= Explorer.Root then Explorer.Expanded[parent] = true end
 Explorer.ScanTree()
 Explorer.SetSelection(moved, moved[#moved])
end

function Explorer.Duplicate()
 local made = {}
 for _, src in ipairs(TopLevel(FilterBy(Explorer.GetSelection(), Explorer.Can.Duplicate))) do
  local G = Explorer.Game
  if G and G.IsGame(src) then
   local c = G.Clone(src, src.Parent or Explorer.Root)
   if c then made[#made + 1] = c end
  else
   made[#made + 1] = CloneVirtual(src, src.Parent or Explorer.Root)
  end
 end
 if #made == 0 then return end
 for _, m in ipairs(made) do Reveal(m) end
 Explorer.ScanTree()
 Explorer.SetSelection(made, made[#made])
end

function Explorer.DeleteSelection()
 for _, inst in ipairs(TopLevel(FilterBy(Explorer.GetSelection(), Explorer.Can.Delete))) do
  Explorer.DestroyInstance(inst)
 end
end

function Explorer.GroupSelection(className)
 className = className or "Folder"
 local list = TopLevel(FilterBy(Explorer.GetSelection(), Explorer.Can.Group))
 if #list == 0 then return end
 local parent = list[1].Parent or Explorer.Root
 local G = Explorer.Game
 local f
 if G and G.IsGame(list[1]) then
  f = G.Create(className, className, parent)
  if not f then return end
  for _, i in ipairs(list) do G.Move(i, f) end
 else
  f = VirtualInstance.new(className, Explorer.UniqueName(parent, className), parent)
  for _, i in ipairs(list) do i:SetParent(f) end
 end
 Explorer.Expanded[f] = true
 Explorer.ScanTree()
 Explorer.SetSelection({ f }, f)
end

function Explorer.Ungroup(inst)
 if not inst then return end
 local G = Explorer.Game
 local isGame = G and G.IsGame(inst) and inst.Real ~= nil
 if isGame and not inst.Loaded then Explorer.LoadChildren(inst) end
 if #inst.Children == 0 then return end
 local parent = inst.Parent or Explorer.Root
 local moved = table.clone(inst.Children)
 if isGame then
  local ok, done = true, {}
  for _, c in ipairs(moved) do
   if G.Move(c, parent) then done[#done + 1] = c else ok = false end
  end
  moved = done
  if not ok then
   Explorer.ScanTree()
   if #moved > 0 then Explorer.SetSelection(moved, moved[#moved]) end
   return
  end
 else
  for _, c in ipairs(moved) do c:SetParent(parent) end
 end
 Explorer.DestroyInstance(inst)
 Explorer.ScanTree()
 Explorer.SetSelection(moved, moved[#moved])
end

function Explorer.StartRename(inst)
 if not inst or not Explorer.Can.Rename(inst) then return end
 local idx = Explorer.RowIndex and Explorer.RowIndex[inst]
 if not idx then return end
 local e = config.entries[idx - config.ScrollIndex]
 if not e or not e.label.Visible then return end

 local PAD = 6
 local textW = config.SV.TextSrv:GetTextSize(
  inst.Name, e.label.TextSize, Enum.Font.SourceSans, Vector2.new(10000, 26)
 ).X

 local box = Instance.new("TextBox")
 box.Name = RandomString()
 box.Position = UDim2.new(
  e.label.Position.X.Scale, e.label.Position.X.Offset - PAD,
  e.label.Position.Y.Scale, e.label.Position.Y.Offset
 )
 box.Size = UDim2.new(0, e.label.Size.X.Offset + PAD, 0, e.label.Size.Y.Offset)
 box.BackgroundColor3 = Color3.fromRGB(20, 21, 26)
 box.BackgroundTransparency = 0
 box.BorderSizePixel = 0
 box.Font = Enum.Font.SourceSans
 box.TextSize = e.label.TextSize
 box.TextColor3 = config.COLORS.TEXT_BRIGHT
 box.TextXAlignment = Enum.TextXAlignment.Left
 box.ClearTextOnFocus = false
 box.Text = inst.Name
 box.ZIndex = 8
 box.Archivable = false
 box.Parent = config.scrolling

 RoundCorner(box, 0, 8)
 local boxStroke = BorderStroke(box, 1, 80, 80, 80)

 local pad = Instance.new("UIPadding")
 pad.PaddingLeft = UDim.new(0, PAD)
 pad.Parent = box

 box.Focused:Connect(function()
  boxStroke.Color = config.COLORS.SELECTED
 end)
 box.FocusLost:Connect(function()
  boxStroke.Color = Color3.fromRGB(80, 80, 80)
  local t = box.Text
  box:Destroy()
  if t ~= "" and t ~= inst.Name then Explorer.SetName(inst, t) end
 end)

 box:CaptureFocus()
 box.SelectionStart = 1
 box.CursorPosition = #box.Text + 1
end
function Explorer.OnSelect(cb) Explorer.OnSelectCb = cb end
function Explorer.OnDoubleClick(cb) Explorer.OnDoubleClickCb = cb end
function Explorer.OnRightClick(cb) Explorer.OnRightClickCb = cb end

function Explorer.RegisterContextItem(label, callback)
 table.insert(Explorer.ContextItems, { label = label, callback = callback })
end

function Explorer.RegisterIcon(className, imageId, ox, oy)
 if not ox then
  Explorer.UserIcons[className] = { id = imageId, size = Vector2.new(0, 0), offset = Vector2.new(0, 0) }
 else
  Explorer.UserIcons[className] = { id = imageId, size = Vector2.new(32, 32), offset = Vector2.new(ox, oy) }
 end
end

function Explorer.AddSetting(name, default, callback)
 table.insert(Explorer.Settings, { name = name, enabled = default == true, callback = callback })
 if Explorer.SettingsDropdownHandle then
  Explorer.SettingsDropdownHandle:Refresh()
 end
end

function Explorer.SetProperty(inst, key, value) inst.Properties[key] = value if Explorer.RefreshProperties then Explorer.RefreshProperties() end end
function Explorer.GetProperty(inst, key) return inst.Properties[key] end
function Explorer.SetAttribute(inst, key, value) inst.Attributes[key] = value if Explorer.RefreshProperties then Explorer.RefreshProperties() end end
function Explorer.GetAttribute(inst, key) return inst.Attributes[key] end

function Explorer.Refresh()
 Explorer.ScanTree()
 RefreshTree()
 if Explorer.RefreshProperties then Explorer.RefreshProperties() end
end

local function ExpandRec(inst, searching)
 Explorer.Expanded[inst] = true
 if searching then Explorer.SearchOpen[inst] = true end
 if inst.Real and not inst.Loaded then Explorer.LoadChildren(inst) end
 local kids = inst.Children
 for i = 1, #kids do ExpandRec(kids[i], searching) end
end

local function CollapseRec(inst, searching)
 Explorer.Expanded[inst] = nil
 if searching then Explorer.SearchOpen[inst] = false end
 local kids = inst.Children
 for i = 1, #kids do CollapseRec(kids[i], searching) end
end

function Explorer.ExpandAll(inst)
 ExpandRec(inst, config.SearchQuery ~= "")
 if not FastRebuild(inst) then Explorer.ScanTree() end
 RefreshTree()
end

function Explorer.CollapseAll(inst)
 CollapseRec(inst, config.SearchQuery ~= "")
 if not FastRebuild(inst) then Explorer.ScanTree() end
 RefreshTree()
end

function Explorer.ClearAll()
 for _, c in ipairs(Explorer.Root.Children) do c.Parent = nil end
 Explorer.Root.Children = {}
 Explorer.Expanded = setmetatable({}, {__mode="k"})
 Explorer.Selected = nil
 Explorer.SelectedSet = {}
 Explorer.ScanTree()
 RefreshTree()
 if Explorer.PropsOnSelect then Explorer.PropsOnSelect() end 
end

function Explorer.Open()
 if config.main.Visible then return end
 config.IsMinimized = false
 config.main.Visible = true
 config.searchbar.Visible = true
 config.threedotmenu.Visible = true
 if config.LayoutDocks then config.LayoutDocks() end
 Explorer.ScanTree()
 RefreshTree()
end

function Explorer.Close()
 if not config.main.Visible then return end
 config.IsMinimized = true
 config.main.Visible = false
 if config.LayoutDocks then config.LayoutDocks() end
end

function Explorer.Toggle()
 if config.main.Visible then Explorer.Close() else Explorer.Open() end
end

function Explorer.IsOpen() return config.main.Visible end

config.close.Activated:Connect(function()
 Explorer.Close()
end)

local function CloseInsertMenu()
 if config.InsertConns then
  for _, c in ipairs(config.InsertConns) do c:Disconnect() end
  config.InsertConns = nil
 end
 if config.InsertMenu then
  config.InsertMenu:Destroy()
  config.InsertMenu = nil
 end
end

config.INSERT_CLASSES = {}
do
 local skip = { Instance = true, Service = true, Value = true, Workspace = true, Lighting = true, Chat = true, Backpack = true }
 for name in pairs(config.ICONS) do
  if not skip[name] then config.INSERT_CLASSES[#config.INSERT_CLASSES + 1] = name end
 end
 table.sort(config.INSERT_CLASSES)
end

function Explorer.OpenInsertMenu(parentInst, x, y)
 CloseInsertMenu()
 CloseContextMenu()
 parentInst = parentInst or Explorer.Root
 local conns = {}
 config.InsertConns = conns

 local ROW = config.ROW_H
 local VISIBLE = 9
 local W = 250
 local listH = VISIBLE * ROW
 local listY = 42
 local H = listY + listH + 6
 local viewW = W - 12

 local menu = Instance.new("Frame")
 menu.Name = RandomString()
 menu.Size = UDim2.new(0, W, 0, H)
 menu.Position = UDim2.new(0, math.clamp(x, 4, math.max(4, config.window.AbsoluteSize.X - W - 4)), 0, math.clamp(y, 4, math.max(4, config.window.AbsoluteSize.Y - H - 4)))
 menu.BackgroundColor3 = config.COLORS.PRIMARY
 menu.BorderSizePixel = 0
 menu.ZIndex = 60
 menu.Active = true
 menu.Archivable = false
 menu.Parent = config.window
 DropStroke(menu)
 config.InsertMenu = menu

 local box = Instance.new("TextBox")
 box.Name = RandomString()
 box.Size = UDim2.new(1, -14, 0, 28)
 box.Position = UDim2.new(0, 7, 0, 6)
 box.BackgroundColor3 = Color3.fromRGB(20, 21, 26)
 box.BorderSizePixel = 0
 box.PlaceholderText = "Search"
 box.PlaceholderColor3 = config.COLORS.TEXT
 box.Text = ""
 box.TextColor3 = config.COLORS.TEXT_BRIGHT
 box.Font = Enum.Font.SourceSans
 box.TextSize = 15
 box.TextXAlignment = Enum.TextXAlignment.Left
 box.ClearTextOnFocus = false
 box.ZIndex = 61
 box.Archivable = false
 box.Parent = menu
 RoundCorner(box, 0, 8)
 local boxStroke = BorderStroke(box, 1, 80, 80, 80)
 local pad = Instance.new("UIPadding")
 pad.PaddingLeft = UDim.new(0, 8)
 pad.Parent = box
 box.Focused:Connect(function() boxStroke.Color = config.COLORS.SELECTED end)
 box.FocusLost:Connect(function() boxStroke.Color = Color3.fromRGB(80, 80, 80) end)

 local view = Instance.new("Frame")
 view.Name = RandomString()
 view.Size = UDim2.new(0, viewW, 0, listH)
 view.Position = UDim2.new(0, 0, 0, listY)
 view.BackgroundTransparency = 1
 view.ClipsDescendants = true
 view.ZIndex = 61
 view.Archivable = false
 view.Parent = menu

 local bar = Instance.new("Frame")
 bar.Name = RandomString()
 bar.Size = UDim2.new(0, 10, 0, listH)
 bar.Position = UDim2.new(1, -10, 0, listY)
 bar.BackgroundTransparency = 1
 bar.BorderSizePixel = 0
 bar.Visible = false
 bar.ZIndex = 62
 bar.Archivable = false
 bar.Parent = menu

 local thumb = Instance.new("Frame")
 thumb.Name = RandomString()
 thumb.Size = UDim2.new(1, 0, 0.2, 0)
 thumb.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
 thumb.BorderSizePixel = 0
 thumb.ZIndex = 63
 thumb.Archivable = false
 thumb.Parent = bar
 RoundCorner(thumb, 1, 0)

 local function Insert(className)
  CloseInsertMenu()
  if parentInst ~= Explorer.Root then Explorer.Expanded[parentInst] = true end
  local inst = Explorer.CreateInstance(className, className, parentInst)
  if inst and config.SelectAfterInsert then Explorer.SelectInstance(inst) end
 end

 local items = {}
 local scrollIndex = 0
 local pool = {}

 local function Refresh()
  local maxIndex = math.max(0, #items - VISIBLE)
  scrollIndex = math.clamp(scrollIndex, 0, maxIndex)
  for i, p in ipairs(pool) do
   local item = items[scrollIndex + i]
   p.item = item
   if item then
    p.entry.Visible = true
    p.entry.Position = UDim2.new(0, 0, 0, (i - 1) * ROW)
    ApplyIcon(p.icon, item)
    p.label.Text = item
   else
    p.entry.Visible = false
    p.entry.BackgroundTransparency = 1
   end
  end
  if #items > VISIBLE then
   bar.Visible = true
   local frac = math.clamp(VISIBLE / #items, 0.05, 1)
   thumb.Size = UDim2.new(1, 0, frac, 0)
   thumb.Position = UDim2.new(0, 0, maxIndex > 0 and (scrollIndex / maxIndex) * (1 - frac) or 0, 0)
  else
   bar.Visible = false
  end
 end

 for i = 1, VISIBLE + 1 do
  local entry = Instance.new("TextButton")
  entry.Name = RandomString()
  entry.Size = UDim2.new(0, viewW, 0, ROW)
  entry.BackgroundColor3 = config.COLORS.SECONDARY
  entry.BackgroundTransparency = 1
  entry.BorderSizePixel = 0
  entry.AutoButtonColor = false
  entry.Text = ""
  entry.Visible = false
  entry.ZIndex = 62
  entry.Archivable = false
  entry.Parent = view

  local icon = Instance.new("ImageLabel")
  icon.Size = UDim2.new(0, config.Positions.ICON_PX, 0, config.Positions.ICON_PX)
  icon.Position = UDim2.new(0, 8, 0.5, -config.Positions.ICON_PX / 2)
  icon.BackgroundTransparency = 1
  icon.ZIndex = 63
  icon.Archivable = false
  icon.Parent = entry

  local label = Instance.new("TextLabel")
  label.Size = UDim2.new(1, -(8 + config.Positions.ICON_PX + 14), 1, 0)
  label.Position = UDim2.new(0, 8 + config.Positions.ICON_PX + 8, 0, 0)
  label.BackgroundTransparency = 1
  label.TextColor3 = config.COLORS.TEXT
  label.TextXAlignment = Enum.TextXAlignment.Left
  label.TextYAlignment = Enum.TextYAlignment.Center
  label.Font = Enum.Font.SourceSans
  label.TextSize = 21
  label.TextTruncate = Enum.TextTruncate.AtEnd
  label.ZIndex = 63
  label.Archivable = false
  label.Parent = entry

  local p = { entry = entry, icon = icon, label = label, item = nil }
  pool[i] = p
  entry.MouseEnter:Connect(function() if p.item then entry.BackgroundTransparency = 0 end end)
  entry.MouseLeave:Connect(function() entry.BackgroundTransparency = 1 end)
  entry.Activated:Connect(function() if p.item then Insert(p.item) end end)
 end

 local function Populate()
  local q = box.Text:lower()
  items = {}
  for _, name in ipairs(config.INSERT_CLASSES) do
   if q == "" or name:lower():find(q, 1, true) then items[#items + 1] = name end
  end
  scrollIndex = 0
  Refresh()
 end
 Populate()
 box:GetPropertyChangedSignal("Text"):Connect(Populate)
 box.FocusLost:Connect(function(enter)
  if enter and items[1] and config.InsertMenu == menu then Insert(items[1]) end
 end)

 conns[#conns + 1] = config.SV.UserInput.InputChanged:Connect(function(input)
  if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
  local ap, as = menu.AbsolutePosition, menu.AbsoluteSize
  local mp = input.Position
  if mp.X < ap.X or mp.X > ap.X + as.X or mp.Y < ap.Y or mp.Y > ap.Y + as.Y then return end
  scrollIndex = scrollIndex - input.Position.Z * 3
  Refresh()
 end)

 local dragging, startY, startIndex = false, 0, 0
 config.WidenHit(thumb, false).InputBegan:Connect(function(inp)
  if not config.Fresh(inp) then return end
  if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  dragging, startY, startIndex = true, inp.Position.Y, scrollIndex
 end)
 conns[#conns + 1] = config.SV.UserInput.InputChanged:Connect(function(inp)
  if not dragging then return end
  if not config.Held(inp) then dragging = false return end
  if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  local maxIndex = math.max(0, #items - VISIBLE)
  local usable = listH * (1 - thumb.Size.Y.Scale)
  if usable > 0 and maxIndex > 0 then
   scrollIndex = math.floor(startIndex + (inp.Position.Y - startY) / usable * maxIndex + 0.5)
   Refresh()
  end
 end)
 conns[#conns + 1] = config.SV.UserInput.InputEnded:Connect(function(inp)
  if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
   dragging = false
  end
 end)

 task.defer(function()
  if box.Parent then box:CaptureFocus() box.Text = "" end
 end)
end

config.insertBtn.MouseEnter:Connect(function() config.OverInsert = true end)
config.insertBtn.MouseLeave:Connect(function()
 config.OverInsert = false
 task.defer(function()
  if not config.HoverInst then config.insertBtn.Visible = false end
 end)
end)
config.insertBtn.Activated:Connect(function()
 local ap = config.insertBtn.AbsolutePosition
 Explorer.OpenInsertMenu(config.InsertTarget, ap.X, ap.Y + 20)
end)

local function MouseInMain()
 local mp = config.SV.UserInput:GetMouseLocation()
 local ap, as = config.main.AbsolutePosition, config.main.AbsoluteSize
 return mp.X >= ap.X and mp.X <= ap.X + as.X and mp.Y >= ap.Y and mp.Y <= ap.Y + as.Y + 36
end

local function SelectRowAt(idx)
 local row = config.visiblerows[idx]
 if not row then return end
 local viewRows = math.max(1, math.floor(config.scrolling.AbsoluteSize.Y / config.ROW_H))
 if idx - 1 < config.ScrollIndex then
  config.ScrollIndex = idx - 1
 elseif idx > config.ScrollIndex + viewRows then
  config.ScrollIndex = idx - viewRows
 end
 config.Anchor = row.instance
 Explorer.SetSelection({ row.instance }, row.instance)
end

config.searchbar.FocusLost:Connect(function(enter)
 if not enter or config.SearchQuery == "" then return end
 local hits = {}
 for i, row in ipairs(config.visiblerows) do
  if row.match then hits[#hits + 1] = i end
 end
 if #hits == 0 then return end
 local back = config.SV.UserInput:IsKeyDown(Enum.KeyCode.LeftShift) or config.SV.UserInput:IsKeyDown(Enum.KeyCode.RightShift)
 if back then
  config.SearchCursor = ((config.SearchCursor - 2) % #hits) + 1
 else
  config.SearchCursor = (config.SearchCursor % #hits) + 1
 end
 SelectRowAt(hits[config.SearchCursor])
end)

config.SV.UserInput.InputBegan:Connect(function(inp, gpe)
 if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
 if not config.main.Visible then return end
 local ctrl = config.SV.UserInput:IsKeyDown(Enum.KeyCode.LeftControl) or config.SV.UserInput:IsKeyDown(Enum.KeyCode.RightControl)
 local shift = config.SV.UserInput:IsKeyDown(Enum.KeyCode.LeftShift) or config.SV.UserInput:IsKeyDown(Enum.KeyCode.RightShift)
 local alt = config.SV.UserInput:IsKeyDown(Enum.KeyCode.LeftAlt) or config.SV.UserInput:IsKeyDown(Enum.KeyCode.RightAlt)
 local key = inp.KeyCode
 if key == Enum.KeyCode.Escape and config.InsertMenu then
  CloseInsertMenu()
  return
 end
 if ctrl and shift and key == Enum.KeyCode.X then
  task.defer(function() config.searchbar:CaptureFocus() end)
  return
 end
 if gpe or not MouseInMain() then return end
 local rows = config.visiblerows
 local cur = Explorer.Selected and Explorer.RowIndex and Explorer.RowIndex[Explorer.Selected]
 local pageRows = math.max(1, math.floor(config.scrolling.AbsoluteSize.Y / config.ROW_H))
 if ctrl and key == Enum.KeyCode.A then
  local all = {}
  for _, row in ipairs(rows) do
   if config.SearchQuery == "" or row.match then all[#all + 1] = row.instance end
  end
  Explorer.SetSelection(all, all[#all])
 elseif ctrl and alt and key == Enum.KeyCode.G then
  Explorer.GroupSelection("Folder")
 elseif ctrl and key == Enum.KeyCode.G then
  Explorer.GroupSelection("Model")
 elseif ctrl and key == Enum.KeyCode.U then
  for _, i in ipairs(Explorer.GetSelection()) do
   if i.ClassName == "Model" or i.ClassName == "Folder" then Explorer.Ungroup(i) end
  end
 elseif ctrl and key == Enum.KeyCode.I then
  local target = config.HoverInst or (config.OverInsert and config.InsertTarget) or Explorer.Selected
  local mp = config.SV.UserInput:GetMouseLocation()
  Explorer.OpenInsertMenu(target, mp.X, mp.Y)
 elseif ctrl and key == Enum.KeyCode.X then
  Explorer.Cut()
 elseif key == Enum.KeyCode.Escape then
  Explorer.SetSelection({}, nil)
 elseif ctrl and shift and key == Enum.KeyCode.V then
  local sel = Explorer.GetSelection()
  if #sel == 0 then Explorer.Paste(nil) else
   for _, t in ipairs(sel) do Explorer.Paste(t) end
  end
 elseif ctrl and key == Enum.KeyCode.V then
  Explorer.Paste(nil)
 elseif ctrl and key == Enum.KeyCode.C then
  Explorer.Copy()
 elseif ctrl and key == Enum.KeyCode.D then
  Explorer.Duplicate()
 elseif key == Enum.KeyCode.Delete or key == Enum.KeyCode.Backspace then
  Explorer.DeleteSelection()
 elseif key == Enum.KeyCode.F2 and Explorer.Selected then
  Explorer.StartRename(Explorer.Selected)
 elseif key == Enum.KeyCode.Down then
  SelectRowAt(cur and math.min(cur + 1, #rows) or 1)
 elseif key == Enum.KeyCode.Up then
  SelectRowAt(cur and math.max(cur - 1, 1) or 1)
 elseif key == Enum.KeyCode.Home then
  SelectRowAt(1)
 elseif key == Enum.KeyCode.End then
  SelectRowAt(#rows)
 elseif key == Enum.KeyCode.PageDown then
  SelectRowAt(cur and math.min(cur + pageRows, #rows) or 1)
 elseif key == Enum.KeyCode.PageUp then
  SelectRowAt(cur and math.max(cur - pageRows, 1) or 1)
 elseif key == Enum.KeyCode.Right and cur then
  local inst = rows[cur].instance
  if rows[cur].searchLeaf then
  elseif Explorer.HasChildren(inst) and not rows[cur].expanded then
   Explorer.SetExpanded(inst, true)
  elseif Explorer.HasChildren(inst) then
   SelectRowAt(cur + 1)
  end
 elseif key == Enum.KeyCode.Left and cur then
  local inst = rows[cur].instance
  if inst.Parent and inst.Parent ~= Explorer.Root and Explorer.RowIndex[inst.Parent] then
   SelectRowAt(Explorer.RowIndex[inst.Parent])
  elseif Explorer.Expanded[inst] then
   Explorer.SetExpanded(inst, false)
  end
 end
end)

local function PointIn(gui, pos)
 if not gui then return false end
 local ap, as = gui.AbsolutePosition, gui.AbsoluteSize
 return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
end

config.SV.UserInput.InputBegan:Connect(function(inp)
 if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.MouseButton2 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
 local pos = Vector2.new(inp.Position.X, inp.Position.Y)
 if config.InsertMenu and not PointIn(config.InsertMenu, pos) then CloseInsertMenu() end
end)

config.SV.ContextAction:BindAction("OpenExplorer", function(_, state)
 if state ~= Enum.UserInputState.Begin then return end
 Explorer.Toggle()
end, false, Enum.KeyCode.K)

config.SV.UserInput.InputBegan:Connect(function(inp, gpe)
 if gpe then return end
 if inp.KeyCode ~= Enum.KeyCode.X then return end
 if config.SV.UserInput:IsKeyDown(Enum.KeyCode.LeftAlt) or config.SV.UserInput:IsKeyDown(Enum.KeyCode.RightAlt) then
  Explorer.Toggle()
 end
end)

do
 local ROW = config.ROW_H

 local P = {
  Collapsed = {},
  PExp = {},
  Divider = 0.42,
  Filter = "",
  Rows = {},
  Scroll = 0,
  FloatH = 320,
  Inst = nil,
 }

 config.SUBCLASS.guitext = { TextLabel = 1, TextButton = 1, TextBox = 1 }

 local function E(enumName, item)
  local ok, v = pcall(function() return Enum[enumName][item] end)
  if ok and v then return v end
  return item
 end

 Explorer.PropertyDefs = {}
 function Explorer.DefineProperty(class, name, default, section, opts)
  opts = opts or {}
  table.insert(Explorer.PropertyDefs, {
   Class = class, Name = name, Default = default,
   Section = section or "Other", ReadOnly = opts.ReadOnly == true,
  })
 end
 function Explorer.OnPropertyChanged(cb) Explorer.OnPropertyChangedCb = cb end

 local D = Explorer.DefineProperty
 D("BasePart", "Color", Color3.fromRGB(163, 162, 165), "Appearance")
 D("BasePart", "Material", E("Material", "Plastic"), "Appearance")
 D("BasePart", "Transparency", 0, "Appearance")
 D("BasePart", "Reflectance", 0, "Appearance")
 D("BasePart", "CastShadow", true, "Appearance")
 D("BasePart", "Size", Vector3.new(4, 1, 2), "Transform")
 D("BasePart", "Position", Vector3.new(0, 0, 0), "Transform")
 D("BasePart", "Orientation", Vector3.new(0, 0, 0), "Transform")
 D("BasePart", "Anchored", false, "Behavior")
 D("BasePart", "Locked", false, "Behavior")
 D("BasePart", "Massless", false, "Behavior")
 D("BasePart", "CanCollide", true, "Collision")
 D("BasePart", "CanTouch", true, "Collision")
 D("BasePart", "CanQuery", true, "Collision")
 D("BasePart", "CollisionGroup", "Default", "Collision")
 D("Part", "Shape", E("PartType", "Block"), "Part")
 D("GuiObject", "BackgroundColor3", Color3.fromRGB(255, 255, 255), "Appearance")
 D("GuiObject", "BackgroundTransparency", 0, "Appearance")
 D("GuiObject", "BorderSizePixel", 1, "Appearance")
 D("GuiObject", "Position", UDim2.new(0, 0, 0, 0), "Transform")
 D("GuiObject", "Size", UDim2.new(0, 100, 0, 100), "Transform")
 D("GuiObject", "AnchorPoint", Vector2.new(0, 0), "Transform")
 D("GuiObject", "Rotation", 0, "Transform")
 D("GuiObject", "Visible", true, "Behavior")
 D("GuiObject", "Active", false, "Behavior")
 D("GuiObject", "ZIndex", 1, "Behavior")
 D("GuiText", "Text", "Label", "Text")
 D("GuiText", "TextColor3", Color3.fromRGB(0, 0, 0), "Text")
 D("GuiText", "TextSize", 14, "Text")
 D("GuiText", "TextWrapped", false, "Text")
 D("GuiText", "TextXAlignment", E("TextXAlignment", "Center"), "Text")
 D("Light", "Brightness", 1, "Appearance")
 D("Light", "Color", Color3.fromRGB(255, 255, 255), "Appearance")
 D("Light", "Enabled", true, "Behavior")
 D("Light", "Shadows", false, "Behavior")
 D("Script", "Enabled", true, "Behavior")
 D("LocalScript", "Enabled", true, "Behavior")
 D("BoolValue", "Value", false, "Data")
 D("IntValue", "Value", 0, "Data")
 D("NumberValue", "Value", 0, "Data")
 D("StringValue", "Value", "", "Data")
 D("Color3Value", "Value", Color3.fromRGB(0, 0, 0), "Data")
 D("Vector3Value", "Value", Vector3.new(0, 0, 0), "Data")
 D("CFrameValue", "Value", CFrame.new(), "Data")

 local SECTION_ORDER = { Data = 1, Appearance = 2, Transform = 3, Part = 4, Text = 5, Behavior = 6, Collision = 7, Other = 8 }
 local RANK = { Name = 1, ClassName = 2, Parent = 3 }

 local function GuessSection(name, v)
  local t = typeof(v)
  if name:match("^Text") or name == "Font" or name == "FontFace" then return "Text" end
  if name:match("Color") or name:match("Transparency") or name:match("Material") or name:match("Image") then return "Appearance" end
  if name == "Position" or name == "Size" or name == "CFrame" or name == "Orientation" or name == "Rotation" or name == "AnchorPoint" or name == "Pivot" then return "Transform" end
  if name:match("^Can") or name:match("Collision") then return "Collision" end
  if t == "boolean" then return "Behavior" end
  return "Other"
 end

 local API = { Classes = nil, Flat = {}, Loading = false, Failed = false }
 Explorer.API = API
 local API_URL = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json"

 local function HasTagStr(tags, name)
  if type(tags) ~= "table" then return false end
  for _, t in ipairs(tags) do if t == name then return true end end
  return false
 end

 local function HttpRequest(url)
  local req = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
  if req then
   local ok, res = pcall(req, { Url = url, Method = "GET" })
   if ok and type(res) == "table" and (res.Success ~= false) and (res.StatusCode == nil or res.StatusCode == 200) and type(res.Body) == "string" and #res.Body > 0 then
    return res.Body
   end
  end
  local ok, body = pcall(function() return game:HttpGet(url) end)
  if ok and type(body) == "string" and #body > 0 then return body end
  return nil
 end

 local function LoadAPI()
  if API.Classes or API.Loading then return end
  API.Loading = true
  task.spawn(function()
   local body
   for _ = 1, 3 do
    body = HttpRequest(API_URL)
    if body then break end
    task.wait(2)
   end
   local data
   if body then
    local ok, d = pcall(function() return config.SV.Http:JSONDecode(body) end)
    if ok and type(d) == "table" and type(d.Classes) == "table" then data = d end
   end
   if not data then
    API.Failed = true
    API.Loading = false
    return
   end
   local classes = {}
   for _, c in ipairs(data.Classes) do
    local props = {}
    for _, m in ipairs(c.Members or {}) do
     if m.MemberType == "Property" and not HasTagStr(m.Tags, "Deprecated") then
      local sec = m.Security
      local writeSec = type(sec) == "table" and sec.Write or sec
      props[#props + 1] = {
       Name = m.Name,
       Category = m.Category or "Other",
       ReadOnly = HasTagStr(m.Tags, "ReadOnly") or (writeSec ~= nil and writeSec ~= "None"),
       NotScriptable = HasTagStr(m.Tags, "NotScriptable"),
       Hidden = HasTagStr(m.Tags, "Hidden"),
       Type = m.ValueType and m.ValueType.Name or "",
       TypeCat = m.ValueType and m.ValueType.Category or "",
      }
     end
    end
    classes[c.Name] = { Super = c.Superclass, Props = props }
   end
   API.Classes = classes
   API.Flat = {}
   API.Loading = false
   if Explorer.RefreshProperties then pcall(Explorer.RefreshProperties) end
  end)
 end

 function API.PropsFor(className)
  if not API.Classes then return nil end
  local cached = API.Flat[className]
  if cached then return cached end
  local out, seen = {}, {}
  local cur, guard = className, 0
  while cur and API.Classes[cur] and guard < 64 do
   for _, p in ipairs(API.Classes[cur].Props) do
    if not seen[p.Name] then
     seen[p.Name] = true
     out[#out + 1] = p
    end
   end
   cur = API.Classes[cur].Super
   guard += 1
  end
  API.Flat[className] = out
  return out
 end

 local function ReadReal(real, name)
  local ok, v = pcall(function() return real[name] end)
  if not ok and type(gethiddenproperty) == "function" then
   ok, v = pcall(gethiddenproperty, real, name)
  end
  return ok, v
 end

 local function WriteReal(real, name, value)
  local ok = pcall(function() real[name] = value end)
  if not ok and type(sethiddenproperty) == "function" then
   ok = pcall(sethiddenproperty, real, name, value)
  end
  return ok
 end

 LoadAPI()

 local function Collect(inst)
  local bySec, order, seen = {}, {}, {}
  local function AddItem(sec, entry)
   local s = bySec[sec]
   if not s then
    s = { name = sec, props = {} }
    bySec[sec] = s
    order[#order + 1] = s
   end
   s.props[#s.props + 1] = entry
  end
  local parentName = "nil"
  if inst.Parent and inst.Parent ~= Explorer.Root then parentName = inst.Parent.Name end
  AddItem("Data", { key = "Name", value = inst.Name })
  AddItem("Data", { key = "ClassName", value = inst.ClassName, readonly = true })
  AddItem("Data", { key = "Parent", value = parentName, readonly = true })
  seen.Name, seen.ClassName, seen.Parent = true, true, true

  local real = inst.Real
  if real then
   local list = API.PropsFor(inst.ClassName)
   if list then
    local canHidden = type(gethiddenproperty) == "function"
    for _, p in ipairs(list) do
     if not seen[p.Name] and (canHidden or not p.NotScriptable) then
      local ok, v = ReadReal(real, p.Name)
      if ok then
       seen[p.Name] = true
       local ro = p.ReadOnly or p.TypeCat == "Class" or (p.NotScriptable and type(sethiddenproperty) ~= "function")
       if v == nil then v, ro = "nil", true end
       AddItem(p.Category, { key = p.Name, value = v, readonly = ro and true or false })
      end
     end
    end
   else
    for _, def in ipairs(Explorer.PropertyDefs) do
     if not seen[def.Name] and IsA(inst, def.Class:lower()) then
      local ok, v = ReadReal(real, def.Name)
      if ok and v ~= nil then
       seen[def.Name] = true
       AddItem(def.Section, { key = def.Name, value = v, readonly = def.ReadOnly })
      end
     end
    end
    if API.Failed then
     AddItem("Data", { key = "(API dump failed to load)", value = "retrying on reselect", readonly = true })
     API.Failed = false
     LoadAPI()
    end
   end
  else
   for _, def in ipairs(Explorer.PropertyDefs) do
    if not seen[def.Name] and IsA(inst, def.Class:lower()) then
     seen[def.Name] = true
     local v = inst.Properties[def.Name]
     if v == nil then v = def.Default end
     AddItem(def.Section, { key = def.Name, value = v, readonly = def.ReadOnly })
    end
   end

   local extra = {}
   for k in pairs(inst.Properties) do
    if type(k) == "string" and not seen[k] then extra[#extra + 1] = k end
   end
   for _, k in ipairs(extra) do
    local v = inst.Properties[k]
    AddItem(GuessSection(k, v), { key = k, value = v })
   end
  end

  for _, s in ipairs(order) do
   table.sort(s.props, function(a, b)
    local ra, rb = RANK[a.key] or 10, RANK[b.key] or 10
    if ra ~= rb then return ra < rb end
    return a.key < b.key
   end)
  end
  table.sort(order, function(a, b)
   local oa, ob = SECTION_ORDER[a.name] or 50, SECTION_ORDER[b.name] or 50
   if oa ~= ob then return oa < ob end
   return a.name < b.name
  end)
  return order
 end

 local function HasProp(t, key)
  if key == "Name" then return true end
  if t.Real then
   local list = API.PropsFor(t.ClassName)
   if list then
    for _, p in ipairs(list) do if p.Name == key then return true end end
    return false
   end
  end
  if t.Properties[key] ~= nil then return true end
  for _, def in ipairs(Explorer.PropertyDefs) do
   if def.Name == key and IsA(t, def.Class:lower()) then return true end
  end
  return false
 end

 local function FmtNum(n)
  if n ~= n then return "nan" end
  if n == math.huge then return "inf" elseif n == -math.huge then return "-inf" end
  if n == math.floor(n) and math.abs(n) < 1e15 then return string.format("%d", n) end
  local s = string.format("%.4f", n)
  s = s:gsub("0+$", "")
  s = s:gsub("%.$", "")
  return s
 end

 local function Fmt(v)
  if type(v) == "table" and v.ClassName then return tostring(v.Name) end
  local t = typeof(v)
  if t == "string" then return v
  elseif t == "number" then return FmtNum(v)
  elseif t == "boolean" then return tostring(v)
  elseif t == "Color3" then
   return string.format("%d, %d, %d", math.round(v.R * 255), math.round(v.G * 255), math.round(v.B * 255))
  elseif t == "Vector3" then return FmtNum(v.X) .. ", " .. FmtNum(v.Y) .. ", " .. FmtNum(v.Z)
  elseif t == "Vector2" then return FmtNum(v.X) .. ", " .. FmtNum(v.Y)
  elseif t == "UDim" then return FmtNum(v.Scale) .. ", " .. FmtNum(v.Offset)
  elseif t == "UDim2" then
   return "{" .. FmtNum(v.X.Scale) .. ", " .. FmtNum(v.X.Offset) .. "}, {" .. FmtNum(v.Y.Scale) .. ", " .. FmtNum(v.Y.Offset) .. "}"
  elseif t == "CFrame" then
   local parts = {}
   for i, n in ipairs({ v:GetComponents() }) do parts[i] = FmtNum(n) end
   return table.concat(parts, ", ")
  elseif t == "EnumItem" then return v.Name
  elseif t == "BrickColor" then return v.Name
  elseif t == "NumberRange" then return FmtNum(v.Min) .. ", " .. FmtNum(v.Max)
  elseif t == "Rect" then return FmtNum(v.Min.X) .. ", " .. FmtNum(v.Min.Y) .. ", " .. FmtNum(v.Max.X) .. ", " .. FmtNum(v.Max.Y)
  elseif t == "nil" then return ""
  end
  return tostring(v)
 end

 local function Nums(text, n)
  local cleaned = text:gsub("[{}%(%)]", " ")
  local out = {}
  for s in cleaned:gmatch("[^,%s]+") do
   local x = tonumber(s)
   if not x then return nil end
   out[#out + 1] = x
  end
  if n and #out ~= n then return nil end
  return out
 end

 local function ParseValue(text, cur)
  local t = typeof(cur)
  if t == "string" then return text
  elseif t == "number" then return tonumber(text)
  elseif t == "Color3" then
   local h = text:match("^%s*#(%x%x%x%x%x%x)%s*$")
   if h then
    return Color3.fromRGB(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16))
   end
   local n = Nums(text, 3)
   if n then return Color3.fromRGB(math.clamp(n[1], 0, 255), math.clamp(n[2], 0, 255), math.clamp(n[3], 0, 255)) end
  elseif t == "Vector3" then
   local n = Nums(text, 3)
   if n then return Vector3.new(n[1], n[2], n[3]) end
  elseif t == "Vector2" then
   local n = Nums(text, 2)
   if n then return Vector2.new(n[1], n[2]) end
  elseif t == "UDim" then
   local n = Nums(text, 2)
   if n then return UDim.new(n[1], n[2]) end
  elseif t == "UDim2" then
   local n = Nums(text, 4)
   if n then return UDim2.new(n[1], n[2], n[3], n[4]) end
  elseif t == "CFrame" then
   local n = Nums(text)
   if n and #n == 3 then return CFrame.new(n[1], n[2], n[3]) * (cur - cur.Position) end
   if n and #n == 12 then return CFrame.new(table.unpack(n)) end
  elseif t == "NumberRange" then
   local n = Nums(text)
   if n and #n == 1 then return NumberRange.new(n[1]) end
   if n and #n == 2 then return NumberRange.new(n[1], n[2]) end
  elseif t == "Rect" then
   local n = Nums(text, 4)
   if n then return Rect.new(n[1], n[2], n[3], n[4]) end
  elseif t == "BrickColor" then
   local ok, bc = pcall(BrickColor.new, text)
   if ok then return bc end
  end
  return nil
 end

 local function Components(v)
  local t = typeof(v)
  if t == "Vector3" then
   return {
    { "X", v.X, function(n) return Vector3.new(n, v.Y, v.Z) end },
    { "Y", v.Y, function(n) return Vector3.new(v.X, n, v.Z) end },
    { "Z", v.Z, function(n) return Vector3.new(v.X, v.Y, n) end },
   }
  elseif t == "Vector2" then
   return {
    { "X", v.X, function(n) return Vector2.new(n, v.Y) end },
    { "Y", v.Y, function(n) return Vector2.new(v.X, n) end },
   }
  elseif t == "UDim" then
   return {
    { "Scale", v.Scale, function(n) return UDim.new(n, v.Offset) end },
    { "Offset", v.Offset, function(n) return UDim.new(v.Scale, n) end },
   }
  elseif t == "UDim2" then
   return {
    { "X", v.X, function(u) return UDim2.new(u, v.Y) end },
    { "Y", v.Y, function(u) return UDim2.new(v.X, u) end },
   }
  elseif t == "Color3" then
   local r, g, b = math.round(v.R * 255), math.round(v.G * 255), math.round(v.B * 255)
   return {
    { "R", r, function(n) return Color3.fromRGB(math.clamp(n, 0, 255), g, b) end },
    { "G", g, function(n) return Color3.fromRGB(r, math.clamp(n, 0, 255), b) end },
    { "B", b, function(n) return Color3.fromRGB(r, g, math.clamp(n, 0, 255)) end },
   }
  elseif t == "CFrame" then
   local rx, ry, rz = v:ToOrientation()
   return {
    { "Position", v.Position, function(p) return CFrame.new(p) * (v - v.Position) end },
    { "Orientation", Vector3.new(math.deg(rx), math.deg(ry), math.deg(rz)), function(o)
      return CFrame.new(v.Position) * CFrame.fromOrientation(math.rad(o.X), math.rad(o.Y), math.rad(o.Z))
    end },
   }
  elseif t == "NumberRange" then
   return {
    { "Min", v.Min, function(n) return NumberRange.new(n, math.max(n, v.Max)) end },
    { "Max", v.Max, function(n) return NumberRange.new(math.min(n, v.Min), n) end },
   }
  end
  return nil
 end

 local EDITABLE = {
  string = true, number = true, Color3 = true, Vector3 = true, Vector2 = true, UDim = true,
  UDim2 = true, CFrame = true, NumberRange = true, Rect = true, BrickColor = true,
 }

 local ATTR_TYPES = {
  { "string", "" }, { "boolean", false }, { "number", 0 },
  { "UDim", UDim.new(0, 0) }, { "UDim2", UDim2.new(0, 0, 0, 0) }, { "Color3", Color3.fromRGB(255, 255, 255) },
  { "Vector2", Vector2.new(0, 0) }, { "Vector3", Vector3.new(0, 0, 0) }, { "CFrame", CFrame.new() },
  { "NumberRange", NumberRange.new(0, 1) }, { "Rect", Rect.new(0, 0, 0, 0) },
 }

 local Rebuild, RefreshList

 local function ApplyProp(key, value)
  local targets = Explorer.GetSelection()
  if #targets == 0 and P.Inst then targets = { P.Inst } end
  for _, t in ipairs(targets) do
   if HasProp(t, key) then
    if key == "Name" then
     if type(value) == "string" and value ~= "" then
      if t.Real then
       if WriteReal(t.Real, "Name", value) then t.Name = value end
      else
       t.Name = value
      end
     end
    elseif t.Real then
     WriteReal(t.Real, key, value)
    else
     t.Properties[key] = value
    end
    if Explorer.OnPropertyChangedCb then pcall(Explorer.OnPropertyChangedCb, t, key, value) end
   end
  end
  if key == "Name" then
   Explorer.ScanTree()
   RefreshTree()
  end
  Explorer.RefreshProperties()
 end

 local function TagList(inst)
  local out = {}
  local t = inst.Tags
  if type(t) == "table" then
   for k, v in pairs(t) do
    if type(k) == "string" and v == true then out[#out + 1] = k
    elseif type(k) == "number" and type(v) == "string" then out[#out + 1] = v end
   end
  end
  table.sort(out)
  return out
 end

 local function RemoveTag(inst, tag)
  local t = inst.Tags
  if type(t) ~= "table" then return end
  t[tag] = nil
  for i = #t, 1, -1 do
   if t[i] == tag then table.remove(t, i) end
  end
 end

 local function AddValueRows(rows, d)
  local row = {
   kind = "prop", name = d.name, value = d.value, readonly = d.readonly,
   Commit = d.Commit, gear = d.gear, expKey = d.expKey,
  }
  local comps = (not d.readonly) and Components(d.value) or nil
  if comps then
   row.expandable = true
   row.expanded = P.PExp[d.expKey] == true
  end
  rows[#rows + 1] = row
  if row.expanded then
   for _, c in ipairs(comps) do
    local make = c[3]
    rows[#rows + 1] = {
     kind = "prop", sub = true, name = c[1], value = c[2],
     Commit = function(nv) d.Commit(make(nv)) end,
    }
   end
  end
 end

 Rebuild = function()
  local rows = {}
  local inst = Explorer.Selected
  if inst == Explorer.Root then inst = nil end
  P.Inst = inst
  if inst then
   local f = P.Filter
   local function Matches(name) return f == "" or name:lower():find(f, 1, true) ~= nil end

   for _, sec in ipairs(Collect(inst)) do
    local keep = {}
    for _, p in ipairs(sec.props) do
     if Matches(p.key) then keep[#keep + 1] = p end
    end
    if #keep > 0 then
     local collapsed = P.Collapsed[sec.name] == true and f == ""
     rows[#rows + 1] = { kind = "section", name = sec.name, collapsed = collapsed }
     if not collapsed then
      for _, p in ipairs(keep) do
       local key = p.key
       AddValueRows(rows, {
        name = key, value = p.value, readonly = p.readonly,
        expKey = inst.ClassName .. ":" .. key,
        Commit = function(nv) ApplyProp(key, nv) end,
       })
      end
     end
    end
   end

   if inst.Real then
    local okA, attrs = pcall(function() return inst.Real:GetAttributes() end)
    if okA and type(attrs) == "table" then
     local store = inst.Attributes
     for k in pairs(store) do store[k] = nil end
     for k, v in pairs(attrs) do store[k] = v end
    end
   end
   local attrNames = {}
   for k in pairs(inst.Attributes) do
    if type(k) == "string" and Matches(k) then attrNames[#attrNames + 1] = k end
   end
   table.sort(attrNames)
   if f == "" or #attrNames > 0 then
    local collapsed = P.Collapsed.Attributes == true and f == ""
    rows[#rows + 1] = { kind = "section", name = "Attributes", collapsed = collapsed, add = (f == "") and "attr" or nil }
    if not collapsed then
     for _, k in ipairs(attrNames) do
      local name = k
      AddValueRows(rows, {
       name = name, value = inst.Attributes[name], gear = true,
       expKey = "attr:" .. name,
       Commit = function(nv)
        inst.Attributes[name] = nv
        if inst.Real then pcall(function() inst.Real:SetAttribute(name, nv) end) end
        if Explorer.OnPropertyChangedCb then pcall(Explorer.OnPropertyChangedCb, inst, "Attribute:" .. name, nv) end
        Explorer.RefreshProperties()
       end,
      })
     end
    end
   end

   local tags = {}
   for _, tg in ipairs(TagList(inst)) do
    if Matches(tg) then tags[#tags + 1] = tg end
   end
   if f == "" or #tags > 0 then
    local collapsed = P.Collapsed.Tags == true and f == ""
    rows[#rows + 1] = { kind = "section", name = "Tags", collapsed = collapsed, add = (f == "") and "tag" or nil }
    if not collapsed then
     for _, tg in ipairs(tags) do rows[#rows + 1] = { kind = "tag", name = tg } end
    end
   end
  end
  P.Rows = rows
 end

 config.pmain = Instance.new("Frame")
 config.pmain.Name = RandomString()
 config.pmain.Size = UDim2.new(0, config.main.Size.X.Offset, 0, P.FloatH)
 config.pmain.Position = UDim2.new(0, 40, 0, 40)
 ClampPanelTop(config.pmain)
 config.pmain.BackgroundColor3 = config.COLORS.PRIMARY
 config.pmain.BackgroundTransparency = config.NT
 config.pmain.Active = true
 config.pmain.BorderSizePixel = 0
 config.pmain.ZIndex = 2
 config.pmain.Archivable = false
 config.pmain.Parent = config.window
 RegisterWindow(config.pmain)

 config.pdocksplitter = Instance.new("Frame")
 config.pdocksplitter.Name = RandomString()
 config.pdocksplitter.Size = UDim2.new(0, 6, 1, 0)
 config.pdocksplitter.BackgroundColor3 = config.COLORS.RESIZER
 config.pdocksplitter.BorderSizePixel = 0
 config.pdocksplitter.ZIndex = 8
 config.pdocksplitter.Visible = false
 config.pdocksplitter.Active = true
 config.pdocksplitter.Archivable = false
 config.pdocksplitter.Parent = config.pmain

 local hdr = Instance.new("Frame")
 hdr.Name = RandomString()
 hdr.Size = UDim2.new(1, 0, 0, 65)
 hdr.BackgroundColor3 = config.COLORS.HEADER
 hdr.BorderSizePixel = 0
 hdr.Active = true
 hdr.ZIndex = 3
 hdr.Archivable = false
 hdr.Parent = config.pmain

 local hAccent = Instance.new("Frame")
 hAccent.Name = RandomString()
 hAccent.Size = UDim2.new(1, 0, 0, 1.5)
 hAccent.Position = UDim2.new(0, 0, 1, -1.5)
 hAccent.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
 hAccent.BorderSizePixel = 0
 hAccent.ZIndex = 3
 hAccent.Archivable = false
 hAccent.Parent = hdr

 local ptitle = Instance.new("TextLabel")
 ptitle.Name = RandomString()
 ptitle.Size = UDim2.new(1, -70, 0, 28)
 ptitle.Position = UDim2.new(0, 35, 0, 0)
 ptitle.BackgroundTransparency = 1
 ptitle.Text = "Properties"
 ptitle.TextColor3 = config.COLORS.TEXT_BRIGHT
 ptitle.FontFace = config.FONT.GothamRegular
 ptitle.TextSize = 12
 ptitle.TextTruncate = Enum.TextTruncate.AtEnd
 ptitle.TextXAlignment = Enum.TextXAlignment.Center
 ptitle.ZIndex = 3
 ptitle.Archivable = false
 ptitle.Parent = hdr

 local pclose = Instance.new("TextButton")
 pclose.Name = RandomString()
 pclose.Size = UDim2.new(0, 28, 0, 28)
 pclose.Position = UDim2.new(1, -30, 0, 1)
 pclose.BackgroundTransparency = 1
 pclose.Text = ""
 pclose.AutoButtonColor = false
 pclose.BorderSizePixel = 0
 pclose.ZIndex = 3
 pclose.Archivable = false
 pclose.Parent = hdr
 MakeCloseIcon(pclose, 8, 4, Color3.fromRGB(210, 210, 210))

 local ppin = Instance.new("TextButton")
 ppin.Name = RandomString()
 ppin.Size = UDim2.new(0, 22, 0, 22)
 ppin.Position = UDim2.new(1, -58, 0, 3)
 ppin.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
 ppin.BackgroundTransparency = 0.7
 ppin.AutoButtonColor = false
 ppin.Text = ""
 ppin.BorderSizePixel = 0
 ppin.ZIndex = 3
 ppin.Archivable = false
 ppin.Parent = hdr
 RoundCorner(ppin, 0, 6)
 MakePinIcon(ppin, 14, 4, Color3.fromRGB(210, 210, 210))

 local searchRowP = Instance.new("Frame")
 searchRowP.Name = RandomString()
 searchRowP.Size = UDim2.new(1, 0, 0, 34)
 searchRowP.Position = UDim2.new(0, 0, 0, 28)
 searchRowP.BackgroundTransparency = 1
 searchRowP.BorderSizePixel = 0
 searchRowP.ZIndex = 3
 searchRowP.Archivable = false
 searchRowP.Parent = config.pmain

 local filterBox = Instance.new("TextBox")
 filterBox.Name = RandomString()
 filterBox.Size = UDim2.new(1, -14, 0, 28)
 filterBox.Position = UDim2.new(0, 7, 0, 4)
 filterBox.BackgroundColor3 = config.COLORS.PRIMARY
 filterBox.PlaceholderText = "Filter Properties (Ctrl+Shift+P)"
 filterBox.PlaceholderColor3 = config.COLORS.TEXT
 filterBox.Text = ""
 filterBox.TextColor3 = config.COLORS.TEXT_BRIGHT
 filterBox.Font = Enum.Font.SourceSans
 filterBox.TextSize = 15
 filterBox.TextXAlignment = Enum.TextXAlignment.Left
 filterBox.ClearTextOnFocus = false
 filterBox.ZIndex = 5
 filterBox.Archivable = false
 filterBox.Parent = searchRowP

 local pbody = Instance.new("Frame")
 pbody.Name = RandomString()
 pbody.Size = UDim2.new(1, 0, 1, -65)
 pbody.Position = UDim2.new(0, 0, 0, 65)
 pbody.BackgroundTransparency = 1
 pbody.ZIndex = 3
 pbody.Archivable = false
 pbody.Parent = config.pmain

 local list = Instance.new("Frame")
 list.Name = RandomString()
 list.Size = UDim2.new(1, -18, 1, -8)
 list.BackgroundTransparency = 1
 list.ClipsDescendants = true
 list.ZIndex = 3
 list.Archivable = false
 list.Parent = pbody

 local SB_W = 18

 local pvbar = Instance.new("Frame")
 pvbar.Name = RandomString()
 pvbar.Size = UDim2.new(0, SB_W, 1, -8)
 pvbar.Position = UDim2.new(1, -SB_W, 0, 0)
 pvbar.BackgroundColor3 = Color3.fromRGB(34, 34, 38)
 pvbar.BorderSizePixel = 0
 pvbar.Active = true
 pvbar.Visible = false
 pvbar.ZIndex = 9
 pvbar.Archivable = false
 pvbar.Parent = pbody

 local function MakeSBButton(up)
  local b = Instance.new("TextButton")
  b.Name = RandomString()
  b.Size = UDim2.new(0, SB_W, 0, SB_W)
  b.Position = up and UDim2.new(0, 0, 0, 0) or UDim2.new(0, 0, 1, -SB_W)
  b.BackgroundColor3 = Color3.fromRGB(52, 52, 57)
  b.BorderSizePixel = 0
  b.AutoButtonColor = false
  b.Text = ""
  b.ZIndex = 10
  b.Archivable = false
  b.Parent = pvbar
  BorderStroke(b, 1, 24, 24, 27)
  local c = Instance.new("ImageLabel")
  c.Name = RandomString()
  c.Size = UDim2.new(0, 10, 0, 10)
  c.AnchorPoint = Vector2.new(0.5, 0.5)
  c.Position = UDim2.new(0.5, 0, 0.5, 0)
  c.BackgroundTransparency = 1
  c.Image = config.IMG.Caret
  c.Rotation = up and -90 or 90
  c.ZIndex = 11
  c.Archivable = false
  c.Parent = b
  b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(70, 70, 76) end)
  b.MouseLeave:Connect(function() b.BackgroundColor3 = Color3.fromRGB(52, 52, 57) end)
  return b
 end
 local pvup = MakeSBButton(true)
 local pvdown = MakeSBButton(false)

 local pvtrack = Instance.new("Frame")
 pvtrack.Name = RandomString()
 pvtrack.Size = UDim2.new(1, 0, 1, -SB_W * 2)
 pvtrack.Position = UDim2.new(0, 0, 0, SB_W)
 pvtrack.BackgroundTransparency = 1
 pvtrack.BorderSizePixel = 0
 pvtrack.ZIndex = 10
 pvtrack.Archivable = false
 pvtrack.Parent = pvbar

 local pvthumb = Instance.new("Frame")
 pvthumb.Name = RandomString()
 pvthumb.Size = UDim2.new(1, 0, 0.2, 0)
 pvthumb.BackgroundTransparency = 1
 pvthumb.BorderSizePixel = 0
 pvthumb.Active = false
 pvthumb.ZIndex = 11
 pvthumb.Archivable = false
 pvthumb.Parent = pvtrack

 local pvvis = Instance.new("Frame")
 pvvis.Name = RandomString()
 pvvis.Size = UDim2.new(1, -2, 1, 0)
 pvvis.Position = UDim2.new(0, 1, 0, 0)
 pvvis.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
 pvvis.BorderSizePixel = 0
 pvvis.ZIndex = 11
 pvvis.Active = false
 pvvis.Archivable = false
 pvvis.Parent = pvthumb

 local divHit = Instance.new("TextButton")
 divHit.Name = RandomString()
 divHit.Size = UDim2.new(0, 14, 1, 0)
 divHit.BackgroundTransparency = 1
 divHit.Text = ""
 divHit.AutoButtonColor = false
 divHit.Visible = false
 divHit.ZIndex = 8
 divHit.Archivable = false
 divHit.Parent = list

 local function CloseMenu()
  if P.MenuBlocker then
   P.MenuBlocker:Destroy()
   P.MenuBlocker = nil
  end
 end

 local function OpenMenu(anchor, items, onPick, minW)
  CloseMenu()
  local blocker = Instance.new("TextButton")
  blocker.Name = RandomString()
  blocker.Size = UDim2.new(1, 0, 1, 0)
  blocker.BackgroundTransparency = 1
  blocker.Text = ""
  blocker.AutoButtonColor = false
  blocker.ZIndex = 70
  blocker.Archivable = false
  blocker.Parent = config.window
  blocker.Activated:Connect(CloseMenu)
  P.MenuBlocker = blocker

  local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
  local ITEM_H = 26
  local w = math.max(minW or 0, as.X, 120)
  local h = math.min(#items * ITEM_H + 4, 240)
  local scr = config.window.AbsoluteSize
  local x = math.clamp(ap.X, 4, math.max(4, scr.X - w - 4))
  local y = ap.Y + as.Y + 2
  if y + h > scr.Y - 4 then y = math.max(4, ap.Y - h - 2) end

  local m = Instance.new("ScrollingFrame")
  m.Name = RandomString()
  m.Size = UDim2.new(0, w, 0, h)
  m.Position = UDim2.new(0, x, 0, y)
  m.BackgroundColor3 = config.COLORS.PRIMARY
  m.BorderSizePixel = 0
  m.CanvasSize = UDim2.new(0, 0, 0, #items * ITEM_H + 4)
  m.ScrollBarThickness = 6
  m.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
  m.ZIndex = 71
  m.Active = true
  m.Archivable = false
  m.Parent = blocker
  BorderStroke(m, 1, 80, 80, 80)

  for i, it in ipairs(items) do
   local b = Instance.new("TextButton")
   b.Name = RandomString()
   b.Size = UDim2.new(1, -8, 0, ITEM_H - 2)
   b.Position = UDim2.new(0, 4, 0, 2 + (i - 1) * ITEM_H)
   b.BackgroundColor3 = config.COLORS.SECONDARY
   b.BackgroundTransparency = 1
   b.BorderSizePixel = 0
   b.AutoButtonColor = false
   b.Text = it.label
   b.TextColor3 = it.danger and config.COLORS.CLOSE_TEXT or config.COLORS.TEXT_BRIGHT
   b.TextXAlignment = Enum.TextXAlignment.Left
   b.Font = Enum.Font.SourceSans
   b.TextSize = 18
   b.ZIndex = 72
   b.Archivable = false
   b.Parent = m
   RoundCorner(b, 0, 4)
   local pad = Instance.new("UIPadding")
   pad.PaddingLeft = UDim.new(0, 8)
   pad.Parent = b
   b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
   b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
   b.Activated:Connect(function()
    CloseMenu()
    onPick(it)
   end)
  end
 end

 local function OpenDialog(cfg)
  CloseMenu()
  local blocker = Instance.new("TextButton")
  blocker.Name = RandomString()
  blocker.Size = UDim2.new(1, 0, 1, 0)
  blocker.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
  blocker.BackgroundTransparency = 0.55
  blocker.Text = ""
  blocker.AutoButtonColor = false
  blocker.ZIndex = 50
  blocker.Archivable = false
  blocker.Parent = config.window
  local function Close() blocker:Destroy() end
  blocker.Activated:Connect(Close)

  local dlg = Instance.new("Frame")
  dlg.Name = RandomString()
  dlg.Size = UDim2.new(0, 270, 0, cfg.withType and 158 or 114)
  dlg.AnchorPoint = Vector2.new(0.5, 0.5)
  dlg.Position = UDim2.new(0.5, 0, 0.4, 0)
  dlg.BackgroundColor3 = config.COLORS.PRIMARY
  dlg.BorderSizePixel = 0
  dlg.Active = true
  dlg.ZIndex = 51
  dlg.Archivable = false
  dlg.Parent = blocker
  RoundCorner(dlg, 0, 8)
  BorderStroke(dlg, 1, 80, 80, 80)

  local t = Instance.new("TextLabel")
  t.Name = RandomString()
  t.Size = UDim2.new(1, -24, 0, 22)
  t.Position = UDim2.new(0, 12, 0, 6)
  t.BackgroundTransparency = 1
  t.Text = cfg.title
  t.TextColor3 = config.COLORS.TEXT_BRIGHT
  t.TextXAlignment = Enum.TextXAlignment.Left
  t.FontFace = config.FONT.GothamMedium
  t.TextSize = 13
  t.ZIndex = 52
  t.Archivable = false
  t.Parent = dlg

  local nameBox = Instance.new("TextBox")
  nameBox.Name = RandomString()
  nameBox.Size = UDim2.new(1, -24, 0, 28)
  nameBox.Position = UDim2.new(0, 12, 0, 34)
  nameBox.BackgroundColor3 = config.COLORS.SECONDARY
  nameBox.PlaceholderText = "Name"
  nameBox.PlaceholderColor3 = config.COLORS.TEXT_DIM
  nameBox.Text = cfg.name or ""
  nameBox.TextColor3 = config.COLORS.TEXT_BRIGHT
  nameBox.Font = Enum.Font.SourceSans
  nameBox.TextSize = 18
  nameBox.TextXAlignment = Enum.TextXAlignment.Left
  nameBox.ClearTextOnFocus = false
  nameBox.ZIndex = 52
  nameBox.Archivable = false
  nameBox.Parent = dlg
  RoundCorner(nameBox, 0, 6)
  local npad = Instance.new("UIPadding")
  npad.PaddingLeft = UDim.new(0, 8)
  npad.Parent = nameBox

  local typeName = cfg.typeName or "string"
  if cfg.withType then
   local typeBtn = Instance.new("TextButton")
   typeBtn.Name = RandomString()
   typeBtn.Size = UDim2.new(1, -24, 0, 28)
   typeBtn.Position = UDim2.new(0, 12, 0, 68)
   typeBtn.BackgroundColor3 = config.COLORS.SECONDARY
   typeBtn.AutoButtonColor = false
   typeBtn.Text = typeName
   typeBtn.TextColor3 = config.COLORS.TEXT_BRIGHT
   typeBtn.Font = Enum.Font.SourceSans
   typeBtn.TextSize = 18
   typeBtn.TextXAlignment = Enum.TextXAlignment.Left
   typeBtn.ZIndex = 52
   typeBtn.Archivable = false
   typeBtn.Parent = dlg
   RoundCorner(typeBtn, 0, 6)
   local tpad = Instance.new("UIPadding")
   tpad.PaddingLeft = UDim.new(0, 8)
   tpad.Parent = typeBtn
   local chev = MakeChevron(typeBtn, 53)
   chev.Position = UDim2.new(1, -20, 0.5, -4)
   typeBtn.Activated:Connect(function()
    local items = {}
    for _, at in ipairs(ATTR_TYPES) do items[#items + 1] = { label = at[1] } end
    OpenMenu(typeBtn, items, function(it)
     typeName = it.label
     typeBtn.Text = typeName
    end)
   end)
  end

  local function MkBtn(text, x, w, color, fn)
   local b = Instance.new("TextButton")
   b.Name = RandomString()
   b.Size = UDim2.new(w, -15, 0, 28)
   b.Position = UDim2.new(x, x == 0 and 12 or 3, 1, -38)
   b.BackgroundColor3 = color
   b.AutoButtonColor = false
   b.Text = text
   b.TextColor3 = Color3.fromRGB(255, 255, 255)
   b.FontFace = config.FONT.GothamMedium
   b.TextSize = 12
   b.ZIndex = 52
   b.Archivable = false
   b.Parent = dlg
   RoundCorner(b, 0, 6)
   b.Activated:Connect(fn)
   return b
  end
  local function Save()
   local n = nameBox.Text:match("^%s*(.-)%s*$")
   if n == "" then return end
   if cfg.Validate then
    local err = cfg.Validate(n)
    if err then
     t.Text = err
     t.TextColor3 = config.COLORS.CLOSE_TEXT
     return
    end
   end
   Close()
   cfg.OnSave(n, typeName)
  end
  MkBtn("Cancel", 0, 0.5, config.COLORS.SECONDARY, Close)
  MkBtn("Save", 0.5, 0.5, config.COLORS.SELECTED, Save)
  nameBox.FocusLost:Connect(function(enter) if enter then Save() end end)
  task.defer(function() if nameBox.Parent then nameBox:CaptureFocus() end end)
 end

 local function DefaultFor(typeName)
  for _, at in ipairs(ATTR_TYPES) do
   if at[1] == typeName then return at[2] end
  end
  return ""
 end

 local pool = {}

 local function MakeRow()
  local r = {}
  local f = Instance.new("TextButton")
  f.Name = RandomString()
  f.Size = UDim2.new(1, 0, 0, ROW)
  f.BackgroundColor3 = config.COLORS.HEADER
  f.BackgroundTransparency = 1
  f.BorderSizePixel = 0
  f.AutoButtonColor = false
  f.Text = ""
  f.ZIndex = 3
  f.Visible = false
  f.Archivable = false
  f.Parent = list
  r.frame = f

  local line = Instance.new("Frame")
  line.Name = RandomString()
  line.Size = UDim2.new(1, 0, 0, 1)
  line.Position = UDim2.new(0, 0, 1, -1)
  line.BackgroundColor3 = Color3.fromRGB(38, 39, 45)
  line.BorderSizePixel = 0
  line.ZIndex = 3
  line.Archivable = false
  line.Parent = f
  r.line = line

  local vline = Instance.new("Frame")
  vline.Name = RandomString()
  vline.Size = UDim2.new(0, 1, 1, 0)
  vline.BackgroundColor3 = Color3.fromRGB(38, 39, 45)
  vline.BorderSizePixel = 0
  vline.ZIndex = 3
  vline.Archivable = false
  vline.Parent = f
  r.vline = vline

  local arrow = Instance.new("ImageButton")
  arrow.Name = RandomString()
  arrow.Size = UDim2.new(0, 10, 0, 10)
  arrow.BackgroundTransparency = 1
  arrow.Image = config.IMG.Caret
  arrow.AutoButtonColor = false
  arrow.ZIndex = 5
  arrow.Visible = false
  arrow.Archivable = false
  arrow.Parent = f
  r.arrow = arrow

  local name = Instance.new("TextLabel")
  name.Name = RandomString()
  name.BackgroundTransparency = 1
  name.TextColor3 = config.COLORS.TEXT
  name.TextXAlignment = Enum.TextXAlignment.Left
  name.TextYAlignment = Enum.TextYAlignment.Center
  name.Font = Enum.Font.SourceSans
  name.TextSize = 19
  name.TextTruncate = Enum.TextTruncate.None
  name.ClipsDescendants = true
  name.ZIndex = 4
  name.Archivable = false
  name.Parent = f
  r.name = name

  local value = Instance.new("TextBox")
  value.Name = RandomString()
  value.BackgroundColor3 = Color3.fromRGB(20, 21, 26)
  value.BackgroundTransparency = 1
  value.BorderSizePixel = 0
  value.TextColor3 = config.COLORS.TEXT_BRIGHT
  value.Font = Enum.Font.SourceSans
  value.TextSize = 19
  value.TextXAlignment = Enum.TextXAlignment.Left
  value.TextTruncate = Enum.TextTruncate.AtEnd
  value.ClearTextOnFocus = false
  value.Text = ""
  value.Visible = false
  value.ZIndex = 5
  value.Archivable = false
  value.Parent = f
  local vpad = Instance.new("UIPadding")
  vpad.PaddingLeft = UDim.new(0, 4)
  vpad.Parent = value
  local vstroke = BorderStroke(value, 1, 0, 51, 225)
  vstroke.Enabled = false
  r.value = value

  local hit = Instance.new("TextButton")
  hit.Name = RandomString()
  hit.BackgroundTransparency = 1
  hit.Text = ""
  hit.AutoButtonColor = false
  hit.Visible = false
  hit.ZIndex = 7
  hit.Archivable = false
  hit.Parent = f
  r.hit = hit

  local swatch = Instance.new("Frame")
  swatch.Name = RandomString()
  swatch.Size = UDim2.new(0, 16, 0, 12)
  swatch.BorderSizePixel = 0
  swatch.Visible = false
  swatch.ZIndex = 5
  swatch.Archivable = false
  swatch.Parent = f
  BorderStroke(swatch, 1, 90, 90, 90)
  r.swatch = swatch

  local checkBtn = Instance.new("TextButton")
  checkBtn.Name = RandomString()
  checkBtn.Size = UDim2.new(0, 20, 0, 20)
  checkBtn.BackgroundTransparency = 1
  checkBtn.Text = ""
  checkBtn.AutoButtonColor = false
  checkBtn.Visible = false
  checkBtn.ZIndex = 6
  checkBtn.Archivable = false
  checkBtn.Parent = f
  local cbox, setCheck = MakeCheckBox(checkBtn, 16, 7)
  cbox.Position = UDim2.new(0, 2, 0, 2)
  r.checkBtn, r.setCheck = checkBtn, setCheck

  local chev = Instance.new("ImageLabel")
  chev.Name = RandomString()
  chev.Size = UDim2.new(0, 10, 0, 10)
  chev.BackgroundTransparency = 1
  chev.Image = config.IMG.Caret
  chev.Rotation = 90
  chev.ZIndex = 6
  chev.Archivable = false
  chev.Visible = false
  chev.Parent = f
  r.chev = chev

  local add = MakePlus(f, 6)
  add.Visible = false
  r.add = add
  local del = MakeCross(f, 6)
  del.Visible = false
  r.del = del
  local more = MakeDots(f, 6)
  more.Visible = false
  r.more = more

  local function ToggleRow()
   local d = r.data
   if not d then return end
   if d.kind == "section" then
    return
   elseif d.expandable then
    P.PExp[d.expKey] = (not P.PExp[d.expKey]) or nil
   else
    return
   end
   Explorer.RefreshProperties()
  end
  f.Activated:Connect(ToggleRow)
  arrow.Activated:Connect(ToggleRow)

  local editData
  value.Focused:Connect(function()
   editData = r.data
   value.BackgroundTransparency = 0
   vstroke.Enabled = true
  end)
  value.FocusLost:Connect(function()
   value.BackgroundTransparency = 1
   vstroke.Enabled = false
   local d = editData or r.data
   editData = nil
   if not d or d.kind ~= "prop" then return end
   if not d.Commit or d.readonly then value.Text = Fmt(d.value) return end
   local nv = ParseValue(value.Text, d.value)
   if nv == nil or (d.name == "Name" and nv == "") then
    value.Text = Fmt(d.value)
    return
   end
   if typeof(nv) == typeof(d.value) and Fmt(nv) == Fmt(d.value) then
    value.Text = Fmt(d.value)
    return
   end
   d.Commit(nv)
  end)

  checkBtn.Activated:Connect(function()
   local d = r.data
   if d and d.Commit and not d.readonly then d.Commit(not d.value) end
  end)

  hit.Activated:Connect(function()
   local d = r.data
   if not d or not d.Commit or d.readonly then return end
   local ok, items = pcall(function() return d.value.EnumType:GetEnumItems() end)
   if not ok then return end
   local menu = {}
   for _, it in ipairs(items) do menu[#menu + 1] = { label = it.Name, value = it } end
   OpenMenu(hit, menu, function(it) d.Commit(it.value) end)
  end)

  add.Activated:Connect(function()
   local d = r.data
   local inst = P.Inst
   if not d or not inst then return end
   if d.add == "attr" then
    OpenDialog({
     title = "New attribute", withType = true, typeName = "string",
     Validate = function(n)
      if inst.Attributes[n] ~= nil then return "Attribute already exists" end
     end,
     OnSave = function(n, tn)
      if inst.Attributes[n] == nil then inst.Attributes[n] = DefaultFor(tn) end
      Explorer.RefreshProperties()
     end,
    })
   elseif d.add == "tag" then
    OpenDialog({
     title = "Add tag",
     OnSave = function(n)
      Explorer.AddTag(inst, n)
      Explorer.RefreshProperties()
     end,
    })
   end
  end)

  del.Activated:Connect(function()
   local d = r.data
   if d and d.kind == "tag" and P.Inst then
    RemoveTag(P.Inst, d.name)
    Explorer.RefreshProperties()
   end
  end)

  more.Activated:Connect(function()
   local d = r.data
   local inst = P.Inst
   if not d or not inst then return end
   local old = d.name
   OpenMenu(more, {
    { label = "Rename", act = "rename" },
    { label = "Delete", act = "delete", danger = true },
   }, function(it)
    if it.act == "delete" then
     inst.Attributes[old] = nil
     Explorer.RefreshProperties()
    else
     OpenDialog({
      title = "Rename attribute", name = old,
      Validate = function(n)
       if n ~= old and inst.Attributes[n] ~= nil then return "Attribute already exists" end
      end,
      OnSave = function(n)
       if n ~= old and inst.Attributes[n] == nil then
        inst.Attributes[n] = inst.Attributes[old]
        inst.Attributes[old] = nil
       end
       Explorer.RefreshProperties()
      end,
     })
    end
   end, 120)
  end)

  return r
 end

 local function Bind(r, d, i, nameW, contentW)
  local f = r.frame
  f.Visible = true
  f.Position = UDim2.new(0, 0, 0, (i - 1) * ROW)
  r.data = d
  r.arrow.Visible = false
  r.value.Visible = false
  r.hit.Visible = false
  r.swatch.Visible = false
  r.checkBtn.Visible = false
  r.chev.Visible = false
  r.add.Visible = false
  r.del.Visible = false
  r.more.Visible = false
  r.vline.Visible = false

  if d.kind == "section" then
   f.BackgroundTransparency = 0
   r.line.Visible = false
   r.name.FontFace = config.FONT.GothamMedium
   r.name.TextSize = 12
   r.name.TextColor3 = config.COLORS.TEXT_BRIGHT
   r.name.TextXAlignment = Enum.TextXAlignment.Left
   r.name.TextTruncate = Enum.TextTruncate.AtEnd
   r.name.Position = UDim2.new(0, 8, 0, 0)
   r.name.Size = UDim2.new(1, -36, 1, 0)
   r.name.Text = d.name
   if d.add then
    r.add.Visible = true
    r.add.Position = UDim2.new(0, contentW - 24, 0.5, -9)
   end
   return
  end

  f.BackgroundTransparency = 1
  r.line.Visible = true
  r.name.Font = Enum.Font.SourceSans
  r.name.TextSize = 19
  r.name.TextColor3 = config.COLORS.TEXT
  r.name.Text = d.name

  if d.kind == "tag" then
   r.name.TextXAlignment = Enum.TextXAlignment.Left
   r.name.TextTruncate = Enum.TextTruncate.AtEnd
   r.name.Position = UDim2.new(0, 24, 0, 0)
   r.name.Size = UDim2.new(0, contentW - 56, 1, 0)
   r.del.Visible = true
   r.del.Position = UDim2.new(0, contentW - 24, 0.5, -9)
   return
  end

  local indent = d.sub and 16 or 0
  if d.expandable then
   r.arrow.Visible = true
   r.arrow.Position = UDim2.new(0, 4 + indent, 0.5, -5)
   r.arrow.Rotation = d.expanded and 90 or 0
  end
  local nameAvail = math.max(10, nameW - 28 - indent)
  r.name.Position = UDim2.new(0, 24 + indent, 0, 0)
  r.name.Size = UDim2.new(0, nameAvail, 1, 0)
  r.name.TextTruncate = Enum.TextTruncate.None
  r.name.TextXAlignment = Enum.TextXAlignment.Left
  local function TW(s) return config.SV.TextSrv:GetTextSize(s, 19, Enum.Font.SourceSans, Vector2.new(10000, 26)).X end
  if TW(d.name) > nameAvail then
   local full, lo, hi = d.name, 0, #d.name
   while lo < hi do
    local mid = math.ceil((lo + hi) / 2)
    if TW("..." .. full:sub(#full - mid + 1)) <= nameAvail then lo = mid else hi = mid - 1 end
   end
   r.name.Text = "..." .. full:sub(#full - lo + 1)
  end
  r.vline.Visible = true
  r.vline.Position = UDim2.new(0, nameW, 0, 0)

  local vx = nameW + 4
  local vw = contentW - vx - 2
  if d.gear then
   vw = vw - 20
   r.more.Visible = true
   r.more.Position = UDim2.new(0, contentW - 20, 0.5, -9)
  end
  vw = math.max(20, vw)

  local t = typeof(d.value)
  local editable = (not d.readonly) and d.Commit ~= nil
  if t == "boolean" then
   r.checkBtn.Visible = true
   r.checkBtn.Position = UDim2.new(0, vx + 4, 0.5, -10)
   r.setCheck(d.value)
   return
  end

  local tx = vx
  if t == "Color3" then
   r.swatch.Visible = true
   r.swatch.BackgroundColor3 = d.value
   r.swatch.Position = UDim2.new(0, vx + 4, 0.5, -6)
   tx = vx + 24
  end
  r.value.Visible = true
  r.value.Position = UDim2.new(0, tx, 0, 2)
  r.value.Size = UDim2.new(0, math.max(10, vw - (tx - vx) - (t == "EnumItem" and editable and 16 or 0)), 1, -5)
  r.value.Text = Fmt(d.value)
  if t == "EnumItem" then
   r.value.TextEditable = false
   r.value.TextColor3 = config.COLORS.TEXT_BRIGHT
   if editable then
    r.hit.Visible = true
    r.hit.Position = UDim2.new(0, vx, 0, 0)
    r.hit.Size = UDim2.new(0, vw, 1, 0)
    r.chev.Visible = true
    r.chev.Position = UDim2.new(0, vx + vw - 12, 0.5, -5)
   end
  elseif editable and EDITABLE[t] then
   r.value.TextEditable = true
   r.value.TextColor3 = config.COLORS.TEXT_BRIGHT
  else
   r.value.TextEditable = false
   r.value.TextColor3 = config.COLORS.TEXT_DIM
  end
 end

 RefreshList = function()
  if not config.pmain.Visible then return end
  local viewH = list.AbsoluteSize.Y
  local listW = list.AbsoluteSize.X
  if viewH <= 0 then return end
  local contentW = listW
  local fullRows = math.floor(viewH / ROW)
  local need = math.ceil(viewH / ROW) + 1
  while #pool < need do pool[#pool + 1] = MakeRow() end

  local total = #P.Rows
  local maxScroll = math.max(0, total - fullRows)
  P.Scroll = math.clamp(P.Scroll, 0, maxScroll)
  local nameW = math.floor(contentW * P.Divider)

  for i = 1, #pool do
   local r = pool[i]
   local d = P.Rows[P.Scroll + i]
   if d and (i - 1) * ROW < viewH then
    Bind(r, d, i, nameW, contentW)
   else
    r.frame.Visible = false
    r.data = nil
   end
  end

  divHit.Visible = total > 0
  divHit.Position = UDim2.new(0, nameW - 7, 0, 0)

  if total * ROW > viewH then
   pvbar.Visible = true
   local frac = math.clamp(fullRows / total, 0.05, 0.85)
   pvthumb.Size = UDim2.new(1, 0, frac, 0)
   local pos = maxScroll > 0 and math.clamp((P.Scroll / maxScroll) * (1 - frac), 0, 1 - frac) or 0
   pvthumb.Position = UDim2.new(0, 0, pos, 0)
  else
   pvbar.Visible = false
  end
 end

 local function UpdateHeader()
  local inst = P.Inst
  if not inst then
   ptitle.Text = "Properties"
   return
  end
  local extra = ""
  local n = 0
  for _ in pairs(Explorer.SelectedSet) do n += 1 end
  if n > 1 then extra = string.format(" (+%d)", n - 1) end
  ptitle.Text = 'Properties - ' .. inst.ClassName .. ' "' .. inst.Name .. '"' .. extra
 end

 function Explorer.RefreshProperties()
  Rebuild()
  UpdateHeader()
  RefreshList()
 end


 config.activeGuiOutline = nil
 config.activePartHighlight = nil

 -- separate ScreenGui drawn BELOW the explorer window so outlines/handles never cover it
 local function GetOutlineLayer()
  local layer = config.outlineLayer
  if layer and layer.Parent then return layer end
  layer = Instance.new("ScreenGui")
  layer.Name = RandomString()
  layer.ResetOnSpawn = false
  layer.IgnoreGuiInset = true
  layer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  layer.DisplayOrder = (config.window.DisplayOrder or 0) - 1
  layer.Archivable = false
  layer.ClipToDeviceSafeArea = config.window.ClipToDeviceSafeArea
  layer.Parent = config.folder
  config.outlineLayer = layer
  return layer
 end

 local function CreateGuiOutline(inst, onUpdate)
  local WHITE = Color3.fromRGB(255, 255, 255)
  local HANDLE_SIZE = 8
  local outline = Instance.new("Frame")
  outline.Name = RandomString()
  outline.BackgroundTransparency = 1
  outline.BorderSizePixel = 0
  outline.ZIndex = 1000
  outline.Archivable = false
  outline.Parent = GetOutlineLayer()

  local function makeLine(pos, size)
   local l = Instance.new("Frame")
   l.BackgroundColor3 = WHITE
   l.BorderSizePixel = 0
   l.Position = pos
   l.Size = size
   l.ZIndex = 1001
   l.Archivable = false
   l.Parent = outline
   return l
  end

  makeLine(UDim2.new(0, -1, 0, -1), UDim2.new(1, 2, 0, 2))
  makeLine(UDim2.new(0, -1, 1, -1), UDim2.new(1, 2, 0, 2))
  makeLine(UDim2.new(0, -1, 0, -1), UDim2.new(0, 2, 1, 2))
  makeLine(UDim2.new(1, -1, 0, -1), UDim2.new(0, 2, 1, 2))

  local liveConnections = {}

  local function clearLive()
   for _, c in ipairs(liveConnections) do c:Disconnect() end
   table.clear(liveConnections)
  end

  local okSize, absSz = pcall(function() return inst.AbsoluteSize end)
  local objW, objH = (okSize and absSz.X) or 100, (okSize and absSz.Y) or 100
  local THICK = math.max(4, math.min(14, math.floor(math.min(objW, objH) / 3)))

  local dragCatcher = Instance.new("Frame")
  dragCatcher.Name = RandomString()
  dragCatcher.Position = UDim2.new(0, THICK, 0, THICK)
  dragCatcher.Size = UDim2.new(1, -THICK * 2, 1, -THICK * 2)
  dragCatcher.BackgroundTransparency = 1
  dragCatcher.ZIndex = 999
  dragCatcher.Active = true
  dragCatcher.Archivable = false
  dragCatcher.Parent = outline

  dragCatcher.InputBegan:Connect(function(io)
   if #liveConnections > 0 then return end
   if io.UserInputType ~= Enum.UserInputType.MouseButton1 and io.UserInputType ~= Enum.UserInputType.Touch then return end
   local ok, startPos = pcall(function() return inst.Position end)
   if not ok then return end
   local startMouse = Vector2.new(io.Position.X, io.Position.Y)

   table.insert(liveConnections, config.SV.UserInput.InputChanged:Connect(function(io2)
    if io2.UserInputType ~= Enum.UserInputType.MouseMovement and io2.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = Vector2.new(io2.Position.X, io2.Position.Y) - startMouse
    pcall(function()
     inst.Position = UDim2.new(
      startPos.X.Scale, RoundPx(startPos.X.Offset + delta.X),
      startPos.Y.Scale, RoundPx(startPos.Y.Offset + delta.Y)
     )
    end)
    if onUpdate then onUpdate() end
   end))

   table.insert(liveConnections, config.SV.UserInput.InputEnded:Connect(function(io2)
    if io2.UserInputType == Enum.UserInputType.MouseButton1 or io2.UserInputType == Enum.UserInputType.Touch then
     clearLive()
    end
   end))
  end)

  config.SV.UserInput.WindowFocusReleased:Connect(clearLive)

  local function makeHandle(edgeX, edgeY, pos, zIndexBase)
   local isEdgeOnly = (edgeX == 0 or edgeY == 0)

   local hitZone = Instance.new("Frame")
   hitZone.Name = RandomString()
   hitZone.AnchorPoint = Vector2.new(0.5, 0.5)
   hitZone.Position = pos
   if edgeX == 0 then
    hitZone.Size = UDim2.new(1, -THICK * 2, 0, THICK)
   elseif edgeY == 0 then
    hitZone.Size = UDim2.new(0, THICK, 1, -THICK * 2)
   else
    hitZone.Size = UDim2.new(0, THICK, 0, THICK)
   end
   hitZone.BackgroundTransparency = 1
   hitZone.ZIndex = zIndexBase
   hitZone.Active = true
   hitZone.Archivable = false
   hitZone.Parent = outline

   local h = Instance.new("Frame")
   h.Name = RandomString()
   h.AnchorPoint = Vector2.new(0.5, 0.5)
   h.Position = pos
   h.Size = UDim2.new(0, HANDLE_SIZE, 0, HANDLE_SIZE)
   h.BackgroundColor3 = WHITE
   h.BorderSizePixel = 0
   h.ZIndex = 1004
   h.Active = false
   h.Archivable = false
   h.Parent = outline

   local hStroke = Instance.new("UIStroke")
   hStroke.Color = Color3.fromRGB(0, 0, 0)
   hStroke.Thickness = 1
   hStroke.Archivable = false
   hStroke.Parent = h


   hitZone.InputBegan:Connect(function(io)
    if #liveConnections > 0 then return end
    if io.UserInputType ~= Enum.UserInputType.MouseButton1 and io.UserInputType ~= Enum.UserInputType.Touch then return end

    local ok1, startSize = pcall(function() return inst.Size end)
    local ok2, startPos = pcall(function() return inst.Position end)
    local ok3, anchor = pcall(function() return inst.AnchorPoint end)
    local ok4, startAbsSize = pcall(function() return inst.AbsoluteSize end)
    local ok5, startAbsPos = pcall(function() return inst.AbsolutePosition end)
    local ok6, parentAbsSize = pcall(function() return inst.Parent.AbsoluteSize end)
    local ok7, parentAbsPos = pcall(function() return inst.Parent.AbsolutePosition end)
    if not (ok1 and ok2 and ok3 and ok4 and ok5 and ok6 and ok7) then return end

    local startMouse = Vector2.new(io.Position.X, io.Position.Y)
    local startAbsRight = startAbsPos.X + startAbsSize.X
    local startAbsBottom = startAbsPos.Y + startAbsSize.Y

    table.insert(liveConnections, config.SV.UserInput.InputChanged:Connect(function(io2)
     if io2.UserInputType ~= Enum.UserInputType.MouseMovement and io2.UserInputType ~= Enum.UserInputType.Touch then return end
     local delta = Vector2.new(io2.Position.X, io2.Position.Y) - startMouse

     local newSizeXOffset, newPosXOffset
     local newSizeYOffset, newPosYOffset

     if edgeX ~= 0 then
      local rawX = startAbsSize.X + delta.X * edgeX
      local clampedX = math.max(4, rawX)
      local dsx = clampedX - startAbsSize.X
      local originShiftX = (edgeX == -1) and -dsx or 0
      newSizeXOffset = RoundPx(startSize.X.Offset + dsx)
      newPosXOffset = RoundPx(startPos.X.Offset + originShiftX + anchor.X * dsx)
     end

     if edgeY ~= 0 then
      local rawY = startAbsSize.Y + delta.Y * edgeY
      local clampedY = math.max(4, rawY)
      local dsy = clampedY - startAbsSize.Y
      local originShiftY = (edgeY == -1) and -dsy or 0
      newSizeYOffset = RoundPx(startSize.Y.Offset + dsy)
      newPosYOffset = RoundPx(startPos.Y.Offset + originShiftY + anchor.Y * dsy)
     end

     pcall(function()
      if newSizeXOffset then
       inst.Size = UDim2.new(startSize.X.Scale, newSizeXOffset, inst.Size.Y.Scale, inst.Size.Y.Offset)
       inst.Position = UDim2.new(startPos.X.Scale, newPosXOffset, inst.Position.Y.Scale, inst.Position.Y.Offset)
      end
      if newSizeYOffset then
       inst.Size = UDim2.new(inst.Size.X.Scale, inst.Size.X.Offset, startSize.Y.Scale, newSizeYOffset)
       inst.Position = UDim2.new(inst.Position.X.Scale, inst.Position.X.Offset, startPos.Y.Scale, newPosYOffset)
      end
     end)
     if onUpdate then onUpdate() end
    end))

    table.insert(liveConnections, config.SV.UserInput.InputEnded:Connect(function(io2)
     if io2.UserInputType == Enum.UserInputType.MouseButton1 or io2.UserInputType == Enum.UserInputType.Touch then
      clearLive()
     end
    end))
   end)

   hitZone.MouseEnter:Connect(function() h.Size = UDim2.new(0, HANDLE_SIZE + 2, 0, HANDLE_SIZE + 2) end)
   hitZone.MouseLeave:Connect(function() h.Size = UDim2.new(0, HANDLE_SIZE, 0, HANDLE_SIZE) end)
  end

  makeHandle(0, -1, UDim2.new(0.5, 0, 0, 0), 1002)
  makeHandle(0, 1, UDim2.new(0.5, 0, 1, 0), 1002)
  makeHandle(-1, 0, UDim2.new(0, 0, 0.5, 0), 1002)
  makeHandle(1, 0, UDim2.new(1, 0, 0.5, 0), 1002)

  makeHandle(-1, -1, UDim2.new(0, 0, 0, 0), 1003)
  makeHandle(1, -1, UDim2.new(1, 0, 0, 0), 1003)
  makeHandle(-1, 1, UDim2.new(0, 0, 1, 0), 1003)
  makeHandle(1, 1, UDim2.new(1, 0, 1, 0), 1003)

  return outline, liveConnections
 end

 local function ClearSelectionVisuals()
  if config.activeGuiOutline then
   if config.activeGuiOutline.posCon then config.activeGuiOutline.posCon:Disconnect() end
   if config.activeGuiOutline.sizeCon then config.activeGuiOutline.sizeCon:Disconnect() end
   if config.activeGuiOutline.handleConnections then
    for _, c in ipairs(config.activeGuiOutline.handleConnections) do c:Disconnect() end
   end
   pcall(function() config.activeGuiOutline.frame:Destroy() end)
   config.activeGuiOutline = nil
  end
  if config.activePartHighlight then
   pcall(function() config.activePartHighlight:Destroy() end)
   config.activePartHighlight = nil
  end
 end

 local function ShowSelectionVisual(inst)
  ClearSelectionVisuals()
  if not inst then return end
  local okR, real = pcall(function() return inst.Real end)
  if okR and real then inst = real end
  if typeof(inst) ~= "Instance" then return end

  local isGui = false
  pcall(function() isGui = inst:IsA("GuiObject") end)
  local isPV = false
  pcall(function() isPV = inst:IsA("PVInstance") end)

  if isGui then
   local outlineFrame, handleConnections
   local function updatePos()
    local fn, absPos = pcall(function() return inst.AbsolutePosition end)
    local ok, absSize = pcall(function() return inst.AbsoluteSize end)
    if not (fn and ok) then return end
    local parentAbs = Vector2.new(0, 0)
    pcall(function() parentAbs = outlineFrame.Parent.AbsolutePosition end)
    outlineFrame.Position = UDim2.new(0, absPos.X - parentAbs.X, 0, absPos.Y - parentAbs.Y)
    outlineFrame.Size = UDim2.new(0, absSize.X, 0, absSize.Y)
   end
   outlineFrame, handleConnections = CreateGuiOutline(inst, updatePos)
   updatePos()

   local posCon, sizeCon
   pcall(function() posCon = inst:GetPropertyChangedSignal("AbsolutePosition"):Connect(updatePos) end)
   pcall(function() sizeCon = inst:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePos) end)

   config.activeGuiOutline = { frame = outlineFrame, posCon = posCon, sizeCon = sizeCon, handleConnections = handleConnections }
  elseif isPV then
   local box = Instance.new("SelectionBox")
   box.LineThickness = 0.05
   box.Color3 = Color3.fromRGB(0, 170, 255)
   box.Archivable = false
   local adorn = pcall(function() box.Adornee = inst end)
   if adorn then
    box.Parent = config.folder
    config.activePartHighlight = box
   else
    pcall(function() box:Destroy() end)
   end
  end
 end

 function Explorer.UpdateSelectionVisual()
  ShowSelectionVisual(Explorer.Selected)
 end


 Explorer.PropsOnSelect = function()
  if P.Inst ~= Explorer.Selected then P.Scroll = 0 end
  Explorer.UpdateSelectionVisual()
  Explorer.RefreshProperties()
 end

 list:GetPropertyChangedSignal("AbsoluteSize"):Connect(RefreshList)

 filterBox:GetPropertyChangedSignal("Text"):Connect(function()
  P.Filter = filterBox.Text:match("^%s*(.-)%s*$"):lower()
  P.Scroll = 0
  Explorer.RefreshProperties()
 end)

 do
  local function MaxScroll()
   return math.max(0, #P.Rows - math.floor(list.AbsoluteSize.Y / ROW))
  end
  local dragging, startPos, startScroll
  local function TopHit(target, extraLeft)
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
    hit.Position = UDim2.fromOffset(math.floor(ap.X - extraLeft), math.floor(ap.Y))
    hit.Size = UDim2.fromOffset(math.ceil(as.X + extraLeft), math.ceil(as.Y))
    hit.ZIndex = top:IsA("GuiObject") and top.ZIndex + 1 or 2
    hit.Visible = true
   end)
   return hit
  end
  local pvhit = TopHit(pvthumb, 14)
  local function BeginDrag(inp)
   if not IsPress(inp) then return end
   if MaxScroll() <= 0 then return end
   dragging = true
   startPos = inp.Position
   startScroll = P.Scroll
   pvvis.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
  end
  pvhit.InputBegan:Connect(BeginDrag)
  pvhit.MouseEnter:Connect(function() if not dragging then pvvis.BackgroundColor3 = Color3.fromRGB(120, 120, 120) end end)
  pvhit.MouseLeave:Connect(function() if not dragging then pvvis.BackgroundColor3 = Color3.fromRGB(90, 90, 90) end end)
  config.SV.UserInput.InputChanged:Connect(function(inp)
   if not dragging then return end
   if not config.Held(inp) then dragging = false pvvis.BackgroundColor3 = Color3.fromRGB(90, 90, 90) return end
   if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
   local m = MaxScroll()
   local trackH = pvtrack.AbsoluteSize.Y
   local usable = trackH * (1 - pvthumb.Size.Y.Scale)
   if usable > 0 and m > 0 then
    P.Scroll = math.floor(startScroll + (inp.Position.Y - startPos.Y) / usable * m + 0.5)
    RefreshList()
   end
  end)
  config.SV.UserInput.InputEnded:Connect(function(inp)
   if IsPress(inp) and dragging then
    dragging = false
    pvvis.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
   end
  end)

  local holdToken = 0
  local function Nudge(dir)
   P.Scroll = math.clamp(P.Scroll + dir, 0, MaxScroll())
   RefreshList()
  end
  local function HookArrow(btn, dir)
   local hit = TopHit(btn, 0)
   hit.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(70, 70, 76) end)
   hit.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(52, 52, 57) end)
   hit.InputBegan:Connect(function(inp)
    if not IsPress(inp) then return end
    if not config.Fresh(inp) then return end
    holdToken += 1
    local my = holdToken
    Nudge(dir)
    task.spawn(function()
     task.wait(0.4)
     while holdToken == my do
      Nudge(dir)
      task.wait(0.05)
     end
    end)
   end)
  end
  HookArrow(pvup, -1)
  HookArrow(pvdown, 1)
  config.SV.UserInput.InputEnded:Connect(function(inp)
   if IsPress(inp) then holdToken += 1 end
  end)
 end

 do
  local dragging, startX, startDiv
  divHit.InputBegan:Connect(function(inp)
   if not config.Fresh(inp) then return end
   if not IsPress(inp) then return end
   dragging = true
   startX = inp.Position.X
   startDiv = P.Divider
  end)
  config.SV.UserInput.InputChanged:Connect(function(inp)
   if not dragging then return end
   if not config.Held(inp) then dragging = false return end
   if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
   local w = math.max(1, list.AbsoluteSize.X)
   P.Divider = math.clamp(startDiv + (inp.Position.X - startX) / w, 0.2, 0.75)
   RefreshList()
  end)
  config.SV.UserInput.InputEnded:Connect(function(inp)
   if IsPress(inp) then dragging = false end
  end)
 end

 config.SV.UserInput.InputChanged:Connect(function(input)
  if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
  if not config.pmain.Visible then return end
  local delta = input.Position.Z
  if delta == 0 then return end
  local mp = config.SV.UserInput:GetMouseLocation()
  local ap, as = config.pmain.AbsolutePosition, config.pmain.AbsoluteSize
  if mp.X < ap.X or mp.X > ap.X + as.X or mp.Y < ap.Y or mp.Y > ap.Y + as.Y then return end
  P.Scroll = P.Scroll - delta * 3
  RefreshList()
 end)

 local function DockProps(side, order)
  config.PDock.Side = side
  if order then config.PDock.Order = order end
  config.LayoutDocks()
 end

 local function UndockProps()
  if not config.PDock.Side then return end
  local px, py = config.pmain.Position.X.Offset, config.pmain.Position.Y.Offset
  local w = config.pmain.Size.X.Offset
  config.PDock.Side = nil
  config.pmain.AnchorPoint = Vector2.new(0, 0)
  config.pmain.Position = UDim2.new(0, px, 0, py)
  config.pmain.Size = UDim2.new(0, w, 0, P.FloatH)
  config.pdocksplitter.Visible = false
  config.LayoutDocks()
 end

 function Explorer.DockProperties(side, order)
  if side == nil then UndockProps() else DockProps(side, order) end
 end

 ppin.Activated:Connect(function()
  if config.PDock.Side then UndockProps() else DockProps(NearestSide(config.pmain)) end
 end)

 MakeDraggable(config.pmain, hdr, {
  BlockCheck = function() return Explorer.PanelResizing[config.pmain] end,
  threshold = 4,
  OnBegin = function() if config.PDock.Side then UndockProps() end end,
  OnDrag = function(cursor)
   local side, zone = ResolveDrop(config.pmain, config.main, config.DockSide, config.main.Visible, cursor)
   ShowHint(config.pmain, config.main, side, zone)
  end,
  OnEnd = function(didDrag, cursor)
   config.dockHint.Visible = false
   if not didDrag then return end
   local side, zone = ResolveDrop(config.pmain, config.main, config.DockSide, config.main.Visible, cursor)
   if not side then return end
   local order
   if zone then order = (zone == "top") and "above" or "below" end
   DockProps(side, order)
  end,
 })

 local function OnPropsResize(newSize)
  if config.PDock.Side then
   if IsStacked() then
    config.main.Size = UDim2.new(0, newSize.X.Offset, 0, config.main.Size.Y.Offset)
    config.NormalSize = UDim2.new(0, newSize.X.Offset, 0, config.NormalSize.Y.Offset)
   end
   config.LayoutDocks()
  else
   P.FloatH = newSize.Y.Offset
  end
 end

 local EDGE = config.EDGE
 local function NotRight() return config.PDock.Side == "right" end
 local function NotLeft() return config.PDock.Side == "left" end
 local function WhenDocked() return config.PDock.Side ~= nil end
 MakeResizeHandler(220, 160, "right", 1, 0, 3-EDGE*2, EDGE, 0, 1, EDGE * 2, -EDGE * 2, 8, config.pmain, NotRight, OnPropsResize)
 MakeResizeHandler(220, 160, "left", 0, 0, -3, EDGE, 0, 1, EDGE * 2, -EDGE * 2, 8, config.pmain, NotLeft, OnPropsResize)
 MakeResizeHandler(220, 160, "bottom", 0, 1, EDGE, 0, 1, 0, -EDGE * 2, EDGE * 2, 8, config.pmain, WhenDocked, OnPropsResize)
 MakeResizeHandler(220, 160, "top", 0, 0, EDGE, -EDGE * 2, 1, 0, -EDGE * 2, EDGE * 2, 8, config.pmain, WhenDocked, OnPropsResize)
 MakeResizeHandler(220, 160, "top_left", 0, 0, -3, -EDGE * 2, 0, 0, EDGE * 2, EDGE * 2, 9, config.pmain, WhenDocked, OnPropsResize)
 MakeResizeHandler(220, 160, "top_right", 1, 0, 3-EDGE*2, -EDGE * 2, 0, 0, EDGE * 2, EDGE * 2, 9, config.pmain, WhenDocked, OnPropsResize)
 MakeResizeHandler(220, 160, "bottom_left", 0, 1, -3, 0, 0, 0, EDGE * 2, EDGE * 2, 9, config.pmain, WhenDocked, OnPropsResize)
 MakeResizeHandler(220, 160, "bottom_right", 1, 1, 3-EDGE*2, 0, 0, 0, EDGE * 2, EDGE * 2, 9, config.pmain, WhenDocked, OnPropsResize)

 function Explorer.OpenProperties()
  if config.pmain.Visible then return end
  config.pmain.Visible = true
  config.LayoutDocks()
  Explorer.RefreshProperties()
 end
 function Explorer.CloseProperties()
  if not config.pmain.Visible then return end
  CloseMenu()
  config.pmain.Visible = false
  config.LayoutDocks()
 end
 function Explorer.ToggleProperties()
  if config.pmain.Visible then Explorer.CloseProperties() else Explorer.OpenProperties() end
 end
 function Explorer.IsPropertiesOpen() return config.pmain.Visible end
 if config.SetPropertiesActive then
  config.SetPropertiesActive(config.pmain.Visible)
  config.pmain:GetPropertyChangedSignal("Visible"):Connect(function() config.SetPropertiesActive(config.pmain.Visible) end)
 end

 pclose.Activated:Connect(Explorer.CloseProperties)

 config.SV.UserInput.InputBegan:Connect(function(inp, gpe)
  if gpe then return end
  local alt = config.SV.UserInput:IsKeyDown(Enum.KeyCode.LeftAlt) or config.SV.UserInput:IsKeyDown(Enum.KeyCode.RightAlt)
  local ctrl = config.SV.UserInput:IsKeyDown(Enum.KeyCode.LeftControl) or config.SV.UserInput:IsKeyDown(Enum.KeyCode.RightControl)
  local shift = config.SV.UserInput:IsKeyDown(Enum.KeyCode.LeftShift) or config.SV.UserInput:IsKeyDown(Enum.KeyCode.RightShift)
  if inp.KeyCode == Enum.KeyCode.P then
   if alt then
    Explorer.ToggleProperties()
   elseif ctrl and shift and config.pmain.Visible then
    filterBox:CaptureFocus()
   end
  end
 end)
end

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
 MakeCloseIcon(vclose, 8, 4, Color3.fromRGB(210, 210, 210))

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
  if VState.conn then VState.conn:Disconnect() VState.conn = nil end
  if VState.Model then VState.Model:Destroy() VState.Model = nil end
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
  Claim(config.main, config.DockSide)
  Claim(config.pmain, config.PDock.Side)
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
  if not config.Held(inp) then VState.Dragging = false VState.ActiveInput = nil return end
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

function Explorer.DumpFunctions(scr)
	if scr ~= nil and typeof(scr) ~= "Instance" and type(scr) == "table" then
		scr = scr.Real
			or (scr.Metadata and scr.Metadata.Real)
			or scr
	end

	local MAX_DEPTH = 100

	local function GetSource(f)
		local ok, src = pcall(debug.info, f, "s")
		return ok and src or nil
	end

	local hasNativeIsClosure = iscclosure ~= nil
	local function IsLClosure(f, cachedSrc)
		if hasNativeIsClosure then return not iscclosure(f) end
		local src = cachedSrc or GetSource(f)
		return src ~= nil and src ~= "[C]"
	end

	local getupvals = debug.getupvalues or getupvalues or (debug.getupvalue and function(func)
		local out = {}
		local i = 1
		while true do
			local ok, name, val = pcall(debug.getupvalue, func, i)
			if not ok or name == nil then break end
			out[name ~= "" and name or i] = val
			i = i + 1
		end
		return out
	end)

	local getconsts = debug.getconstants or getconstants
	local getprotos = debug.getprotos or getprotos

	local function SafeStr(s)
		if type(s) ~= "string" then return tostring(s) end
		local clean = {}
		for i = 1, #s do
			local b = s:byte(i)
			if (b >= 32 and b <= 126) or b == 10 or b == 9 then
				clean[#clean + 1] = s:sub(i, i)
			end
		end
		return table.concat(clean)
	end

	local lines = {}
	local function AddLine(str, indent)
		table.insert(lines, string.rep("  ", indent or 0) .. str)
	end

	local function GetFunctionDetails(func)
		local ok, name, source, numParams, isVarArg, line = pcall(debug.info, func, "nsal")
		if not ok then return "Unknown", "Unknown", 0, false, -1 end
		return (name and name ~= "" and name or "Anonymous"), source or "Unknown", numParams or 0, isVarArg or false, line or -1
	end

	local function DumpValue(val, indent, index, visited, depth)
		visited = visited or {}
		depth = depth or 0
		if depth > MAX_DEPTH then
			AddLine(tostring(index) .. " = ... (depth " .. MAX_DEPTH .. " exceeded)", indent)
			return
		end
		local t = typeof(val)
		if t == "function" then
			local name = IsLClosure(val) and GetFunctionDetails(val) or "[C Function]"
			AddLine(tostring(index) .. " [function] = " .. tostring(name), indent)
		elseif t == "table" then
			if visited[val] then
				AddLine(tostring(index) .. " [table] (circular reference)", indent)
			else
				visited[val] = true
				AddLine(tostring(index) .. " [table]:", indent)
				local ok = pcall(function()
					for k, v in next, val do
						DumpValue(v, indent + 1, k, visited, depth + 1)
					end
				end)
				if not ok then
					AddLine("... (protected table)", indent + 1)
				end
			end
		else
			local s = ""
			local ok = pcall(function() s = tostring(val) end)
			if not ok then s = "<error tostring>" end
			pcall(function() s = SafeStr(s) end)
			AddLine(tostring(index) .. " [" .. t .. "] = " .. s, indent)
		end
	end

	local function DumpFunction(func, indent, visitedFuncs)
		visitedFuncs = visitedFuncs or {}
		if visitedFuncs[func] or not IsLClosure(func) then return end
		visitedFuncs[func] = true
		local name, source, params, vararg, line = GetFunctionDetails(func)
		AddLine("", 0)
		AddLine(string.format("Function: %s | Source: %s | Line: %d | Params: %d%s", name, source, line, params, vararg and "+" or ""), indent)

		if getupvals then
			local ok, ups = pcall(getupvals, func)
			if ok and typeof(ups) == "table" and next(ups) ~= nil then
				AddLine("Upvalues:", indent)
				local visitedValues = {}
				for k, v in ups do DumpValue(v, indent + 1, k, visitedValues, 0) end
			end
		end
		if getconsts then
			local ok, consts = pcall(getconsts, func)
			if ok and typeof(consts) == "table" and next(consts) ~= nil then
				AddLine("Constants:", indent)
				local visitedValues = {}
				for i, c in consts do DumpValue(c, indent + 1, i, visitedValues, 0) end
			end
		end
		if getprotos then
			local ok, protos = pcall(getprotos, func)
			if ok and typeof(protos) == "table" and next(protos) ~= nil then
				AddLine("Prototypes:", indent)
				for _, proto in protos do
					if typeof(proto) == "function" and IsLClosure(proto) then
						DumpFunction(proto, indent + 1, visitedFuncs)
					end
				end
			end
		end
	end

	local function IsScriptMatch(func, cachedSrc)
		if not scr then return true end
		local src = cachedSrc or GetSource(func)
		if src and src ~= "[C]" then
			if typeof(scr) == "Instance" then
				local sName = scr:GetFullName()
				if src == sName or src:find(scr.Name, 1, true) then return true end
			elseif typeof(scr) == "string" and src:find(scr, 1, true) then
				return true
			end
		end
		local okEnv, env = pcall(getfenv, func)
		if okEnv and typeof(env) == "table" and env.script == scr then return true end
		return false
	end

	local ok_run, err_run = pcall(function()
		local found = 0
		local lookin = (getgc and getgc(true)) or {}
		local processed = 0
		local BATCH = 1400

		for _, obj in ipairs(lookin) do
			if typeof(obj) == "function" then
				local src = hasNativeIsClosure and nil or GetSource(obj)
				if IsLClosure(obj, src) and IsScriptMatch(obj, src) then
					DumpFunction(obj, 1)
					found = found + 1
				end
			end
			processed = processed + 1
			if processed % BATCH == 0 then task.wait() end
		end

		if found == 0 then
			lines = nil
			return
		end
		table.insert(lines, 1, "")
		table.insert(lines, 1, string.format("-- Function Dump: %d top-level function(s) found", found))
		table.insert(lines, 1, "-- " .. string.rep("=", 40))
	end)

	if not ok_run then
		return "-- Dump failed: " .. tostring(err_run)
	end

	if not lines then return nil end
	return table.concat(lines, "\n")
end

Explorer.Sources = setmetatable({}, {__mode = "k"})
Explorer.SourceProvider = nil
Explorer.Highlighter = nil
Explorer.HighlighterUrl = "https://raw.githubusercontent.com/lqdxt/Scripts/refs/heads/main/Highlighter.lua"

config.SCRIPT_CLASSES = { Script = true, LocalScript = true, ModuleScript = true }
config.srcOpen = false
config.ReloadSource = nil

function Explorer.IsScript(inst)
 if inst == nil then return false end
 local ok, cn = pcall(function() return inst.ClassName end)
 return ok and config.SCRIPT_CLASSES[cn] == true
end

function Explorer.IsSourceOpen() return config.srcOpen end

local function GetRealRef(inst)
 if typeof(inst) == "Instance" then return inst end
 if type(inst) ~= "table" then return nil end
 local r = rawget(inst, "Real")
 if r == nil then
  local md = rawget(inst, "Metadata")
  if type(md) == "table" then r = md.Real end
 end
 return r
end

function Explorer.SetSource(target, source)
 if type(target) == "function" then
  Explorer.SourceProvider = target
 elseif target ~= nil then
  Explorer.Sources[target] = source
 end
 if config.ReloadSource then config.ReloadSource(target) end
end

function Explorer.GetSource(inst)
 local realRef = GetRealRef(inst)
 local s = Explorer.Sources[inst]
 if s == nil and realRef and realRef ~= inst then s = Explorer.Sources[realRef] end
 if type(s) == "function" then
  local ok, r = pcall(s, inst)
  s = ok and r or nil
 end
 if s == nil then
  local ok, r = pcall(function() return inst.Source end)
  if ok and type(r) == "string" then s = r end
 end
 if s == nil and realRef and realRef ~= inst then
  local ok, r = pcall(function() return realRef.Source end)
  if ok and type(r) == "string" and r ~= "" then s = r end
 end
 if s == nil and Explorer.SourceProvider then
  local ok, r = pcall(Explorer.SourceProvider, inst)
  if ok then s = r end
 end
 if s == nil and decompile then
  local target = realRef or (typeof(inst) == "Instance" and inst or nil)
  if target then
   local ok, r = pcall(decompile, target)
   if ok and type(r) == "string" then s = r end
  end
 end
 if s ~= nil and type(s) ~= "string" then s = tostring(s) end
 return s
end

do
 local LH, TS, CODE_FONT = 18, 14, Enum.Font.Code
 local CODE_FACE = nil
 local function ApplyCodeFont(obj)
  if CODE_FACE then
   obj.FontFace = CODE_FACE
  else
   obj.Font = CODE_FONT
  end
 end
 local function MeasureCharW()
  local w
  if CODE_FACE then
   local ok, res = pcall(function()
    local p = Instance.new("GetTextBoundsParams")
    p.Text = "WWWWWWWWWW"
    p.Font = CODE_FACE
    p.Size = TS
    p.Width = 10000
    return config.SV.TextSrv:GetTextBoundsAsync(p).X / 10
   end)
   if ok then w = res end
  end
  if not w then
   local ok, res = pcall(function()
    return config.SV.TextSrv:GetTextSize("WWWWWWWWWW", TS, CODE_FONT, Vector2.new(10000, 100)).X / 10
   end)
   if ok then w = res end
  end
  return w
 end
 local TEXT_PLAIN = Color3.fromRGB(255, 255, 255) -- KEEP IT, LOOKS BAD WHEN GRAY

 local function Esc(s)
  if not s:find("[&<>]") then return s end
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
 end
 local openTag = setmetatable({}, {__index = function(t, c)
  local v = '<font color="' .. c .. '">'
  t[c] = v
  return v
 end})

 local function BoldWrap(c, text)
  return "<b>" .. openTag[c] .. text .. "</font></b>"
 end

 local function Highlight(H, line, state)
  local cc = state ~= nil and state.kind == "comment"
  local cs = state ~= nil and state.kind == "string"
  local lvl = state and state.level or 0
  local tokens, ec, cml, es, sl = H.Tokenize(line, cc, lvl, cs, lvl)
  local colors = H.SyntaxColors or {}
  local out = {}
  for k, tok in ipairs(tokens) do
   local c = tok.type ~= "plain" and colors[tok.type] or nil
   if c then
    out[k] = (tok.type == "keyword") and BoldWrap(c, Esc(tok.value)) or (openTag[c] .. Esc(tok.value) .. "</font>")
   else
    out[k] = Esc(tok.value)
   end
  end
  local ns = nil
  if ec then ns = { kind = "comment", level = cml }
  elseif es then ns = { kind = "string", level = sl } end
  return table.concat(out), ns
 end

 local function HighlightLine(line, state)
  local H = Explorer.Highlighter
  if H then
   local ok, r, ns = pcall(Highlight, H, line, state)
   if ok then return r, ns end
  end
  return Esc(line), nil
 end

 local panel = Instance.new("Frame")
 panel.Name = RandomString()
 panel.BackgroundColor3 = config.COLORS.PRIMARY
 panel.BackgroundTransparency = config.NT
 panel.BorderSizePixel = 0
 panel.Active = true
 panel.ZIndex = 1
 panel.Visible = false
 panel.ClipsDescendants = true
 panel.Archivable = false
 panel.Parent = config.window

 local hdr = Instance.new("Frame")
 hdr.Name = RandomString()
 hdr.Size = UDim2.new(1, 0, 0, 28)
 hdr.BackgroundColor3 = config.COLORS.HEADER
 hdr.BorderSizePixel = 0
 hdr.ZIndex = 3
 hdr.Archivable = false
 hdr.Parent = panel

 local hicon = Instance.new("ImageLabel")
 hicon.Name = RandomString()
 hicon.Size = UDim2.new(0, 18, 0, 18)
 hicon.Position = UDim2.new(0, 8, 0.5, -9)
 hicon.BackgroundTransparency = 1
 hicon.ZIndex = 4
 hicon.Archivable = false
 hicon.Parent = hdr

 local htitle = Instance.new("TextLabel")
 htitle.Name = RandomString()
 htitle.Size = UDim2.new(1, -236, 1, 0)
 htitle.Position = UDim2.new(0, 32, 0, 0)
 htitle.BackgroundTransparency = 1
 htitle.RichText = true
 htitle.Text = ""
 htitle.TextColor3 = config.COLORS.TEXT_BRIGHT
 htitle.FontFace = config.FONT.GothamRegular
 htitle.TextSize = 12
 htitle.TextXAlignment = Enum.TextXAlignment.Left
 htitle.TextTruncate = Enum.TextTruncate.AtEnd
 htitle.ZIndex = 4
 htitle.Archivable = false
 htitle.Parent = hdr

 local hclose = Instance.new("TextButton")
 hclose.Name = RandomString()
 hclose.Size = UDim2.new(0, 28, 0, 28)
 hclose.Position = UDim2.new(1, -30, 0, 0)
 hclose.BackgroundTransparency = 1
 hclose.Text = ""
 hclose.AutoButtonColor = false
 hclose.BorderSizePixel = 0
 hclose.ZIndex = 4
 hclose.Archivable = false
 hclose.Parent = hdr
 MakeCloseIcon(hclose, 8, 5, Color3.fromRGB(210, 210, 210))

 local hcopy = Instance.new("TextButton")
 hcopy.Name = RandomString()
 hcopy.Size = UDim2.new(0, 52, 0, 20)
 hcopy.Position = UDim2.new(1, -88, 0.5, -10)
 hcopy.BackgroundColor3 = config.COLORS.SECONDARY
 hcopy.BackgroundTransparency = 0.5
 hcopy.AutoButtonColor = true
 hcopy.Text = "Copy"
 hcopy.TextColor3 = config.COLORS.TEXT_BRIGHT
 hcopy.FontFace = config.FONT.GothamMedium
 hcopy.TextSize = 11
 hcopy.BorderSizePixel = 0
 hcopy.ZIndex = 4
 hcopy.Archivable = false
 hcopy.Parent = hdr
 RoundCorner(hcopy, 0, 6)

local hdump = Instance.new("TextButton")
hdump.Name = RandomString()
hdump.Size = UDim2.new(0, 52, 0, 20)
hdump.Position = UDim2.new(1, -144, 0.5, -10)
hdump.BackgroundColor3 = config.COLORS.SECONDARY
hdump.BackgroundTransparency = 0.5
hdump.AutoButtonColor = true
hdump.Text = "Dump"
hdump.TextColor3 = config.COLORS.TEXT_BRIGHT
hdump.FontFace = config.FONT.GothamMedium
hdump.TextSize = 11
hdump.BorderSizePixel = 0
hdump.ZIndex = 4
hdump.Archivable = false
hdump.Parent = hdr
RoundCorner(hdump, 0, 6)

 local function MakeZoomBtn(xOff, imageName)
  local b = Instance.new("ImageButton")
  b.Name = RandomString()
  b.Size = UDim2.new(0, 22, 0, 20)
  b.Position = UDim2.new(1, xOff, 0.5, -10)
  b.BackgroundColor3 = config.COLORS.SECONDARY
  b.BackgroundTransparency = 0.5
  b.AutoButtonColor = true
  b.Image = ""
  b.ImageColor3 = config.COLORS.TEXT_BRIGHT
  b.ScaleType = Enum.ScaleType.Fit
  b.BorderSizePixel = 0
  b.ZIndex = 4
  b.Archivable = false
  b.Parent = hdr
  RoundCorner(b, 0, 6)
  local pad = Instance.new("UIPadding")
  pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 3), UDim.new(0, 3)
  pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 3), UDim.new(0, 3)
  pad.Parent = b
  Explorer.ApplyImage(b, imageName)
  return b
 end
 local hzoomin = MakeZoomBtn(-196, "ZoomIn")
 local hzoomout = MakeZoomBtn(-170, "ZoomOut")

 local sBody = Instance.new("Frame")
 sBody.Name = RandomString()
 sBody.Size = UDim2.new(1, 0, 1, -28)
 sBody.Position = UDim2.new(0, 0, 0, 28)
 sBody.BackgroundTransparency = 1
 sBody.ZIndex = 3
 sBody.Archivable = false
 sBody.Parent = panel

 local sScroll = Instance.new("Frame")
 sScroll.Name = RandomString()
 sScroll.Size = UDim2.new(1, -12, 1, -8)
 sScroll.Position = UDim2.new(0, 0, 0, 0)
 sScroll.BackgroundTransparency = 1
 sScroll.ClipsDescendants = true
 sScroll.ZIndex = 3
 sScroll.Archivable = false
 sScroll.Parent = sBody

 local sCode = Instance.new("Frame")
 sCode.Name = RandomString()
 sCode.BackgroundTransparency = 1
 sCode.ClipsDescendants = true
 sCode.Size = UDim2.new(1, -40, 1, 0)
 sCode.Position = UDim2.new(0, 40, 0, 0)
 sCode.ZIndex = 3
 sCode.Archivable = false
 sCode.Parent = sScroll

 local sGutter = Instance.new("Frame")
 sGutter.Name = RandomString()
 sGutter.BackgroundColor3 = config.COLORS.HEADER
 sGutter.BackgroundTransparency = 0.5
 sGutter.BorderSizePixel = 0
 sGutter.ClipsDescendants = true
 sGutter.Size = UDim2.new(0, 40, 1, 0)
 sGutter.ZIndex = 4
 sGutter.Archivable = false
 sGutter.Parent = sScroll

 local gInner = Instance.new("Frame")
 gInner.Name = RandomString()
 gInner.BackgroundTransparency = 1
 gInner.BorderSizePixel = 0
 gInner.Size = UDim2.new(1, 0, 1, 0)
 gInner.ZIndex = 4
 gInner.Active = false
 gInner.Archivable = false
 gInner.Parent = sGutter

 local cInner = Instance.new("Frame")
 cInner.Name = RandomString()
 cInner.BackgroundTransparency = 1
 cInner.BorderSizePixel = 0
 cInner.Size = UDim2.new(1, 0, 1, 0)
 cInner.ZIndex = 3
 cInner.Active = false
 cInner.Archivable = false
 cInner.Parent = sCode

 local sVbar = Instance.new("Frame")
 sVbar.Name = RandomString()
 sVbar.Size = UDim2.new(0, 10, 1, 0)
 sVbar.Position = UDim2.new(1, -10, 0, 0)
 sVbar.BackgroundTransparency = 1
 sVbar.BorderSizePixel = 0
 sVbar.Visible = false
 sVbar.ZIndex = 4
 sVbar.Archivable = false
 sVbar.Parent = sBody

 local sVthumb = Instance.new("Frame")
 sVthumb.Name = RandomString()
 sVthumb.Size = UDim2.new(1, 0, 0.2, 0)
 sVthumb.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
 sVthumb.BorderSizePixel = 0
 sVthumb.ZIndex = 5
 sVthumb.Archivable = false
 sVthumb.Parent = sVbar
 RoundCorner(sVthumb, 1, 0)

 local sHbar = Instance.new("Frame")
 sHbar.Name = RandomString()
 sHbar.Size = UDim2.new(1, -10, 0, 10)
 sHbar.Position = UDim2.new(0, 0, 1, -10)
 sHbar.BackgroundTransparency = 1
 sHbar.BorderSizePixel = 0
 sHbar.Visible = false
 sHbar.ZIndex = 4
 sHbar.Archivable = false
 sHbar.Parent = sBody

 local sHthumb = Instance.new("Frame")
 sHthumb.Name = RandomString()
 sHthumb.Size = UDim2.new(0.2, 0, 1, 0)
 sHthumb.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
 sHthumb.BorderSizePixel = 0
 sHthumb.ZIndex = 5
 sHthumb.Archivable = false
 sHthumb.Parent = sHbar
 RoundCorner(sHthumb, 1, 0)

 local charW = 8
 do
  local w = MeasureCharW()
  if w and w > 2 then charW = w end
 end

 local st = { inst = nil, raw = "", lines = {}, rich = {}, ind = {}, gen = 0, index = 0, hoff = 0, contentW = 0, gW = 40,
  base = 0, pool = 0, maxLen = 0, hlDone = 0, hlState = nil, hlBusy = false, loaded = false }
 local entries = {}

 local INDENT_SIZE = 4
 local MAX_GUIDES = 48
 local GUIDE_TRANSPARENCY = 0.88
 local BLANK_SCAN = 1000
 local HL_AHEAD = 1500
 local HL_BUDGET = 0.006
 local REBASE = 400

 local appliedRowW, appliedLH, appliedGW = -1, -1, -1
 local appliedCY, appliedHX = nil, nil
 local vVis, vF, vP, hVis, hF, hP, hGW = nil, nil, nil, nil, nil, nil, nil
 local pending = false
 local PumpHighlight

 local function IsBlank(l) return l:find("^%s*$") ~= nil end

 local function IndentOf(ln)
  local v = st.ind[ln]
  if v then return v end
  local lines = st.lines
  local line = lines[ln]
  if IsBlank(line) then
   local prevI, nextI = 0, 0
   for j = ln - 1, math.max(1, ln - BLANK_SCAN), -1 do
    local l = lines[j]
    if not IsBlank(l) then
     local _, e = l:find("^ *")
     prevI = math.floor(e / INDENT_SIZE)
     break
    end
   end
   for j = ln + 1, math.min(#lines, ln + BLANK_SCAN) do
    local l = lines[j]
    if not IsBlank(l) then
     local _, e = l:find("^ *")
     nextI = math.floor(e / INDENT_SIZE)
     break
    end
   end
   v = math.min(prevI, nextI)
  else
   local _, e = line:find("^ *")
   v = math.floor(e / INDENT_SIZE)
  end
  st.ind[ln] = v
  return v
 end

 local function GuideX(k)
  return math.floor(8 + (k - 1) * INDENT_SIZE * charW + 0.5)
 end

 local function CreateEntry()
  local num = Instance.new("TextLabel")
  num.Name = RandomString()
  num.BackgroundTransparency = 1
  ApplyCodeFont(num)
  num.TextSize = TS
  num.TextColor3 = config.COLORS.TEXT_DIM
  num.TextXAlignment = Enum.TextXAlignment.Right
  num.Size = UDim2.new(1, -8, 0, LH)
  num.ZIndex = 5
  num.Visible = false
  num.Archivable = false
  num.Parent = gInner

  local code = Instance.new("TextLabel")
  code.Name = RandomString()
  code.BackgroundTransparency = 1
  code.RichText = true
  ApplyCodeFont(code)
  code.TextSize = TS
  code.TextColor3 = TEXT_PLAIN
  code.TextXAlignment = Enum.TextXAlignment.Left
  code.TextWrapped = false
  code.Size = UDim2.new(0, math.max(appliedRowW, 0), 0, LH)
  code.ZIndex = 3
  code.Visible = false
  code.Archivable = false
  code.Parent = cInner

  local gf = Instance.new("Frame")
  gf.Name = RandomString()
  gf.BackgroundTransparency = 1
  gf.BorderSizePixel = 0
  gf.Size = UDim2.new(0, 0, 0, LH)
  gf.ZIndex = 2
  gf.Active = false
  gf.Archivable = false
  gf.Parent = cInner

  return { num = num, code = code, gf = gf, guides = {}, shown = 0, line = nil, vis = false, hl = false }
 end

 local function SetGuides(e, count)
  if count > MAX_GUIDES then count = MAX_GUIDES end
  local g = e.guides
  for k = #g + 1, count do
   local f = Instance.new("Frame")
   f.Name = RandomString()
   f.BorderSizePixel = 0
   f.BackgroundColor3 = config.COLORS.WHITE
   f.BackgroundTransparency = GUIDE_TRANSPARENCY
   f.Size = UDim2.new(0, 1, 0, LH)
   f.Position = UDim2.new(0, GuideX(k), 0, 0)
   f.ZIndex = 2
   f.Active = false
   f.Archivable = false
   f.Visible = false
   f.Parent = e.gf
   g[k] = f
  end
  local shown = e.shown
  if count == shown then return end
  if count > shown then
   for k = shown + 1, count do g[k].Visible = true end
  else
   for k = count + 1, shown do g[k].Visible = false end
  end
  e.shown = count
 end

 local function HideEntry(e)
  e.line = nil
  if e.vis then
   e.vis = false
   e.num.Visible = false
   e.code.Visible = false
  end
  if e.shown > 0 then SetGuides(e, 0) end
 end

 local function BindEntry(e, ln)
  e.line = ln
  local y = (ln - 1 - st.base) * LH
  local r = st.rich[ln]
  e.hl = r ~= nil
  e.num.Text = tostring(ln)
  e.num.Position = UDim2.new(0, 0, 0, y)
  e.code.Position = UDim2.new(0, 8, 0, y)
  e.code.Text = r or Esc(st.lines[ln])
  e.gf.Position = UDim2.new(0, 0, 0, y)
  SetGuides(e, IndentOf(ln))
  if not e.vis then
   e.vis = true
   e.num.Visible = true
   e.code.Visible = true
  end
 end

 local function EnsureEntryPoolSize(n)
  for i = #entries + 1, n do entries[i] = CreateEntry() end
 end

 local function InvalidateAll()
  for i = 1, #entries do entries[i].line = nil end
 end

 local function RefreshNow()
  if not panel.Visible then return end
  local total = #st.lines
  local viewH = sScroll.AbsoluteSize.Y
  local viewW = sScroll.AbsoluteSize.X
  local codeW = math.max(0, viewW - st.gW)

  local visibleCount = math.max(1, math.ceil(viewH / LH) + 1)
  local maxIndex = math.max(0, total - math.floor(viewH / LH))
  st.index = math.clamp(st.index, 0, maxIndex)
  local maxHOffset = math.max(0, st.contentW - codeW)
  st.hoff = math.clamp(st.hoff, 0, maxHOffset)
  local rowW = math.max(codeW, st.contentW)

  if st.gW ~= appliedGW then
   appliedGW = st.gW
   sGutter.Size = UDim2.new(0, st.gW, 1, 0)
   sCode.Position = UDim2.new(0, st.gW, 0, 0)
   sCode.Size = UDim2.new(1, -st.gW, 1, 0)
  end

  if visibleCount ~= st.pool then
   EnsureEntryPoolSize(visibleCount)
   st.pool = visibleCount
   for i = 1, #entries do
    entries[i].line = nil
    if i > visibleCount then HideEntry(entries[i]) end
   end
  end

  if rowW ~= appliedRowW or LH ~= appliedLH then
   appliedRowW, appliedLH = rowW, LH
   local sz = UDim2.new(0, rowW, 0, LH)
   for i = 1, #entries do entries[i].code.Size = sz end
  end

  if math.abs(st.index - st.base) > REBASE then
   st.base = st.index
   InvalidateAll()
  end

  local cy = -(st.index - st.base) * LH
  local hx = -st.hoff
  if cy ~= appliedCY then gInner.Position = UDim2.new(0, 0, 0, cy) end
  if cy ~= appliedCY or hx ~= appliedHX then cInner.Position = UDim2.new(0, hx, 0, cy) end
  appliedCY, appliedHX = cy, hx

  local first = st.index + 1
  local off = first - 1
  local pool = st.pool
  local rich = st.rich
  for s = 1, pool do
   local ln = first + (s - 1 - off) % pool
   local e = entries[s]
   if ln <= total then
    if e.line ~= ln then
     BindEntry(e, ln)
    elseif not e.hl then
     local r = rich[ln]
     if r ~= nil then
      e.hl = true
      e.code.Text = r
     end
    end
   elseif e.line ~= nil or e.vis then
    HideEntry(e)
   end
  end

  if total * LH > viewH then
   local thumbFrac = math.clamp(viewH / (total * LH), 0.05, 1)
   local posFrac = maxIndex > 0 and (st.index / maxIndex) * (1 - thumbFrac) or 0
   if vVis ~= true then vVis = true sVbar.Visible = true end
   if thumbFrac ~= vF then vF = thumbFrac sVthumb.Size = UDim2.new(1, 0, thumbFrac, 0) end
   if posFrac ~= vP then vP = posFrac sVthumb.Position = UDim2.new(0, 0, posFrac, 0) end
  elseif vVis ~= false then
   vVis = false
   sVbar.Visible = false
  end

  if st.contentW > codeW then
   local thumbFrac = math.clamp(codeW / st.contentW, 0.05, 1)
   local posFrac = maxHOffset > 0 and (st.hoff / maxHOffset) * (1 - thumbFrac) or 0
   if hVis ~= true then hVis = true sHbar.Visible = true end
   if hGW ~= st.gW then
    hGW = st.gW
    sHbar.Position = UDim2.new(0, st.gW, 1, -10)
    sHbar.Size = UDim2.new(1, -st.gW - 10, 0, 10)
   end
   if thumbFrac ~= hF then hF = thumbFrac sHthumb.Size = UDim2.new(thumbFrac, 0, 1, 0) end
   if posFrac ~= hP then hP = posFrac sHthumb.Position = UDim2.new(posFrac, 0, 0, 0) end
  elseif hVis ~= false then
   hVis = false
   sHbar.Visible = false
  end

  if st.hlDone < total and not st.hlBusy then PumpHighlight() end
 end

 local function Refresh()
  if pending then return end
  pending = true
  config.SV.RunSrv.RenderStepped:Once(function()
   pending = false
   RefreshNow()
  end)
 end

 local function PointIn(gui, mp)
  local ap, as = gui.AbsolutePosition, gui.AbsoluteSize
  return mp.X >= ap.X and mp.X <= ap.X + as.X and mp.Y >= ap.Y and mp.Y <= ap.Y + as.Y
 end

 config.SV.UserInput.InputChanged:Connect(function(input)
  if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
  if not panel.Visible then return end
  local delta = input.Position.Z
  if delta == 0 then return end
  local mp = Vector2.new(input.Position.X, input.Position.Y)
  if not PointIn(panel, mp) then return end
  if config.main.Visible and PointIn(config.main, mp) then return end
  local viewH = sScroll.AbsoluteSize.Y
  local maxIdx = math.max(0, #st.lines - math.floor(viewH / LH))
  st.index = math.clamp(st.index - delta * 3, 0, maxIdx)
  Refresh()
 end)

 local function DraggableThumb(thumb, track, isHorizontal)
  local dragging, startPos, startScroll
  config.WidenHit(thumb, isHorizontal).InputBegan:Connect(function(inp)
   if not config.Fresh(inp) then return end
   if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
   dragging = true
   startPos = inp.Position
   startScroll = isHorizontal and st.hoff or st.index
  end)
  config.SV.UserInput.InputChanged:Connect(function(inp)
   if not dragging then return end
   if not config.Held(inp) then dragging = false return end
   if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
   if isHorizontal then
    local trackW = track.AbsoluteSize.X
    local delta = inp.Position.X - startPos.X
    local maxOff = math.max(0, st.contentW - math.max(0, sScroll.AbsoluteSize.X - st.gW))
    local usable = trackW * (1 - thumb.Size.X.Scale)
    if usable > 0 and maxOff > 0 then
     st.hoff = math.clamp(startScroll + delta / usable * maxOff, 0, maxOff)
    end
   else
    local trackH = track.AbsoluteSize.Y
    local delta = inp.Position.Y - startPos.Y
    local maxIdx = math.max(0, #st.lines - math.floor(sScroll.AbsoluteSize.Y / LH))
    local usable = trackH * (1 - thumb.Size.Y.Scale)
    if usable > 0 and maxIdx > 0 then
     st.index = math.clamp(math.floor(startScroll + delta / usable * maxIdx + 0.5), 0, maxIdx)
    end
   end
   Refresh()
  end)
  config.SV.UserInput.InputEnded:Connect(function(inp)
   if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
    dragging = false
   end
  end)
 end
 DraggableThumb(sVthumb, sVbar, false)
 DraggableThumb(sHthumb, sHbar, true)

 sScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(Refresh)

 local function SetHeader(inst)
  ApplyIcon(hicon, inst.ClassName)
  htitle.Text = Escape(inst.Name)
 end

 PumpHighlight = function()
  if st.hlBusy then return end
  local lines = st.lines
  if st.hlDone >= #lines then return end
  st.hlBusy = true
  local gen = st.gen
  task.spawn(function()
   local rich = st.rich
   local i, state = st.hlDone, st.hlState
   while st.gen == gen and panel.Visible do
    local total = #lines
    local viewRows = math.ceil(sScroll.AbsoluteSize.Y / LH) + 1
    local target = math.min(total, st.index + viewRows + HL_AHEAD)
    if i >= target then break end
    local t0 = os.clock()
    while i < target and os.clock() - t0 < HL_BUDGET do
     i += 1
     local ok, r, ns = pcall(HighlightLine, lines[i], state)
     if ok then rich[i] = r state = ns else state = nil end
    end
    if st.gen ~= gen then return end
    st.hlDone, st.hlState = i, state
    Refresh()
    if i < target then task.wait() end
   end
   if st.gen == gen then
    st.hlDone, st.hlState = i, state
    st.hlBusy = false
   end
  end)
 end

 local function Load(inst, keepScroll, force)
  local src = Explorer.GetSource(inst)
  if src == nil then
   src = ""
  end
  if not force and st.loaded and st.inst == inst and st.raw == src then
   SetHeader(inst)
   Refresh()
   return
  end
  st.inst, st.raw = inst, src
  st.gen += 1
  st.loaded = true

  local s = src:gsub("\r\n", "\n")
  s = s:gsub("\r", "\n")
  s = s:gsub("\t", "    ")
  local lines, maxLen = {}, 0
  for line in (s .. "\n"):gmatch("(.-)\n") do
   lines[#lines + 1] = line
   if #line > maxLen then maxLen = #line end
  end
  st.lines, st.rich, st.ind = lines, {}, {}
  st.maxLen = maxLen
  st.hlDone, st.hlState, st.hlBusy = 0, nil, false

  st.gW = #tostring(#lines) * charW + 20
  st.contentW = maxLen * charW + 40
  if not keepScroll then st.index, st.hoff = 0, 0 end
  st.base = st.index
  InvalidateAll()
  SetHeader(inst)
  Refresh()
 end

 local function Layout()
  local scr = config.window.AbsoluteSize
  local x0, x1 = 0, scr.X
  local pad = 3
  local function Claim(gui, side)
   if not gui or not gui.Visible then return end
   if side == "left" then
    x0 = math.max(x0, gui.AbsolutePosition.X + gui.AbsoluteSize.X + pad)
   elseif side == "right" then
    x1 = math.min(x1, gui.AbsolutePosition.X - pad)
   end
  end
  Claim(config.main, config.DockSide)
  Claim(config.pmain, config.PDock.Side)
  local w = x1 - x0
  local inset = TopInset()
  panel.Position = UDim2.new(0, x0, 0, inset)
  panel.Size = UDim2.new(0, math.max(0, w), 1, -inset)
  panel.Visible = config.srcOpen and w > 0
  Refresh()
 end
 config.LayoutSource = Layout
 config.main:GetPropertyChangedSignal("Visible"):Connect(Layout)

 function Explorer.OpenSource(inst)
  if not inst then return end
  config.srcOpen = true
  Layout()
  Load(inst, st.inst == inst)
 end

 function Explorer.CloseSource()
  config.srcOpen = false
  Layout()
 end

 function Explorer.SetHighlighter(mod)
  if mod ~= nil and (type(mod) ~= "table" or type(mod.Tokenize) ~= "function") then return false end
  Explorer.Highlighter = mod
  if config.srcOpen and st.inst then Load(st.inst, true, true) end
  return true
 end

 config.ReloadSource = function(target)
  if not config.srcOpen or not st.inst then return end
  if type(target) == "function" or target == st.inst or target == GetRealRef(st.inst) then
   Load(st.inst, true)
  end
 end

 local MIN_TS, MAX_TS = 8, 28
 local function SetFontSize(n, force)
  n = math.clamp(n, MIN_TS, MAX_TS)
  if n == TS and not force then return end
  TS = n
  LH = n + 4
  do
   local w = MeasureCharW()
   if w and w > 2 then charW = w end
  end
  for _, e in ipairs(entries) do
   ApplyCodeFont(e.num)
   ApplyCodeFont(e.code)
   e.num.TextSize = TS
   e.code.TextSize = TS
   e.num.Size = UDim2.new(1, -8, 0, LH)
   e.gf.Size = UDim2.new(0, 0, 0, LH)
   for k, g in ipairs(e.guides) do
    g.Size = UDim2.new(0, 1, 0, LH)
    g.Position = UDim2.new(0, GuideX(k), 0, 0)
   end
   e.line = nil
  end
  st.gW = #tostring(#st.lines) * charW + 20
  st.contentW = st.maxLen * charW + 40
  Refresh()
 end

 task.spawn(function()
  if not (isfile and writefile and readfile and getcustomasset and makefolder) then return end
  local ok, face = pcall(function()
   MakeFolder({ "LqExplorer", "LqExplorer/fonts" })
   local ttfPath = "LqExplorer/fonts/FiraMono-Regular.ttf"
   local jsonPath = "LqExplorer/fonts/FiraMono.json"
   if not isfile(ttfPath) then
    writefile(ttfPath, game:HttpGet("https://raw.githubusercontent.com/google/fonts/main/ofl/firamono/FiraMono-Regular.ttf"))
   end
   local ttfAsset = getcustomasset(ttfPath)
   writefile(jsonPath, game:GetService("HttpService"):JSONEncode({
    name = "Fira Mono",
    faces = {
     { name = "Regular", weight = 400, style = "normal", assetId = ttfAsset },
    },
   }))
   return Font.new(getcustomasset(jsonPath), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
  end)
  if ok and face then
   CODE_FACE = face
   SetFontSize(TS, true)
  end
 end)

 local function MouseOverSource()
  if not panel.Visible then return false end
  local ml = config.SV.UserInput:GetMouseLocation()
  local gi = Vector2.new(0, 0)
  pcall(function() gi = config.SV.Gui:GetGuiInset() end)
  local function Inside(gui, m)
   return gui.Visible and PointIn(gui, m)
  end
  local over = Inside(panel, ml) or Inside(panel, ml - gi)
  if not over then return false end
  if config.main.Visible and (Inside(config.main, ml) or Inside(config.main, ml - gi)) then return false end
  return true
 end

 config.SV.ContextAction:BindActionAtPriority("ExplorerSourceFontSize", function(_, state, inp)
  if not MouseOverSource() then return Enum.ContextActionResult.Pass end
  if state == Enum.UserInputState.Begin then
   SetFontSize(TS + (inp.KeyCode == Enum.KeyCode.I and 1 or -1))
  end
  return Enum.ContextActionResult.Sink
 end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.I, Enum.KeyCode.O)

 hclose.Activated:Connect(Explorer.CloseSource)
 hzoomin.Activated:Connect(function() SetFontSize(TS + 1) end)
 hzoomout.Activated:Connect(function() SetFontSize(TS - 1) end)
 hcopy.Activated:Connect(function()
  if setclipboard then
   pcall(setclipboard, st.raw)
   hcopy.Text = "Copied"
   task.delay(1, function() hcopy.Text = "Copy" end)
  end
 end)

 hdump.Activated:Connect(function()
 	if not st.inst then return end
 	if hdump.Text == "..." then return end
 	hdump.Text = "..."
 	hdump.TextColor3 = config.COLORS.TEXT_DIM

 	local inst = st.inst
 	task.spawn(function()
 		local dumpText = Explorer.DumpFunctions(inst)
 		hdump.Text = "Dump"
 		hdump.TextColor3 = config.COLORS.TEXT_BRIGHT

 		if not dumpText then
 			hdump.Text = "No Dump"
 			task.delay(1.5, function()
 				if hdump.Text == "No Dump" then hdump.Text = "Dump" end
 			end)
 			return
 		end

 		if st.inst ~= inst then return end

 		local append = "\n\n--[[\n" .. dumpText .. "\n]]"
 		st.raw = st.raw .. append
 		local s = append:gsub("\r\n", "\n"):gsub("\r", "\n"):gsub("\t", "    ")
 		local newLines = {}
 		for line in (s .. "\n"):gmatch("(.-)\n") do
 			newLines[#newLines + 1] = line
 		end

 		local lines = st.lines
 		for _, line in ipairs(newLines) do
 			lines[#lines + 1] = line
 			if #line > st.maxLen then st.maxLen = #line end
 		end
 		st.ind = {}
 		st.gW = #tostring(#lines) * charW + 20
 		st.contentW = st.maxLen * charW + 40
 		InvalidateAll()
 		Refresh()
 	end)
 end)

 config.main:GetPropertyChangedSignal("AbsoluteSize"):Connect(Layout)
 config.main:GetPropertyChangedSignal("AbsolutePosition"):Connect(Layout)
 config.main:GetPropertyChangedSignal("Visible"):Connect(Layout)
 config.window:GetPropertyChangedSignal("AbsoluteSize"):Connect(Layout)
 config.pmain:GetPropertyChangedSignal("AbsoluteSize"):Connect(Layout)
 config.pmain:GetPropertyChangedSignal("AbsolutePosition"):Connect(Layout)
 config.pmain:GetPropertyChangedSignal("Visible"):Connect(Layout)

 task.spawn(function()
  local ok, mod = pcall(function()
   return loadstring(game:HttpGet(Explorer.HighlighterUrl))()
  end)
  if ok and type(mod) == "table" then Explorer.SetHighlighter(mod) end
 end)
end

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
   if okN then
    local kids = gameRoot.Children
    for i = 1, #kids do
     local c = kids[i]
     if c.Name == nm and c.Real then
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
   if showHidden or not HIDDEN_SERVICES[svcName] then
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
   for i = 1, #ch do top += 1 stack[top] = ch[i] end
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
    present[real] = true
    if not existing[real] and MirrorOne(real, nilRoot) then added = true end
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

 function Explorer.EnsureDeepLoad()
  if Explorer.Mode ~= "Game" or deepLoaded or deepRunning then return end
  deepRunning = true
  local myToken = deepToken
  task.spawn(function()
   local stack, top = {}, 0
   local roots = Explorer.Root.Children
   for i = #roots, 1, -1 do top += 1 stack[top] = roots[i] end
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
    for i = 1, #ch do top += 1 stack[top] = ch[i] end
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
  if showNil and not scanning and #nilRoot.Children == 0 then
   task.spawn(ScanNilInstances)
  end
 end)

 local settingsDirty = false
 local function RescanGame()
  if scanning then return end
  for _, c in ipairs(gameRoot.Children) do Unregister(c) end
  ScanGame()
 end

 local settingsBtn
 config.settingsDropdown = Explorer.AddDropdown(function(Add)
  Add("Show Hidden Services", "Toggle", function(v)
   config.ShowHiddenServices = v
   if Explorer.Mode == "Game" then
    RescanGame()
   else
    settingsDirty = true
   end
  end, config.ShowHiddenServices)
 end, {
  Studio = true,
  RowH = 34,
  Width = 210,
  Parent = config.menuGui,
  ZBase = config.MENU_Z + 10,
 })

 settingsBtn = Explorer.AddMenuButton("Settings", function()
  config.settingsDropdown:ToggleAt(settingsBtn, false, 6)
 end)
 config.OnMenuToggle = function(open)
  if not open and config.settingsDropdown then config.settingsDropdown:Close() end
 end

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
   task.spawn(function() ScanGame() ScanNilInstances() end)
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
   if pv == Explorer.Root then rowsDirty = true return end
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
      if not set then set = {} byParent[pv] = set end
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
    if c.Real and not present[c.Real] then removeQ[c] = true changed = true end
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
   if game_ and showNil and not scanning and now - lastNil >= NIL_INTERVAL then
    lastNil = now
    task.spawn(ScanNilInstances)
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
    if c.Name == "Workspace" then return c end
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
   if not ok then return false end
   v.Name = name
   local p = v.Parent
   if p then Reposition(p, v) end
   return true
  end

  function G.Move(src, pv)
   local real = src.Real
   if not real or pv == gameRoot then return false end
   LoadKids(pv)
   local ok = pcall(function()
    if pv == nilRoot then real.Parent = nil else real.Parent = pv.Real end
   end)
   if not ok then return false end
   src:SetParent(pv)
   if pv == nilRoot then Unregister(src) else realToV[real] = src end
   return true
  end

  function G.Clone(src, pv)
   local real = src.Real
   if not real or pv == gameRoot then return nil end
   LoadKids(pv)
   local ok, c = pcall(real.Clone, real)
   if not ok or not c then return nil end
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
   ScanNilInstances()
  end
 end)
end

for _, v in ipairs(config.folder:GetDescendants()) do
 if v.RobloxLocked == false then v.RobloxLocked = true end
end

task.spawn(function()
 repeat task.wait() until config.window.AbsoluteSize.X > 0
 config.PDock.Side = "right"
 config.PDock.Order = "below"
 ApplyDock("right")
 Explorer.ScanTree()
 RefreshTree()
 Explorer.RefreshProperties()
end)

config.window:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
 if config.LayoutDocks then config.LayoutDocks() end
end)

getgenv().Explorer = Explorer
return Explorer
