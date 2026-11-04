local ServiceCache = {}
local function GetService(name)
 if ServiceCache[name] then return ServiceCache[name] end
 local ok, svc = pcall(game.GetService, game, name)
 if ok then
  ServiceCache[name] = svc
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
 function f.invalidate(g: any): any
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
 return f.invalidate
end

local SV = {
 UserInput = cloneref(GetService("UserInputService")),
 Tween = cloneref(GetService("TweenService")),
 TextSrv = cloneref(GetService("TextService")),
 CoreGui = cloneref(GetService("CoreGui")),
 RunSrv = cloneref(GetService("RunService")),
 ContextAction = cloneref(GetService("ContextActionService")),
 Gui = cloneref(GetService("GuiService")),
 Http = cloneref(GetService("HttpService")),
}

local function randomString()
 local n = math.random(35, 45)
 local t = {}
 for i = 1, n do t[i] = string.char(math.random(32, 126)) end
 return table.concat(t)
end

local function RoundPx(n) return math.floor(n + 0.5) end

local function isPress(inp)
 return inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch
end

local function absOf(inp, gui)
 local p = Vector2.new(inp.Position.X, inp.Position.Y)
 local gi = Vector2.new(0, 0)
 if SV.Gui then
  local ok, v = pcall(function() return SV.Gui:GetGuiInset() end)
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

local COLORS = {
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

local FONT = {
 GothamBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
 GothamMedium = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
 GothamRegular = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
}

local function ComputeResponsiveWidth(w)
 return math.clamp(math.floor(w * 0.3), 100, 500)
end

local Explorer
local VirtualInstance = {}
local LAZY_TABLES = { Attributes = true, Properties = true, Metadata = true }
VirtualInstance.__index = function(t, k)
 local m = VirtualInstance[k]
 if m ~= nil then return m end
 if LAZY_TABLES[k] then
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

local Root = setmetatable({
 Name = "<root>",
 ClassName = "Root",
 Parent = nil,
 Children = {},
}, VirtualInstance)

local CLASS_PRIORITY = {
 Folder = 1, Model = 2, WorldModel = 2,
 LocalScript = 3, Script = 3, ModuleScript = 3,
 RemoteEvent = 4, RemoteFunction = 4, BindableEvent = 4, BindableFunction = 4,
}

local PRIO_STR = {}
for i = 0, 99 do PRIO_STR[i] = string.format("%02d", i) end

local function refreshKey(n)
 local name, cls = n.Name, n.ClassName
 local md = rawget(n, "Metadata")
 local o = md and md.Order
 if n._skName ~= name or n._skCls ~= cls or n._skOrd ~= o then
  n._skName, n._skCls, n._skOrd = name, cls, o
  if o then
   n._sk = "\1" .. string.format("%08d", o)
  else
   n._sk = PRIO_STR[CLASS_PRIORITY[cls] or 99] .. tostring(name):lower()
  end
 end
 return n._sk
end

local function sortedChildren(inst)
 local kids = inst.Children
 local n = #kids
 local cache = inst._sorted
 if cache and inst._live and #cache == n then return cache end
 if cache and #cache == n then
  local ok, prev = true, nil
  for i = 1, n do
   local k = refreshKey(cache[i])
   if prev and k < prev then ok = false break end
   prev = k
  end
  if ok then return cache end
 end
 local keys, map = table.create(n), {}
 for i = 1, n do
  local c = kids[i]
  local k = refreshKey(c) .. "\0" .. i
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
 Root = Root,
 SelectedSet = {},
 Clipboard = {},
 Expanded = setmetatable({}, {__mode="k"}),
 SearchOpen = setmetatable({}, {__mode="k"}),
 Selected = nil,
 ContextItems = {},
 UserIcons = {},
 Settings = {},
 OnSelectCb = nil,
 OnDoubleClickCb = nil,
 OnRightClickCb = nil,
 PanelResizing = setmetatable({}, {__mode="k"}),
}

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

local Positions = {
 ARROW_X = math.floor(config.ROW_H * 0.4 + 0.5),
 ICON_X = math.floor(config.ROW_H * 1 + 0.5),
 TEXT_X = math.floor(config.ROW_H * 2.25 + 0.5),
 INDENT = math.floor(config.ROW_H * 0.67 + 0.5),
 ICON_PX = math.floor(config.ROW_H * 0.9 + 0.5),
}

local function RoundCorner(inst, scale, radius)
 local c = Instance.new("UICorner")
 c.Name = randomString()
 c.CornerRadius = UDim.new(scale, radius)
 c.Archivable = false
 c.Parent = inst
 return c
end

local function BorderStroke(inst, thickness, R, G, B)
 local s = Instance.new("UIStroke")
 s.Name = randomString()
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

local function MakeCheckBox(parent, size, z)
 local box = Instance.new("Frame")
 box.Name = randomString()
 box.Size = UDim2.new(0, size, 0, size)
 box.BackgroundColor3 = Color3.fromRGB(20, 21, 26)
 box.BorderSizePixel = 0
 box.ZIndex = z
 box.Archivable = false
 box.Parent = parent
 BorderStroke(box, 1, 90, 90, 90)
 local arms = {}
 local s = size / 16
 local function arm(len, cx, cy, rot)
  local f = Instance.new("Frame")
  f.Name = randomString()
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
 arm(5.5, 4.75, 10, -45)
 arm(10, 9.75, 8.5, 45)
 local function set(on)
  box.BackgroundColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(20, 21, 26)
  for _, a in ipairs(arms) do a.Visible = on and true or false end
 end
 return box, set
end

local function MakeStudioCheckBox(parent, size, z)
 local box = Instance.new("Frame")
 box.Name = randomString()
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
 local function arm(len, cx, cy, rot)
  local f = Instance.new("Frame")
  f.Name = randomString()
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
 arm(4.8, 5.1, 10.1, -45)
 arm(9.8, 9.6, 8, 40.6)
 local function set(on)
  on = on and true or false
  box.BackgroundTransparency = on and 0 or 1
  stroke.Color = on and Color3.fromRGB(59, 91, 243) or Color3.fromRGB(215, 215, 220)
  for _, a in ipairs(arms) do a.Visible = on end
 end
 return box, set
end

local function MakePinIcon(parent, size, z, color)
 local box = Instance.new("Frame")
 box.Name = randomString()
 box.Size = UDim2.new(0, size, 0, size)
 box.AnchorPoint = Vector2.new(0.5, 0.5)
 box.Position = UDim2.new(0.5, 0, 0.5, 0)
 box.BackgroundTransparency = 1
 box.Active = false
 box.ZIndex = z
 box.Archivable = false
 box.Parent = parent
 local s = size / 16
 local function px(v) return math.floor(v * s + 0.5) end
 local function rect(x, y, w, h, rot, anchored)
  local f = Instance.new("Frame")
  f.Name = randomString()
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
 local bl, bt, bb = px(0), px(6.5), px(16)
 local br, bTopEnd, bRightTop = px(9.5), px(5), px(11)
 rect(bl, bt, t, bb - bt)
 rect(bl, bb - t, br - bl, t)
 rect(bl, bt, bTopEnd - bl, t)
 rect(br - t, bRightTop, t, bb - bRightTop)
 local hl, ht, hp = px(6), px(2), px(8)
 for j = 0, hp - 1 do
  rect(hl, ht + j, j + 1, 1)
 end
 local len = 7 * s
 local mx, my = hl + hp / 2, ht + hp / 2
 local k = 0.70710678 * len / 2
 rect(mx + k, my - k, t, len, 45, true)
 return box
end

local function MakeCloseIcon(parent, size, z, color)
 size = size - (size % 2)
 local box = Instance.new("Frame")
 box.Name = randomString()
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
  f.Name = randomString()
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
 c.Name = randomString()
 c.Size = UDim2.new(0, 12, 0, 8)
 c.BackgroundTransparency = 1
 c.ZIndex = z
 c.Archivable = false
 c.Parent = parent
 for _, d in ipairs({ { 3.5, -45 }, { 8.5, 45 } }) do
  local f = Instance.new("Frame")
  f.Name = randomString()
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
 b.Name = randomString()
 b.Size = UDim2.new(0, 18, 0, 18)
 b.BackgroundTransparency = 1
 b.BorderSizePixel = 0
 b.AutoButtonColor = false
 b.Text = ""
 b.ZIndex = z
 b.Archivable = false
 b.Parent = parent
 local ring = Instance.new("Frame")
 ring.Name = randomString()
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
  bar.Name = randomString()
  bar.Size = UDim2.new(0, d[1], 0, d[2])
  bar.Position = UDim2.new(0.5, -d[1] / 2, 0.5, -d[2] / 2)
  bar.BackgroundColor3 = COLORS.PRIMARY
  bar.BorderSizePixel = 0
  bar.ZIndex = z + 1
  bar.Archivable = false
  bar.Parent = b
 end
 return b
end

local function MakeCross(parent, z)
 local b = Instance.new("TextButton")
 b.Name = randomString()
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
  f.Name = randomString()
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
 b.Name = randomString()
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
  d.Name = randomString()
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

local ICON_ID = "rbxassetid://135148380892747"
local ICON_SIZE = Vector2.new(32, 32)
local ICONS = {
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
 ["SpringConstraint"]={6,4},
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
 ["Tools"]={15,4},
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

local function getIconOffset(classname)
 local c = ICONS[classname]
 if not c and classname:match("Value$") then c = ICONS["Value"] end
 if not c and (classname:match("Service$") or classname:match("Provider$")) then c = ICONS["Service"] end
 if not c then c = ICONS["Instance"] end
 return Vector2.new((c[2] - 1) * 32, (c[1] - 1) * 32)
end

local function applyIcon(iconLabel, className)
 if not iconLabel then return end
 if Explorer.UserIcons[className] then
  local u = Explorer.UserIcons[className]
  iconLabel.Image = u.id
  iconLabel.ImageRectSize = u.size or Vector2.new(0, 0)
  iconLabel.ImageRectOffset = u.offset or Vector2.new(0, 0)
  return
 end
 iconLabel.Image = ICON_ID
 iconLabel.ImageRectSize = ICON_SIZE
 iconLabel.ImageRectOffset = getIconOffset(className)
end

local function escape(s)
 return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local ADBP = loadstring(game:HttpGet("https://raw.githubusercontent.com/lqdxt/Scripts/refs/heads/main/ADBP.lua"))()
local main
local docksplitter
local layoutSource
local layoutDocks, pmain, pdocksplitter
local PDock = { Side = nil, Order = "below", Split = nil }

local folder = Instance.new("Folder")
folder.Name = randomString()
folder.Archivable = false
folder.RobloxLocked = true
folder.Parent = (gethui and gethui()) or SV.CoreGui
ADBP(folder)

local window = Instance.new("ScreenGui")
window.Name = randomString()
window.ResetOnSpawn = false
window.IgnoreGuiInset = true
window.DisplayOrder = 10
window.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
window.Archivable = false
window.ClipToDeviceSafeArea = true
window.Parent = folder

local function topInset()
 local ok, v = pcall(function() return SV.Gui:GetGuiInset() end)
 return (ok and v and v.Y) or 0
end

local function clampPanelTop(panel)
 local H = window.AbsoluteSize.Y
 local inset = topInset()
 local p, sz, ap = panel.Position, panel.Size, panel.AnchorPoint
 local top = p.Y.Scale * H + p.Y.Offset - ap.Y * (sz.Y.Scale * H + sz.Y.Offset)
 if top < inset then
  panel.Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + (inset - top))
 end
end

local function nearestSide(gui)
 local ap, as = gui.AbsolutePosition, gui.AbsoluteSize
 return (ap.X + as.X / 2 < window.AbsoluteSize.X / 2) and "left" or "right"
end

local DT = 1
local function ApplyDock(side)
 config.DockSide = side
 main.AnchorPoint = Vector2.new(0, 0)
 docksplitter.Visible = true
 if side == "left" then
  docksplitter.Position = UDim2.new(1, 0, 0, 0)
 else
  docksplitter.Position = UDim2.new(0, -3, 0, 0)
 end
 if layoutDocks then layoutDocks() end
 if layoutSource then layoutSource() end
end

local function undock()
 if not config.DockSide then return end
 local px, py = main.Position.X.Offset, main.Position.Y.Offset
 local w, h = main.Size.X.Offset, config.NormalSize.Y.Offset
 config.DockSide = nil
 main.AnchorPoint = Vector2.new(0.5, 0.5)
 main.Position = UDim2.new(0, px + w / 2, 0, py + h / 2)
 main.Size = UDim2.new(0, w, 0, h)
 docksplitter.Visible = false
 if layoutDocks then layoutDocks() end
 if layoutSource then layoutSource() end
end

local function applyResponsiveWidth()
 local vpX = window.AbsoluteSize.X
 if vpX <= 0 then return end
 local newDT = ComputeResponsiveWidth(vpX)
 if newDT == DT then return end
 DT = newDT
 config.NormalSize = UDim2.new(0, DT, 0, config.NormalSize.Y.Offset)
 config.MinimizedSize = UDim2.new(0, DT, 0, 44)
 if main and main.Parent then
  main.Size = UDim2.new(0, DT, 0, main.Size.Y.Offset)
 end
 if pmain and pmain.Parent and PDock.Side then
  pmain.Size = UDim2.new(0, DT, 0, pmain.Size.Y.Offset)
 end
 if layoutDocks and (config.DockSide or PDock.Side) then layoutDocks() end
end
DT = ComputeResponsiveWidth(window.AbsoluteSize.X > 0 and window.AbsoluteSize.X or 1000)
window:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyResponsiveWidth)

local WinOrder = {}
local function BringToFront(w)
 for i, v in ipairs(WinOrder) do
  if v == w then table.remove(WinOrder, i) break end
 end
 table.insert(WinOrder, w)
 for i, v in ipairs(WinOrder) do v.ZIndex = 1 + i end
end
local function RegisterWindow(w)
 table.insert(WinOrder, w)
 w.ZIndex = 1 + #WinOrder
end
SV.UserInput.InputBegan:Connect(function(inp)
 local t = inp.UserInputType
 if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
 local pos = SV.UserInput:GetMouseLocation()
 if t == Enum.UserInputType.Touch then
  local ok, gi = pcall(function() return SV.Gui:GetGuiInset() end)
  pos = Vector2.new(inp.Position.X, inp.Position.Y) + ((ok and gi) or Vector2.new(0, 0))
 end
 for i = #WinOrder, 1, -1 do
  local w = WinOrder[i]
  if w.Visible then
   local ap, as = w.AbsolutePosition, w.AbsoluteSize
   if pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y then
    if i ~= #WinOrder then BringToFront(w) end
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

 local function close()
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

 local function closeSub()
  if handle.Sub then
   handle.Sub:Destroy()
   handle.Sub = nil
  end
  handle.SubOwner = nil
 end

 local function build()
  local prev = {}
  local prevItems = handle.Items
  for _, item in ipairs(prevItems) do
   if item.name then prev[item.name] = item.state end
  end
  handle.Items = {}
  local function makeAdd(list, allowOptions, prevStates)
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
     local ok2, err2 = pcall(callback, makeAdd(item.children, false, subPrev))
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
  local Add = makeAdd(handle.Items, true, prev)
  local ok, err = pcall(builder, Add)
  if not ok then
   warn(err)
  end
 end

 local openSub

 local function renderInto(frame, items, isSub)
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
   empty.TextColor3 = COLORS.TEXT_DIM
   empty.FontFace = FONT.GothamMedium
   empty.TextSize = 14
   empty.ZIndex = 13 + ZB
   empty.Archivable = false
   empty.Parent = frame
   y += ROW_H
  end

  for _, item in ipairs(items) do
   if item.kind == "Separator" then
    local sep = Instance.new("Frame")
    sep.Name = randomString()
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
   row.Name = randomString()
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
   lbl.FontFace = STUDIO and FONT.GothamRegular or FONT.GothamMedium
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
   btn.MouseEnter:Connect(function()
    hoverTarget.BackgroundColor3 = COLORS.SECONDARY
    hoverTarget.BackgroundTransparency = 0
   end)
   btn.MouseLeave:Connect(function()
    if handle.SubOwner == item then return end
    hoverTarget.BackgroundTransparency = 1
   end)

   if item.kind == "Options" then
    local chev = MakeChevron(btn, 15 + ZB)
    chev.AnchorPoint = Vector2.new(0.5, 0.5)
    chev.Position = UDim2.new(1, -12, 0.5, 0)
    chev.Rotation = -90
    btn.Activated:Connect(function()
     if handle.SubOwner == item then
      closeSub()
      btn.BackgroundTransparency = 1
     else
      openSub(item, row, frame)
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
     if opts.CloseOnClick then close() end
     if item.callback then pcall(item.callback) end
    end)
   end

   y += ROW_H
  end

  frame.Size = UDim2.new(0, DROPDOWN_WIDTH, 0, y + PAD)
 end

 local function render()
  if not handle.Frame then return end
  closeSub()
  renderInto(handle.Frame, handle.Items, false)
 end

 openSub = function(item, row, parentFrame)
  local parent = parentFrame.Parent
  if not parent then return end
  closeSub()
  handle.SubOwner = item

  local sub = Instance.new("Frame")
  sub.Name = randomString()
  sub.BackgroundColor3 = COLORS.PRIMARY
  sub.BorderSizePixel = 0
  sub.ZIndex = 11 + ZB
  sub.Archivable = false
  sub.Parent = parent
  DropStroke(sub)
  handle.Sub = sub
  renderInto(sub, item.children, true)
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

  for _, c in ipairs(row:GetChildren()) do
   if c:IsA("TextButton") then
    c.BackgroundColor3 = COLORS.SECONDARY
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
  local parent = opts.Screen and window or main
  if not parent then return self end
  close()
  build()
  lastOpen = tick()

  local frame = Instance.new("Frame")
  frame.Name = randomString()
  frame.BackgroundColor3 = COLORS.PRIMARY
  frame.BorderSizePixel = 0
  frame.ZIndex = 11 + ZB
  frame.Archivable = false
  frame.Parent = parent
  local frameStroke = DropStroke(frame)
  if STUDIO then
   RoundCorner(frame, 0, 10)
   frameStroke.Color = Color3.fromRGB(75, 78, 88)
  end
  handle.Frame = frame
  render()
  if opts.Screen then frame.BackgroundTransparency = config.NT end

  local maxX = math.max(4, parent.AbsoluteSize.X - frame.Size.X.Offset - 4)
  local maxY = math.max(4, parent.AbsoluteSize.Y - frame.Size.Y.Offset - 4)
  frame.Position = UDim2.new(
   0, math.clamp(x or 0, 4, maxX),
   0, math.clamp(y or 0, 4, maxY)
  )

  handle.Connection = SV.UserInput.InputBegan:Connect(function(inp)
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
   close()
  end)

  return self
 end

 function handle:OpenAt(gui, alignRight, offsetY)
  if not gui or not main then return self end
  local ap = gui.AbsolutePosition
  local as = gui.AbsoluteSize
  local mainAp = main.AbsolutePosition
  local x
  if opts.FullWidth then
   DROPDOWN_WIDTH = math.max(180, main.AbsoluteSize.X - 14)
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

 function handle:Close() close() return self end
 function handle:Toggle(x, y)
  if handle.Frame then close() else self:Open(x, y) end
  return self
 end
 function handle:ToggleAt(gui, alignRight, offsetY)
  if handle.Frame then close() else self:OpenAt(gui, alignRight, offsetY) end
  return self
 end
 function handle:Refresh()
  if handle.Frame then build() render() end
  return self
 end
 function handle:Destroy() close() return self end

 return handle
end

main = Instance.new("Frame")
main.Name = randomString()
main.Size = UDim2.new(0, DT, 0, 280)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = COLORS.PRIMARY
main.BackgroundTransparency = config.NT
main.Active = true
main.BorderSizePixel = 0
main.ZIndex = 2
main.Archivable = false
main.Parent = window
RegisterWindow(main)

docksplitter = Instance.new("Frame")
docksplitter.Name = randomString()
docksplitter.Size = UDim2.new(0, 3, 1, 0)
docksplitter.BackgroundColor3 = COLORS.RESIZER
docksplitter.BorderSizePixel = 0
docksplitter.ZIndex = 8
docksplitter.Visible = false
docksplitter.Archivable = false
docksplitter.Active = true
docksplitter.Parent = main

local header = Instance.new("Frame")
header.Name = randomString()
header.Size = UDim2.new(1, 0, 0, 28)
header.BackgroundColor3 = COLORS.HEADER
header.BorderSizePixel = 0
header.Active = true
header.ZIndex = 3
header.Archivable = false
header.Parent = main

local separator = Instance.new("Frame")
separator.Name = randomString()
separator.Size = UDim2.new(1, -8, 0, 2)
separator.Position = UDim2.new(0, 7, 0, 63)
separator.BackgroundColor3 = COLORS.SECONDARY
separator.BorderSizePixel = 0
separator.ZIndex = 5
separator.Archivable = false
separator.Parent = main

local searchRow = Instance.new("Frame")
searchRow.Name = randomString()
searchRow.Size = UDim2.new(1, 0, 0, 34)
searchRow.Position = UDim2.new(0, 0, 0, 28)
searchRow.BackgroundTransparency = 1
searchRow.BorderSizePixel = 0
searchRow.ZIndex = 3
searchRow.Archivable = false
searchRow.Parent = main

local searchbar = Instance.new("TextBox")
searchbar.Name = randomString()
searchbar.Size = UDim2.new(1, -50, 0, 28)
searchbar.Position = UDim2.new(0, 7, 0, 4)
searchbar.BackgroundTransparency = 0
searchbar.BackgroundColor3 = COLORS.SECONDARY
searchbar.PlaceholderText = "Search"
searchbar.PlaceholderColor3 = COLORS.TEXT
searchbar.Text = ""
searchbar.TextColor3 = COLORS.TEXT_BRIGHT
searchbar.Font = Enum.Font.SourceSans
searchbar.TextSize = 15
searchbar.TextXAlignment = Enum.TextXAlignment.Left
searchbar.ClearTextOnFocus = false
searchbar.ZIndex = 5
searchbar.Archivable = false
searchbar.Parent = searchRow
RoundCorner(searchbar, 0, 8)

local threedotmenu = Instance.new("ImageButton")
threedotmenu.Name = randomString()
threedotmenu.Size = UDim2.new(0, 28, 0, 28)
threedotmenu.Position = UDim2.new(1, -36, 0.5, -13)
threedotmenu.BackgroundColor3 = COLORS.SECONDARY
threedotmenu.Image = ""
threedotmenu.BorderSizePixel = 0
threedotmenu.ZIndex = 5
threedotmenu.Archivable = false
threedotmenu.Parent = searchRow
RoundCorner(threedotmenu, 0, 8)

local colonimage = Instance.new("ImageLabel")
colonimage.Name = randomString()
colonimage.Size = UDim2.new(0, 24, 0, 24)
colonimage.Position = UDim2.new(0, 2, 0, 2)
colonimage.BackgroundTransparency = 1
colonimage.Image = "rbxassetid://18569843302"
colonimage.BorderSizePixel = 0
colonimage.ZIndex = 5
colonimage.Archivable = false
colonimage.Parent = threedotmenu

config.SearchHistory = {}

local historybtn = Instance.new("ImageButton")
historybtn.Name = randomString()
historybtn.Size = UDim2.new(0, 28, 0, 28)
historybtn.Position = UDim2.new(1, -68, 0.5, -13)
historybtn.BackgroundColor3 = COLORS.SECONDARY
historybtn.BackgroundTransparency = 0
historybtn.Image = "rbxassetid://101905359759779"
historybtn.BorderSizePixel = 0
historybtn.ZIndex = 5
historybtn.Archivable = false
historybtn.Parent = searchRow
RoundCorner(historybtn, 0, 8)

local clearbtn = Instance.new("TextButton")
clearbtn.Name = randomString()
clearbtn.Size = UDim2.new(0, 28, 0, 28)
clearbtn.Position = UDim2.new(1, -95, 0.5, -13)
clearbtn.BackgroundTransparency = 1
clearbtn.Text = ""
clearbtn.AutoButtonColor = false
clearbtn.BorderSizePixel = 0
clearbtn.ZIndex = 6
clearbtn.Visible = false
clearbtn.Archivable = false
clearbtn.Parent = searchRow
RoundCorner(clearbtn, 0, 8)
MakeCloseIcon(clearbtn, 11, 7, Color3.fromRGB(160, 160, 160))

clearbtn.Activated:Connect(function()
 searchbar.Text = ""
end)

searchbar:GetPropertyChangedSignal("Text"):Connect(function()
 clearbtn.Visible = searchbar.Text ~= ""
end)

local historyDropdown
historyDropdown = Explorer.AddDropdown(function(Add)
 for _, term in ipairs(config.SearchHistory) do
  Add(term, "Button", function()
   searchbar.Text = term
   config.SearchQuery = term
   historyDropdown:Close()
  end)
 end
 if #config.SearchHistory > 0 then
  Add("Clear history", "Button", function()
   table.clear(config.SearchHistory)
   historyDropdown:Close()
  end, nil, { TextColor = COLORS.CLOSE_TEXT })
 end
end)

historybtn.Activated:Connect(function()
 if #config.SearchHistory == 0 then return end
 historyDropdown:ToggleAt(historybtn)
end)

searchbar.FocusLost:Connect(function()
 local text = searchbar.Text
 if text == "" then return end
 if config.SearchHistory[1] == text then return end
 for i = #config.SearchHistory, 1, -1 do
  if config.SearchHistory[i] == text then table.remove(config.SearchHistory, i) end
 end
 table.insert(config.SearchHistory, 1, text)
 if #config.SearchHistory > 10 then table.remove(config.SearchHistory) end
end)

local accent = Instance.new("Frame")
accent.Name = randomString()
accent.Size = UDim2.new(1, 0, 0, 1.5)
accent.Position = UDim2.new(0, 0, 1, -1.5)
accent.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
accent.BorderSizePixel = 0
accent.ZIndex = 3
accent.Archivable = false
accent.Parent = header

local title = Instance.new("TextLabel")
title.Name = randomString()
title.Text = "Explorer"
title.Size = UDim2.new(1, 0, 1, 0)
title.Position = UDim2.new(0, -15, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = COLORS.TEXT_BRIGHT
title.FontFace = FONT.GothamRegular
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Center
title.ZIndex = 3
title.Archivable = false
title.Parent = header

local close = Instance.new("TextButton")
close.Name = randomString()
close.Size = UDim2.new(0, 28, 0, 28)
close.Position = UDim2.new(1, -30, 0.5, -13)
close.BackgroundTransparency = 1
close.Text = ""
close.AutoButtonColor = false
close.BorderSizePixel = 0
close.ZIndex = 3
close.Archivable = false
close.Parent = header
MakeCloseIcon(close, 8, 4, Color3.fromRGB(210, 210, 210))

local MENU_Z, menuGui, topbar
do
local MENU_BTN_W, MENU_BTN_H = 96, 32
local CELL_W, CELL_H, CELL_GAP, BAR_PAD = 76, 66, 4, 8
local TEXT_ROW_H = 26
local MENU_BAR_W = BAR_PAD * 2 + CELL_W * 2 + CELL_GAP
local MENU_BAR_H = BAR_PAD * 2 + CELL_H
local layoutBar
local menuCells = {}
MENU_Z = 60
local ICON_WHITE = Color3.fromRGB(255, 255, 255)
local ICON_ACCENT = Color3.fromRGB(125, 128, 175)

menuGui = Instance.new("ScreenGui")
menuGui.Name = randomString()
menuGui.ResetOnSpawn = false
menuGui.IgnoreGuiInset = true
menuGui.DisplayOrder = 11
menuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
menuGui.ClipToDeviceSafeArea = false
menuGui.Archivable = false
menuGui.Parent = folder

local menubtn = Instance.new("TextButton")
menubtn.Name = randomString()
menubtn.Size = UDim2.new(0, MENU_BTN_W, 0, MENU_BTN_H)
menubtn.AnchorPoint = Vector2.new(0.5, 0)
menubtn.Position = UDim2.new(0.5, 0, 0, 6)
menubtn.BackgroundColor3 = COLORS.HEADER
menubtn.AutoButtonColor = false
menubtn.Text = "Menu"
menubtn.TextColor3 = COLORS.TEXT_BRIGHT
menubtn.FontFace = FONT.GothamMedium
menubtn.TextSize = 15
menubtn.BorderSizePixel = 0
menubtn.ZIndex = MENU_Z
menubtn.Archivable = false
menubtn.Parent = menuGui
RoundCorner(menubtn, 0, 8)
BorderStroke(menubtn, 1, 60, 60, 60)

topbar = Instance.new("Frame")
topbar.Name = randomString()
topbar.Size = UDim2.new(0, MENU_BAR_W, 0, MENU_BAR_H)
topbar.AnchorPoint = Vector2.new(0.5, 0)
topbar.Position = UDim2.new(0.5, 0, 0, 6 + MENU_BTN_H + 6)
topbar.BackgroundColor3 = COLORS.PRIMARY
topbar.BorderSizePixel = 0
topbar.Visible = false
topbar.Active = true
topbar.ZIndex = MENU_Z
topbar.Archivable = false
topbar.Parent = menuGui
RoundCorner(topbar, 0, 10)
BorderStroke(topbar, 1, 60, 60, 60)

local textRow = Instance.new("Frame")
textRow.Name = randomString()
textRow.Size = UDim2.new(1, -BAR_PAD * 2, 0, TEXT_ROW_H)
textRow.Position = UDim2.new(0, BAR_PAD, 0, BAR_PAD - 2)
textRow.BackgroundTransparency = 1
textRow.Visible = false
textRow.ZIndex = MENU_Z + 1
textRow.Archivable = false
textRow.Parent = topbar

local textRowLayout = Instance.new("UIListLayout")
textRowLayout.FillDirection = Enum.FillDirection.Horizontal
textRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
textRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
textRowLayout.Padding = UDim.new(0, 4)
textRowLayout.Parent = textRow

local textRowLine = Instance.new("Frame")
textRowLine.Name = randomString()
textRowLine.Size = UDim2.new(1, -BAR_PAD * 2, 0, 1)
textRowLine.Position = UDim2.new(0, BAR_PAD, 0, BAR_PAD + TEXT_ROW_H + 1)
textRowLine.BackgroundColor3 = COLORS.SECONDARY
textRowLine.BorderSizePixel = 0
textRowLine.Visible = false
textRowLine.ZIndex = MENU_Z + 1
textRowLine.Archivable = false
textRowLine.Parent = topbar

local textBtnCount = 0
function Explorer.AddMenuButton(name, callback)
 textBtnCount += 1
 local b = Instance.new("TextButton")
 b.Name = randomString()
 b.AutomaticSize = Enum.AutomaticSize.X
 b.Size = UDim2.new(0, 0, 0, 22)
 b.BackgroundColor3 = COLORS.SECONDARY
 b.BackgroundTransparency = 1
 b.AutoButtonColor = false
 b.Text = name
 b.TextColor3 = COLORS.TEXT_BRIGHT
 b.FontFace = FONT.GothamMedium
 b.TextSize = 12
 b.BorderSizePixel = 0
 b.LayoutOrder = textBtnCount
 b.ZIndex = MENU_Z + 2
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
 if layoutBar then layoutBar() end
 return b
end

local function iconRect(parent, x, y, w, h, color, radius)
 local f = Instance.new("Frame")
 f.Name = randomString()
 f.Position = UDim2.new(0, x, 0, y)
 f.Size = UDim2.new(0, w, 0, h)
 f.BackgroundColor3 = color
 f.BorderSizePixel = 0
 f.ZIndex = MENU_Z + 2
 f.Archivable = false
 f.Parent = parent
 if radius and radius > 0 then RoundCorner(f, 0, radius) end
 return f
end

local function buildExplorerIcon(box)
 local sq = iconRect(box, 2, 2, 7, 7, ICON_ACCENT, 2)
 BorderStroke(sq, 2, 255, 255, 255)
 iconRect(box, 15, 5, 17, 2, ICON_WHITE, 1)
 iconRect(box, 5, 11, 2, 16, ICON_WHITE, 0)
 iconRect(box, 5, 16, 19, 2, ICON_WHITE, 0)
 iconRect(box, 24, 14, 8, 7, ICON_WHITE, 2)
 iconRect(box, 5, 26, 19, 2, ICON_WHITE, 0)
 iconRect(box, 24, 24, 8, 7, ICON_WHITE, 2)
end

local function buildPropertiesIcon(box)
 iconRect(box, 4, 5, 23, 25, ICON_ACCENT, 4)
 local front = iconRect(box, 9, 2, 19, 21, COLORS.PRIMARY, 4)
 BorderStroke(front, 2, 255, 255, 255)
 for _, y in ipairs({ 5, 12 }) do
  iconRect(front, 3, y, 4, 4, ICON_WHITE, 1)
  iconRect(front, 10, y + 1, 6, 2, ICON_WHITE, 1)
 end
end

local function makeMenuCell(index, labelText, buildIcon)
 local cell = Instance.new("TextButton")
 cell.Name = randomString()
 cell.Size = UDim2.new(0, CELL_W, 0, CELL_H)
 cell.Position = UDim2.new(0, 0, 0, BAR_PAD)
 cell.BackgroundColor3 = COLORS.SECONDARY
 cell.BackgroundTransparency = 1
 cell.AutoButtonColor = false
 cell.Text = ""
 cell.BorderSizePixel = 0
 cell.ZIndex = MENU_Z + 1
 cell.Archivable = false
 cell.Parent = topbar
 menuCells[index] = cell
 RoundCorner(cell, 0, 8)

 local iconBox = Instance.new("Frame")
 iconBox.Name = randomString()
 iconBox.Size = UDim2.new(0, 32, 0, 32)
 iconBox.Position = UDim2.new(0.5, -16, 0, 6)
 iconBox.BackgroundTransparency = 1
 iconBox.ZIndex = MENU_Z + 2
 iconBox.Archivable = false
 iconBox.Parent = cell
 buildIcon(iconBox)

 local lbl = Instance.new("TextLabel")
 lbl.Name = randomString()
 lbl.Size = UDim2.new(1, 0, 0, 16)
 lbl.Position = UDim2.new(0, 0, 0, 44)
 lbl.BackgroundTransparency = 1
 lbl.Text = labelText
 lbl.TextColor3 = COLORS.TEXT_BRIGHT
 lbl.FontFace = FONT.GothamMedium
 lbl.TextSize = 12
 lbl.ZIndex = MENU_Z + 2
 lbl.Archivable = false
 lbl.Parent = cell

 local hover, active = false, false
 local function paint()
  if active or hover then
   cell.BackgroundColor3 = COLORS.SECONDARY
   cell.BackgroundTransparency = active and (hover and 0.2 or 0.3) or 0.5
  else
   cell.BackgroundTransparency = 1
  end
 end
 cell.MouseEnter:Connect(function() hover = true paint() end)
 cell.MouseLeave:Connect(function() hover = false paint() end)
 return cell, function(on) active = on and true or false paint() end
end

local explorerbtn, setExplorerActive = makeMenuCell(1, "Explorer", buildExplorerIcon)
local propertiesbtn, setPropertiesActive = makeMenuCell(2, "Properties", buildPropertiesIcon)
layoutBar = function()
 local hasText = textBtnCount > 0
 local extra = hasText and (TEXT_ROW_H + 6) or 0
 local cellsW = CELL_W * #menuCells + CELL_GAP * (#menuCells - 1)
 local textW = hasText and (textRowLayout.AbsoluteContentSize.X + BAR_PAD * 2) or 0
 local barW = math.max(cellsW + BAR_PAD * 2, textW)
 topbar.Size = UDim2.new(0, barW, 0, BAR_PAD * 2 + CELL_H + extra)
 textRow.Visible = hasText
 textRowLine.Visible = hasText
 for i, c in ipairs(menuCells) do
  c.Position = UDim2.new(0.5, -cellsW / 2 + (i - 1) * (CELL_W + CELL_GAP), 0, BAR_PAD + extra)
 end
end
textRowLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(layoutBar)
layoutBar()

config.SetPropertiesActive = setPropertiesActive
setExplorerActive(main.Visible)
main:GetPropertyChangedSignal("Visible"):Connect(function() setExplorerActive(main.Visible) end)

explorerbtn.Activated:Connect(function() Explorer.Toggle() end)
propertiesbtn.Activated:Connect(function()
 if Explorer.ToggleProperties then Explorer.ToggleProperties() end
end)

local function setMenuOpen(open)
 config.MenuOpen = open
 topbar.Visible = open
 menubtn.BackgroundColor3 = open and COLORS.SECONDARY or COLORS.HEADER
 if config.OnMenuToggle then config.OnMenuToggle(open) end
end
config.MenuOpen = false
menubtn.Activated:Connect(function() setMenuOpen(not config.MenuOpen) end)
end

local pinbtn = Instance.new("TextButton")
pinbtn.Name = randomString()
pinbtn.Size = UDim2.new(0, 22, 0, 22)
pinbtn.Position = UDim2.new(1, -58, 0.5, -11)
pinbtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
pinbtn.BackgroundTransparency = 0.7
pinbtn.AutoButtonColor = false
pinbtn.Text = ""
pinbtn.BorderSizePixel = 0
pinbtn.ZIndex = 3
pinbtn.Archivable = false
pinbtn.Parent = header
RoundCorner(pinbtn, 0, 6)
MakePinIcon(pinbtn, 14, 4, Color3.fromRGB(210, 210, 210))
pinbtn.Activated:Connect(function()
 if config.DockSide then undock() else ApplyDock(nearestSide(main)) end
end)

local body = Instance.new("Frame")
body.Name = randomString()
body.Size = UDim2.new(1, 0, 1, -65)
body.Position = UDim2.new(0, 0, 0, 65)
body.BackgroundTransparency = 1
body.ZIndex = 3
body.Archivable = false
body.Parent = main

local scrolling = Instance.new("Frame")
scrolling.Name = randomString()
scrolling.Size = UDim2.new(1, -24, 1, 0)
scrolling.Position = UDim2.new(0, 0, 0, 0)
scrolling.BackgroundTransparency = 1
scrolling.ClipsDescendants = true
scrolling.ZIndex = 3
scrolling.Archivable = false
scrolling.Parent = body

local vbar = Instance.new("Frame")
vbar.Name = randomString()
vbar.Size = UDim2.new(0, 24, 1, 0)
vbar.Position = UDim2.new(1, -24, 0, 0)
vbar.BackgroundTransparency = 1
vbar.BorderSizePixel = 0
vbar.Active = true
vbar.Visible = false
vbar.ZIndex = 9
vbar.Archivable = false
vbar.Parent = body

local vthumb = Instance.new("Frame")
vthumb.Name = randomString()
vthumb.Size = UDim2.new(1, 0, 0.2, 0)
vthumb.BackgroundTransparency = 1
vthumb.BorderSizePixel = 0
vthumb.Active = false
vthumb.ZIndex = 10
vthumb.Archivable = false
vthumb.Parent = vbar

local vvis = Instance.new("Frame")
vvis.Name = randomString()
vvis.Size = UDim2.new(0, 12, 1, 0)
vvis.Position = UDim2.new(1, -14, 0, 0)
vvis.BackgroundColor3 = Color3.fromRGB(90,90,90)
vvis.BorderSizePixel = 0
vvis.ZIndex = 10
vvis.Active = false
vvis.Archivable = false
vvis.Parent = vthumb
RoundCorner(vvis, 1, 0)

local hbar = Instance.new("Frame")
hbar.Name = randomString()
hbar.Size = UDim2.new(1, -24, 0, 24)
hbar.Position = UDim2.new(0, 0, 1, -24)
hbar.BackgroundTransparency = 1
hbar.BorderSizePixel = 0
hbar.Active = true
hbar.Visible = false
hbar.ZIndex = 9
hbar.Archivable = false
hbar.Parent = body

local hthumb = Instance.new("Frame")
hthumb.Name = randomString()
hthumb.Size = UDim2.new(0.2, 0, 1, 0)
hthumb.BackgroundTransparency = 1
hthumb.BorderSizePixel = 0
hthumb.Active = false
hthumb.ZIndex = 10
hthumb.Archivable = false
hthumb.Parent = hbar

local hvis = Instance.new("Frame")
hvis.Name = randomString()
hvis.Size = UDim2.new(1, 0, 0, 12)
hvis.Position = UDim2.new(0, 0, 1, -14)
hvis.BackgroundColor3 = Color3.fromRGB(90,90,90)
hvis.BorderSizePixel = 0
hvis.ZIndex = 10
hvis.Active = false
hvis.Archivable = false
hvis.Parent = hthumb
RoundCorner(hvis, 1, 0)

local emptyLabel = Instance.new("TextLabel")
emptyLabel.Name = randomString()
emptyLabel.Size = UDim2.new(1, 0, 0, 40)
emptyLabel.Position = UDim2.new(0, 0, 0, 40)
emptyLabel.BackgroundTransparency = 1
emptyLabel.Text = ""
emptyLabel.TextColor3 = COLORS.TEXT_DIM
emptyLabel.FontFace = FONT.GothamMedium
emptyLabel.TextSize = 11
emptyLabel.TextWrapped = true
emptyLabel.Visible = false
emptyLabel.ZIndex = 4
emptyLabel.Archivable = false
emptyLabel.Parent = scrolling

local insertBtn = Instance.new("TextButton")
insertBtn.Name = randomString()
insertBtn.Size = UDim2.new(0, 18, 0, 18)
insertBtn.BackgroundTransparency = 1
insertBtn.BorderSizePixel = 0
insertBtn.AutoButtonColor = false
insertBtn.Text = ""
insertBtn.Visible = false
insertBtn.ZIndex = 6
insertBtn.Archivable = false
insertBtn.Parent = scrolling

do
 local ring = Instance.new("Frame")
 ring.Size = UDim2.new(0, 14, 0, 14)
 ring.Position = UDim2.new(0.5, -7, 0.5, -7)
 ring.BackgroundColor3 = Color3.fromRGB(190, 190, 190)
 ring.BorderSizePixel = 0
 ring.ZIndex = 7
 ring.Archivable = false
 ring.Parent = insertBtn
 local rc = Instance.new("UICorner")
 rc.CornerRadius = UDim.new(1, 0)
 rc.Parent = ring
 for _, d in ipairs({ { 8, 2 }, { 2, 8 } }) do
  local bar = Instance.new("Frame")
  bar.Size = UDim2.new(0, d[1], 0, d[2])
  bar.Position = UDim2.new(0.5, -d[1] / 2, 0.5, -d[2] / 2)
  bar.BackgroundColor3 = COLORS.PRIMARY
  bar.BorderSizePixel = 0
  bar.ZIndex = 7
  bar.Archivable = false
  bar.Parent = insertBtn
 end
end

local function placeInsertBtn(row, slot)
 local w = SV.TextSrv:GetTextSize(row.instance.Name, 21, Enum.Font.SourceSans, Vector2.new(10000, 26)).X
 local x = Positions.TEXT_X + row.depth * Positions.INDENT + w + 6 - config.ScrollHOffset
 insertBtn.Position = UDim2.new(0, math.max(0, x), 0, (slot - 1) * config.ROW_H + (config.ROW_H - 18) / 2)
 insertBtn.Visible = true
end

local function MakeDraggable(panel, handle, opts)
 opts = opts or {}
 local state = { Dragging = false, activeInput = nil, dragStart = nil, startPos = nil, didDrag = false, inset = Vector2.new(0, 0), cursor = nil }

 handle.InputBegan:Connect(function(inp)
  if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  if opts.blockCheck and opts.blockCheck() then return end
  state.inset = absOf(inp, handle) - Vector2.new(inp.Position.X, inp.Position.Y)
  state.cursor = nil
  if opts.onBegin then opts.onBegin(inp) end
  state.Dragging = true
  state.didDrag = false
  state.activeInput = inp
  state.dragStart = inp.Position
  state.startPos = panel.Position
 end)

 SV.UserInput.InputChanged:Connect(function(inp)
  if not state.Dragging then return end
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
  clampPanelTop(panel)
  state.cursor = Vector2.new(inp.Position.X, inp.Position.Y) + state.inset
  if opts.onDrag then opts.onDrag(state.cursor) end
 end)

 SV.UserInput.InputEnded:Connect(function(inp)
  if inp ~= state.activeInput then return end
  if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  state.Dragging = false
  state.activeInput = nil
  if opts.onEnd then opts.onEnd(state.didDrag, state.cursor) end
 end)

 return state
end

local function MakeResizeHandler(min_w, min_h, edge, xS, yS, xO, yO, wS, hS, wO, hO, z, window, blockCheck, onResize)
 local isH = edge:find("left") or edge:find("right")
 local isV = edge:find("top") or edge:find("bottom")
 local signX = edge:find("left") and -1 or 1
 local signY = edge:find("top") and -1 or 1

 local h = Instance.new("TextButton")
 h.Name = randomString()
 h.Position = UDim2.new(xS, xO, yS, yO)
 h.Size = UDim2.new(wS, wO, hS, hO)
 h.BackgroundTransparency = 1
 h.Text = ""
 h.ZIndex = z or 8
 h.Archivable = false
 h.Parent = window

 h.InputBegan:Connect(function(inp)
  if Explorer.PanelResizing[window] then return end
  if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  if config.IsMinimized and isV and window == main then return end
  if blockCheck and blockCheck() then return end

  local pos = absOf(inp, h)
  local ap, as = h.AbsolutePosition, h.AbsoluteSize
  if pos.X < ap.X or pos.X > ap.X + as.X or pos.Y < ap.Y or pos.Y > ap.Y + as.Y then return end

  Explorer.PanelResizing[window] = true
  local startMouse = inp.Position
  local startW, startH = window.Size.X.Offset, window.Size.Y.Offset
  local startPosXScale, startPosXOffset = window.Position.X.Scale, window.Position.X.Offset
  local startPosYScale, startPosYOffset = window.Position.Y.Scale, window.Position.Y.Offset

  local relCon, movCon

  relCon = SV.UserInput.InputEnded:Connect(function(i)
   if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
   relCon:Disconnect()
   if movCon then movCon:Disconnect() end
   Explorer.PanelResizing[window] = nil
  end)

  movCon = SV.UserInput.InputChanged:Connect(function(i)
   if not Explorer.PanelResizing[window] then return end
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
     newH = math.max(min_h, math.min(newH, startH + math.max(0, startTop - topInset())))
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
 if config.DockSide and layoutDocks then layoutDocks() end
end

local dockHint = Instance.new("Frame")
dockHint.Name = randomString()
dockHint.BackgroundColor3 = COLORS.ACCENT
dockHint.BackgroundTransparency = 0.75
dockHint.BorderSizePixel = 0
dockHint.Visible = false
dockHint.ZIndex = 30
dockHint.Active = false
dockHint.Archivable = false
dockHint.Parent = window
BorderStroke(dockHint, 2, 100, 160, 255)

local stackSplitter = Instance.new("TextButton")
stackSplitter.Name = randomString()
stackSplitter.BackgroundColor3 = COLORS.RESIZER
stackSplitter.BorderSizePixel = 0
stackSplitter.AutoButtonColor = false
stackSplitter.Text = ""
stackSplitter.Visible = false
stackSplitter.ZIndex = 9
stackSplitter.Archivable = false
stackSplitter.Parent = window

local function isStacked()
 return pmain ~= nil and PDock.Side ~= nil and PDock.Side == config.DockSide and main.Visible and pmain.Visible
end

layoutDocks = function()
 local scr = window.AbsoluteSize
 if scr.X <= 0 or scr.Y <= 0 then return end
 local stacked = isStacked()
 local ew = main.Size.X.Offset
 local pw = pmain and pmain.Size.X.Offset or ew
 local minH = 120
 local top = topInset()
 if stacked then
  pw = ew
  if not PDock.WasStacked or PDock.LastOrder ~= PDock.Order then PDock.Split = nil end
  PDock.WasStacked, PDock.LastOrder = true, PDock.Order
  local availH = scr.Y - top
  local defaultSplit = top + ((PDock.Order == "below") and math.floor(availH * 0.7) or math.floor(availH * 0.3))
  PDock.Split = math.clamp(PDock.Split or defaultSplit, top + minH, math.max(top + minH, scr.Y - minH))
 else
  PDock.WasStacked = false
 end
 local explorerOnTop = PDock.Order == "below"

 if config.DockSide then
  local y, h = top, scr.Y - top
  if stacked then
   if explorerOnTop then y, h = top, PDock.Split - top else y, h = PDock.Split, scr.Y - PDock.Split end
  end
  main.AnchorPoint = Vector2.new(0, 0)
  main.Position = UDim2.new(0, config.DockSide == "left" and 0 or scr.X - ew, 0, y)
  main.Size = UDim2.new(0, ew, 0, h)
 end

 if pmain and PDock.Side then
  local y, h = top, scr.Y - top
  if stacked then
   if explorerOnTop then y, h = PDock.Split, scr.Y - PDock.Split else y, h = top, PDock.Split - top end
  end
  pmain.AnchorPoint = Vector2.new(0, 0)
  pmain.Position = UDim2.new(0, PDock.Side == "left" and 0 or scr.X - pw, 0, y)
  pmain.Size = UDim2.new(0, pw, 0, h)
 end

 if pdocksplitter then
  pdocksplitter.Visible = PDock.Side ~= nil
  if PDock.Side == "left" then
   pdocksplitter.Position = UDim2.new(1, 0, 0, 0)
  else
   pdocksplitter.Position = UDim2.new(0, -3, 0, 0)
  end
 end

 stackSplitter.Visible = stacked
 if stacked then
  stackSplitter.Position = UDim2.new(0, config.DockSide == "left" and 0 or scr.X - ew, 0, PDock.Split - 1)
  stackSplitter.Size = UDim2.new(0, ew, 0, 3)
 end

 if layoutSource then layoutSource() end
end

do
 local dragging, startY, startSplit
 stackSplitter.InputBegan:Connect(function(inp)
  if not isPress(inp) then return end
  dragging = true
  startY = inp.Position.Y
  startSplit = PDock.Split or 0
 end)
 SV.UserInput.InputChanged:Connect(function(inp)
  if not dragging then return end
  if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  PDock.Split = startSplit + (inp.Position.Y - startY)
  layoutDocks()
 end)
 SV.UserInput.InputEnded:Connect(function(inp)
  if isPress(inp) then dragging = false end
 end)
end

local function dropZone(gui, cur)
 local ap, as = gui.AbsolutePosition, gui.AbsoluteSize
 if cur.X < ap.X or cur.X > ap.X + as.X or cur.Y < ap.Y or cur.Y > ap.Y + as.Y then return nil, false end
 local z = math.clamp(as.Y * 0.25, 40, 140)
 if cur.Y <= ap.Y + z then return "top", true end
 if cur.Y >= ap.Y + as.Y - z then return "bottom", true end
 return nil, true
end

local function resolveDrop(dragged, other, otherSide, otherVisible, cur)
 if not cur then return nil end
 local scr = window.AbsoluteSize
 local otherDocked = otherSide ~= nil and otherVisible
 if otherDocked then
  local zone, inside = dropZone(other, cur)
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

local function showHint(dragged, other, side, zone)
 if not side then dockHint.Visible = false return end
 local scr = window.AbsoluteSize
 if zone and other then
  local ap, as = other.AbsolutePosition, other.AbsoluteSize
  local h = as.Y / 2
  dockHint.Position = UDim2.new(0, ap.X, 0, zone == "top" and ap.Y or ap.Y + h)
  dockHint.Size = UDim2.new(0, as.X, 0, h)
 else
  local w = dragged.AbsoluteSize.X
  local inset = topInset()
  dockHint.Position = UDim2.new(0, side == "left" and 0 or scr.X - w, 0, inset)
  dockHint.Size = UDim2.new(0, w, 1, -inset)
 end
 dockHint.Visible = true
end

MakeDraggable(main, header, {
 blockCheck = function()
  return Explorer.PanelResizing[main]
 end,
 threshold = 4,
 onBegin = function()
  if config.DockSide then undock() end
 end,
 onDrag = function(cursor)
  local side, zone = resolveDrop(main, pmain, PDock.Side, pmain ~= nil and pmain.Visible, cursor)
  showHint(main, pmain, side, zone)
 end,
 onEnd = function(didDrag, cursor)
  dockHint.Visible = false
  if not didDrag then return end
  local side, zone = resolveDrop(main, pmain, PDock.Side, pmain ~= nil and pmain.Visible, cursor)
  if not side then return end
  if zone and PDock.Side == side and pmain and pmain.Visible then
   PDock.Order = (zone == "top") and "below" or "above"
  end
  ApplyDock(side)
 end,
})

MakeResizeHandler(220, 160, "right", 1,0, 0, config.EDGE, 0,1, config.EDGE*2, -config.EDGE*2, 8, main, function() return config.DockSide == "right" end, SyncMainResize)
MakeResizeHandler(220, 160, "left", 0,0, -config.EDGE*2, config.EDGE, 0,1, config.EDGE*2, -config.EDGE*2, 8, main, function() return config.DockSide == "left" end, SyncMainResize)
MakeResizeHandler(220, 160, "bottom", 0,1, config.EDGE, 0, 1,0, -config.EDGE*2, config.EDGE*2, 8, main, function() return config.DockSide ~= nil end, SyncMainResize)
MakeResizeHandler(220, 160, "top", 0,0, config.EDGE, -config.EDGE*2, 1,0, -config.EDGE*2, config.EDGE*2, 8, main, function() return config.DockSide ~= nil end, SyncMainResize)
MakeResizeHandler(220, 160, "top_left", 0,0, -config.EDGE*2, -config.EDGE*2, 0,0, config.EDGE*2, config.EDGE*2, 9, main, function() return config.DockSide ~= nil end, SyncMainResize)
MakeResizeHandler(220, 160, "top_right", 1,0, 0, -config.EDGE*2, 0,0, config.EDGE*2, config.EDGE*2, 9, main, function() return config.DockSide ~= nil end, SyncMainResize)
MakeResizeHandler(220, 160, "bottom_left", 0,1, -config.EDGE*2, 0, 0,0, config.EDGE*2, config.EDGE*2, 9, main, function() return config.DockSide ~= nil end, SyncMainResize)
MakeResizeHandler(220, 160, "bottom_right", 1,1, 0, 0, 0,0, config.EDGE*2, config.EDGE*2, 9, main, function() return config.DockSide ~= nil end, SyncMainResize)

do
local Drag = {
 pending = nil, active = false, list = nil, target = nil,
 startPos = nil, justDragged = false, hb = nil, cursor = Vector2.new(0, 0),
}
local DRAG_THRESHOLD = 6
local GHOST_MAX_W = 320

local dragGhost = Instance.new("Frame")
dragGhost.Name = randomString()
dragGhost.Size = UDim2.new(0, 220, 0, config.ROW_H)
dragGhost.BackgroundColor3 = COLORS.SELECTED
dragGhost.BackgroundTransparency = 0.25
dragGhost.BorderSizePixel = 0
dragGhost.Visible = false
dragGhost.Active = false
dragGhost.ZIndex = 60
dragGhost.Archivable = false
dragGhost.Parent = window
local dragIcon, dragLabel, dragBadge
do
 local gc = Instance.new("UICorner")
 gc.CornerRadius = UDim.new(0, 8)
 gc.Parent = dragGhost
 local gs = Instance.new("UIStroke")
 gs.Color = COLORS.ACCENT
 gs.Thickness = 1
 gs.Parent = dragGhost
 dragIcon = Instance.new("ImageLabel")
 dragIcon.Name = randomString()
 dragIcon.Size = UDim2.new(0, Positions.ICON_PX, 0, Positions.ICON_PX)
 dragIcon.Position = UDim2.new(0, 8, 0.5, -Positions.ICON_PX / 2)
 dragIcon.BackgroundTransparency = 1
 dragIcon.ZIndex = 61
 dragIcon.Active = false
 dragIcon.Parent = dragGhost
 dragLabel = Instance.new("TextLabel")
 dragLabel.Name = randomString()
 dragLabel.Size = UDim2.new(1, -(8 + Positions.ICON_PX + 8 + 8), 1, 0)
 dragLabel.Position = UDim2.new(0, 8 + Positions.ICON_PX + 8, 0, 0)
 dragLabel.BackgroundTransparency = 1
 dragLabel.TextColor3 = COLORS.TEXT_BRIGHT
 dragLabel.TextXAlignment = Enum.TextXAlignment.Left
 dragLabel.Font = Enum.Font.SourceSans
 dragLabel.TextSize = 21
 dragLabel.TextTruncate = Enum.TextTruncate.AtEnd
 dragLabel.ZIndex = 61
 dragLabel.Active = false
 dragLabel.Parent = dragGhost
 dragBadge = Instance.new("TextLabel")
 dragBadge.Name = randomString()
 dragBadge.AnchorPoint = Vector2.new(1, 0.5)
 dragBadge.Size = UDim2.new(0, 22, 0, 18)
 dragBadge.Position = UDim2.new(1, -6, 0.5, 0)
 dragBadge.BackgroundColor3 = COLORS.ACCENT
 dragBadge.TextColor3 = COLORS.TEXT_BRIGHT
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
dropHL.Name = randomString()
dropHL.BackgroundColor3 = COLORS.ACCENT
dropHL.BackgroundTransparency = 0.8
dropHL.BorderSizePixel = 0
dropHL.Visible = false
dropHL.Active = false
dropHL.ZIndex = 6
dropHL.Archivable = false
dropHL.Parent = scrolling
do
 local hc = Instance.new("UICorner")
 hc.CornerRadius = UDim.new(0, 8)
 hc.Parent = dropHL
 local hs = Instance.new("UIStroke")
 hs.Color = COLORS.ACCENT
 hs.Thickness = 1.5
 hs.Parent = dropHL
end

local function dragCursor(inp)
 if inp.UserInputType == Enum.UserInputType.Touch then
  local ok, gi = pcall(function() return SV.Gui:GetGuiInset() end)
  return Vector2.new(inp.Position.X, inp.Position.Y) + ((ok and gi) or Vector2.new(0, 0))
 end
 return SV.UserInput:GetMouseLocation()
end

local function dragWarn(where, err)
 warn("[Explorer drag] " .. where .. ": " .. tostring(err))
end

local function dragTopLevel(list)
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

local function canDropOn(list, target)
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

local function dragTargetAt(cur)
 local ap, as = scrolling.AbsolutePosition, scrolling.AbsoluteSize
 if cur.X < ap.X or cur.X > ap.X + as.X or cur.Y < ap.Y or cur.Y > ap.Y + as.Y then return nil end
 local idx = math.floor((cur.Y - ap.Y) / config.ROW_H) + 1 + config.ScrollIndex
 local row = config.visiblerows[idx]
 if not row then return nil end
 return row.instance, idx
end

local function dragUpdate()
 local cur = Drag.cursor
 local g = Drag.grab or Vector2.new(20, config.ROW_H / 2)
 dragGhost.Position = UDim2.fromOffset(cur.X - g.X, cur.Y - g.Y)
 local target, idx = dragTargetAt(cur)
 if target and canDropOn(Drag.list, target) then
  Drag.target = target
  dropHL.Position = UDim2.new(0, 0, 0, (idx - 1 - config.ScrollIndex) * config.ROW_H)
  dropHL.Size = UDim2.new(1, 0, 0, config.ROW_H)
  dropHL.Visible = true
 else
  Drag.target = nil
  dropHL.Visible = false
 end
end

local function dragStop()
 Drag.pending = nil
 Drag.active = false
 Drag.list = nil
 Drag.target = nil
 Drag.grab = nil
 dragGhost.Visible = false
 dropHL.Visible = false
 if Drag.hb then Drag.hb:Disconnect() Drag.hb = nil end
end

local function dragBegin()
 local inst = Drag.pending.inst
 local list
 if Explorer.SelectedSet[inst] then
  list = dragTopLevel(Explorer.GetSelection())
 else
  list = dragTopLevel({ inst })
  if #list > 0 then Explorer.SetSelection(list, inst) end
 end
 if #list == 0 then Drag.pending = nil return end
 Drag.list = list
 Drag.active = true
 do
  local first = list[1]
  applyIcon(dragIcon, first.ClassName)
  dragLabel.Text = first.Name
  dragBadge.Visible = #list > 1
  dragBadge.Text = tostring(#list)
  local pw = Drag.pending.rowWidth or 220
  dragGhost.Size = UDim2.new(0, math.clamp(pw, 160, GHOST_MAX_W), 0, config.ROW_H)
  local gx = (Drag.pending.grabX or 20)
  Drag.grab = Vector2.new(math.clamp(gx, 0, dragGhost.Size.X.Offset), config.ROW_H / 2)
 end
 dragGhost.Visible = true
 if Drag.pending.cancelHold then Drag.pending.cancelHold() end

 local acc = 0
 Drag.hb = SV.RunSrv.Heartbeat:Connect(function(dt)
  if not Drag.active then return end
  local ap, as = scrolling.AbsolutePosition, scrolling.AbsoluteSize
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
    dragUpdate()
   end
  else
   acc = 0
  end
 end)
 dragUpdate()
end

SV.UserInput.InputChanged:Connect(function(inp)
 local p = Drag.pending
 if not p then return end
 local okc, errc = pcall(function()
 local t = inp.UserInputType
 if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end
 Drag.cursor = dragCursor(inp)
 if not Drag.active then
  if (Vector2.new(inp.Position.X, inp.Position.Y) - Drag.startPos).Magnitude < DRAG_THRESHOLD then return end
  dragBegin()
  if not Drag.active then return end
 end
 dragUpdate()
 end)
 if not okc then dragWarn("move", errc) dragStop() end
end)

SV.UserInput.InputEnded:Connect(function(inp)
 if not isPress(inp) then return end
 if not Drag.pending then return end
 if Drag.active then
  local target, list = Drag.target, Drag.list
  Drag.justDragged = true
  task.delay(0.2, function() Drag.justDragged = false end)
  dragStop()
  if target and list and canDropOn(list, target) and Explorer.MoveInstances then
   local okm, errm = pcall(Explorer.MoveInstances, list, target)
   if not okm then dragWarn("drop", errm) end
  end
 else
  Drag.pending = nil
 end
end)

SV.UserInput.InputBegan:Connect(function(inp)
 if Drag.active and inp.KeyCode == Enum.KeyCode.Escape then
  Drag.justDragged = true
  task.delay(0.2, function()
   Drag.justDragged = false
  end)
  dragStop()
 end
end)
Drag.cursorOf = dragCursor
Explorer.Drag = Drag
end

local function CreatePoolEntry(poolIndex)
 local entry = Instance.new("TextButton")
 entry.Name = randomString()
 entry.Size = UDim2.new(0, 100, 0, config.ROW_H)
 entry.BackgroundColor3 = COLORS.SELECTED
 entry.BackgroundTransparency = 1
 entry.Text = ""
 entry.Visible = false
 entry.ZIndex = 3
 entry.Archivable = false
 entry.Parent = scrolling

 local corner = Instance.new("UICorner")
 corner.CornerRadius = UDim.new(0, 8)
 corner.Parent = entry

 local bottomMask = Instance.new("Frame")
 bottomMask.Name = randomString()
 bottomMask.BorderSizePixel = 0
 bottomMask.BackgroundColor3 = entry.BackgroundColor3
 bottomMask.BackgroundTransparency = 1
 bottomMask.ZIndex = entry.ZIndex
 bottomMask.Visible = false
 bottomMask.Archivable = false
 bottomMask.Parent = scrolling

 local toggle = Instance.new("ImageButton")
 toggle.Name = randomString()
 toggle.Size = UDim2.new(0, 16, 0, 16)
 toggle.BackgroundTransparency = 1
 toggle.Image = "rbxassetid://81462102154124"
 toggle.ZIndex = 5
 toggle.Active = true
 toggle.AutoButtonColor = false
 toggle.Archivable = false
 toggle.Parent = scrolling

 local icon = Instance.new("ImageLabel")
 icon.Name = randomString()
 icon.Size = UDim2.new(0, Positions.ICON_PX, 0, Positions.ICON_PX)
 icon.BackgroundTransparency = 1
 icon.Image = ICON_ID
 icon.ImageRectSize = ICON_SIZE
 icon.ZIndex = 4
 icon.Archivable = false
 icon.Parent = scrolling

 local label = Instance.new("TextLabel")
 label.Name = randomString()
 label.BackgroundTransparency = 1
 label.TextColor3 = COLORS.TEXT
 label.TextXAlignment = Enum.TextXAlignment.Left
 label.TextYAlignment = Enum.TextYAlignment.Center
 label.Font = Enum.Font.SourceSans
 label.TextSize = 21
 label.TextTruncate = Enum.TextTruncate.AtEnd
 label.ZIndex = 4
 label.Archivable = false
 label.Parent = scrolling

 local holdThread, holdStartPos
 local data = { inst = nil, row = nil, mask = bottomMask, holdTriggered = false, hovering = false, highlighted = false }

 local function onHoverEnter()
  local inst = data.inst
  if not inst then return end
  data.hovering = true
  if not data.highlighted then
   entry.BackgroundColor3 = COLORS.SECONDARY
   entry.BackgroundTransparency = 0.6
  elseif Explorer.SelectedSet[inst] then
   entry.BackgroundColor3 = COLORS.SELECTED_HOVER
   entry.BackgroundTransparency = 0
  else
   entry.BackgroundColor3 = COLORS.SELECTED
   entry.BackgroundTransparency = 0.7
  end
  bottomMask.BackgroundColor3 = entry.BackgroundColor3
  bottomMask.BackgroundTransparency = entry.BackgroundTransparency
  config.HoverInst = inst
  config.InsertTarget = inst
  placeInsertBtn(data.row, poolIndex)
 end
 local function onHoverLeave()
  data.hovering = false
  if not data.highlighted then
   entry.BackgroundColor3 = COLORS.SELECTED
   entry.BackgroundTransparency = 1
  else
   local sel = data.inst and Explorer.SelectedSet[data.inst] == true
   entry.BackgroundColor3 = COLORS.SELECTED
   entry.BackgroundTransparency = sel and 0 or 0.85
  end
  bottomMask.BackgroundColor3 = entry.BackgroundColor3
  bottomMask.BackgroundTransparency = entry.BackgroundTransparency
  config.HoverInst = nil
  task.defer(function()
   if not config.OverInsert and not config.HoverInst then insertBtn.Visible = false end
  end)
 end
 local inEntry, inMask = false, false
 local function refreshHover()
  local want = inEntry or inMask
  if want and not data.hovering then onHoverEnter()
  elseif not want and data.hovering then onHoverLeave() end
 end
 data.clearMaskHover = function()
  if inMask then inMask = false; refreshHover() end
 end
 entry.MouseEnter:Connect(function() inEntry = true; refreshHover() end)
 entry.MouseLeave:Connect(function() inEntry = false; refreshHover() end)
 bottomMask.MouseEnter:Connect(function() inMask = true; refreshHover() end)
 bottomMask.MouseLeave:Connect(function() inMask = false; refreshHover() end)
 config.pooldata[poolIndex] = data

 entry.InputBegan:Connect(function(inp)
  local inst = data.inst
  if not inst then return end
  if inp.UserInputType == Enum.UserInputType.MouseButton2 then
   if OpenContextMenu then OpenContextMenu(inst, inp.Position.X, inp.Position.Y) end
   return
  end
  if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end

  holdStartPos = inp.Position
  if inst.Parent ~= Explorer.Root then
   Explorer.Drag.pending = {
    inst = inst,
    grabX = Explorer.Drag.cursorOf(inp).X - entry.AbsolutePosition.X,
    rowWidth = entry.AbsoluteSize.X,
    cancelHold = function()
     if holdThread then task.cancel(holdThread) holdThread = nil end
    end,
   }
   Explorer.Drag.startPos = Vector2.new(inp.Position.X, inp.Position.Y)
   Explorer.Drag.cursor = Explorer.Drag.cursorOf(inp)
  end
  if holdThread then task.cancel(holdThread) end
  holdThread = task.delay(0.4, function()
   holdThread = nil
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
  local shift = SV.UserInput:IsKeyDown(Enum.KeyCode.LeftShift) or SV.UserInput:IsKeyDown(Enum.KeyCode.RightShift)
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
  line.Name = randomString()
  line.BorderSizePixel = 0
  line.BackgroundColor3 = COLORS.WHITE
  line.BackgroundTransparency = 0.9
  line.ZIndex = 3
  line.Archivable = false
  line.Parent = scrolling
  table.insert(config.guideLines, line)
 end
 return config.guideLines[n]
end

local SUBCLASS = {
 basepart = {Part=1,MeshPart=1,UnionOperation=1,WedgePart=1,CornerWedgePart=1,TrussPart=1,SpawnLocation=1,Seat=1,VehicleSeat=1},
 luasourcecontainer = {Script=1,LocalScript=1,ModuleScript=1},
 guiobject = {Frame=1,TextLabel=1,TextButton=1,TextBox=1,ImageLabel=1,ImageButton=1,ScrollingFrame=1,ViewportFrame=1,CanvasGroup=1},
 guibutton = {TextButton=1,ImageButton=1},
 light = {PointLight=1,SpotLight=1,SurfaceLight=1},
 pvinstance = {Model=1,Part=1,MeshPart=1,UnionOperation=1,WedgePart=1,CornerWedgePart=1,TrussPart=1,SpawnLocation=1,Seat=1,VehicleSeat=1,WorldModel=1},
}

local function isA(inst, cls)
 local c = inst.ClassName:lower()
 if c == cls or cls == "instance" then return true end
 local set = SUBCLASS[cls]
 if set and set[inst.ClassName] then return true end
 if cls == "valuebase" and c:match("value$") then return true end
 if cls == "constraint" and c:match("constraint$") then return true end
 if cls == "soundeffect" and c:match("soundeffect$") then return true end
 if cls == "posteffect" and c:match("effect$") and not c:match("soundeffect$") then return true end
 return false
end

local function hasTag(inst, tag)
 local t = inst.Tags
 if type(t) ~= "table" then return false end
 for k, v in pairs(t) do
  if type(k) == "string" and v == true and k:lower() == tag then return true end
  if type(v) == "string" and v:lower() == tag then return true end
 end
 return false
end

local function getProp(inst, key)
 local k = key:lower()
 if k == "name" then return inst.Name end
 if k == "classname" then return inst.ClassName end
 for pk, pv in pairs(inst.Properties) do
  if tostring(pk):lower() == k then return pv end
 end
 for ak, av in pairs(inst.Attributes) do
  if tostring(ak):lower() == k then return av end
 end
 return nil
end

local LCLS = {}
local function lcls(c)
 local l = LCLS[c]
 if not l then l = c:lower() LCLS[c] = l end
 return l
end

local function lname(inst)
 local nm = inst.Name
 if inst._lnSrc ~= nm then
  inst._lnSrc = nm
  inst._ln = tostring(nm):lower()
 end
 return inst._ln
end

local function normVal(v) return (tostring(v):lower():gsub("%s", "")) end
local function unquote(v) return (v:gsub('"', "")) end

local function tokenize(str)
 str = str:gsub("%s*([<>=!~]+)%s*", "%1")
 local toks, cur, inQ = {}, "", false
 local function push() if cur ~= "" then toks[#toks + 1] = cur cur = "" end end
 for i = 1, #str do
  local ch = str:sub(i, i)
  if ch == '"' then
   inQ = not inQ
   cur = cur .. ch
  elseif inQ then
   cur = cur .. ch
  elseif ch == "(" or ch == ")" then
   push()
   toks[#toks + 1] = ch
  elseif ch:match("%s") then
   push()
  else
   cur = cur .. ch
  end
 end
 push()
 return toks
end

local function parentOf(n)
 local p = n.Parent
 if p == Explorer.Root then return nil end
 return p
end

local function makeAtom(t)
 local key, op, val = t:match('^([%w_]+)([<>=!~]+)(.+)$')
 if key and not t:find('^"') then
  val = unquote(val)
  return function(inst)
   local pv = getProp(inst, key)
   if op == "=" or op == "==" then
    return pv ~= nil and normVal(pv):find(normVal(val), 1, true) ~= nil
   elseif op == "!=" or op == "~=" then
    return pv == nil or normVal(pv):find(normVal(val), 1, true) == nil
   end
   local a, b = tonumber(pv), tonumber(val)
   if not a or not b then return false end
   if op == "<" then return a < b
   elseif op == ">" then return a > b
   elseif op == "<=" then return a <= b
   elseif op == ">=" then return a >= b end
   return false
  end
 end

 local pfx, rest = t:match('^(%a+):(.*)$')
 if pfx then
  local p = pfx:lower()
  rest = unquote(rest):lower()
  if p == "classname" or p == "class" then
   return function(inst) return lcls(inst.ClassName):find(rest, 1, true) ~= nil end
  elseif p == "is" then
   return function(inst) return isA(inst, rest) end
  elseif p == "tag" then
   return function(inst) return hasTag(inst, rest) end
  elseif p == "name" then
   return function(inst) return lname(inst):find(rest, 1, true) ~= nil end
  end
 end

 if t:find(".", 1, true) and not t:find('"') then
  local segs = {}
  for part in (t .. "."):gmatch("([^%.]*)%.") do segs[#segs + 1] = part:lower() end
  local ok = #segs >= 2
  for _, sg in ipairs(segs) do if sg == "" then ok = false end end
  if ok then
   local function m(node, i)
    if i == 0 then return true end
    local sg = segs[i]
    if sg == "**" then
     local cur = node
     while cur do
      if m(parentOf(cur), i - 1) then return true end
      cur = parentOf(cur)
     end
     return false
    end
    if not node then return false end
    if sg ~= "*" and not lname(node):find(sg, 1, true) then return false end
    return m(parentOf(node), i - 1)
   end
   return function(inst) return m(inst, #segs) end
  end
 end

 local q = unquote(t):lower()
 return function(inst) return lname(inst):find(q, 1, true) ~= nil end
end

function Explorer.CompileSearch(str)
 str = str:match("^%s*(.-)%s*$")
 if str == "" then return nil end
 local toks, pos = tokenize(str), 1
 local parseOr
 local function isKw(t, kw) return t ~= nil and t:lower() == kw end
 local function parsePrimary()
  local t = toks[pos]
  if not t or t == ")" or isKw(t, "and") or isKw(t, "or") then return nil end
  pos += 1
  if t == "(" then
   local e = parseOr()
   if toks[pos] == ")" then pos += 1 end
   return e
  end
  return makeAtom(t)
 end
 local function parseAnd()
  local left = parsePrimary()
  if not left then return nil end
  while true do
   local t = toks[pos]
   if not t or t == ")" or isKw(t, "or") then break end
   if isKw(t, "and") then pos += 1 end
   local right = parsePrimary()
   if not right then break end
   local l, r = left, right
   left = function(i) return l(i) and r(i) end
  end
  return left
 end
 parseOr = function()
  local left = parseAnd() or function() return true end
  while isKw(toks[pos], "or") do
   pos += 1
   local right = parseAnd()
   if not right then break end
   local l, r = left, right
   left = function(i) return l(i) or r(i) end
  end
  return left
 end
 local ok, pred = pcall(parseOr)
 if ok then return pred end
 local q = str:lower()
 return function(inst) return lname(inst):find(q, 1, true) ~= nil end
end

local function readInfo(i) return i.Name, i.ClassName end

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
  if c ~= folder then
   local ok, name, class = pcall(readInfo, c)
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
   if h and r == folder then
    local ok2, k = pcall(real.GetChildren, real)
    h = ok2 and #k > 1
   end
   inst.HasKids = h
  end
  return h
 end
 return false
end

local function nameWidth(inst)
 local nm = inst.Name
 if inst._wSrc == nm then return inst._w end
 local w = SV.TextSrv:GetTextSize(nm, 13, Enum.Font.Gotham, Vector2.new(10000, 26)).X
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

 local function matches(inst)
  if not searching or not pred then return true end
  local m = matchMemo[inst]
  if m == nil then
   m = pred(inst) == true
   matchMemo[inst] = m
  end
  return m
 end

 local function isAncestorOfMatch(inst)
  local a = ancMemo[inst]
  if a ~= nil then return a end
  a = false
  local kids = inst.Children
  for i = 1, #kids do
   local c = kids[i]
   if matches(c) or isAncestorOfMatch(c) then a = true break end
  end
  ancMemo[inst] = a
  return a
 end

 local Expanded, SearchOpen = Explorer.Expanded, Explorer.SearchOpen

 local function traverse(inst, depth, showAll)
  if inst.Real and not inst.Loaded then Explorer.LoadChildren(inst) end
  local kids = sortedChildren(inst)
  for i = 1, #kids do
   local child = kids[i]
   local m = matches(child)
   local anc = (searching and isAncestorOfMatch(child)) or false
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
    if expanded then traverse(child, depth + 1, childShowAll or (showAll and searching)) end
   end
  end
 end
 traverse(Explorer.Root, 0)

 local index, nRows = {}, #rows
 local INDENT = Positions.INDENT
 local bestEst, bestRow = -1, nil
 for i = 1, nRows do
  local row = rows[i]
  local inst = row.instance
  index[inst] = i
  local est = row.depth * INDENT + #inst.Name * 8
  if est > bestEst then bestEst, bestRow = est, row end
 end
 Explorer.RowIndex = index
 config.TreeWidthBase = bestRow and (bestRow.depth * INDENT + 44 + nameWidth(bestRow.instance) + 60) or 0
 config.TreeWidthRow = bestRow
 emptyLabel.Visible = (nRows == 0)
end

local function appendSubtree(out, inst, depth)
 if inst.Real and not inst.Loaded then Explorer.LoadChildren(inst) end
 local kids = sortedChildren(inst)
 local Expanded = Explorer.Expanded
 local n = #out
 for i = 1, #kids do
  local child = kids[i]
  local expanded = Expanded[child] == true
  n += 1
  out[n] = { instance = child, depth = depth, expanded = expanded, searchLeaf = false, match = false }
  if expanded then appendSubtree(out, child, depth + 1) n = #out end
 end
end

local function fastRebuild(inst)
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
 if expanded then appendSubtree(fresh, inst, depth + 1) end
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

 local INDENT = Positions.INDENT
 if lostWidthRow or not widthRow then
  local bestEst, bestRow = -1, nil
  for i = 1, newN do
   local r = rows[i]
   local est = r.depth * INDENT + #r.instance.Name * 8
   if est > bestEst then bestEst, bestRow = est, r end
  end
  config.TreeWidthRow = bestRow
  config.TreeWidthBase = bestRow and (bestRow.depth * INDENT + 44 + nameWidth(bestRow.instance) + 60) or 0
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
   config.TreeWidthBase = bestRow.depth * INDENT + 44 + nameWidth(bestRow.instance) + 60
  end
 end
 emptyLabel.Visible = (newN == 0)
 return true
end

function Explorer.ExpandRow(idx, row, inst)
 Explorer.Expanded[inst] = true
 if config.SearchQuery ~= "" then Explorer.SearchOpen[inst] = true end
 if not fastRebuild(inst) then Explorer.ScanTree() end
 RefreshTree()
end

function Explorer.CollapseRow(idx, row, inst)
 Explorer.Expanded[inst] = nil
 if config.SearchQuery ~= "" then Explorer.SearchOpen[inst] = false end
 if not fastRebuild(inst) then Explorer.ScanTree() end
 RefreshTree()
end

function RefreshTree()
 if config.IsMinimized then return end

 local maxW = config.TreeWidthBase or 0
 do
  local vr = config.visiblerows
  local from = config.ScrollIndex + 1
  local to = math.min(#vr, from + math.ceil(body.AbsoluteSize.Y / config.ROW_H) + 2)
  for i = from, to do
   local row = vr[i]
   local needed = row.depth * Positions.INDENT + 44 + nameWidth(row.instance) + 60
   if needed > maxW then maxW = needed end
  end
 end
 config.TreeContentWidth = maxW

 local viewW = body.AbsoluteSize.X - 24
 local needH = config.TreeContentWidth > viewW
 local gutterH = needH and -24 or 0
 scrolling.Size = UDim2.new(1, -24, 1, gutterH)
 vbar.Size = UDim2.new(0, 24, 1, gutterH)
 local viewH = body.AbsoluteSize.Y + gutterH
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
   local indentation = depth * Positions.INDENT

   local hasKids = (not row.searchLeaf) and Explorer.HasChildren(inst)

   local isHighlighted = highlightCache[i] or false
   local isSelected = Explorer.SelectedSet[inst] == true
   data.highlighted = isHighlighted

   e.toggle.Position = UDim2.new(0, Positions.ARROW_X - 4 + indentation - config.ScrollHOffset, 0, (i-0.8)*config.ROW_H + (config.ROW_H-26)/2)
   e.toggle.Visible = hasKids
   e.toggle.Rotation = row.expanded and 90 or 0

   e.entry.Visible = true
   e.icon.Visible = true
   e.label.Visible = true
   e.entry.Position = UDim2.new(0, -config.ScrollHOffset, 0, (i-1)*config.ROW_H)
   e.entry.Size = UDim2.new(0, viewW + config.ScrollHOffset, 0, config.ROW_H)

   if isHighlighted then
    e.entry.BackgroundColor3 = COLORS.SELECTED
    e.entry.BackgroundTransparency = isSelected and 0 or 0.85
    if data.hovering then
     if isSelected then
      e.entry.BackgroundColor3 = COLORS.SELECTED_HOVER
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
    if not e.mask.Visible and data.clearMaskHover then data.clearMaskHover() end
    if e.mask.Visible then
     e.mask.BackgroundColor3 = e.entry.BackgroundColor3
     e.mask.BackgroundTransparency = e.entry.BackgroundTransparency
     e.mask.Position = UDim2.new(0, -config.ScrollHOffset, 0, (i-1)*config.ROW_H + config.ROW_H - 8)
     e.mask.Size = UDim2.new(0, viewW + config.ScrollHOffset, 0, 8)
    end
   else
    if data.hovering then
     e.entry.BackgroundColor3 = COLORS.SECONDARY
     e.entry.BackgroundTransparency = 0.6
    else
     e.entry.BackgroundColor3 = COLORS.SELECTED
     e.entry.BackgroundTransparency = 1
    end
    e.corner.CornerRadius = UDim.new(0, 0)
    e.mask.Visible = false
    if data.clearMaskHover then data.clearMaskHover() end
   end

   e.icon.Position = UDim2.new(0, Positions.ICON_X + indentation - config.ScrollHOffset, 0, (i-1)*config.ROW_H + (config.ROW_H - Positions.ICON_PX)/2)
   local cls = inst.ClassName
   local userIcon = Explorer.UserIcons[cls]
   if data.iconCls ~= cls or data.iconUser ~= userIcon then
    data.iconCls, data.iconUser = cls, userIcon
    applyIcon(e.icon, cls)
   end

   e.label.Position = UDim2.new(0, Positions.TEXT_X + indentation - config.ScrollHOffset, 0, (i-1)*config.ROW_H)
   e.label.Size = UDim2.new(0, math.max(rowW, viewW) - Positions.TEXT_X - indentation - 8, 0, config.ROW_H)
   local newText = escape(inst.Name):gsub("%s+", " ")
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
  line.Position = UDim2.new(0, Positions.ARROW_X - 9 + depth*Positions.INDENT + 13 - config.ScrollHOffset, 0, startIdx*config.ROW_H)
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
  vbar.Visible = true
  local thumbFrac = math.clamp(math.floor(viewH / config.ROW_H) / totalRows, 0.05, 0.85)
  vthumb.Size = UDim2.new(1, 0, thumbFrac, 0)
  local posFrac = maxIndex > 0 and math.clamp((config.ScrollIndex / maxIndex) * (1 - thumbFrac), 0, 1 - thumbFrac) or 0
  vthumb.Position = UDim2.new(0, 0, posFrac, 0)
 else
  vbar.Visible = false
 end

 if config.TreeContentWidth > viewW then
  hbar.Visible = true
  local thumbFrac = math.clamp(viewW / config.TreeContentWidth, 0.05, 0.85)
  hthumb.Size = UDim2.new(thumbFrac, 0, 1, 0)
  local posFrac = maxHOffset > 0 and math.clamp((config.ScrollHOffset / maxHOffset) * (1 - thumbFrac), 0, 1 - thumbFrac) or 0
  hthumb.Position = UDim2.new(posFrac, 0, 0, 0)
 else
  hbar.Visible = false
 end

 local hi = config.HoverInst and Explorer.RowIndex and Explorer.RowIndex[config.HoverInst]
 local hrow = hi and (hi - config.ScrollIndex)
 if hrow and hrow >= 1 and hrow <= #config.entries then
  placeInsertBtn(config.visiblerows[hi], hrow)
 elseif not config.OverInsert then
  insertBtn.Visible = false
 end
end

SV.UserInput.InputChanged:Connect(function(input)
 if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
 if not main.Visible or config.IsMinimized then return end
 local delta = input.Position.Z
 if delta == 0 then return end
 local mp = SV.UserInput:GetMouseLocation()
 local ap = main.AbsolutePosition
 local as = main.AbsoluteSize
 if mp.X < ap.X or mp.X > ap.X + as.X or mp.Y < ap.Y or mp.Y > ap.Y + as.Y then return end
 local viewH = scrolling.AbsoluteSize.Y
 local maxIdx = math.max(0, #config.visiblerows - math.floor(viewH / config.ROW_H))
 config.ScrollIndex = math.clamp(config.ScrollIndex - delta * 3, 0, maxIdx)
 RefreshTree()
end)

local function Draggable(thumb, track, isHorizontal, vis)
 local dragging, startPos, startScroll
 local hovering = false
 local function paint()
  vis.BackgroundColor3 = (dragging or hovering) and Color3.fromRGB(140,140,140) or Color3.fromRGB(90,90,90)
 end
 local function maxScroll()
  if isHorizontal then return math.max(0, config.TreeContentWidth - scrolling.AbsoluteSize.X) end
  return math.max(0, #config.visiblerows - math.floor(scrolling.AbsoluteSize.Y / config.ROW_H))
 end
 local function current() return isHorizontal and config.ScrollHOffset or config.ScrollIndex end
 local function apply(v)
  local m = maxScroll()
  if isHorizontal then
   config.ScrollHOffset = math.clamp(v, 0, m)
  else
   config.ScrollIndex = math.clamp(math.floor(v + 0.5), 0, m)
  end
  RefreshTree()
 end
 local function isPress(inp)
  return inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch
 end

 thumb.Active = true
 thumb.InputBegan:Connect(function(inp)
  if not isPress(inp) then return end
  if maxScroll() <= 0 then return end
  dragging = true
  startPos = inp.Position
  startScroll = current()
  paint()
 end)
 track.MouseEnter:Connect(function() hovering = true paint() end)
 track.MouseLeave:Connect(function() hovering = false paint() end)

 SV.UserInput.InputChanged:Connect(function(inp)
  if not dragging then return end
  if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  local m = maxScroll()
  local ts = track.AbsoluteSize
  local trackLen = isHorizontal and ts.X or ts.Y
  local thumbFrac = isHorizontal and thumb.Size.X.Scale or thumb.Size.Y.Scale
  local usable = trackLen * (1 - thumbFrac)
  local delta = isHorizontal and (inp.Position.X - startPos.X) or (inp.Position.Y - startPos.Y)
  if usable > 0 and m > 0 then
   apply(startScroll + delta / usable * m)
  end
 end)
 SV.UserInput.InputEnded:Connect(function(inp)
  if isPress(inp) and dragging then
   dragging = false
   paint()
  end
 end)
end

Draggable(vthumb, vbar, false, vvis)
Draggable(hthumb, hbar, true, hvis)

scrolling:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
 if scrolling.Visible then RefreshTree() end
end)

local searchOptionsDropdown = Explorer.AddDropdown(function(Add)
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

threedotmenu.Activated:Connect(function()
 searchOptionsDropdown:ToggleAt(threedotmenu)
end)

local searchToken = 0
searchbar:GetPropertyChangedSignal("Text"):Connect(function()
 searchToken += 1
 local my = searchToken
 local text = searchbar.Text
 local function apply()
  if my ~= searchToken then return end
  config.SearchQuery = text:match("^%s*(.-)%s*$")
  config.SearchPred = Explorer.CompileSearch(text)
  config.SearchCursor = 0
  Explorer.SearchOpen = setmetatable({}, {__mode="k"})
  Explorer.ScanTree()
  RefreshTree()
  if config.SearchQuery ~= "" and Explorer.EnsureDeepLoad then Explorer.EnsureDeepLoad() end
 end
 if text:match("^%s*$") then apply() else task.delay(0.15, apply) end
end)

local contextItems = {}
local contextDropdown = Explorer.AddDropdown(function(Add)
 for _, it in ipairs(contextItems) do
  if it == "SEPARATOR" then
   Add(nil, "Separator")
  else
   Add(it[1], "Button", it[3])
  end
 end
end, { Width = 240, RowH = 34, TextSize = 14, Screen = true, CloseOnClick = true, OnClose = function()
 config.ContextMenu = nil
 config.ContextMenuTarget = nil
end })

local function CloseContextMenu()
 if contextDropdown then contextDropdown:Close() end
end

function OpenContextMenu(inst, x, y)
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
 local function add(label, danger, fn)
  table.insert(items, { label, danger, fn })
 end
 add("Cut", false, Explorer.Cut)
 add("Copy", false, Explorer.Copy)
 if #Explorer.Clipboard > 0 then
  add("Paste Into", false, function() Explorer.Paste(inst) end)
 end
 add("Duplicate", false, Explorer.Duplicate)
 add("Insert", false, function() Explorer.OpenInsertMenu(inst, x, y) end)
 if selCount == 1 then
  add("Rename", false, function() Explorer.StartRename(inst) end)
  if #inst.Children > 0 and (inst.ClassName == "Model" or inst.ClassName == "Folder") then
   add("Ungroup", false, function() Explorer.Ungroup(inst) end)
  end
 end
 add("Group", false, function() Explorer.GroupSelection("Model") end)
 add("Group As a Folder", false, function() Explorer.GroupSelection("Folder") end)
 table.insert(items, "SEPARATOR")
 add("Copy Name", false, function() if setclipboard then pcall(setclipboard, inst.Name) end end)
 add("Copy Path", false, function() if setclipboard then pcall(setclipboard, inst:GetFullName()) end end)
 if #Explorer.ContextItems > 0 then
  table.insert(items, "SEPARATOR")
  for _, item in ipairs(Explorer.ContextItems) do
   table.insert(items, { item.label, item.danger or false, function() pcall(item.callback, inst) end })
  end
 end
 table.insert(items, "SEPARATOR")
 add("Delete", true, Explorer.DeleteSelection)

 contextItems = items
 contextDropdown:Open(x, y)
 config.ContextMenu = contextDropdown.Frame
 config.ContextMenuTarget = inst
 config.MenuTime = tick()
end

function Explorer.CreateInstance(className, name, parent)
 parent = parent or Explorer.Root
 local G = Explorer.Game
 local inst
 if G and G.isGame(parent) then
  inst = G.create(className, name or className, parent)
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
 if G and G.isGame(inst) and not G.destroy(inst) then return end
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
 if G and G.isGame(inst) and inst.Real then
  if not G.rename(inst, name) then return end
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
 if not fastRebuild(inst) then Explorer.ScanTree() end
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
 local ctrl = SV.UserInput:IsKeyDown(Enum.KeyCode.LeftControl) or SV.UserInput:IsKeyDown(Enum.KeyCode.RightControl)
 local shift = SV.UserInput:IsKeyDown(Enum.KeyCode.LeftShift) or SV.UserInput:IsKeyDown(Enum.KeyCode.RightShift)
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

local function cloneVirtual(inst, parent)
 local kids = table.clone(inst.Children)
 local c = VirtualInstance.new(inst.ClassName, Explorer.UniqueName(parent, inst.Name), nil)
 for k, v in pairs(inst.Properties) do c.Properties[k] = v end
 for k, v in pairs(inst.Attributes) do c.Attributes[k] = v end
 for k, v in pairs(inst.Metadata) do c.Metadata[k] = v end
 if inst.Real then c.Metadata.Real = inst.Real end
 if inst.Tags then c.Tags = table.clone(inst.Tags) end
 c:SetParent(parent)
 for _, ch in ipairs(kids) do cloneVirtual(ch, c) end
 return c
end

local function topLevel(list)
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

local function reveal(inst)
 if not config.ExpandOnSelect then return end
 local cur = inst.Parent
 while cur and cur ~= Explorer.Root do
  Explorer.Expanded[cur] = true
  cur = cur.Parent
 end
end

function Explorer.Copy()
 Explorer.Clipboard = topLevel(Explorer.GetSelection())
 Explorer.ClipboardCut = false
end

function Explorer.Cut()
 Explorer.Clipboard = topLevel(Explorer.GetSelection())
 Explorer.ClipboardCut = true
end

function Explorer.Paste(target)
 local parent = target or Explorer.Root
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
    if G and G.isGame(src) then
     if G.move(src, parent) then made[#made + 1] = src end
    else
     src:SetParent(parent)
     made[#made + 1] = src
    end
   end
  elseif src.Parent then
   local G = Explorer.Game
   if G and G.isGame(src) then
    local c = G.clone(src, parent)
    if c then made[#made + 1] = c end
   else
    made[#made + 1] = cloneVirtual(src, parent)
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
 for _, src in ipairs(topLevel(list)) do
  local cur, bad = parent, false
  while cur do
   if cur == src then bad = true break end
   cur = cur.Parent
  end
  if not bad and src.Parent and src.Parent ~= parent then
   if G and G.isGame(src) then
    if G.move(src, parent) then moved[#moved + 1] = src end
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
 for _, src in ipairs(topLevel(Explorer.GetSelection())) do
  local G = Explorer.Game
  if G and G.isGame(src) then
   local c = G.clone(src, src.Parent or Explorer.Root)
   if c then made[#made + 1] = c end
  else
   made[#made + 1] = cloneVirtual(src, src.Parent or Explorer.Root)
  end
 end
 if #made == 0 then return end
 for _, m in ipairs(made) do reveal(m) end
 Explorer.ScanTree()
 Explorer.SetSelection(made, made[#made])
end

function Explorer.DeleteSelection()
 for _, inst in ipairs(topLevel(Explorer.GetSelection())) do
  Explorer.DestroyInstance(inst)
 end
end

function Explorer.GroupSelection(className)
 className = className or "Folder"
 local list = topLevel(Explorer.GetSelection())
 if #list == 0 then return end
 local parent = list[1].Parent or Explorer.Root
 local G = Explorer.Game
 local f
 if G and G.isGame(list[1]) then
  f = G.create(className, className, parent)
  if not f then return end
  for _, i in ipairs(list) do G.move(i, f) end
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
 local isGame = G and G.isGame(inst) and inst.Real ~= nil
 if isGame and not inst.Loaded then Explorer.LoadChildren(inst) end
 if #inst.Children == 0 then return end
 local parent = inst.Parent or Explorer.Root
 local moved = table.clone(inst.Children)
 if isGame then
  local ok, done = true, {}
  for _, c in ipairs(moved) do
   if G.move(c, parent) then done[#done + 1] = c else ok = false end
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
 local idx = Explorer.RowIndex and Explorer.RowIndex[inst]
 if not idx then return end
 local e = config.entries[idx - config.ScrollIndex]
 if not e or not e.label.Visible then return end

 local PAD = 6
 local textW = SV.TextSrv:GetTextSize(
  inst.Name, e.label.TextSize, Enum.Font.SourceSans, Vector2.new(10000, 26)
 ).X

 local box = Instance.new("TextBox")
 box.Name = randomString()
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
 box.TextColor3 = COLORS.TEXT_BRIGHT
 box.TextXAlignment = Enum.TextXAlignment.Left
 box.ClearTextOnFocus = false
 box.Text = inst.Name
 box.ZIndex = 8
 box.Archivable = false
 box.Parent = scrolling

 RoundCorner(box, 0, 8)
 local boxStroke = BorderStroke(box, 1, 80, 80, 80)

 local pad = Instance.new("UIPadding")
 pad.PaddingLeft = UDim.new(0, PAD)
 pad.Parent = box

 box.Focused:Connect(function()
  boxStroke.Color = COLORS.SELECTED
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

local function expandRec(inst, searching)
 Explorer.Expanded[inst] = true
 if searching then Explorer.SearchOpen[inst] = true end
 if inst.Real and not inst.Loaded then Explorer.LoadChildren(inst) end
 local kids = inst.Children
 for i = 1, #kids do expandRec(kids[i], searching) end
end

local function collapseRec(inst, searching)
 Explorer.Expanded[inst] = nil
 if searching then Explorer.SearchOpen[inst] = false end
 local kids = inst.Children
 for i = 1, #kids do collapseRec(kids[i], searching) end
end

function Explorer.ExpandAll(inst)
 expandRec(inst, config.SearchQuery ~= "")
 if not fastRebuild(inst) then Explorer.ScanTree() end
 RefreshTree()
end

function Explorer.CollapseAll(inst)
 collapseRec(inst, config.SearchQuery ~= "")
 if not fastRebuild(inst) then Explorer.ScanTree() end
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
 if main.Visible then return end
 config.IsMinimized = false
 main.Visible = true
 searchbar.Visible = true
 threedotmenu.Visible = true
 if layoutDocks then layoutDocks() end
 Explorer.ScanTree()
 RefreshTree()
end

function Explorer.Close()
 if not main.Visible then return end
 config.IsMinimized = true
 main.Visible = false
 if layoutDocks then layoutDocks() end
end

function Explorer.Toggle()
 if main.Visible then Explorer.Close() else Explorer.Open() end
end

function Explorer.IsOpen() return main.Visible end

close.Activated:Connect(function()
 Explorer.Close()
end)

local function closeInsertMenu()
 if config.InsertConns then
  for _, c in ipairs(config.InsertConns) do c:Disconnect() end
  config.InsertConns = nil
 end
 if config.InsertMenu then
  config.InsertMenu:Destroy()
  config.InsertMenu = nil
 end
end

local INSERT_CLASSES = {}
do
 local skip = { Instance = true, Service = true, Value = true, Workspace = true, Lighting = true, Chat = true, Backpack = true }
 for name in pairs(ICONS) do
  if not skip[name] then INSERT_CLASSES[#INSERT_CLASSES + 1] = name end
 end
 table.sort(INSERT_CLASSES)
end

function Explorer.OpenInsertMenu(parentInst, x, y)
 closeInsertMenu()
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
 menu.Name = randomString()
 menu.Size = UDim2.new(0, W, 0, H)
 menu.Position = UDim2.new(0, math.clamp(x, 4, math.max(4, window.AbsoluteSize.X - W - 4)), 0, math.clamp(y, 4, math.max(4, window.AbsoluteSize.Y - H - 4)))
 menu.BackgroundColor3 = COLORS.PRIMARY
 menu.BorderSizePixel = 0
 menu.ZIndex = 60
 menu.Active = true
 menu.Archivable = false
 menu.Parent = window
 DropStroke(menu)
 config.InsertMenu = menu

 local box = Instance.new("TextBox")
 box.Name = randomString()
 box.Size = UDim2.new(1, -14, 0, 28)
 box.Position = UDim2.new(0, 7, 0, 6)
 box.BackgroundColor3 = Color3.fromRGB(20, 21, 26)
 box.BorderSizePixel = 0
 box.PlaceholderText = "Search"
 box.PlaceholderColor3 = COLORS.TEXT
 box.Text = ""
 box.TextColor3 = COLORS.TEXT_BRIGHT
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
 box.Focused:Connect(function() boxStroke.Color = COLORS.SELECTED end)
 box.FocusLost:Connect(function() boxStroke.Color = Color3.fromRGB(80, 80, 80) end)

 local view = Instance.new("Frame")
 view.Name = randomString()
 view.Size = UDim2.new(0, viewW, 0, listH)
 view.Position = UDim2.new(0, 0, 0, listY)
 view.BackgroundTransparency = 1
 view.ClipsDescendants = true
 view.ZIndex = 61
 view.Archivable = false
 view.Parent = menu

 local bar = Instance.new("Frame")
 bar.Name = randomString()
 bar.Size = UDim2.new(0, 10, 0, listH)
 bar.Position = UDim2.new(1, -10, 0, listY)
 bar.BackgroundTransparency = 1
 bar.BorderSizePixel = 0
 bar.Visible = false
 bar.ZIndex = 62
 bar.Archivable = false
 bar.Parent = menu

 local thumb = Instance.new("Frame")
 thumb.Name = randomString()
 thumb.Size = UDim2.new(1, 0, 0.2, 0)
 thumb.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
 thumb.BorderSizePixel = 0
 thumb.ZIndex = 63
 thumb.Archivable = false
 thumb.Parent = bar
 RoundCorner(thumb, 1, 0)

 local function insert(className)
  closeInsertMenu()
  if parentInst ~= Explorer.Root then Explorer.Expanded[parentInst] = true end
  local inst = Explorer.CreateInstance(className, className, parentInst)
  if inst and config.SelectAfterInsert then Explorer.SelectInstance(inst) end
 end

 local items = {}
 local scrollIndex = 0
 local pool = {}

 local function refresh()
  local maxIndex = math.max(0, #items - VISIBLE)
  scrollIndex = math.clamp(scrollIndex, 0, maxIndex)
  for i, p in ipairs(pool) do
   local item = items[scrollIndex + i]
   p.item = item
   if item then
    p.entry.Visible = true
    p.entry.Position = UDim2.new(0, 0, 0, (i - 1) * ROW)
    applyIcon(p.icon, item)
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
  entry.Name = randomString()
  entry.Size = UDim2.new(0, viewW, 0, ROW)
  entry.BackgroundColor3 = COLORS.SECONDARY
  entry.BackgroundTransparency = 1
  entry.BorderSizePixel = 0
  entry.AutoButtonColor = false
  entry.Text = ""
  entry.Visible = false
  entry.ZIndex = 62
  entry.Archivable = false
  entry.Parent = view

  local icon = Instance.new("ImageLabel")
  icon.Size = UDim2.new(0, Positions.ICON_PX, 0, Positions.ICON_PX)
  icon.Position = UDim2.new(0, 8, 0.5, -Positions.ICON_PX / 2)
  icon.BackgroundTransparency = 1
  icon.ZIndex = 63
  icon.Archivable = false
  icon.Parent = entry

  local label = Instance.new("TextLabel")
  label.Size = UDim2.new(1, -(8 + Positions.ICON_PX + 14), 1, 0)
  label.Position = UDim2.new(0, 8 + Positions.ICON_PX + 8, 0, 0)
  label.BackgroundTransparency = 1
  label.TextColor3 = COLORS.TEXT
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
  entry.Activated:Connect(function() if p.item then insert(p.item) end end)
 end

 local function populate()
  local q = box.Text:lower()
  items = {}
  for _, name in ipairs(INSERT_CLASSES) do
   if q == "" or name:lower():find(q, 1, true) then items[#items + 1] = name end
  end
  scrollIndex = 0
  refresh()
 end
 populate()
 box:GetPropertyChangedSignal("Text"):Connect(populate)
 box.FocusLost:Connect(function(enter)
  if enter and items[1] and config.InsertMenu == menu then insert(items[1]) end
 end)

 conns[#conns + 1] = SV.UserInput.InputChanged:Connect(function(input)
  if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
  local ap, as = menu.AbsolutePosition, menu.AbsoluteSize
  local mp = input.Position
  if mp.X < ap.X or mp.X > ap.X + as.X or mp.Y < ap.Y or mp.Y > ap.Y + as.Y then return end
  scrollIndex = scrollIndex - input.Position.Z * 3
  refresh()
 end)

 local dragging, startY, startIndex = false, 0, 0
 thumb.InputBegan:Connect(function(inp)
  if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  dragging, startY, startIndex = true, inp.Position.Y, scrollIndex
 end)
 conns[#conns + 1] = SV.UserInput.InputChanged:Connect(function(inp)
  if not dragging then return end
  if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
  local maxIndex = math.max(0, #items - VISIBLE)
  local usable = listH * (1 - thumb.Size.Y.Scale)
  if usable > 0 and maxIndex > 0 then
   scrollIndex = math.floor(startIndex + (inp.Position.Y - startY) / usable * maxIndex + 0.5)
   refresh()
  end
 end)
 conns[#conns + 1] = SV.UserInput.InputEnded:Connect(function(inp)
  if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
   dragging = false
  end
 end)

 task.defer(function()
  if box.Parent then box:CaptureFocus() box.Text = "" end
 end)
end

insertBtn.MouseEnter:Connect(function() config.OverInsert = true end)
insertBtn.MouseLeave:Connect(function()
 config.OverInsert = false
 task.defer(function()
  if not config.HoverInst then insertBtn.Visible = false end
 end)
end)
insertBtn.Activated:Connect(function()
 local ap = insertBtn.AbsolutePosition
 Explorer.OpenInsertMenu(config.InsertTarget, ap.X, ap.Y + 20)
end)

local function mouseInMain()
 local mp = SV.UserInput:GetMouseLocation()
 local ap, as = main.AbsolutePosition, main.AbsoluteSize
 return mp.X >= ap.X and mp.X <= ap.X + as.X and mp.Y >= ap.Y and mp.Y <= ap.Y + as.Y + 36
end

local function selectRowAt(idx)
 local row = config.visiblerows[idx]
 if not row then return end
 local viewRows = math.max(1, math.floor(scrolling.AbsoluteSize.Y / config.ROW_H))
 if idx - 1 < config.ScrollIndex then
  config.ScrollIndex = idx - 1
 elseif idx > config.ScrollIndex + viewRows then
  config.ScrollIndex = idx - viewRows
 end
 config.Anchor = row.instance
 Explorer.SetSelection({ row.instance }, row.instance)
end

searchbar.FocusLost:Connect(function(enter)
 if not enter or config.SearchQuery == "" then return end
 local hits = {}
 for i, row in ipairs(config.visiblerows) do
  if row.match then hits[#hits + 1] = i end
 end
 if #hits == 0 then return end
 local back = SV.UserInput:IsKeyDown(Enum.KeyCode.LeftShift) or SV.UserInput:IsKeyDown(Enum.KeyCode.RightShift)
 if back then
  config.SearchCursor = ((config.SearchCursor - 2) % #hits) + 1
 else
  config.SearchCursor = (config.SearchCursor % #hits) + 1
 end
 selectRowAt(hits[config.SearchCursor])
end)

SV.UserInput.InputBegan:Connect(function(inp, gpe)
 if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
 if not main.Visible then return end
 local ctrl = SV.UserInput:IsKeyDown(Enum.KeyCode.LeftControl) or SV.UserInput:IsKeyDown(Enum.KeyCode.RightControl)
 local shift = SV.UserInput:IsKeyDown(Enum.KeyCode.LeftShift) or SV.UserInput:IsKeyDown(Enum.KeyCode.RightShift)
 local alt = SV.UserInput:IsKeyDown(Enum.KeyCode.LeftAlt) or SV.UserInput:IsKeyDown(Enum.KeyCode.RightAlt)
 local key = inp.KeyCode
 if key == Enum.KeyCode.Escape and config.InsertMenu then
  closeInsertMenu()
  return
 end
 if ctrl and shift and key == Enum.KeyCode.X then
  task.defer(function() searchbar:CaptureFocus() end)
  return
 end
 if gpe or not mouseInMain() then return end
 local rows = config.visiblerows
 local cur = Explorer.Selected and Explorer.RowIndex and Explorer.RowIndex[Explorer.Selected]
 local pageRows = math.max(1, math.floor(scrolling.AbsoluteSize.Y / config.ROW_H))
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
  local mp = SV.UserInput:GetMouseLocation()
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
  selectRowAt(cur and math.min(cur + 1, #rows) or 1)
 elseif key == Enum.KeyCode.Up then
  selectRowAt(cur and math.max(cur - 1, 1) or 1)
 elseif key == Enum.KeyCode.Home then
  selectRowAt(1)
 elseif key == Enum.KeyCode.End then
  selectRowAt(#rows)
 elseif key == Enum.KeyCode.PageDown then
  selectRowAt(cur and math.min(cur + pageRows, #rows) or 1)
 elseif key == Enum.KeyCode.PageUp then
  selectRowAt(cur and math.max(cur - pageRows, 1) or 1)
 elseif key == Enum.KeyCode.Right and cur then
  local inst = rows[cur].instance
  if rows[cur].searchLeaf then
  elseif Explorer.HasChildren(inst) and not rows[cur].expanded then
   Explorer.SetExpanded(inst, true)
  elseif Explorer.HasChildren(inst) then
   selectRowAt(cur + 1)
  end
 elseif key == Enum.KeyCode.Left and cur then
  local inst = rows[cur].instance
  if inst.Parent and inst.Parent ~= Explorer.Root and Explorer.RowIndex[inst.Parent] then
   selectRowAt(Explorer.RowIndex[inst.Parent])
  elseif Explorer.Expanded[inst] then
   Explorer.SetExpanded(inst, false)
  end
 end
end)

local function pointIn(gui, pos)
 if not gui then return false end
 local ap, as = gui.AbsolutePosition, gui.AbsoluteSize
 return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
end

SV.UserInput.InputBegan:Connect(function(inp)
 if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.MouseButton2 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
 local pos = Vector2.new(inp.Position.X, inp.Position.Y)
 if config.InsertMenu and not pointIn(config.InsertMenu, pos) then closeInsertMenu() end
end)

SV.ContextAction:BindAction("OpenExplorer", function(_, state)
 if state ~= Enum.UserInputState.Begin then return end
 Explorer.Toggle()
end, false, Enum.KeyCode.K)

SV.UserInput.InputBegan:Connect(function(inp, gpe)
 if gpe then return end
 if inp.KeyCode ~= Enum.KeyCode.X then return end
 if SV.UserInput:IsKeyDown(Enum.KeyCode.LeftAlt) or SV.UserInput:IsKeyDown(Enum.KeyCode.RightAlt) then
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

 SUBCLASS.guitext = { TextLabel = 1, TextButton = 1, TextBox = 1 }

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

 local function guessSection(name, v)
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

 local function hasTagStr(tags, name)
  if type(tags) ~= "table" then return false end
  for _, t in ipairs(tags) do if t == name then return true end end
  return false
 end

 local function httpRequest(url)
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

 local function loadAPI()
  if API.Classes or API.Loading then return end
  API.Loading = true
  task.spawn(function()
   local body
   for _ = 1, 3 do
    body = httpRequest(API_URL)
    if body then break end
    task.wait(2)
   end
   local data
   if body then
    local ok, d = pcall(function() return SV.Http:JSONDecode(body) end)
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
     if m.MemberType == "Property" and not hasTagStr(m.Tags, "Deprecated") then
      local sec = m.Security
      local writeSec = type(sec) == "table" and sec.Write or sec
      props[#props + 1] = {
       Name = m.Name,
       Category = m.Category or "Other",
       ReadOnly = hasTagStr(m.Tags, "ReadOnly") or (writeSec ~= nil and writeSec ~= "None"),
       NotScriptable = hasTagStr(m.Tags, "NotScriptable"),
       Hidden = hasTagStr(m.Tags, "Hidden"),
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

 local function readReal(real, name)
  local ok, v = pcall(function() return real[name] end)
  if not ok and type(gethiddenproperty) == "function" then
   ok, v = pcall(gethiddenproperty, real, name)
  end
  return ok, v
 end

 local function writeReal(real, name, value)
  local ok = pcall(function() real[name] = value end)
  if not ok and type(sethiddenproperty) == "function" then
   ok = pcall(sethiddenproperty, real, name, value)
  end
  return ok
 end

 loadAPI()

 local function collect(inst)
  local bySec, order, seen = {}, {}, {}
  local function add(sec, entry)
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
  add("Data", { key = "Name", value = inst.Name })
  add("Data", { key = "ClassName", value = inst.ClassName, readonly = true })
  add("Data", { key = "Parent", value = parentName, readonly = true })
  seen.Name, seen.ClassName, seen.Parent = true, true, true

  local real = inst.Real
  if real then
   local list = API.PropsFor(inst.ClassName)
   if list then
    local canHidden = type(gethiddenproperty) == "function"
    for _, p in ipairs(list) do
     if not seen[p.Name] and (canHidden or not p.NotScriptable) then
      local ok, v = readReal(real, p.Name)
      if ok then
       seen[p.Name] = true
       local ro = p.ReadOnly or p.TypeCat == "Class" or (p.NotScriptable and type(sethiddenproperty) ~= "function")
       if v == nil then v, ro = "nil", true end
       add(p.Category, { key = p.Name, value = v, readonly = ro and true or false })
      end
     end
    end
   else
    for _, def in ipairs(Explorer.PropertyDefs) do
     if not seen[def.Name] and isA(inst, def.Class:lower()) then
      local ok, v = readReal(real, def.Name)
      if ok and v ~= nil then
       seen[def.Name] = true
       add(def.Section, { key = def.Name, value = v, readonly = def.ReadOnly })
      end
     end
    end
    if API.Failed then
     add("Data", { key = "(API dump failed to load)", value = "retrying on reselect", readonly = true })
     API.Failed = false
     loadAPI()
    end
   end
  else
   for _, def in ipairs(Explorer.PropertyDefs) do
    if not seen[def.Name] and isA(inst, def.Class:lower()) then
     seen[def.Name] = true
     local v = inst.Properties[def.Name]
     if v == nil then v = def.Default end
     add(def.Section, { key = def.Name, value = v, readonly = def.ReadOnly })
    end
   end

   local extra = {}
   for k in pairs(inst.Properties) do
    if type(k) == "string" and not seen[k] then extra[#extra + 1] = k end
   end
   for _, k in ipairs(extra) do
    local v = inst.Properties[k]
    add(guessSection(k, v), { key = k, value = v })
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

 local function hasProp(t, key)
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
   if def.Name == key and isA(t, def.Class:lower()) then return true end
  end
  return false
 end

 local function fmtNum(n)
  if n ~= n then return "nan" end
  if n == math.huge then return "inf" elseif n == -math.huge then return "-inf" end
  if n == math.floor(n) and math.abs(n) < 1e15 then return string.format("%d", n) end
  local s = string.format("%.4f", n)
  s = s:gsub("0+$", "")
  s = s:gsub("%.$", "")
  return s
 end

 local function fmt(v)
  if type(v) == "table" and v.ClassName then return tostring(v.Name) end
  local t = typeof(v)
  if t == "string" then return v
  elseif t == "number" then return fmtNum(v)
  elseif t == "boolean" then return tostring(v)
  elseif t == "Color3" then
   return string.format("%d, %d, %d", math.round(v.R * 255), math.round(v.G * 255), math.round(v.B * 255))
  elseif t == "Vector3" then return fmtNum(v.X) .. ", " .. fmtNum(v.Y) .. ", " .. fmtNum(v.Z)
  elseif t == "Vector2" then return fmtNum(v.X) .. ", " .. fmtNum(v.Y)
  elseif t == "UDim" then return fmtNum(v.Scale) .. ", " .. fmtNum(v.Offset)
  elseif t == "UDim2" then
   return "{" .. fmtNum(v.X.Scale) .. ", " .. fmtNum(v.X.Offset) .. "}, {" .. fmtNum(v.Y.Scale) .. ", " .. fmtNum(v.Y.Offset) .. "}"
  elseif t == "CFrame" then
   local parts = {}
   for i, n in ipairs({ v:GetComponents() }) do parts[i] = fmtNum(n) end
   return table.concat(parts, ", ")
  elseif t == "EnumItem" then return v.Name
  elseif t == "BrickColor" then return v.Name
  elseif t == "NumberRange" then return fmtNum(v.Min) .. ", " .. fmtNum(v.Max)
  elseif t == "Rect" then return fmtNum(v.Min.X) .. ", " .. fmtNum(v.Min.Y) .. ", " .. fmtNum(v.Max.X) .. ", " .. fmtNum(v.Max.Y)
  elseif t == "nil" then return ""
  end
  return tostring(v)
 end

 local function nums(text, n)
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

 local function parseValue(text, cur)
  local t = typeof(cur)
  if t == "string" then return text
  elseif t == "number" then return tonumber(text)
  elseif t == "Color3" then
   local h = text:match("^%s*#(%x%x%x%x%x%x)%s*$")
   if h then
    return Color3.fromRGB(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16))
   end
   local n = nums(text, 3)
   if n then return Color3.fromRGB(math.clamp(n[1], 0, 255), math.clamp(n[2], 0, 255), math.clamp(n[3], 0, 255)) end
  elseif t == "Vector3" then
   local n = nums(text, 3)
   if n then return Vector3.new(n[1], n[2], n[3]) end
  elseif t == "Vector2" then
   local n = nums(text, 2)
   if n then return Vector2.new(n[1], n[2]) end
  elseif t == "UDim" then
   local n = nums(text, 2)
   if n then return UDim.new(n[1], n[2]) end
  elseif t == "UDim2" then
   local n = nums(text, 4)
   if n then return UDim2.new(n[1], n[2], n[3], n[4]) end
  elseif t == "CFrame" then
   local n = nums(text)
   if n and #n == 3 then return CFrame.new(n[1], n[2], n[3]) * (cur - cur.Position) end
   if n and #n == 12 then return CFrame.new(table.unpack(n)) end
  elseif t == "NumberRange" then
   local n = nums(text)
   if n and #n == 1 then return NumberRange.new(n[1]) end
   if n and #n == 2 then return NumberRange.new(n[1], n[2]) end
  elseif t == "Rect" then
   local n = nums(text, 4)
   if n then return Rect.new(n[1], n[2], n[3], n[4]) end
  elseif t == "BrickColor" then
   local ok, bc = pcall(BrickColor.new, text)
   if ok then return bc end
  end
  return nil
 end

 local function components(v)
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

 local rebuild, refreshList

 local function applyProp(key, value)
  local targets = Explorer.GetSelection()
  if #targets == 0 and P.Inst then targets = { P.Inst } end
  for _, t in ipairs(targets) do
   if hasProp(t, key) then
    if key == "Name" then
     if type(value) == "string" and value ~= "" then
      if t.Real then
       if writeReal(t.Real, "Name", value) then t.Name = value end
      else
       t.Name = value
      end
     end
    elseif t.Real then
     writeReal(t.Real, key, value)
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

 local function tagList(inst)
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

 local function removeTag(inst, tag)
  local t = inst.Tags
  if type(t) ~= "table" then return end
  t[tag] = nil
  for i = #t, 1, -1 do
   if t[i] == tag then table.remove(t, i) end
  end
 end

 local function addValueRows(rows, d)
  local row = {
   kind = "prop", name = d.name, value = d.value, readonly = d.readonly,
   commit = d.commit, gear = d.gear, expKey = d.expKey,
  }
  local comps = (not d.readonly) and components(d.value) or nil
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
     commit = function(nv) d.commit(make(nv)) end,
    }
   end
  end
 end

 rebuild = function()
  local rows = {}
  local inst = Explorer.Selected
  if inst == Explorer.Root then inst = nil end
  P.Inst = inst
  if inst then
   local f = P.Filter
   local function matches(name) return f == "" or name:lower():find(f, 1, true) ~= nil end

   for _, sec in ipairs(collect(inst)) do
    local keep = {}
    for _, p in ipairs(sec.props) do
     if matches(p.key) then keep[#keep + 1] = p end
    end
    if #keep > 0 then
     local collapsed = P.Collapsed[sec.name] == true and f == ""
     rows[#rows + 1] = { kind = "section", name = sec.name, collapsed = collapsed }
     if not collapsed then
      for _, p in ipairs(keep) do
       local key = p.key
       addValueRows(rows, {
        name = key, value = p.value, readonly = p.readonly,
        expKey = inst.ClassName .. ":" .. key,
        commit = function(nv) applyProp(key, nv) end,
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
    if type(k) == "string" and matches(k) then attrNames[#attrNames + 1] = k end
   end
   table.sort(attrNames)
   if f == "" or #attrNames > 0 then
    local collapsed = P.Collapsed.Attributes == true and f == ""
    rows[#rows + 1] = { kind = "section", name = "Attributes", collapsed = collapsed, add = (f == "") and "attr" or nil }
    if not collapsed then
     for _, k in ipairs(attrNames) do
      local name = k
      addValueRows(rows, {
       name = name, value = inst.Attributes[name], gear = true,
       expKey = "attr:" .. name,
       commit = function(nv)
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
   for _, tg in ipairs(tagList(inst)) do
    if matches(tg) then tags[#tags + 1] = tg end
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

 pmain = Instance.new("Frame")
 pmain.Name = randomString()
 pmain.Size = UDim2.new(0, main.Size.X.Offset, 0, P.FloatH)
 pmain.Position = UDim2.new(0, 40, 0, 40)
 clampPanelTop(pmain)
 pmain.BackgroundColor3 = COLORS.PRIMARY
 pmain.BackgroundTransparency = config.NT
 pmain.Active = true
 pmain.BorderSizePixel = 0
 pmain.ZIndex = 2
 pmain.Archivable = false
 pmain.Parent = window
 RegisterWindow(pmain)

 pdocksplitter = Instance.new("Frame")
 pdocksplitter.Name = randomString()
 pdocksplitter.Size = UDim2.new(0, 3, 1, 0)
 pdocksplitter.BackgroundColor3 = COLORS.RESIZER
 pdocksplitter.BorderSizePixel = 0
 pdocksplitter.ZIndex = 8
 pdocksplitter.Visible = false
 pdocksplitter.Active = true
 pdocksplitter.Archivable = false
 pdocksplitter.Parent = pmain

 local hdr = Instance.new("Frame")
 hdr.Name = randomString()
 hdr.Size = UDim2.new(1, 0, 0, 65)
 hdr.BackgroundColor3 = COLORS.HEADER
 hdr.BorderSizePixel = 0
 hdr.Active = true
 hdr.ZIndex = 3
 hdr.Archivable = false
 hdr.Parent = pmain

 local hAccent = Instance.new("Frame")
 hAccent.Name = randomString()
 hAccent.Size = UDim2.new(1, 0, 0, 1.5)
 hAccent.Position = UDim2.new(0, 0, 1, -1.5)
 hAccent.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
 hAccent.BorderSizePixel = 0
 hAccent.ZIndex = 3
 hAccent.Archivable = false
 hAccent.Parent = hdr

 local ptitle = Instance.new("TextLabel")
 ptitle.Name = randomString()
 ptitle.Size = UDim2.new(1, -70, 0, 28)
 ptitle.Position = UDim2.new(0, 35, 0, 0)
 ptitle.BackgroundTransparency = 1
 ptitle.Text = "Properties"
 ptitle.TextColor3 = COLORS.TEXT_BRIGHT
 ptitle.FontFace = FONT.GothamRegular
 ptitle.TextSize = 12
 ptitle.TextTruncate = Enum.TextTruncate.AtEnd
 ptitle.TextXAlignment = Enum.TextXAlignment.Center
 ptitle.ZIndex = 3
 ptitle.Archivable = false
 ptitle.Parent = hdr

 local pclose = Instance.new("TextButton")
 pclose.Name = randomString()
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
 ppin.Name = randomString()
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
 searchRowP.Name = randomString()
 searchRowP.Size = UDim2.new(1, 0, 0, 34)
 searchRowP.Position = UDim2.new(0, 0, 0, 28)
 searchRowP.BackgroundTransparency = 1
 searchRowP.BorderSizePixel = 0
 searchRowP.ZIndex = 3
 searchRowP.Archivable = false
 searchRowP.Parent = pmain

 local filterBox = Instance.new("TextBox")
 filterBox.Name = randomString()
 filterBox.Size = UDim2.new(1, -14, 0, 28)
 filterBox.Position = UDim2.new(0, 7, 0, 4)
 filterBox.BackgroundColor3 = COLORS.PRIMARY
 filterBox.PlaceholderText = "Filter Properties (Ctrl+Shift+P)"
 filterBox.PlaceholderColor3 = COLORS.TEXT
 filterBox.Text = ""
 filterBox.TextColor3 = COLORS.TEXT_BRIGHT
 filterBox.Font = Enum.Font.SourceSans
 filterBox.TextSize = 15
 filterBox.TextXAlignment = Enum.TextXAlignment.Left
 filterBox.ClearTextOnFocus = false
 filterBox.ZIndex = 5
 filterBox.Archivable = false
 filterBox.Parent = searchRowP

 local pbody = Instance.new("Frame")
 pbody.Name = randomString()
 pbody.Size = UDim2.new(1, 0, 1, -65)
 pbody.Position = UDim2.new(0, 0, 0, 65)
 pbody.BackgroundTransparency = 1
 pbody.ZIndex = 3
 pbody.Archivable = false
 pbody.Parent = pmain

 local list = Instance.new("Frame")
 list.Name = randomString()
 list.Size = UDim2.new(1, -12, 1, -8)
 list.BackgroundTransparency = 1
 list.ClipsDescendants = true
 list.ZIndex = 3
 list.Archivable = false
 list.Parent = pbody

 local pvbar = Instance.new("Frame")
 pvbar.Name = randomString()
 pvbar.Size = UDim2.new(0, 24, 1, -8)
 pvbar.Position = UDim2.new(1, -24, 0, 0)
 pvbar.BackgroundTransparency = 1
 pvbar.BorderSizePixel = 0
 pvbar.Active = true
 pvbar.Visible = false
 pvbar.ZIndex = 9
 pvbar.Archivable = false
 pvbar.Parent = pbody

 local pvthumb = Instance.new("Frame")
 pvthumb.Name = randomString()
 pvthumb.Size = UDim2.new(1, 0, 0.2, 0)
 pvthumb.BackgroundTransparency = 1
 pvthumb.BorderSizePixel = 0
 pvthumb.Active = false
 pvthumb.ZIndex = 10
 pvthumb.Archivable = false
 pvthumb.Parent = pvbar

 local pvvis = Instance.new("Frame")
 pvvis.Name = randomString()
 pvvis.Size = UDim2.new(0, 8, 1, 0)
 pvvis.Position = UDim2.new(1, -10, 0, 0)
 pvvis.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
 pvvis.BorderSizePixel = 0
 pvvis.ZIndex = 10
 pvvis.Active = false
 pvvis.Archivable = false
 pvvis.Parent = pvthumb
 RoundCorner(pvvis, 1, 0)

 local divHit = Instance.new("TextButton")
 divHit.Name = randomString()
 divHit.Size = UDim2.new(0, 14, 1, 0)
 divHit.BackgroundTransparency = 1
 divHit.Text = ""
 divHit.AutoButtonColor = false
 divHit.Visible = false
 divHit.ZIndex = 8
 divHit.Archivable = false
 divHit.Parent = list

 local function closeMenu()
  if P.MenuBlocker then
   P.MenuBlocker:Destroy()
   P.MenuBlocker = nil
  end
 end

 local function openMenu(anchor, items, onPick, minW)
  closeMenu()
  local blocker = Instance.new("TextButton")
  blocker.Name = randomString()
  blocker.Size = UDim2.new(1, 0, 1, 0)
  blocker.BackgroundTransparency = 1
  blocker.Text = ""
  blocker.AutoButtonColor = false
  blocker.ZIndex = 70
  blocker.Archivable = false
  blocker.Parent = window
  blocker.Activated:Connect(closeMenu)
  P.MenuBlocker = blocker

  local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
  local ITEM_H = 26
  local w = math.max(minW or 0, as.X, 120)
  local h = math.min(#items * ITEM_H + 4, 240)
  local scr = window.AbsoluteSize
  local x = math.clamp(ap.X, 4, math.max(4, scr.X - w - 4))
  local y = ap.Y + as.Y + 2
  if y + h > scr.Y - 4 then y = math.max(4, ap.Y - h - 2) end

  local m = Instance.new("ScrollingFrame")
  m.Name = randomString()
  m.Size = UDim2.new(0, w, 0, h)
  m.Position = UDim2.new(0, x, 0, y)
  m.BackgroundColor3 = COLORS.PRIMARY
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
   b.Name = randomString()
   b.Size = UDim2.new(1, -8, 0, ITEM_H - 2)
   b.Position = UDim2.new(0, 4, 0, 2 + (i - 1) * ITEM_H)
   b.BackgroundColor3 = COLORS.SECONDARY
   b.BackgroundTransparency = 1
   b.BorderSizePixel = 0
   b.AutoButtonColor = false
   b.Text = it.label
   b.TextColor3 = it.danger and COLORS.CLOSE_TEXT or COLORS.TEXT_BRIGHT
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
    closeMenu()
    onPick(it)
   end)
  end
 end

 local function openDialog(cfg)
  closeMenu()
  local blocker = Instance.new("TextButton")
  blocker.Name = randomString()
  blocker.Size = UDim2.new(1, 0, 1, 0)
  blocker.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
  blocker.BackgroundTransparency = 0.55
  blocker.Text = ""
  blocker.AutoButtonColor = false
  blocker.ZIndex = 50
  blocker.Archivable = false
  blocker.Parent = window
  local function close() blocker:Destroy() end
  blocker.Activated:Connect(close)

  local dlg = Instance.new("Frame")
  dlg.Name = randomString()
  dlg.Size = UDim2.new(0, 270, 0, cfg.withType and 158 or 114)
  dlg.AnchorPoint = Vector2.new(0.5, 0.5)
  dlg.Position = UDim2.new(0.5, 0, 0.4, 0)
  dlg.BackgroundColor3 = COLORS.PRIMARY
  dlg.BorderSizePixel = 0
  dlg.Active = true
  dlg.ZIndex = 51
  dlg.Archivable = false
  dlg.Parent = blocker
  RoundCorner(dlg, 0, 8)
  BorderStroke(dlg, 1, 80, 80, 80)

  local t = Instance.new("TextLabel")
  t.Name = randomString()
  t.Size = UDim2.new(1, -24, 0, 22)
  t.Position = UDim2.new(0, 12, 0, 6)
  t.BackgroundTransparency = 1
  t.Text = cfg.title
  t.TextColor3 = COLORS.TEXT_BRIGHT
  t.TextXAlignment = Enum.TextXAlignment.Left
  t.FontFace = FONT.GothamMedium
  t.TextSize = 13
  t.ZIndex = 52
  t.Archivable = false
  t.Parent = dlg

  local nameBox = Instance.new("TextBox")
  nameBox.Name = randomString()
  nameBox.Size = UDim2.new(1, -24, 0, 28)
  nameBox.Position = UDim2.new(0, 12, 0, 34)
  nameBox.BackgroundColor3 = COLORS.SECONDARY
  nameBox.PlaceholderText = "Name"
  nameBox.PlaceholderColor3 = COLORS.TEXT_DIM
  nameBox.Text = cfg.name or ""
  nameBox.TextColor3 = COLORS.TEXT_BRIGHT
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
   typeBtn.Name = randomString()
   typeBtn.Size = UDim2.new(1, -24, 0, 28)
   typeBtn.Position = UDim2.new(0, 12, 0, 68)
   typeBtn.BackgroundColor3 = COLORS.SECONDARY
   typeBtn.AutoButtonColor = false
   typeBtn.Text = typeName
   typeBtn.TextColor3 = COLORS.TEXT_BRIGHT
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
    openMenu(typeBtn, items, function(it)
     typeName = it.label
     typeBtn.Text = typeName
    end)
   end)
  end

  local function mkBtn(text, x, w, color, fn)
   local b = Instance.new("TextButton")
   b.Name = randomString()
   b.Size = UDim2.new(w, -15, 0, 28)
   b.Position = UDim2.new(x, x == 0 and 12 or 3, 1, -38)
   b.BackgroundColor3 = color
   b.AutoButtonColor = false
   b.Text = text
   b.TextColor3 = Color3.fromRGB(255, 255, 255)
   b.FontFace = FONT.GothamMedium
   b.TextSize = 12
   b.ZIndex = 52
   b.Archivable = false
   b.Parent = dlg
   RoundCorner(b, 0, 6)
   b.Activated:Connect(fn)
   return b
  end
  local function save()
   local n = nameBox.Text:match("^%s*(.-)%s*$")
   if n == "" then return end
   if cfg.validate then
    local err = cfg.validate(n)
    if err then
     t.Text = err
     t.TextColor3 = COLORS.CLOSE_TEXT
     return
    end
   end
   close()
   cfg.onSave(n, typeName)
  end
  mkBtn("Cancel", 0, 0.5, COLORS.SECONDARY, close)
  mkBtn("Save", 0.5, 0.5, COLORS.SELECTED, save)
  nameBox.FocusLost:Connect(function(enter) if enter then save() end end)
  task.defer(function() if nameBox.Parent then nameBox:CaptureFocus() end end)
 end

 local function defaultFor(typeName)
  for _, at in ipairs(ATTR_TYPES) do
   if at[1] == typeName then return at[2] end
  end
  return ""
 end

 local pool = {}

 local function makeRow()
  local r = {}
  local f = Instance.new("TextButton")
  f.Name = randomString()
  f.Size = UDim2.new(1, 0, 0, ROW)
  f.BackgroundColor3 = COLORS.HEADER
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
  line.Name = randomString()
  line.Size = UDim2.new(1, 0, 0, 1)
  line.Position = UDim2.new(0, 0, 1, -1)
  line.BackgroundColor3 = Color3.fromRGB(38, 39, 45)
  line.BorderSizePixel = 0
  line.ZIndex = 3
  line.Archivable = false
  line.Parent = f
  r.line = line

  local vline = Instance.new("Frame")
  vline.Name = randomString()
  vline.Size = UDim2.new(0, 1, 1, 0)
  vline.BackgroundColor3 = Color3.fromRGB(38, 39, 45)
  vline.BorderSizePixel = 0
  vline.ZIndex = 3
  vline.Archivable = false
  vline.Parent = f
  r.vline = vline

  local arrow = Instance.new("ImageButton")
  arrow.Name = randomString()
  arrow.Size = UDim2.new(0, 16, 0, 16)
  arrow.BackgroundTransparency = 1
  arrow.Image = "rbxassetid://81462102154124"
  arrow.AutoButtonColor = false
  arrow.ZIndex = 5
  arrow.Visible = false
  arrow.Archivable = false
  arrow.Parent = f
  r.arrow = arrow

  local name = Instance.new("TextLabel")
  name.Name = randomString()
  name.BackgroundTransparency = 1
  name.TextColor3 = COLORS.TEXT
  name.TextXAlignment = Enum.TextXAlignment.Left
  name.TextYAlignment = Enum.TextYAlignment.Center
  name.Font = Enum.Font.SourceSans
  name.TextSize = 19
  name.TextTruncate = Enum.TextTruncate.AtEnd
  name.ZIndex = 4
  name.Archivable = false
  name.Parent = f
  r.name = name

  local value = Instance.new("TextBox")
  value.Name = randomString()
  value.BackgroundColor3 = Color3.fromRGB(20, 21, 26)
  value.BackgroundTransparency = 1
  value.BorderSizePixel = 0
  value.TextColor3 = COLORS.TEXT_BRIGHT
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
  hit.Name = randomString()
  hit.BackgroundTransparency = 1
  hit.Text = ""
  hit.AutoButtonColor = false
  hit.Visible = false
  hit.ZIndex = 7
  hit.Archivable = false
  hit.Parent = f
  r.hit = hit

  local swatch = Instance.new("Frame")
  swatch.Name = randomString()
  swatch.Size = UDim2.new(0, 16, 0, 12)
  swatch.BorderSizePixel = 0
  swatch.Visible = false
  swatch.ZIndex = 5
  swatch.Archivable = false
  swatch.Parent = f
  BorderStroke(swatch, 1, 90, 90, 90)
  r.swatch = swatch

  local checkBtn = Instance.new("TextButton")
  checkBtn.Name = randomString()
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

  local chev = MakeChevron(f, 6)
  chev.Visible = false
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

  local function toggleRow()
   local d = r.data
   if not d then return end
   if d.kind == "section" then
    P.Collapsed[d.name] = (not P.Collapsed[d.name]) or nil
   elseif d.expandable then
    P.PExp[d.expKey] = (not P.PExp[d.expKey]) or nil
   else
    return
   end
   Explorer.RefreshProperties()
  end
  f.Activated:Connect(toggleRow)
  arrow.Activated:Connect(toggleRow)

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
   if not d.commit or d.readonly then value.Text = fmt(d.value) return end
   local nv = parseValue(value.Text, d.value)
   if nv == nil or (d.name == "Name" and nv == "") then
    value.Text = fmt(d.value)
    return
   end
   if typeof(nv) == typeof(d.value) and fmt(nv) == fmt(d.value) then
    value.Text = fmt(d.value)
    return
   end
   d.commit(nv)
  end)

  checkBtn.Activated:Connect(function()
   local d = r.data
   if d and d.commit and not d.readonly then d.commit(not d.value) end
  end)

  hit.Activated:Connect(function()
   local d = r.data
   if not d or not d.commit or d.readonly then return end
   local ok, items = pcall(function() return d.value.EnumType:GetEnumItems() end)
   if not ok then return end
   local menu = {}
   for _, it in ipairs(items) do menu[#menu + 1] = { label = it.Name, value = it } end
   openMenu(hit, menu, function(it) d.commit(it.value) end)
  end)

  add.Activated:Connect(function()
   local d = r.data
   local inst = P.Inst
   if not d or not inst then return end
   if d.add == "attr" then
    openDialog({
     title = "New attribute", withType = true, typeName = "string",
     validate = function(n)
      if inst.Attributes[n] ~= nil then return "Attribute already exists" end
     end,
     onSave = function(n, tn)
      if inst.Attributes[n] == nil then inst.Attributes[n] = defaultFor(tn) end
      Explorer.RefreshProperties()
     end,
    })
   elseif d.add == "tag" then
    openDialog({
     title = "Add tag",
     onSave = function(n)
      Explorer.AddTag(inst, n)
      Explorer.RefreshProperties()
     end,
    })
   end
  end)

  del.Activated:Connect(function()
   local d = r.data
   if d and d.kind == "tag" and P.Inst then
    removeTag(P.Inst, d.name)
    Explorer.RefreshProperties()
   end
  end)

  more.Activated:Connect(function()
   local d = r.data
   local inst = P.Inst
   if not d or not inst then return end
   local old = d.name
   openMenu(more, {
    { label = "Rename", act = "rename" },
    { label = "Delete", act = "delete", danger = true },
   }, function(it)
    if it.act == "delete" then
     inst.Attributes[old] = nil
     Explorer.RefreshProperties()
    else
     openDialog({
      title = "Rename attribute", name = old,
      validate = function(n)
       if n ~= old and inst.Attributes[n] ~= nil then return "Attribute already exists" end
      end,
      onSave = function(n)
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

 local function bind(r, d, i, nameW, contentW)
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
   r.arrow.Visible = true
   r.arrow.Position = UDim2.new(0, 4, 0.5, -8)
   r.arrow.Rotation = d.collapsed and 0 or 90
   r.name.FontFace = FONT.GothamMedium
   r.name.TextSize = 12
   r.name.TextColor3 = COLORS.TEXT_BRIGHT
   r.name.Position = UDim2.new(0, 24, 0, 0)
   r.name.Size = UDim2.new(1, -52, 1, 0)
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
  r.name.TextColor3 = COLORS.TEXT
  r.name.Text = d.name

  if d.kind == "tag" then
   r.name.Position = UDim2.new(0, 24, 0, 0)
   r.name.Size = UDim2.new(0, contentW - 56, 1, 0)
   r.del.Visible = true
   r.del.Position = UDim2.new(0, contentW - 24, 0.5, -9)
   return
  end

  local indent = d.sub and 16 or 0
  if d.expandable then
   r.arrow.Visible = true
   r.arrow.Position = UDim2.new(0, 4 + indent, 0.5, -8)
   r.arrow.Rotation = d.expanded and 90 or 0
  end
  r.name.Position = UDim2.new(0, 24 + indent, 0, 0)
  r.name.Size = UDim2.new(0, math.max(10, nameW - 28 - indent), 1, 0)
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
  local editable = (not d.readonly) and d.commit ~= nil
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
  r.value.Text = fmt(d.value)
  if t == "EnumItem" then
   r.value.TextEditable = false
   r.value.TextColor3 = COLORS.TEXT_BRIGHT
   if editable then
    r.hit.Visible = true
    r.hit.Position = UDim2.new(0, vx, 0, 0)
    r.hit.Size = UDim2.new(0, vw, 1, 0)
    r.chev.Visible = true
    r.chev.Position = UDim2.new(0, vx + vw - 16, 0.5, -4)
   end
  elseif editable and EDITABLE[t] then
   r.value.TextEditable = true
   r.value.TextColor3 = COLORS.TEXT_BRIGHT
  else
   r.value.TextEditable = false
   r.value.TextColor3 = COLORS.TEXT_DIM
  end
 end

 refreshList = function()
  if not pmain.Visible then return end
  local viewH = list.AbsoluteSize.Y
  local listW = list.AbsoluteSize.X
  if viewH <= 0 then return end
  local contentW = listW - 12
  local fullRows = math.floor(viewH / ROW)
  local need = math.ceil(viewH / ROW) + 1
  while #pool < need do pool[#pool + 1] = makeRow() end

  local total = #P.Rows
  local maxScroll = math.max(0, total - fullRows)
  P.Scroll = math.clamp(P.Scroll, 0, maxScroll)
  local nameW = math.floor(contentW * P.Divider)

  for i = 1, #pool do
   local r = pool[i]
   local d = P.Rows[P.Scroll + i]
   if d and (i - 1) * ROW < viewH then
    bind(r, d, i, nameW, contentW)
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

 local function updateHeader()
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
  rebuild()
  updateHeader()
  refreshList()
 end

 Explorer.PropsOnSelect = function()
  if P.Inst ~= Explorer.Selected then P.Scroll = 0 end
  Explorer.RefreshProperties()
 end

 list:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshList)

 filterBox:GetPropertyChangedSignal("Text"):Connect(function()
  P.Filter = filterBox.Text:match("^%s*(.-)%s*$"):lower()
  P.Scroll = 0
  Explorer.RefreshProperties()
 end)

 do
  local function maxScroll()
   return math.max(0, #P.Rows - math.floor(list.AbsoluteSize.Y / ROW))
  end
  local dragging, startPos, startScroll
  pvthumb.Active = true
  pvthumb.InputBegan:Connect(function(inp)
   if not isPress(inp) then return end
   if maxScroll() <= 0 then return end
   dragging = true
   startPos = inp.Position
   startScroll = P.Scroll
   pvvis.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
  end)
  pvbar.MouseEnter:Connect(function() if not dragging then pvvis.BackgroundColor3 = Color3.fromRGB(120, 120, 120) end end)
  pvbar.MouseLeave:Connect(function() if not dragging then pvvis.BackgroundColor3 = Color3.fromRGB(90, 90, 90) end end)
  SV.UserInput.InputChanged:Connect(function(inp)
   if not dragging then return end
   if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
   local m = maxScroll()
   local trackH = pvbar.AbsoluteSize.Y
   local usable = trackH * (1 - pvthumb.Size.Y.Scale)
   if usable > 0 and m > 0 then
    P.Scroll = math.floor(startScroll + (inp.Position.Y - startPos.Y) / usable * m + 0.5)
    refreshList()
   end
  end)
  SV.UserInput.InputEnded:Connect(function(inp)
   if isPress(inp) and dragging then
    dragging = false
    pvvis.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
   end
  end)
 end

 do
  local dragging, startX, startDiv
  divHit.InputBegan:Connect(function(inp)
   if not isPress(inp) then return end
   dragging = true
   startX = inp.Position.X
   startDiv = P.Divider
  end)
  SV.UserInput.InputChanged:Connect(function(inp)
   if not dragging then return end
   if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
   local w = math.max(1, list.AbsoluteSize.X - 12)
   P.Divider = math.clamp(startDiv + (inp.Position.X - startX) / w, 0.2, 0.75)
   refreshList()
  end)
  SV.UserInput.InputEnded:Connect(function(inp)
   if isPress(inp) then dragging = false end
  end)
 end

 SV.UserInput.InputChanged:Connect(function(input)
  if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
  if not pmain.Visible then return end
  local delta = input.Position.Z
  if delta == 0 then return end
  local mp = SV.UserInput:GetMouseLocation()
  local ap, as = pmain.AbsolutePosition, pmain.AbsoluteSize
  if mp.X < ap.X or mp.X > ap.X + as.X or mp.Y < ap.Y or mp.Y > ap.Y + as.Y then return end
  P.Scroll = P.Scroll - delta * 3
  refreshList()
 end)

 local function dockProps(side, order)
  PDock.Side = side
  if order then PDock.Order = order end
  layoutDocks()
 end

 local function undockProps()
  if not PDock.Side then return end
  local px, py = pmain.Position.X.Offset, pmain.Position.Y.Offset
  local w = pmain.Size.X.Offset
  PDock.Side = nil
  pmain.AnchorPoint = Vector2.new(0, 0)
  pmain.Position = UDim2.new(0, px, 0, py)
  pmain.Size = UDim2.new(0, w, 0, P.FloatH)
  pdocksplitter.Visible = false
  layoutDocks()
 end

 function Explorer.DockProperties(side, order)
  if side == nil then undockProps() else dockProps(side, order) end
 end

 ppin.Activated:Connect(function()
  if PDock.Side then undockProps() else dockProps(nearestSide(pmain)) end
 end)

 MakeDraggable(pmain, hdr, {
  blockCheck = function() return Explorer.PanelResizing[pmain] end,
  threshold = 4,
  onBegin = function() if PDock.Side then undockProps() end end,
  onDrag = function(cursor)
   local side, zone = resolveDrop(pmain, main, config.DockSide, main.Visible, cursor)
   showHint(pmain, main, side, zone)
  end,
  onEnd = function(didDrag, cursor)
   dockHint.Visible = false
   if not didDrag then return end
   local side, zone = resolveDrop(pmain, main, config.DockSide, main.Visible, cursor)
   if not side then return end
   local order
   if zone then order = (zone == "top") and "above" or "below" end
   dockProps(side, order)
  end,
 })

 local function onPropsResize(newSize)
  if PDock.Side then
   if isStacked() then
    main.Size = UDim2.new(0, newSize.X.Offset, 0, main.Size.Y.Offset)
    config.NormalSize = UDim2.new(0, newSize.X.Offset, 0, config.NormalSize.Y.Offset)
   end
   layoutDocks()
  else
   P.FloatH = newSize.Y.Offset
  end
 end

 local EDGE = config.EDGE
 local function notRight() return PDock.Side == "right" end
 local function notLeft() return PDock.Side == "left" end
 local function whenDocked() return PDock.Side ~= nil end
 MakeResizeHandler(220, 160, "right", 1, 0, 0, EDGE, 0, 1, EDGE * 2, -EDGE * 2, 8, pmain, notRight, onPropsResize)
 MakeResizeHandler(220, 160, "left", 0, 0, -EDGE * 2, EDGE, 0, 1, EDGE * 2, -EDGE * 2, 8, pmain, notLeft, onPropsResize)
 MakeResizeHandler(220, 160, "bottom", 0, 1, EDGE, 0, 1, 0, -EDGE * 2, EDGE * 2, 8, pmain, whenDocked, onPropsResize)
 MakeResizeHandler(220, 160, "top", 0, 0, EDGE, -EDGE * 2, 1, 0, -EDGE * 2, EDGE * 2, 8, pmain, whenDocked, onPropsResize)
 MakeResizeHandler(220, 160, "top_left", 0, 0, -EDGE * 2, -EDGE * 2, 0, 0, EDGE * 2, EDGE * 2, 9, pmain, whenDocked, onPropsResize)
 MakeResizeHandler(220, 160, "top_right", 1, 0, 0, -EDGE * 2, 0, 0, EDGE * 2, EDGE * 2, 9, pmain, whenDocked, onPropsResize)
 MakeResizeHandler(220, 160, "bottom_left", 0, 1, -EDGE * 2, 0, 0, 0, EDGE * 2, EDGE * 2, 9, pmain, whenDocked, onPropsResize)
 MakeResizeHandler(220, 160, "bottom_right", 1, 1, 0, 0, 0, 0, EDGE * 2, EDGE * 2, 9, pmain, whenDocked, onPropsResize)

 function Explorer.OpenProperties()
  if pmain.Visible then return end
  pmain.Visible = true
  layoutDocks()
  Explorer.RefreshProperties()
 end
 function Explorer.CloseProperties()
  if not pmain.Visible then return end
  closeMenu()
  pmain.Visible = false
  layoutDocks()
 end
 function Explorer.ToggleProperties()
  if pmain.Visible then Explorer.CloseProperties() else Explorer.OpenProperties() end
 end
 function Explorer.IsPropertiesOpen() return pmain.Visible end
 if config.SetPropertiesActive then
  config.SetPropertiesActive(pmain.Visible)
  pmain:GetPropertyChangedSignal("Visible"):Connect(function() config.SetPropertiesActive(pmain.Visible) end)
 end

 pclose.Activated:Connect(Explorer.CloseProperties)

 SV.UserInput.InputBegan:Connect(function(inp, gpe)
  if gpe then return end
  local alt = SV.UserInput:IsKeyDown(Enum.KeyCode.LeftAlt) or SV.UserInput:IsKeyDown(Enum.KeyCode.RightAlt)
  local ctrl = SV.UserInput:IsKeyDown(Enum.KeyCode.LeftControl) or SV.UserInput:IsKeyDown(Enum.KeyCode.RightControl)
  local shift = SV.UserInput:IsKeyDown(Enum.KeyCode.LeftShift) or SV.UserInput:IsKeyDown(Enum.KeyCode.RightShift)
  if inp.KeyCode == Enum.KeyCode.P then
   if alt then
    Explorer.ToggleProperties()
   elseif ctrl and shift and pmain.Visible then
    filterBox:CaptureFocus()
   end
  end
 end)
end

function Explorer.DumpFunctions(scr)
	if scr ~= nil and typeof(scr) ~= "Instance" and type(scr) == "table" then
		scr = scr.Real
			or (scr.Metadata and scr.Metadata.Real)
			or scr
	end

	local MAX_DEPTH = 100

	local function getSource(f)
		local ok, src = pcall(debug.info, f, "s")
		return ok and src or nil
	end

	local hasNativeIsClosure = iscclosure ~= nil
	local function islclosure(f, cachedSrc)
		if hasNativeIsClosure then return not iscclosure(f) end
		local src = cachedSrc or getSource(f)
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

	local function safeStr(s)
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

	local function getfunctiondetails(func)
		local ok, name, source, numParams, isVarArg, line = pcall(debug.info, func, "nsal")
		if not ok then return "Unknown", "Unknown", 0, false, -1 end
		return (name and name ~= "" and name or "Anonymous"), source or "Unknown", numParams or 0, isVarArg or false, line or -1
	end

	local function dump_value(val, indent, index, visited, depth)
		visited = visited or {}
		depth = depth or 0
		if depth > MAX_DEPTH then
			AddLine(tostring(index) .. " = ... (depth " .. MAX_DEPTH .. " exceeded)", indent)
			return
		end
		local t = typeof(val)
		if t == "function" then
			local name = islclosure(val) and getfunctiondetails(val) or "[C Function]"
			AddLine(tostring(index) .. " [function] = " .. tostring(name), indent)
		elseif t == "table" then
			if visited[val] then
				AddLine(tostring(index) .. " [table] (circular reference)", indent)
			else
				visited[val] = true
				AddLine(tostring(index) .. " [table]:", indent)
				local ok = pcall(function()
					for k, v in next, val do
						dump_value(v, indent + 1, k, visited, depth + 1)
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
			pcall(function() s = safeStr(s) end)
			AddLine(tostring(index) .. " [" .. t .. "] = " .. s, indent)
		end
	end

	local function dump_function(func, indent, visitedFuncs)
		visitedFuncs = visitedFuncs or {}
		if visitedFuncs[func] or not islclosure(func) then return end
		visitedFuncs[func] = true
		local name, source, params, vararg, line = getfunctiondetails(func)
		AddLine("", 0)
		AddLine(string.format("Function: %s | Source: %s | Line: %d | Params: %d%s", name, source, line, params, vararg and "+" or ""), indent)

		if getupvals then
			local ok, ups = pcall(getupvals, func)
			if ok and typeof(ups) == "table" and next(ups) ~= nil then
				AddLine("Upvalues:", indent)
				local visitedValues = {}
				for k, v in ups do dump_value(v, indent + 1, k, visitedValues, 0) end
			end
		end
		if getconsts then
			local ok, consts = pcall(getconsts, func)
			if ok and typeof(consts) == "table" and next(consts) ~= nil then
				AddLine("Constants:", indent)
				local visitedValues = {}
				for i, c in consts do dump_value(c, indent + 1, i, visitedValues, 0) end
			end
		end
		if getprotos then
			local ok, protos = pcall(getprotos, func)
			if ok and typeof(protos) == "table" and next(protos) ~= nil then
				AddLine("Prototypes:", indent)
				for _, proto in protos do
					if typeof(proto) == "function" and islclosure(proto) then
						dump_function(proto, indent + 1, visitedFuncs)
					end
				end
			end
		end
	end

	local function isScriptMatch(func, cachedSrc)
		if not scr then return true end
		local src = cachedSrc or getSource(func)
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
				local src = hasNativeIsClosure and nil or getSource(obj)
				if islclosure(obj, src) and isScriptMatch(obj, src) then
					dump_function(obj, 1)
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

local SCRIPT_CLASSES = { Script = true, LocalScript = true, ModuleScript = true }
local srcOpen = false
local reloadSource

function Explorer.IsScript(inst)
 return inst ~= nil and SCRIPT_CLASSES[inst.ClassName] == true
end

function Explorer.IsSourceOpen() return srcOpen end

function Explorer.SetSource(target, source)
 if type(target) == "function" then
  Explorer.SourceProvider = target
 elseif target ~= nil then
  Explorer.Sources[target] = source
 end
 if reloadSource then reloadSource(target) end
end

function Explorer.GetSource(inst)
 local s = Explorer.Sources[inst]
 if type(s) == "function" then
  local ok, r = pcall(s, inst)
  s = ok and r or nil
 end
 if s == nil then
  local ok, r = pcall(function() return inst.Source end)
  if ok then s = r end
 end
 local realRef = inst.Real or inst.Metadata.Real
 if s == nil and realRef then
  local real = realRef
  local ok, r = pcall(function() return real.Source end)
  if ok and type(r) == "string" and r ~= "" then s = r end
  if s == nil and decompile then
   local ok2, r2 = pcall(decompile, real)
   if ok2 and type(r2) == "string" then s = r2 end
  end
 end
 if s == nil and Explorer.SourceProvider then
  local ok, r = pcall(Explorer.SourceProvider, inst)
  if ok then s = r end
 end
 if s ~= nil and type(s) ~= "string" then s = tostring(s) end
 return s
end

do
 local LH, TS, CODE_FONT = 18, 14, Enum.Font.Code
 local TEXT_PLAIN = Color3.fromRGB(204, 204, 204)

 local function esc(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
 end

 local function highlightWithModule(H, line, state)
  local cc = state ~= nil and state.kind == "comment"
  local cs = state ~= nil and state.kind == "string"
  local lvl = state and state.level or 0
  local tokens, ec, cml, es, sl = H.Tokenize(line, cc, lvl, cs, lvl)
  local colors = H.SyntaxColors or {}
  local out = {}
  for k, tok in ipairs(tokens) do
   local c = tok.type ~= "plain" and colors[tok.type] or nil
   if c then out[k] = '<font color="' .. c .. '">' .. esc(tok.value) .. "</font>"
   else out[k] = esc(tok.value) end
  end
  local ns = nil
  if ec then ns = { kind = "comment", level = cml }
  elseif es then ns = { kind = "string", level = sl } end
  return table.concat(out), ns
 end

 local C_KEYWORD, C_BUILTIN = "#f86d7c", "#84d6f7"
 local C_STRING, C_NUMBER, C_COMMENT = "#adf195", "#ffc600", "#6a6a6a"
 local KEYWORDS, BUILTINS = {}, {}
 for w in ("and break continue do else elseif end false for function goto if in local nil not or repeat return then true until while"):gmatch("%S+") do KEYWORDS[w] = true end
 for w in ("print warn error assert pcall xpcall require game workspace script typeof type tostring tonumber ipairs pairs next select unpack setmetatable getmetatable rawget rawset rawequal rawlen task math string table os coroutine buffer bit32 utf8 Instance Vector2 Vector3 CFrame Color3 BrickColor UDim UDim2 Enum Random Ray Rect TweenInfo tick time wait spawn delay shared _G _VERSION"):gmatch("%S+") do BUILTINS[w] = true end

 local function highlightBuiltin(line, state)
  local out, n, i = {}, #line, 1
  local function push(text, c)
   if text == "" then return end
   if c then out[#out + 1] = '<font color="' .. c .. '">' .. esc(text) .. "</font>"
   else out[#out + 1] = esc(text) end
  end
  if state then
   local close = "]" .. string.rep("=", state.level) .. "]"
   local _, e = line:find(close, 1, true)
   local c = state.kind == "comment" and C_COMMENT or C_STRING
   if e then push(line:sub(1, e), c) i = e + 1 state = nil
   else push(line, c) return table.concat(out), state end
  end
  while i <= n do
   local ch = line:sub(i, i)
   if ch == "-" and line:sub(i + 1, i + 1) == "-" then
    local lvl = line:match("^%-%-%[(=*)%[", i)
    if lvl then
     local _, e = line:find("]" .. lvl .. "]", i, true)
     if e then push(line:sub(i, e), C_COMMENT) i = e + 1
     else push(line:sub(i), C_COMMENT) return table.concat(out), { kind = "comment", level = #lvl } end
    else
     push(line:sub(i), C_COMMENT) i = n + 1
    end
   elseif ch == '"' or ch == "'" or ch == "`" then
    local j = i + 1
    while j <= n do
     local c2 = line:sub(j, j)
     if c2 == "\\" then j += 2
     elseif c2 == ch then break
     else j += 1 end
    end
    push(line:sub(i, math.min(j, n)), C_STRING) i = j + 1
   elseif ch == "[" and line:match("^%[=*%[", i) then
    local lvl = line:match("^%[(=*)%[", i)
    local _, e = line:find("]" .. lvl .. "]", i, true)
    if e then push(line:sub(i, e), C_STRING) i = e + 1
    else push(line:sub(i), C_STRING) return table.concat(out), { kind = "string", level = #lvl } end
   elseif ch:match("%d") or (ch == "." and line:sub(i + 1, i + 1):match("%d")) then
    local num = line:match("^0[xX][%x_]+", i) or line:match("^0[bB][01_]+", i)
     or line:match("^%d[%d_]*%.?%d*[eE][%+%-]?%d+", i) or line:match("^%d[%d_]*%.?%d*", i)
     or line:match("^%.%d+", i) or ch
    push(num, C_NUMBER) i += #num
   elseif ch:match("[%a_]") then
    local word = line:match("^[%w_]+", i)
    local prev = i > 1 and line:sub(i - 1, i - 1) or ""
    local c = nil
    if prev ~= "." and prev ~= ":" then
     c = KEYWORDS[word] and C_KEYWORD or (BUILTINS[word] and C_BUILTIN) or nil
    end
    push(word, c) i += #word
   elseif ch:match("%s") then
    local ws = line:match("^%s+", i)
    push(ws) i += #ws
   else
    push(ch) i += 1
   end
  end
  return table.concat(out), nil
 end

 local function highlightLine(line, state)
  local H = Explorer.Highlighter
  if H then
   local ok, r, ns = pcall(highlightWithModule, H, line, state)
   if ok then return r, ns end
  end
  return highlightBuiltin(line, state)
 end

 local panel = Instance.new("Frame")
 panel.Name = randomString()
 panel.BackgroundColor3 = COLORS.PRIMARY
 panel.BackgroundTransparency = config.NT
 panel.BorderSizePixel = 0
 panel.Active = true
 panel.ZIndex = 1
 panel.Visible = false
 panel.ClipsDescendants = true
 panel.Archivable = false
 panel.Parent = window

 local hdr = Instance.new("Frame")
 hdr.Name = randomString()
 hdr.Size = UDim2.new(1, 0, 0, 28)
 hdr.BackgroundColor3 = COLORS.HEADER
 hdr.BorderSizePixel = 0
 hdr.ZIndex = 3
 hdr.Archivable = false
 hdr.Parent = panel

 local hicon = Instance.new("ImageLabel")
 hicon.Name = randomString()
 hicon.Size = UDim2.new(0, 18, 0, 18)
 hicon.Position = UDim2.new(0, 8, 0.5, -9)
 hicon.BackgroundTransparency = 1
 hicon.ZIndex = 4
 hicon.Archivable = false
 hicon.Parent = hdr

 local htitle = Instance.new("TextLabel")
 htitle.Name = randomString()
 htitle.Size = UDim2.new(1, -210, 1, 0)
 htitle.Position = UDim2.new(0, 32, 0, 0)
 htitle.BackgroundTransparency = 1
 htitle.RichText = true
 htitle.Text = ""
 htitle.TextColor3 = COLORS.TEXT_BRIGHT
 htitle.FontFace = FONT.GothamRegular
 htitle.TextSize = 12
 htitle.TextXAlignment = Enum.TextXAlignment.Left
 htitle.TextTruncate = Enum.TextTruncate.AtEnd
 htitle.ZIndex = 4
 htitle.Archivable = false
 htitle.Parent = hdr

 local hclose = Instance.new("TextButton")
 hclose.Name = randomString()
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
 hcopy.Name = randomString()
 hcopy.Size = UDim2.new(0, 52, 0, 20)
 hcopy.Position = UDim2.new(1, -88, 0.5, -10)
 hcopy.BackgroundColor3 = COLORS.SECONDARY
 hcopy.BackgroundTransparency = 0.5
 hcopy.AutoButtonColor = true
 hcopy.Text = "Copy"
 hcopy.TextColor3 = COLORS.TEXT_BRIGHT
 hcopy.FontFace = FONT.GothamMedium
 hcopy.TextSize = 11
 hcopy.BorderSizePixel = 0
 hcopy.ZIndex = 4
 hcopy.Archivable = false
 hcopy.Parent = hdr
 RoundCorner(hcopy, 0, 6)

local hdump = Instance.new("TextButton")
hdump.Name = randomString()
hdump.Size = UDim2.new(0, 52, 0, 20)
hdump.Position = UDim2.new(1, -144, 0.5, -10)
hdump.BackgroundColor3 = COLORS.SECONDARY
hdump.BackgroundTransparency = 0.5
hdump.AutoButtonColor = true
hdump.Text = "Dump"
hdump.TextColor3 = COLORS.TEXT_BRIGHT
hdump.FontFace = FONT.GothamMedium
hdump.TextSize = 11
hdump.BorderSizePixel = 0
hdump.ZIndex = 4
hdump.Archivable = false
hdump.Parent = hdr
RoundCorner(hdump, 0, 6)

 local sBody = Instance.new("Frame")
 sBody.Name = randomString()
 sBody.Size = UDim2.new(1, 0, 1, -28)
 sBody.Position = UDim2.new(0, 0, 0, 28)
 sBody.BackgroundTransparency = 1
 sBody.ZIndex = 3
 sBody.Archivable = false
 sBody.Parent = panel

 local sScroll = Instance.new("Frame")
 sScroll.Name = randomString()
 sScroll.Size = UDim2.new(1, -12, 1, -8)
 sScroll.Position = UDim2.new(0, 0, 0, 0)
 sScroll.BackgroundTransparency = 1
 sScroll.ClipsDescendants = true
 sScroll.ZIndex = 3
 sScroll.Archivable = false
 sScroll.Parent = sBody

 local sCode = Instance.new("Frame")
 sCode.Name = randomString()
 sCode.BackgroundTransparency = 1
 sCode.ClipsDescendants = true
 sCode.Size = UDim2.new(1, -40, 1, 0)
 sCode.Position = UDim2.new(0, 40, 0, 0)
 sCode.ZIndex = 3
 sCode.Archivable = false
 sCode.Parent = sScroll

 local sGutter = Instance.new("Frame")
 sGutter.Name = randomString()
 sGutter.BackgroundColor3 = COLORS.HEADER
 sGutter.BackgroundTransparency = 0.5
 sGutter.BorderSizePixel = 0
 sGutter.ClipsDescendants = true
 sGutter.Size = UDim2.new(0, 40, 1, 0)
 sGutter.ZIndex = 4
 sGutter.Archivable = false
 sGutter.Parent = sScroll

 local sVbar = Instance.new("Frame")
 sVbar.Name = randomString()
 sVbar.Size = UDim2.new(0, 10, 1, 0)
 sVbar.Position = UDim2.new(1, -10, 0, 0)
 sVbar.BackgroundTransparency = 1
 sVbar.BorderSizePixel = 0
 sVbar.Visible = false
 sVbar.ZIndex = 4
 sVbar.Archivable = false
 sVbar.Parent = sBody

 local sVthumb = Instance.new("Frame")
 sVthumb.Name = randomString()
 sVthumb.Size = UDim2.new(1, 0, 0.2, 0)
 sVthumb.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
 sVthumb.BorderSizePixel = 0
 sVthumb.ZIndex = 5
 sVthumb.Archivable = false
 sVthumb.Parent = sVbar
 RoundCorner(sVthumb, 1, 0)

 local sHbar = Instance.new("Frame")
 sHbar.Name = randomString()
 sHbar.Size = UDim2.new(1, -10, 0, 10)
 sHbar.Position = UDim2.new(0, 0, 1, -10)
 sHbar.BackgroundTransparency = 1
 sHbar.BorderSizePixel = 0
 sHbar.Visible = false
 sHbar.ZIndex = 4
 sHbar.Archivable = false
 sHbar.Parent = sBody

 local sHthumb = Instance.new("Frame")
 sHthumb.Name = randomString()
 sHthumb.Size = UDim2.new(0.2, 0, 1, 0)
 sHthumb.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
 sHthumb.BorderSizePixel = 0
 sHthumb.ZIndex = 5
 sHthumb.Archivable = false
 sHthumb.Parent = sHbar
 RoundCorner(sHthumb, 1, 0)

 local charW = 8
 pcall(function()
  local w = SV.TextSrv:GetTextSize("WWWWWWWWWW", TS, CODE_FONT, Vector2.new(10000, 100)).X / 10
  if w > 2 then charW = w end
 end)

 local st = { inst = nil, raw = "", lines = {}, rich = {}, ind = {}, gen = 0, index = 0, hoff = 0, contentW = 0, gW = 40 }
 local entries = {}

 local INDENT_SIZE = 4
 local MAX_GUIDES = 48
 local GUIDE_TRANSPARENCY = 0.88

 local function computeIndents()
  local lines, ind = st.lines, {}
  local n = #lines
  local blank = {}
  for i = 1, n do
   local ws = lines[i]:match("^( *)")
   if lines[i]:match("^%s*$") then
    blank[i] = true
    ind[i] = 0
   else
    ind[i] = math.floor(#ws / INDENT_SIZE)
   end
  end
  local nextInd = 0
  local nxt = {}
  for i = n, 1, -1 do
   if blank[i] then nxt[i] = nextInd else nextInd = ind[i] nxt[i] = nextInd end
  end
  local prevInd = 0
  for i = 1, n do
   if blank[i] then
    ind[i] = math.min(prevInd, nxt[i])
   else
    prevInd = ind[i]
   end
  end
  st.ind = ind
 end

 local function createEntry()
  local num = Instance.new("TextLabel")
  num.Name = randomString()
  num.BackgroundTransparency = 1
  num.Font = CODE_FONT
  num.TextSize = TS
  num.TextColor3 = COLORS.TEXT_DIM
  num.TextXAlignment = Enum.TextXAlignment.Right
  num.Size = UDim2.new(1, -8, 0, LH)
  num.ZIndex = 5
  num.Visible = false
  num.Archivable = false
  num.Parent = sGutter

  local code = Instance.new("TextLabel")
  code.Name = randomString()
  code.BackgroundTransparency = 1
  code.RichText = true
  code.Font = CODE_FONT
  code.TextSize = TS
  code.TextColor3 = TEXT_PLAIN
  code.TextXAlignment = Enum.TextXAlignment.Left
  code.TextWrapped = false
  code.ZIndex = 3
  code.Visible = false
  code.Archivable = false
  code.Parent = sCode
  return { num = num, code = code, guides = {}, shown = 0 }
 end

 local function setGuides(e, count, y)
  count = math.min(count, MAX_GUIDES)
  local g = e.guides
  for k = #g + 1, count do
   local f = Instance.new("Frame")
   f.Name = randomString()
   f.BorderSizePixel = 0
   f.BackgroundColor3 = COLORS.WHITE
   f.BackgroundTransparency = GUIDE_TRANSPARENCY
   f.Size = UDim2.new(0, 1, 0, LH)
   f.ZIndex = 2
   f.Active = false
   f.Archivable = false
   f.Visible = false
   f.Parent = sCode
   g[k] = f
  end
  local step = INDENT_SIZE * charW
  local x0 = 8 - st.hoff
  for k = 1, count do
   local f = g[k]
   f.Position = UDim2.new(0, math.floor(x0 + (k - 1) * step + 0.5), 0, y)
   f.Visible = true
  end
  for k = count + 1, e.shown do
   if g[k] then g[k].Visible = false end
  end
  e.shown = count
 end

 local function ensurePoolSize(n)
  for i = #entries + 1, n do entries[i] = createEntry() end
 end

 local function refresh()
  if not panel.Visible then return end
  local total = #st.lines
  local viewH = sScroll.AbsoluteSize.Y
  local viewW = sScroll.AbsoluteSize.X
  local codeW = math.max(0, viewW - st.gW)

  local visibleCount = math.max(1, math.ceil(viewH / LH) + 1)
  ensurePoolSize(visibleCount)

  local maxIndex = math.max(0, total - math.floor(viewH / LH))
  st.index = math.clamp(st.index, 0, maxIndex)
  local maxHOffset = math.max(0, st.contentW - codeW)
  st.hoff = math.clamp(st.hoff, 0, maxHOffset)
  local rowW = math.max(codeW, st.contentW)

  sGutter.Size = UDim2.new(0, st.gW, 1, 0)
  sCode.Position = UDim2.new(0, st.gW, 0, 0)
  sCode.Size = UDim2.new(1, -st.gW, 1, 0)

  for i = 1, #entries do
   local e = entries[i]
   local ln = st.index + i
   if i <= visibleCount and ln <= total then
    e.num.Visible = true
    e.code.Visible = true
    e.num.Position = UDim2.new(0, 0, 0, (i - 1) * LH)
    e.code.Position = UDim2.new(0, 8 - st.hoff, 0, (i - 1) * LH)
    e.code.Size = UDim2.new(0, rowW, 0, LH)
    local txt = st.rich[ln]
    if e.code.Text ~= txt then e.code.Text = txt end
    local ns = tostring(ln)
    if e.num.Text ~= ns then e.num.Text = ns end
    setGuides(e, st.ind[ln] or 0, (i - 1) * LH)
   else
    e.num.Visible = false
    e.code.Visible = false
    if e.shown > 0 then setGuides(e, 0, 0) end
   end
  end

  if total * LH > viewH then
   sVbar.Visible = true
   local thumbFrac = math.clamp(viewH / (total * LH), 0.05, 1)
   sVthumb.Size = UDim2.new(1, 0, thumbFrac, 0)
   local posFrac = maxIndex > 0 and (st.index / maxIndex) * (1 - thumbFrac) or 0
   sVthumb.Position = UDim2.new(0, 0, posFrac, 0)
  else
   sVbar.Visible = false
  end

  if st.contentW > codeW then
   sHbar.Visible = true
   sHbar.Position = UDim2.new(0, st.gW, 1, -10)
   sHbar.Size = UDim2.new(1, -st.gW - 10, 0, 10)
   local thumbFrac = math.clamp(codeW / st.contentW, 0.05, 1)
   sHthumb.Size = UDim2.new(thumbFrac, 0, 1, 0)
   local posFrac = maxHOffset > 0 and (st.hoff / maxHOffset) * (1 - thumbFrac) or 0
   sHthumb.Position = UDim2.new(posFrac, 0, 0, 0)
  else
   sHbar.Visible = false
  end
 end

 local function pointIn(gui, mp)
  local ap, as = gui.AbsolutePosition, gui.AbsoluteSize
  return mp.X >= ap.X and mp.X <= ap.X + as.X and mp.Y >= ap.Y and mp.Y <= ap.Y + as.Y
 end

 SV.UserInput.InputChanged:Connect(function(input)
  if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
  if not panel.Visible then return end
  local delta = input.Position.Z
  if delta == 0 then return end
  local mp = Vector2.new(input.Position.X, input.Position.Y)
  if not pointIn(panel, mp) then return end
  if main.Visible and pointIn(main, mp) then return end
  local viewH = sScroll.AbsoluteSize.Y
  local maxIdx = math.max(0, #st.lines - math.floor(viewH / LH))
  st.index = math.clamp(st.index - delta * 3, 0, maxIdx)
  refresh()
 end)

 local function draggable(thumb, track, isHorizontal)
  local dragging, startPos, startScroll
  thumb.InputBegan:Connect(function(inp)
   if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
   dragging = true
   startPos = inp.Position
   startScroll = isHorizontal and st.hoff or st.index
  end)
  SV.UserInput.InputChanged:Connect(function(inp)
   if not dragging then return end
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
   refresh()
  end)
  SV.UserInput.InputEnded:Connect(function(inp)
   if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
    dragging = false
   end
  end)
 end
 draggable(sVthumb, sVbar, false)
 draggable(sHthumb, sHbar, true)

 sScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh)

 local function setHeader(inst)
  applyIcon(hicon, inst.ClassName)
  htitle.Text = escape(inst.Name) .. '  <font color="#646464">' .. escape(inst.ClassName) .. "</font>"
 end

 local function load(inst, keepScroll)
  local src = Explorer.GetSource(inst)
  if src == nil then
   src = ""
  end
  st.inst, st.raw = inst, src
  st.gen += 1
  local gen = st.gen

  local s = src:gsub("\r\n", "\n")
  s = s:gsub("\r", "\n")
  s = s:gsub("\t", "    ")
  local lines, rich, maxLen = {}, {}, 0
  for line in (s .. "\n"):gmatch("(.-)\n") do
   if #line > 4000 then line = line:sub(1, 4000) .. " ..." end
   lines[#lines + 1] = line
   rich[#rich + 1] = esc(line)
   if #line > maxLen then maxLen = #line end
  end
  st.lines, st.rich = lines, rich
  computeIndents()

  local total = #lines
  st.gW = #tostring(total) * charW + 20
  st.contentW = maxLen * charW + 40
  if not keepScroll then st.index, st.hoff = 0, 0 end
  setHeader(inst)
  refresh()

  if #src > 600000 then return end
  task.spawn(function()
   local state = nil
   for i = 1, total do
    local ok, r, ns = pcall(highlightLine, lines[i], state)
    if ok then rich[i] = r state = ns else state = nil end
    if i % 400 == 0 then
     refresh()
     task.wait()
     if st.gen ~= gen then return end
    end
   end
   if st.gen == gen then refresh() end
  end)
 end

 local function layout()
  local scr = window.AbsoluteSize
  local x0, x1 = 0, scr.X
  local function claim(gui, side)
   if not gui or not gui.Visible then return end
   if side == "left" then
    x0 = math.max(x0, gui.AbsolutePosition.X + gui.AbsoluteSize.X)
   elseif side == "right" then
    x1 = math.min(x1, gui.AbsolutePosition.X)
   end
  end
  claim(main, config.DockSide)
  claim(pmain, PDock.Side)
  local w = x1 - x0
  local inset = topInset()
  panel.Position = UDim2.new(0, x0, 0, inset)
  panel.Size = UDim2.new(0, math.max(0, w), 1, -inset)
  panel.Visible = srcOpen and main.Visible and w > 0
  refresh()
 end
 layoutSource = layout

 function Explorer.OpenSource(inst)
  if not inst then return end
  srcOpen = true
  layout()
  load(inst, st.inst == inst)
 end

 function Explorer.CloseSource()
  srcOpen = false
  layout()
 end

 function Explorer.SetHighlighter(mod)
  if mod ~= nil and (type(mod) ~= "table" or type(mod.Tokenize) ~= "function") then return false end
  Explorer.Highlighter = mod
  if srcOpen and st.inst then load(st.inst, true) end
  return true
 end

 reloadSource = function(target)
  if not srcOpen or not st.inst then return end
  if type(target) == "function" or target == st.inst then load(st.inst, true) end
 end

 hclose.Activated:Connect(Explorer.CloseSource)
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
 	hdump.TextColor3 = COLORS.TEXT_DIM

 	local inst = st.inst
 	task.spawn(function()
 		local dumpText = Explorer.DumpFunctions(inst)
 		hdump.Text = "Dump"
 		hdump.TextColor3 = COLORS.TEXT_BRIGHT

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
 			if #line > 4000 then line = line:sub(1, 4000) .. " ..." end
 			newLines[#newLines + 1] = line
 		end

 		local baseLen = #st.lines
 		for _, line in ipairs(newLines) do
 			st.lines[#st.lines + 1] = line
 			st.rich[#st.rich + 1] = esc(line)
 		end

 		computeIndents()
 		st.gW = #tostring(#st.lines) * charW + 20
 		local maxLen = 0
 		for _, line in ipairs(st.lines) do
 			if #line > maxLen then maxLen = #line end
 		end
 		st.contentW = maxLen * charW + 40

 		local gen = st.gen
 		task.spawn(function()
 			local state = nil
 			for i = baseLen + 1, #st.lines do
 				local ok, r, ns = pcall(highlightLine, st.lines[i], state)
 				if ok then st.rich[i] = r state = ns else state = nil end
 				if i % 400 == 0 then
 					refresh()
 					task.wait()
 					if st.gen ~= gen then return end
 				end
 			end
 			if st.gen == gen then refresh() end
 		end)
 	end)
 end)

 main:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
 main:GetPropertyChangedSignal("AbsolutePosition"):Connect(layout)
 main:GetPropertyChangedSignal("Visible"):Connect(layout)
 window:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
 pmain:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
 pmain:GetPropertyChangedSignal("AbsolutePosition"):Connect(layout)
 pmain:GetPropertyChangedSignal("Visible"):Connect(layout)

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

 local function currentRoot()
  if Explorer.Mode ~= "Game" then return virtualRoot end
  return showNil and nilRoot or gameRoot
 end

 local function safe(f, ...)
  local ok, r = pcall(f, ...)
  if ok then return r end
  return nil
 end

 local function readParent(i) return i.Parent end
 local function readNameOf(i) return i.Name end

 local function vOf(real)
  if real == nil then return nil end
  local v = realToV[real]
  if v then return v end
  local ok, par = pcall(readParent, real)
  if ok and par == game then
   local okN, nm = pcall(readNameOf, real)
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

 local function mirrorOne(real, parent)
  local ok, name, class = pcall(readInfo, real)
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

 local function finish()
  Explorer.ScanTree()
  RefreshTree()
  if Explorer.RefreshProperties then Explorer.RefreshProperties() end
 end

 local function clearGameRoot()
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
  clearGameRoot()
  for i, svcName in ipairs(Services) do
   local svc = safe(GetService, svcName)
   if svc then
    local v = mirrorOne(cloneref(svc), gameRoot)
    if v then
     v.Name = svcName
     v.Metadata.Order = i
    end
   end
  end
  local have = {}
  for _, c in ipairs(gameRoot.Children) do have[c.Name] = true end
  local okC, top = pcall(game.GetChildren, game)
  if okC and type(top) == "table" then
   for j = 1, #top do
    local kid = top[j]
    local okN, nm = pcall(readNameOf, kid)
    if okN and not have[nm] and kid ~= folder then
     local v = mirrorOne(cloneref(kid), gameRoot)
     if v then
      have[nm] = true
      v.Metadata.Order = #Services + j
     end
    end
   end
  end
  scanning = false
  scanned = true
  finish()
  if config.SearchQuery ~= "" then Explorer.EnsureDeepLoad() end
 end

 local function unregister(v)
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

 local function dropDetachedSelection()
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
  local list = safe(getnilinstances) or {}
  local existing = {}
  for _, c in ipairs(nilRoot.Children) do
   if c.Real then existing[c.Real] = c end
  end
  local present = {}
  local added, removed = false, false
  local t0 = os.clock()
  for i = 1, #list do
   local real = list[i]
   local ok, par = pcall(readParent, real)
   if ok and par == nil then
    present[real] = true
    if not existing[real] and mirrorOne(real, nilRoot) then added = true end
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
    unregister(c)
    removed = true
   end
  end
  if removed then
   nilRoot.Children = keep
   nilRoot._sorted = nil
   dropDetachedSelection()
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
     if config.SearchQuery ~= "" and Explorer.Mode == "Game" and t0 - lastRefresh > 0.6 then
      lastRefresh = t0
      Explorer.ScanTree()
      RefreshTree()
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

 local function applyRoot()
  Explorer.Selected = nil
  Explorer.SelectedSet = {}
  config.Anchor = nil
  Explorer.Root = currentRoot()
  deepLoaded, deepRunning = false, false
  deepToken += 1
  finish()
  if Explorer.PropsOnSelect then Explorer.PropsOnSelect() end
  if Explorer.OnSelectCb then pcall(Explorer.OnSelectCb, nil) end
  if config.SearchQuery ~= "" then Explorer.EnsureDeepLoad() end
 end

 local nilBtn
 nilBtn = Explorer.AddMenuButton("Nil Instances", function()
  if Explorer.Mode ~= "Game" then return end
  showNil = not showNil
  applyRoot()
  if showNil and not scanning and #nilRoot.Children == 0 then
   task.spawn(ScanNilInstances)
  end
 end)

 function Explorer.SetMode(mode)
  if mode ~= "Game" and mode ~= "Virtual" then return false end
  if Explorer.Mode == mode then return true end
  Explorer.Mode = mode
  Explorer.Selected = nil
  Explorer.SelectedSet = {}
  config.Anchor = nil
  Explorer.Root = currentRoot()
  nilBtn.Visible = (mode == "Game")
  if mode == "Game" and not scanned then
   task.spawn(function() ScanGame() ScanNilInstances() end)
  end
  finish()
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

  local function readName(i) return i.Name end

  local function onAdded(inst)
   if vOf(inst.Parent) then
    addN += 1
    addQ[addN] = inst
   end
  end

  local function onRemoving(inst)
   local v = realToV[inst]
   if v then
    removeQ[v] = true
   else
    local pv = vOf(inst.Parent)
    if pv and not pv.Loaded then pv.HasKids = nil end
   end
  end

  local function markParent(pv)
   if pv == Explorer.Root then rowsDirty = true return end
   local idx = Explorer.RowIndex
   if idx and idx[pv] then
    if Explorer.Expanded[pv] == true then rowsDirty = true else drawDirty = true end
   end
  end

  local function bsearch(cache, key, n)
   local lo, hi = 1, n + 1
   while lo < hi do
    local mid = (lo + hi) // 2
    if refreshKey(cache[mid]) <= key then lo = mid + 1 else hi = mid end
   end
   return lo
  end

  local function sortedInsert(pv, v)
   local ch = pv.Children
   local n = #ch
   ch[n + 1] = v
   local cache = pv._sorted
   if cache and #cache == n then
    table.insert(cache, bsearch(cache, refreshKey(v), n), v)
    pv._live = true
   else
    pv._sorted = nil
   end
  end

  local function reposition(pv, v)
   local cache = pv._sorted
   if cache and pv._live then
    local old = table.find(cache, v)
    if old then
     table.remove(cache, old)
     local pos = bsearch(cache, refreshKey(v), #cache)
     table.insert(cache, pos, v)
     return pos ~= old
    end
   end
   pv._sorted = nil
   return true
  end

  local function filterOut(arr, set)
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

  local function processRemovals()
   local byParent, any = {}, false
   for v in pairs(removeQ) do
    removeQ[v] = nil
    local pv, r = v.Parent, v.Real
    local pr = pv and pv.Real
    if r and pr then
     local ok, cur = pcall(readParent, r)
     if not (ok and cur ~= nil and vOf(cur) == pv) then
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
     filterOut(ch, set)
     if cacheOk then filterOut(cache, set) end
    end
    if not cacheOk then pv._sorted = nil end
    for v in pairs(set) do
     v.Parent = nil
     unregister(v)
    end
    any = true
    markParent(pv)
   end
   if any then dropDetachedSelection() end
  end

  local function processAdds(t0)
   local count, added = 0, false
   while addHead <= addN do
    local inst = addQ[addHead]
    addQ[addHead] = nil
    addHead += 1
    count += 1
    if inst ~= folder then
     local pv = vOf(inst.Parent)
     if pv then
      if not pv.Loaded then
       if pv.HasKids ~= true then
        pv.HasKids = true
        local idx = Explorer.RowIndex
        if idx and idx[pv] then drawDirty = true end
       end
      elseif not realToV[inst] then
       local ok, name, class = pcall(readInfo, inst)
       if ok then
        local v = setmetatable({
         Name = tostring(name),
         ClassName = class or "Instance",
         Parent = pv,
         Children = {},
         Real = inst,
        }, VirtualInstance)
        sortedInsert(pv, v)
        realToV[inst] = v
        added = true
        markParent(pv)
       end
      end
     end
    end
    if count % 32 == 0 and os.clock() - t0 > ADD_BUDGET then break end
   end
   if addHead > addN then addQ, addHead, addN = {}, 1, 0 end
   return added
  end

  local function reconcile(pv)
   local real = pv.Real
   if not real or not pv.Loaded then return end
   local ok, kids = pcall(real.GetChildren, real)
   if not ok or type(kids) ~= "table" then return end
   local present, changed = {}, false
   for i = 1, #kids do
    local kid = kids[i]
    present[kid] = true
    if kid ~= folder and not realToV[kid] then
     local okI, name, class = pcall(readInfo, kid)
     if okI then
      local v = setmetatable({
       Name = tostring(name),
       ClassName = class or "Instance",
       Parent = pv,
       Children = {},
       Real = kid,
      }, VirtualInstance)
      sortedInsert(pv, v)
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
   if changed then markParent(pv) end
  end

  local RECON_INTERVAL = 0.25
  local reconCursor, lastRecon = 1, 0
  local function reconcileStep()
   local rows = config.visiblerows
   local n = #rows
   if n == 0 then return end
   for _ = 1, math.min(n, 32) do
    if reconCursor > n then reconCursor = 1 end
    local row = rows[reconCursor]
    reconCursor += 1
    local v = row.instance
    if row.expanded and v.Real and v.Loaded then
     reconcile(v)
     return
    end
   end
  end

  local function checkRow(row)
   local v = row and row.instance
   local r = v and v.Real
   if not r then return end
   local ok, name = pcall(readName, r)
   if not ok then return end
   name = tostring(name)
   if name == v.Name then return end
   v.Name = name
   drawDirty = true
   local p = v.Parent
   if p and reposition(p, v) then markParent(p) end
  end

  local function viewNames()
   local rows = config.visiblerows
   local from = config.ScrollIndex + 1
   local to = math.min(#rows, from + math.ceil(body.AbsoluteSize.Y / config.ROW_H) + 2)
   for i = from, to do checkRow(rows[i]) end
  end

  local function bgNames()
   local rows = config.visiblerows
   local n = #rows
   if n == 0 then return end
   if nameCursor > n then nameCursor = 1 end
   local t0, checked = os.clock(), 0
   while checked < n do
    checkRow(rows[nameCursor])
    nameCursor += 1
    if nameCursor > n then nameCursor = 1 end
    checked += 1
    if checked % 16 == 0 and os.clock() - t0 > BG_NAME_BUDGET then break end
   end
  end

  local function startBuild()
   local b = {
    rows = {}, index = {}, n = 0,
    sK = {}, sI = {}, sD = {}, top = 1,
    bestEst = -1, bestRow = nil,
    rev = config.RowsRev,
   }
   b.sK[1] = table.clone(sortedChildren(Explorer.Root))
   b.sI[1] = 1
   b.sD[1] = 0
   build = b
  end

  local function stepBuild(budget)
   local b = build
   local rows, index = b.rows, b.index
   local sK, sI, sD = b.sK, b.sI, b.sD
   local Expanded = Explorer.Expanded
   local INDENT = Positions.INDENT
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
      sK[top] = table.clone(sortedChildren(child))
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

  local function finishBuild()
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
   config.TreeWidthBase = br and (br.depth * Positions.INDENT + 44 + nameWidth(br.instance) + 60) or 0
   emptyLabel.Visible = (b.n == 0)
   drawDirty = false
   lastDraw = os.clock()
   RefreshTree()
  end

  local function step()
   local now = os.clock()
   local game_ = Explorer.Mode == "Game"
   if next(removeQ) ~= nil then processRemovals() end
   if addHead <= addN and processAdds(now) then addedSinceDeep = true end
   if game_ and not config.IsMinimized then
    if now - lastView >= VIEW_NAME_INTERVAL then
     lastView = now
     viewNames()
    end
    if now - lastBg >= BG_NAME_INTERVAL then
     lastBg = now
     bgNames()
    end
    if now - lastRecon >= RECON_INTERVAL then
     lastRecon = now
     reconcileStep()
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
    startBuild()
   end
   if build then
    if stepBuild(BUILD_BUDGET) then finishBuild() end
   elseif drawDirty and now - lastDraw >= DRAW_GAP then
    drawDirty = false
    lastDraw = now
    RefreshTree()
   end
  end

  local function loadKids(pv)
   if pv.Real and not pv.Loaded then Explorer.LoadChildren(pv) end
  end

  local function workspaceNode()
   for _, c in ipairs(gameRoot.Children) do
    if c.Name == "Workspace" then return c end
   end
   return nil
  end

  local function ensureNode(real, pv)
   if pv == nilRoot then return mirrorOne(real, nilRoot) end
   loadKids(pv)
   local v = realToV[real]
   if v then return v end
   local ok, name, class = pcall(readInfo, real)
   if not ok then return nil end
   v = setmetatable({
    Name = tostring(name),
    ClassName = class or "Instance",
    Parent = pv,
    Children = {},
    Real = real,
   }, VirtualInstance)
   sortedInsert(pv, v)
   realToV[real] = v
   return v
  end

  local G = {}
  Explorer.Game = G

  function G.isGame(v)
   return Explorer.Mode == "Game" and v ~= nil and (v.Real ~= nil or v == gameRoot or v == nilRoot)
  end

  function G.create(className, name, pv)
   if pv == gameRoot then
    pv = workspaceNode()
    if not pv then return nil end
   end
   loadKids(pv)
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
   return ensureNode(real, pv)
  end

  function G.destroy(v)
   if v.Parent == gameRoot then return false end
   local real = v.Real
   if real then
    local ok = pcall(real.Destroy, real)
    if not ok then return false end
   end
   unregister(v)
   return true
  end

  function G.rename(v, name)
   local ok = pcall(function() v.Real.Name = name end)
   if not ok then return false end
   v.Name = name
   local p = v.Parent
   if p then reposition(p, v) end
   return true
  end

  function G.move(src, pv)
   local real = src.Real
   if not real or pv == gameRoot then return false end
   loadKids(pv)
   local ok = pcall(function()
    if pv == nilRoot then real.Parent = nil else real.Parent = pv.Real end
   end)
   if not ok then return false end
   src:SetParent(pv)
   if pv == nilRoot then unregister(src) else realToV[real] = src end
   return true
  end

  function G.clone(src, pv)
   local real = src.Real
   if not real or pv == gameRoot then return nil end
   loadKids(pv)
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
   return ensureNode(c, pv)
  end

  local gm = cloneref(game)
  pcall(function() gm.DescendantAdded:Connect(onAdded) end)
  pcall(function() gm.DescendantRemoving:Connect(onRemoving) end)
  SV.RunSrv.Heartbeat:Connect(function()
   pcall(step)
  end)
 end

 task.spawn(function()
  repeat task.wait() until window.AbsoluteSize.X > 0
  if Explorer.Mode == "Game" and not scanned then
   ScanGame()
   ScanNilInstances()
  end
 end)
end

for _, v in ipairs(folder:GetDescendants()) do
 if v.RobloxLocked == false then v.RobloxLocked = true end
end

task.spawn(function()
 repeat task.wait() until window.AbsoluteSize.X > 0
 PDock.Side = "right"
 PDock.Order = "below"
 ApplyDock("right")
 Explorer.ScanTree()
 RefreshTree()
 Explorer.RefreshProperties()
end)

window:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
 if layoutDocks then layoutDocks() end
end)

getgenv().Explorer = Explorer
return Explorer
