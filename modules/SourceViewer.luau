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
 local TEXT_PLAIN = Color3.fromRGB(255, 255, 255) -- KEEP
 config.SyntaxOverrides = {}
 config.Theme = "Dark"
 local LIGHT_SYNTAX = {
  keyword = "#D32F4F", string = "#2E7D32", value = "#B26A00", comment = "#7A7A7A", builtin = "#0277BD",
  property = "#1A5FB4", method = "#8A6D00", identifier = "#1F1F1F", plain = "#000000",
 }
 config.SyntaxKeys = { "keyword", "string", "value", "comment", "builtin", "property", "method", "identifier", "plain" }
 local FALLBACK_SYNTAX = {
  keyword = "#F86D7C", string = "#ADF195", value = "#FFC600", comment = "#666666", builtin = "#84D6F7",
  property = "#61A1F1", method = "#FDFBAC", identifier = "#F8F8F2", plain = "#FFFFFF",
 }
 local function HexToColor(h)
  local r, g, b = tostring(h):match("^#?(%x%x)(%x%x)(%x%x)$")
  if not r then return Color3.new(1, 1, 1) end
  return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
 end
 local function ColorToHex(c)
  return `#{string.format("%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))}`
 end
 function Explorer.GetSyntaxColors()
  local out = Explorer.GetSyntaxDefaults()
  for k, hex in pairs(config.SyntaxOverrides) do out[k] = HexToColor(hex) end
  return out
 end
 function Explorer.GetSyntaxDefaults()
  local out = {}
  local base = config.Theme == "Light" and LIGHT_SYNTAX or (Explorer.Highlighter and Explorer.Highlighter.SyntaxColors) or {}
  for _, k in ipairs(config.SyntaxKeys) do out[k] = HexToColor(base[k] or FALLBACK_SYNTAX[k]) end
  return out
 end

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
  local colors = config.Theme == "Light" and LIGHT_SYNTAX or H.SyntaxColors or {}
  local over = config.SyntaxOverrides
  local out = {}
  for k, tok in ipairs(tokens) do
   local c = over[tok.type] or (tok.type ~= "plain" and colors[tok.type] or nil)
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

 local tabBar = Instance.new("ScrollingFrame")
 tabBar.Name = RandomString()
 tabBar.Size = UDim2.new(1, -204, 1, 0)
 tabBar.Position = UDim2.new(0, 0, 0, 0)
 tabBar.BackgroundTransparency = 1
 tabBar.BorderSizePixel = 0
 tabBar.ScrollBarThickness = 0
 tabBar.ScrollingDirection = Enum.ScrollingDirection.X
 tabBar.ElasticBehavior = Enum.ElasticBehavior.Never
 tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
 tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
 tabBar.ClipsDescendants = true
 tabBar.ZIndex = 4
 tabBar.Archivable = false
 tabBar.Parent = hdr

 local tabLayout = Instance.new("UIListLayout")
 tabLayout.FillDirection = Enum.FillDirection.Horizontal
 tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
 tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
 tabLayout.Padding = UDim.new(0, 0)
 tabLayout.Parent = tabBar

 local tabs, tabOf, activeTab, tabSeq = {}, {}, nil, 0

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
 MakeCloseImage(hclose, 12, 5)

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
   if vVis ~= true then vVis = true; sVbar.Visible = true end
   if thumbFrac ~= vF then vF = thumbFrac; sVthumb.Size = UDim2.new(1, 0, thumbFrac, 0) end
   if posFrac ~= vP then vP = posFrac; sVthumb.Position = UDim2.new(0, 0, posFrac, 0) end
  elseif vVis ~= false then
   vVis = false
   sVbar.Visible = false
  end

  if st.contentW > codeW then
   local thumbFrac = math.clamp(codeW / st.contentW, 0.05, 1)
   local posFrac = maxHOffset > 0 and (st.hoff / maxHOffset) * (1 - thumbFrac) or 0
   if hVis ~= true then hVis = true; sHbar.Visible = true end
   if hGW ~= st.gW then
    hGW = st.gW
    sHbar.Position = UDim2.new(0, st.gW, 1, -10)
    sHbar.Size = UDim2.new(1, -st.gW - 10, 0, 10)
   end
   if thumbFrac ~= hF then hF = thumbFrac; sHthumb.Size = UDim2.new(thumbFrac, 0, 1, 0) end
   if posFrac ~= hP then hP = posFrac; sHthumb.Position = UDim2.new(posFrac, 0, 0, 0) end
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
  if PointIn(tabBar, mp) then
   tabBar.CanvasPosition = Vector2.new(math.max(0, tabBar.CanvasPosition.X - delta * 60), 0)
   return
  end
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
   if not config.Held(inp) then dragging = false; return end
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
  local t = tabOf[inst]
  if not t then return end
  ApplyIcon(t.icon, inst.ClassName)
  t.label.Text = inst.Name
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
     if ok then rich[i] = r; state = ns else state = nil end
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

 local headerCache = setmetatable({}, {__mode = "k"})

 local function BuildHeader(inst, ms)
  local ok, path = pcall(function() return inst:GetFullName() end)
  if not ok or type(path) ~= "string" then
   path = tostring(inst)
  else
   local inGame = true
   if typeof(inst) == "Instance" then
    local okD, d = pcall(function() return inst:IsDescendantOf(game) end)
    inGame = okD and d
   end
   if inGame then path = path == "" and "game" or "game." .. path end
  end
  local name, version = "Unknown", ""
  if identifyexecutor then
   local okE, n, v = pcall(identifyexecutor)
   if okE then
    if n ~= nil then name = tostring(n) end
    if v ~= nil then version = " " .. tostring(v) end
   end
  end
  return `--[[\n Time taken to decompile: {math.floor(ms + 0.5)}ms\n Script path: {path}\n Executor: {name}{version}\n]]\n\n`
 end

 local function Load(inst, keepScroll, force)
  local t0 = os.clock()
  local src = Explorer.GetSource(inst)
  local elapsed = (os.clock() - t0) * 1000
  if src == nil then
   src = ""
  end
  local cached = headerCache[inst]
  if cached and cached.src == src then
   elapsed = cached.ms
  else
   headerCache[inst] = { src = src, ms = elapsed }
  end
  if config.SourceHeaders ~= false then
   src = BuildHeader(inst, elapsed) .. src
  end
  local dumpTab = tabOf[inst]
  if dumpTab and dumpTab.dump then
   src = src .. dumpTab.dump
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
  for _, d in ipairs(config.DockMgr.Docked()) do Claim(d.gui, d.side) end
  local w = x1 - x0
  local inset = TopInset()
  panel.Position = UDim2.new(0, x0, 0, inset)
  panel.Size = UDim2.new(0, math.max(0, w), 1, -inset)
  panel.Visible = config.srcOpen and w > 0
  Refresh()
 end
 config.LayoutSource = Layout
 config.main:GetPropertyChangedSignal("Visible"):Connect(Layout)

 local function StyleTab(t)
  local active = t == activeTab
  local lit = active or t.hover
  if active then
   t.frame.BackgroundColor3 = config.COLORS.PRIMARY
   t.frame.BackgroundTransparency = config.NT
  elseif t.hover then
   t.frame.BackgroundColor3 = config.COLORS.SECONDARY
   t.frame.BackgroundTransparency = 0.5
  else
   t.frame.BackgroundTransparency = 1
  end
  t.label.TextColor3 = lit and config.COLORS.TEXT_BRIGHT or config.COLORS.TEXT
  t.close.ImageColor3 = t.closeHover and config.COLORS.WHITE
   or (lit and config.COLORS.TEXT or config.COLORS.TEXT_DIM)
 end

 local function ScrollTabIntoView(t)
  task.spawn(function()
   task.wait()
   task.wait()
   if not t.frame.Parent then return end
   local left = t.frame.AbsolutePosition.X - tabBar.AbsolutePosition.X + tabBar.CanvasPosition.X
   local right = left + t.frame.AbsoluteSize.X
   local viewW = tabBar.AbsoluteSize.X
   local cx = tabBar.CanvasPosition.X
   if left < cx then
    cx = left
   elseif right > cx + viewW then
    cx = right - viewW
   end
   tabBar.CanvasPosition = Vector2.new(math.max(0, cx), 0)
  end)
 end

 local SelectTab
 local function CloseTab(t)
  local i = table.find(tabs, t)
  if not i then return end
  table.remove(tabs, i)
  tabOf[t.inst] = nil
  t.frame:Destroy()
  if activeTab == t then
   activeTab = nil
   local n = tabs[i] or tabs[i - 1]
   if n then
    SelectTab(n)
   else
    Explorer.CloseSource()
   end
  end
 end

 local function CreateTab(inst)
  local t = { inst = inst, index = 0, hoff = 0, hover = false, closeHover = false }
  tabSeq += 1

  local f = Instance.new("TextButton")
  f.Name = RandomString()
  f.Size = UDim2.new(0, 0, 1, 0)
  f.AutomaticSize = Enum.AutomaticSize.X
  f.BackgroundColor3 = config.COLORS.SECONDARY
  f.BackgroundTransparency = 1
  f.BorderSizePixel = 0
  f.AutoButtonColor = false
  f.Text = ""
  f.LayoutOrder = tabSeq
  f.ZIndex = 4
  f.Archivable = false
  f.Parent = tabBar
  t.frame = f

  local lay = Instance.new("UIListLayout")
  lay.FillDirection = Enum.FillDirection.Horizontal
  lay.SortOrder = Enum.SortOrder.LayoutOrder
  lay.VerticalAlignment = Enum.VerticalAlignment.Center
  lay.Padding = UDim.new(0, 6)
  lay.Parent = f

  local pad = Instance.new("UIPadding")
  pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 6)
  pad.Parent = f

  local icon = Instance.new("ImageLabel")
  icon.Name = RandomString()
  icon.Size = UDim2.new(0, 16, 0, 16)
  icon.BackgroundTransparency = 1
  icon.LayoutOrder = 1
  icon.ZIndex = 5
  icon.Archivable = false
  icon.Parent = f
  t.icon = icon

  local label = Instance.new("TextLabel")
  label.Name = RandomString()
  label.Size = UDim2.new(0, 0, 1, 0)
  label.AutomaticSize = Enum.AutomaticSize.X
  label.BackgroundTransparency = 1
  label.Text = ""
  label.TextColor3 = config.COLORS.TEXT
  label.FontFace = config.FONT.GothamRegular
  label.TextSize = 12
  label.TextXAlignment = Enum.TextXAlignment.Left
  label.TextTruncate = Enum.TextTruncate.AtEnd
  label.LayoutOrder = 2
  label.ZIndex = 5
  label.Archivable = false
  label.Parent = f
  t.label = label
  local cap = Instance.new("UISizeConstraint")
  cap.MaxSize = Vector2.new(160, math.huge)
  cap.Parent = label

  local x = Instance.new("ImageButton")
  x.Name = RandomString()
  x.Size = UDim2.new(0, 14, 0, 14)
  x.BackgroundTransparency = 1
  x.BorderSizePixel = 0
  x.AutoButtonColor = false
  x.Image = ""
  x.ImageColor3 = config.COLORS.TEXT_DIM
  x.ScaleType = Enum.ScaleType.Fit
  x.LayoutOrder = 3
  x.ZIndex = 5
  x.Archivable = false
  x.Parent = f
  local xp = Instance.new("UIPadding")
  xp.PaddingTop, xp.PaddingBottom = UDim.new(0, 3), UDim.new(0, 3)
  xp.PaddingLeft, xp.PaddingRight = UDim.new(0, 3), UDim.new(0, 3)
  xp.Parent = x
  Explorer.ApplyImage(x, "Close")
  t.close = x

  f.MouseEnter:Connect(function() t.hover = true; StyleTab(t) end)
  f.MouseLeave:Connect(function() t.hover = false; StyleTab(t) end)
  x.MouseEnter:Connect(function() t.closeHover = true; StyleTab(t) end)
  x.MouseLeave:Connect(function() t.closeHover = false; StyleTab(t) end)
  f.Activated:Connect(function() SelectTab(t) end)
  x.Activated:Connect(function() CloseTab(t) end)
  f.InputBegan:Connect(function(inp)
   if inp.UserInputType == Enum.UserInputType.MouseButton3 then CloseTab(t) end
  end)

  tabs[#tabs + 1] = t
  tabOf[inst] = t
  SetHeader(inst)
  StyleTab(t)
  return t
 end

 SelectTab = function(t)
  local switching = activeTab ~= t
  if switching and activeTab then
   activeTab.index, activeTab.hoff = st.index, st.hoff
  end
  activeTab = t
  for _, x in ipairs(tabs) do StyleTab(x) end
  if switching then st.index, st.hoff = t.index, t.hoff end
  Load(t.inst, true)
  ScrollTabIntoView(t)
 end

 function Explorer.OpenSource(inst)
  if not inst then return end
  config.srcOpen = true
  Layout()
  SelectTab(tabOf[inst] or CreateTab(inst))
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

 function Explorer.SetSyntaxColor(key, color)
  if FALLBACK_SYNTAX[key] == nil then return false end
  local hex = typeof(color) == "Color3" and ColorToHex(color) or tostring(color)
  config.SyntaxOverrides[key] = hex
  Explorer.ReloadHighlight()
  return true
 end

 function Explorer.ReloadHighlight()
  if config.srcOpen and st.inst then Load(st.inst, true, true) end
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
   local faces = {
    { name = "Regular", weight = 400, style = "normal", assetId = ttfAsset },
   }
   local boldPath = "LqExplorer/fonts/FiraMono-Bold.ttf"
   pcall(function()
    if not isfile(boldPath) then
     writefile(boldPath, game:HttpGet("https://raw.githubusercontent.com/google/fonts/main/ofl/firamono/FiraMono-Bold.ttf"))
    end
    table.insert(faces, { name = "Bold", weight = 700, style = "normal", assetId = getcustomasset(boldPath) })
   end)
   writefile(jsonPath, game:GetService("HttpService"):JSONEncode({
    name = "Fira Mono",
    faces = faces,
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
  local dumpTab = tabOf[inst]
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

   local append = "\n\n--[[\n" .. dumpText .. "\n]]"

   -- save the dump on the tab so it survives tab switches / closing the viewer
   if dumpTab and tabOf[inst] == dumpTab then
    dumpTab.dump = (dumpTab.dump or "") .. append
   end

   if st.inst ~= inst then return end
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
