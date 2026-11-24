do
 local EXACT = {}
 local function Key(r, g, b) return r * 65536 + g * 256 + b end
 for _, m in ipairs({
  { 28, 29, 35, 255, 255, 255 },
  { 43, 44, 50, 238, 239, 243 },
  { 61, 64, 71, 226, 228, 233 },
  { 63, 67, 75, 214, 217, 224 },
  { 70, 70, 70, 190, 190, 190 },
  { 100, 100, 100, 125, 125, 125 },
  { 200, 200, 200, 55, 55, 55 },
  { 220, 220, 220, 30, 30, 30 },
  { 0, 51, 225, 170, 200, 250 },
  { 45, 91, 242, 150, 185, 245 },
  { 125, 128, 175, 90, 94, 160 },
 }) do
  EXACT[Key(m[1], m[2], m[3])] = Color3.fromRGB(m[4], m[5], m[6])
 end

 local function MapColor(c)
  local r, g, b = math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)
  local hit = EXACT[Key(r, g, b)]
  if hit then return hit end
  local mx = math.max(r, g, b)
  if mx > 0 and (mx - math.min(r, g, b)) / mx > 0.3 then return c end
  local v = 255 - mx
  return Color3.fromRGB(v, v, v)
 end

 local function PropsFor(o)
  if o:IsA("UIStroke") then return { "Color" } end
  if not o:IsA("GuiObject") then return nil end
  local p = { "BackgroundColor3" }
  if o:IsA("TextLabel") or o:IsA("TextButton") then
   p[2] = "TextColor3"
  elseif o:IsA("TextBox") then
   p[2] = "TextColor3"
   p[3] = "PlaceholderColor3"
  elseif o:IsA("ImageLabel") or o:IsA("ImageButton") then
   p[2] = "ImageColor3"
  elseif o:IsA("ScrollingFrame") then
   p[2] = "ScrollBarImageColor3"
  end
  return p
 end

 local light, started = false, false
 local state = setmetatable({}, { __mode = "k" })
 local hooked = setmetatable({}, { __mode = "k" })

 local function IsSprite(o)
  return o.ImageRectSize ~= Vector2.zero or o.Image == config.IMG.ClassIcons or o.Image == config.IMG.ClassIconsLight
 end

 local function Sync(o, prop)
  local e = state[o]
  if not e then
   e = { orig = {}, mapped = {} }
   state[o] = e
  end
  local cur = o[prop]
  if e.mapped[prop] ~= cur then e.orig[prop] = cur end
  local want = e.orig[prop]
  if light and not (prop == "ImageColor3" and IsSprite(o)) then want = MapColor(want) end
  e.mapped[prop] = want
  if cur ~= want then o[prop] = want end
 end

 local function Hook(o)
  if hooked[o] then return end
  local props = PropsFor(o)
  if not props then return end
  hooked[o] = props
  for _, p in ipairs(props) do
   Sync(o, p)
   o:GetPropertyChangedSignal(p):Connect(function() Sync(o, p) end)
  end
  if o:IsA("ImageLabel") or o:IsA("ImageButton") then
   local function Re() Sync(o, "ImageColor3") end
   o:GetPropertyChangedSignal("Image"):Connect(Re)
   o:GetPropertyChangedSignal("ImageRectSize"):Connect(Re)
  end
 end

 local function Start()
  started = true
  for _, o in ipairs(config.window:GetDescendants()) do Hook(o) end
  config.window.DescendantAdded:Connect(Hook)
  if config.menuGui then
   for _, o in ipairs(config.menuGui:GetDescendants()) do Hook(o) end
   config.menuGui.DescendantAdded:Connect(Hook)
  end
 end

 local function SwapIcons(from, to)
  if from == to then return end
  for _, o in ipairs(config.window:GetDescendants()) do
   if (o:IsA("ImageLabel") or o:IsA("ImageButton")) and o.Image == from then o.Image = to end
  end
 end

 function Explorer.SetTheme(name)
  if name ~= "Dark" and name ~= "Light" then return false end
  light = name == "Light"
  config.Theme = name
  local darkId, lightId = config.IMG.ClassIcons, config.IMG.ClassIconsLight
  if lightId == nil or lightId == "" then lightId = darkId end
  local old = config.ICON_ID
  config.ICON_ID = light and lightId or darkId
  if not started then
   if not light then return true end
   Start()
  end
  SwapIcons(old, config.ICON_ID)
  for o, props in pairs(hooked) do
   for _, p in ipairs(props) do Sync(o, p) end
  end
  Explorer.ReloadHighlight()
  return true
 end

 function Explorer.GetTheme() return config.Theme end
end
