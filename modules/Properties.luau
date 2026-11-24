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

 Explorer.PropertyDefs = {}
 function Explorer.DefineProperty(class, name, default, section, opts)
  opts = opts or {}
  table.insert(Explorer.PropertyDefs, {
   Class = class, Name = name, Default = default,
   Section = section or "Other", ReadOnly = opts.ReadOnly == true,
  })
 end
 function Explorer.OnPropertyChanged(cb) Explorer.OnPropertyChangedCb = cb end

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
  if n == math.floor(n) and math.abs(n) < 1e15 then return `{n}` end
  local s = `{string.format("%.4f", n)}`
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
   return `{math.round(v.R * 255)}, {math.round(v.G * 255)}, {math.round(v.B * 255)}`
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
 config.DockMgr.Register(config.pmain, {
  GetSide = function() return config.PDock.Side end,
  SetSide = function(s) config.PDock.Side = s end,
  GetSplitter = function() return config.pdocksplitter end,
 })

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
 MakeCloseImage(pclose, 12, 4)

 local ppin = Instance.new("TextButton")
 ppin.Name = RandomString()
 ppin.Size = UDim2.new(0, 22, 0, 22)
 ppin.Position = UDim2.new(1, -49, 0, 3)
 ppin.BackgroundTransparency = 1
 ppin.AutoButtonColor = false
 ppin.Text = ""
 ppin.BorderSizePixel = 0
 ppin.ZIndex = 3
 ppin.Archivable = false
 ppin.Parent = hdr
 RoundCorner(ppin, 0, 6)
 MakePinImage(ppin, 22, 4)

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
  c.Size = UDim2.new(0, 9, 0, 9)
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

 local OpenColorPicker
 do
  local UIS = config.SV.UserInput
  local RUN = config.SV.RunSrv
  local W, H = 600, 492
  local SCALE = 0.75
  local FILE = "LqExplorer/customcolors.json"
  local CUSTOM_N = 16

  local C_BODY = Color3.fromRGB(27, 28, 33)
  local C_BTN = Color3.fromRGB(57, 59, 66)
  local C_BTN_HOVER = Color3.fromRGB(70, 73, 81)
  local C_BTN_DOWN = Color3.fromRGB(84, 87, 96)
  local C_FIELD = Color3.fromRGB(38, 39, 45)
  local C_TEXT = Color3.fromRGB(205, 205, 205)
  local C_ARROW = Color3.fromRGB(150, 150, 150)

  local BASIC = {}
  for i = 0, 47 do
   local g = math.floor(i / 12)
   local r = math.floor(i / 3) % 4
   local b = i % 3
   BASIC[i + 1] = Color3.fromRGB(math.floor(r * 255 / 3), math.floor(g * 255 / 3), b * 127)
  end

  local custom, nextCustom = {}, 0
  for i = 1, CUSTOM_N do custom[i] = Color3.new(1, 1, 1) end
  pcall(function()
   if not (isfile and readfile and isfile(FILE)) then return end
   local data = config.SV.Http:JSONDecode(readfile(FILE))
   if type(data) ~= "table" or type(data.colors) ~= "table" then return end
   for i = 1, CUSTOM_N do
    if type(data.colors[i]) == "string" then custom[i] = Color3.fromHex(data.colors[i]) end
   end
   nextCustom = (tonumber(data.next) or 0) % CUSTOM_N
  end)
  local function SaveCustom()
   pcall(function()
    if not writefile then return end
    local list = {}
    for i = 1, CUSTOM_N do list[i] = custom[i]:ToHex() end
    writefile(FILE, config.SV.Http:JSONEncode({ colors = list, next = nextCustom }))
   end)
  end

  local function ToRGB(c)
   return math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)
  end
  local IsPress, Pointer, New = Explorer.UI.IsPress, Explorer.UI.Pointer, Explorer.UI.New

  local function Triangle(parent, dir, n, color, x, y)
   local base = 2 * n - 1
   local horiz = dir == "left"
   local holder = New("Frame", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(x, y),
    Size = horiz and UDim2.fromOffset(n, base) or UDim2.fromOffset(base, n),
   }, parent)
   for i = 0, n - 1 do
    local len = 2 * i + 1
    local off = (base - len) / 2
    if dir == "up" then
     New("Frame", { BackgroundColor3 = color, Position = UDim2.fromOffset(off, i), Size = UDim2.fromOffset(len, 1) }, holder)
    elseif dir == "down" then
     New("Frame", { BackgroundColor3 = color, Position = UDim2.fromOffset(off, n - 1 - i), Size = UDim2.fromOffset(len, 1) }, holder)
    else
     New("Frame", { BackgroundColor3 = color, Position = UDim2.fromOffset(i, off), Size = UDim2.fromOffset(1, len) }, holder)
    end
   end
   return holder
  end

  local function SampleScreen(ignoreGui)
   local mp = UIS:GetMouseLocation()
   local okI, inset = pcall(function() return config.SV.Gui:GetGuiInset() end)
   local iy = (okI and inset and inset.Y) or 0
   local roots = { config.SV.CoreGui }
   local okP, plr = pcall(function() return GetService("Players").LocalPlayer end)
   if okP and plr then
    local pg = plr:FindFirstChildOfClass("PlayerGui")
    if pg then roots[#roots + 1] = pg end
   end
   for _, root in ipairs(roots) do
    local ok, objs = pcall(function() return root:GetGuiObjectsAtPosition(mp.X, mp.Y - iy) end)
    if ok and objs then
     for _, o in ipairs(objs) do
      if o:IsA("GuiObject") and o.Visible and not o:IsDescendantOf(ignoreGui) and o.BackgroundTransparency < 0.5 then
       return o.BackgroundColor3
      end
     end
    end
   end
   local ws = GetService("Workspace")
   local cam = ws and ws.CurrentCamera
   if cam then
    local ray = cam:ViewportPointToRay(mp.X, mp.Y)
    local ok, res = pcall(function() return ws:Raycast(ray.Origin, ray.Direction * 5000) end)
    if ok and res and res.Instance then
     local inst = res.Instance
     if inst:IsA("Terrain") then
      local okT, c = pcall(function() return inst:GetMaterialColor(res.Material) end)
      if okT and c then return c end
     elseif inst:IsA("BasePart") then
      return inst.Color
     end
    end
   end
   return nil
  end

  local current

  OpenColorPicker = function(cfg)
   cfg = cfg or {}
   if current then current() end

   local win = Explorer:CreateWindow({ Name = "Select Color", Size = Vector2.new(math.floor(W * SCALE), math.floor(H * SCALE)) })
   local gui = win.Gui
   local content = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(W, H) }, win.Content)
   New("UIScale", { Scale = SCALE }, content)
   local function Conn(c) return win:Track(c) end

   local st = { h = 0, s = 0, v = 0, r = 0, g = 0, b = 0 }
   st.r, st.g, st.b = ToRGB(cfg.color or Color3.new(1, 1, 1))
   do
    local h, s, v = Color3.fromRGB(st.r, st.g, st.b):ToHSV()
    st.h = math.floor(h * 360 + 0.5) % 360
    st.s = math.floor(s * 255 + 0.5)
    st.v = math.floor(v * 255 + 0.5)
   end
   local function FromHSV()
    st.r, st.g, st.b = ToRGB(Color3.fromHSV(st.h / 360, st.s / 255, st.v / 255))
   end
   local function FromRGB()
    local h, s, v = Color3.fromRGB(st.r, st.g, st.b):ToHSV()
    if s > 0 and v > 0 then st.h = math.floor(h * 360 + 0.5) % 360 end
    st.s = math.floor(s * 255 + 0.5)
    st.v = math.floor(v * 255 + 0.5)
   end

   local function Label(text, x, y, w, h, align)
    return New("TextLabel", {
     BackgroundTransparency = 1, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
     Text = text, TextXAlignment = align or Enum.TextXAlignment.Left,
    }, content)
   end
   local function Button(text, x, y, w, h, onClick)
    local b = New("TextButton", { BackgroundColor3 = C_BTN, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), Text = text }, content)
    RoundCorner(b, 0, 2)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = C_BTN_HOVER end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = C_BTN end)
    b.MouseButton1Down:Connect(function() b.BackgroundColor3 = C_BTN_DOWN end)
    b.MouseButton1Up:Connect(function() b.BackgroundColor3 = C_BTN_HOVER end)
    b.Activated:Connect(onClick)
    return b
   end

   local Update
   local function SetRGB(r, g, b)
    st.r, st.g, st.b = math.clamp(math.floor(r), 0, 255), math.clamp(math.floor(g), 0, 255), math.clamp(math.floor(b), 0, 255)
    FromRGB()
    Update()
   end
   local function SetHSV(h, s, v)
    st.h, st.s, st.v = math.clamp(math.floor(h), 0, 359), math.clamp(math.floor(s), 0, 255), math.clamp(math.floor(v), 0, 255)
    FromHSV()
    Update()
   end
   local function SetColor(c)
    local r, g, b = ToRGB(c)
    SetRGB(r, g, b)
   end

   Label("Basic colors", 12, 10, 200, 20)
   local selStroke
   local function Select(stroke)
    if selStroke and selStroke.Parent then selStroke.Color = Color3.fromRGB(20, 20, 24); selStroke.Thickness = 1 end
    selStroke = stroke
    if stroke then stroke.Color = Color3.fromRGB(255, 255, 255); stroke.Thickness = 2 end
   end
   for col = 0, 7 do
    for row = 0, 5 do
     local color = BASIC[col * 6 + row + 1]
     local well = New("TextButton", {
      BackgroundColor3 = color, Position = UDim2.fromOffset(17 + 32 * col, math.floor(40.5 + 27.5 * row)), Size = UDim2.fromOffset(23, 18),
     }, content)
     local stroke = BorderStroke(well, 1, 20, 20, 24)
     well.Activated:Connect(function()
      Select(stroke)
      SetColor(color)
     end)
    end
   end

   local picking, pickConns, pickSaved, pickOverlay, pickChip
   local pickBtn
   local function StopPick(commit)
    if not picking then return end
    picking = false
    for _, c in ipairs(pickConns) do c:Disconnect() end
    pickConns = {}
    if pickOverlay then pickOverlay:Destroy(); pickOverlay = nil end
    pickChip = nil
    pickBtn.Text = "Pick Screen Color"
    if not commit and pickSaved then
     st.h, st.s, st.v, st.r, st.g, st.b = pickSaved.h, pickSaved.s, pickSaved.v, pickSaved.r, pickSaved.g, pickSaved.b
     Update()
    end
   end
   local function StartPick()
    if picking then StopPick(false) return end
    picking = true
    pickSaved = { h = st.h, s = st.s, v = st.v, r = st.r, g = st.g, b = st.b }
    pickConns = {}
    pickBtn.Text = "Click to pick (Esc cancels)"
    pickOverlay = New("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 2000000000, Active = true }, gui)
    pickChip = New("Frame", { Size = UDim2.fromOffset(26, 26), ZIndex = 2000000001, BackgroundColor3 = Color3.new(1, 1, 1) }, pickOverlay)
    BorderStroke(pickChip, 2, 255, 255, 255)
    New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, pickChip)
    pickConns[#pickConns + 1] = pickOverlay.InputBegan:Connect(function(inp)
     if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
      StopPick(true)
     elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
      StopPick(false)
     end
    end)
    pickConns[#pickConns + 1] = RUN.RenderStepped:Connect(function()
     local mp = UIS:GetMouseLocation()
     if pickChip then
      pickChip.Position = UDim2.fromOffset(mp.X + 16, mp.Y + 6)
      pickChip.BackgroundColor3 = Color3.fromRGB(st.r, st.g, st.b)
     end
     local c = SampleScreen(gui)
     if c then
      local r, g, b = ToRGB(c)
      if r ~= st.r or g ~= st.g or b ~= st.b then SetRGB(r, g, b) end
     end
    end)
   end
   pickBtn = Button("Pick Screen Color", 13, 208, 256, 28, StartPick)

   Label("Custom colors", 12, 285, 200, 20)
   local customWells = {}
   for col = 0, 7 do
    for row = 0, 1 do
     local idx = row + col * 2 + 1
     local well = New("TextButton", {
      BackgroundColor3 = custom[idx], Position = UDim2.fromOffset(17 + 32 * col, row == 0 and 316 or 344), Size = UDim2.fromOffset(22, 16),
     }, content)
     local stroke = BorderStroke(well, 1, 20, 20, 24)
     customWells[idx] = well
     well.Activated:Connect(function()
      Select(stroke)
      SetColor(custom[idx])
     end)
    end
   end
   Button("Add to Custom Colors", 13, 372, 256, 28, function()
    local idx = nextCustom + 1
    custom[idx] = Color3.fromRGB(st.r, st.g, st.b)
    customWells[idx].BackgroundColor3 = custom[idx]
    nextCustom = (nextCustom + 1) % CUSTOM_N
    SaveCustom()
   end)

   local spec = New("TextButton", { BackgroundColor3 = Color3.new(1, 1, 1), Position = UDim2.fromOffset(283, 23), Size = UDim2.fromOffset(253, 230), ClipsDescendants = true }, content)
   local hueKeys = {}
   for k = 0, 6 do hueKeys[#hueKeys + 1] = ColorSequenceKeypoint.new(k / 6, Color3.fromHSV(1 - k / 6, 1, 1)) end
   local hueGrad = Instance.new("UIGradient")
   hueGrad.Color = ColorSequence.new(hueKeys)
   hueGrad.Parent = spec
   local satOverlay = New("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(1, 0, 1, 0) }, spec)
   local satGrad = Instance.new("UIGradient")
   satGrad.Rotation = 90
   satGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
   satGrad.Parent = satOverlay
   local cross = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0) }, spec)
   for _, seg in ipairs({ { -10, 0, 6, 1 }, { 4, 0, 6, 1 }, { 0, -10, 1, 6 }, { 0, 4, 1, 6 } }) do
    New("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), Position = UDim2.fromOffset(seg[1], seg[2]), Size = UDim2.fromOffset(seg[3], seg[4]) }, cross)
   end

   local slider = New("TextButton", { BackgroundColor3 = Color3.new(1, 1, 1), Position = UDim2.fromOffset(556, 23), Size = UDim2.fromOffset(15, 230) }, content)
   local valGrad = Instance.new("UIGradient")
   valGrad.Rotation = 90
   valGrad.Parent = slider
   local marker = Triangle(content, "left", 7, Color3.fromRGB(235, 235, 235), 573, 23)

   local function Dragger(obj, onPos)
    Conn(obj.InputBegan:Connect(function(inp)
     if not IsPress(inp) then return end
     onPos(Pointer(inp))
     local mc, ec
     local function stop()
      if mc then mc:Disconnect() end
      if ec then ec:Disconnect() end
     end
     mc = Conn(UIS.InputChanged:Connect(function(i)
      if i.UserInputType == Enum.UserInputType.MouseMovement or i == inp then onPos(Pointer(i)) end
     end))
     ec = Conn(UIS.InputEnded:Connect(function(i)
      if i == inp or (inp.UserInputType == Enum.UserInputType.MouseButton1 and i.UserInputType == Enum.UserInputType.MouseButton1) then stop() end
     end))
    end))
   end
   Dragger(spec, function(p)
    local ap, as = spec.AbsolutePosition, spec.AbsoluteSize
    local x = math.clamp((p.X - ap.X) / math.max(1, as.X), 0, 1)
    local y = math.clamp((p.Y - ap.Y) / math.max(1, as.Y), 0, 1)
    Select(nil)
    SetHSV(359 - math.floor(x * 360), 255 - math.floor(y * 256), st.v)
   end)
   Dragger(slider, function(p)
    local ap, as = slider.AbsolutePosition, slider.AbsoluteSize
    local y = math.clamp((p.Y - ap.Y) / math.max(1, as.Y), 0, 1)
    Select(nil)
    SetHSV(st.h, st.s, 255 - math.floor(y * 256))
   end)

   local preview = New("Frame", { Position = UDim2.fromOffset(283, 278), Size = UDim2.fromOffset(68, 123), BackgroundColor3 = Color3.fromRGB(st.r, st.g, st.b) }, content)

   local boxes = {}
   local function MakeSpin(key, text, labelX, boxX, y, lo, hi, get, set)
    Label(text, labelX, y, 52, 23, Enum.TextXAlignment.Right)
    local holder = New("Frame", { BackgroundColor3 = C_FIELD, Position = UDim2.fromOffset(boxX, y), Size = UDim2.fromOffset(48, 23) }, content)
    local box = New("TextBox", {
     BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, 0), Text = "", ClearTextOnFocus = false,
     TextXAlignment = Enum.TextXAlignment.Left, TextSize = 17,
    }, holder)
    New("UIPadding", { PaddingLeft = UDim.new(0, 5) }, box)
    boxes[key] = box
    Conn(box:GetPropertyChangedSignal("Text"):Connect(function()
     if not box:IsFocused() then return end
     if box.Text:match("^%d+$") then
      local n = math.clamp(tonumber(box.Text), lo, hi)
      if n ~= get() then Select(nil); set(n) end
     end
    end))
    Conn(box.FocusLost:Connect(function() Update(true) end))

    local function Arrow(dir, yy, delta)
     local b = New("TextButton", { BackgroundTransparency = 1, Position = UDim2.new(1, -16, 0, yy), Size = UDim2.fromOffset(16, 11) }, holder)
     Triangle(b, dir, 3, C_ARROW, 5, 4)
     local held
     local function step() Select(nil); set(math.clamp(get() + delta, lo, hi)) end
     Conn(b.InputBegan:Connect(function(inp)
      if not IsPress(inp) then return end
      local token = {}
      held = token
      step()
      task.spawn(function()
       task.wait(0.4)
       while held == token and content.Parent do step(); task.wait(0.05) end
      end)
     end))
     Conn(b.InputEnded:Connect(function(inp) if IsPress(inp) then held = nil end end))
     Conn(b.MouseLeave:Connect(function() held = nil end))
    end
    Arrow("up", 0, 1)
    Arrow("down", 11, -1)
   end
   local function SetH(n) SetHSV(n, st.s, st.v) end
   local function SetS(n) SetHSV(st.h, n, st.v) end
   local function SetV(n) SetHSV(st.h, st.s, n) end
   MakeSpin("h", "Hue:", 357, 417, 278, 0, 359, function() return st.h end, SetH)
   MakeSpin("s", "Sat:", 357, 417, 309, 0, 255, function() return st.s end, SetS)
   MakeSpin("v", "Val:", 357, 417, 339, 0, 255, function() return st.v end, SetV)
   MakeSpin("r", "Red:", 470, 529, 278, 0, 255, function() return st.r end, function(n) SetRGB(n, st.g, st.b) end)
   MakeSpin("g", "Green:", 470, 529, 309, 0, 255, function() return st.g end, function(n) SetRGB(st.r, n, st.b) end)
   MakeSpin("b", "Blue:", 470, 529, 339, 0, 255, function() return st.b end, function(n) SetRGB(st.r, st.g, n) end)

   -- hex
   Label("Hex:", 357, 377, 52, 22, Enum.TextXAlignment.Right)
   local hexHolder = New("Frame", { BackgroundColor3 = C_FIELD, Position = UDim2.fromOffset(416, 378), Size = UDim2.fromOffset(105, 22) }, content)
   local hexBox = New("TextBox", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 17 }, hexHolder)
   New("UIPadding", { PaddingLeft = UDim.new(0, 5) }, hexBox)
   local function ParseHex(s)
    s = s:gsub("%s", "")
    s = s:gsub("^#", "")
    if s:match("^%x%x%x$") then s = s:gsub(".", function(ch) return ch .. ch end) end
    if not s:match("^%x%x%x%x%x%x$") then return nil end
    return tonumber(s:sub(1, 2), 16), tonumber(s:sub(3, 4), 16), tonumber(s:sub(5, 6), 16)
   end
   Conn(hexBox:GetPropertyChangedSignal("Text"):Connect(function()
    if not hexBox:IsFocused() then return end
    local r, g, b = ParseHex(hexBox.Text)
    if r and (r ~= st.r or g ~= st.g or b ~= st.b) then Select(nil); SetRGB(r, g, b) end
   end))
   Conn(hexBox.FocusLost:Connect(function() Update(true) end))

   local function Close() win:Close() end
   win.OnClose = function()
    StopPick(false)
    if current == Close then current = nil end
   end
   current = Close
   local function Accept()
    local c = Color3.fromRGB(st.r, st.g, st.b)
    Close()
    if cfg.OnAccept then cfg.OnAccept(c) end
   end
   Button("OK", 407, 416, 85, 28, Accept)
   Button("Cancel", 499, 416, 85, 28, Close)
   Conn(UIS.InputBegan:Connect(function(inp)
    if inp.KeyCode ~= Enum.KeyCode.Escape then return end
    if picking then StopPick(false) return end
    if UIS:GetFocusedTextBox() then return end
    Close()
   end))

   local function SetText(box, s, force)
    if box:IsFocused() and not force then return end
    if box.Text ~= s then box.Text = s end
   end
   Update = function(force)
    preview.BackgroundColor3 = Color3.fromRGB(st.r, st.g, st.b)
    cross.Position = UDim2.new((359 - st.h) / 359, 0, (255 - st.s) / 255, 0)
    valGrad.Color = ColorSequence.new(Color3.fromHSV(st.h / 360, st.s / 255, 1), Color3.new(0, 0, 0))
    marker.Position = UDim2.fromOffset(573, 23 + math.floor((255 - st.v) / 255 * 230) - 6)
    SetText(boxes.h, tostring(st.h), force)
    SetText(boxes.s, tostring(st.s), force)
    SetText(boxes.v, tostring(st.v), force)
    SetText(boxes.r, tostring(st.r), force)
    SetText(boxes.g, tostring(st.g), force)
    SetText(boxes.b, tostring(st.b), force)
    SetText(hexBox, `#{string.format("%02x%02x%02x", st.r, st.g, st.b)}`, force)
   end
   Update(true)
  end
 end
 Explorer.OpenColorPicker = OpenColorPicker


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
  arrow.Size = UDim2.new(0, 9, 0, 9)
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

  local swatch = Instance.new("TextButton")
  swatch.Name = RandomString()
  swatch.Size = UDim2.new(0, 16, 0, 12)
  swatch.BorderSizePixel = 0
  swatch.AutoButtonColor = false
  swatch.Text = ""
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
  chev.Size = UDim2.new(0, 9, 0, 9)
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
   if not d.Commit or d.readonly then value.Text = Fmt(d.value); return end
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

  swatch.Activated:Connect(function()
   local d = r.data
   if not d or d.kind ~= "prop" or typeof(d.value) ~= "Color3" then return end
   local editable = d.Commit ~= nil and not d.readonly
   OpenColorPicker({
    color = d.value,
    OnAccept = function(c)
     if not editable then return end
     if Fmt(c) == Fmt(d.value) then return end
     d.Commit(c)
    end,
   })
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
   r.arrow.Position = UDim2.new(0, 4 + indent, 0.5, -4)
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
    r.chev.Position = UDim2.new(0, vx + vw - 12, 0.5, -4)
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
  if n > 1 then extra = ` (+{n - 1})` end
  ptitle.Text = 'Properties - ' .. inst.ClassName .. ' "' .. inst.Name .. '"' .. extra
 end

 function Explorer.RefreshProperties()
  Rebuild()
  UpdateHeader()
  RefreshList()
 end

 config.activeGuiOutline = nil
 config.activePartVisuals = nil
 config.MaxResizeHandles = 25
 config.MaxSelectionBoxes = 100
 config.ResizeIncrement = 1
 config.ResizeFineIncrement = 0.1
 config.ResizeMinSize = 0.05
 config.ResizeMaxSize = 2048
 config.ResizeColor = BrickColor.new("Cyan").Color

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

  local function MakeLine(pos, size)
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

  MakeLine(UDim2.new(0, -1, 0, -1), UDim2.new(1, 2, 0, 2))
  MakeLine(UDim2.new(0, -1, 1, -1), UDim2.new(1, 2, 0, 2))
  MakeLine(UDim2.new(0, -1, 0, -1), UDim2.new(0, 2, 1, 2))
  MakeLine(UDim2.new(1, -1, 0, -1), UDim2.new(0, 2, 1, 2))

  local liveConnections = {}

  local function ClearLive()
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
     ClearLive()
    end
   end))
  end)

  config.SV.UserInput.WindowFocusReleased:Connect(ClearLive)

  local function MakeHandle(edgeX, edgeY, pos, zIndexBase)
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
    local ok6, _ = pcall(function() return inst.Parent.AbsoluteSize end)
    local ok7, _ = pcall(function() return inst.Parent.AbsolutePosition end)
    if not (ok1 and ok2 and ok3 and ok4 and ok5 and ok6 and ok7) then return end

    local startMouse = Vector2.new(io.Position.X, io.Position.Y)
    local _ = startAbsPos.X + startAbsSize.X
    local _ = startAbsPos.Y + startAbsSize.Y

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
      ClearLive()
     end
    end))
   end)

   hitZone.MouseEnter:Connect(function() h.Size = UDim2.new(0, HANDLE_SIZE + 2, 0, HANDLE_SIZE + 2) end)
   hitZone.MouseLeave:Connect(function() h.Size = UDim2.new(0, HANDLE_SIZE, 0, HANDLE_SIZE) end)
  end

  MakeHandle(0, -1, UDim2.new(0.5, 0, 0, 0), 1002)
  MakeHandle(0, 1, UDim2.new(0.5, 0, 1, 0), 1002)
  MakeHandle(-1, 0, UDim2.new(0, 0, 0.5, 0), 1002)
  MakeHandle(1, 0, UDim2.new(1, 0, 0.5, 0), 1002)

  MakeHandle(-1, -1, UDim2.new(0, 0, 0, 0), 1003)
  MakeHandle(1, -1, UDim2.new(1, 0, 0, 0), 1003)
  MakeHandle(-1, 1, UDim2.new(0, 0, 1, 0), 1003)
  MakeHandle(1, 1, UDim2.new(1, 0, 1, 0), 1003)

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
  local vis = config.activePartVisuals
  if vis then
   config.activePartVisuals = nil
   for _, c in ipairs(vis.conns) do c:Disconnect() end
   for _, o in ipairs(vis.objs) do pcall(function() o:Destroy() end) end
  end
 end

 local FACE_AXIS = {
  [Enum.NormalId.Right] = Vector3.new(1, 0, 0),
  [Enum.NormalId.Left] = Vector3.new(-1, 0, 0),
  [Enum.NormalId.Top] = Vector3.new(0, 1, 0),
  [Enum.NormalId.Bottom] = Vector3.new(0, -1, 0),
  [Enum.NormalId.Back] = Vector3.new(0, 0, 1),
  [Enum.NormalId.Front] = Vector3.new(0, 0, -1),
 }

 local function AttachResizeHandles(part, vis)
  local h = Instance.new("Handles")
  h.Name = RandomString()
  h.Style = Enum.HandlesStyle.Resize
  h.Color3 = config.ResizeColor
  h.Archivable = false
  local okA = pcall(function() h.Adornee = part end)
  if not okA then pcall(function() h:Destroy() end); return end
  h.Parent = config.folder
  table.insert(vis.objs, h)

  local startSize, startCF
  local lastProps = 0

  table.insert(vis.conns, h.MouseButton1Down:Connect(function()
   local ok, sz, cf = pcall(function() return part.Size, part.CFrame end)
   if ok then startSize, startCF = sz, cf end
  end))

  table.insert(vis.conns, h.MouseDrag:Connect(function(face, distance)
   if not startSize then return end
   local axis = FACE_AXIS[face]
   if not axis then return end
   local mask = Vector3.new(math.abs(axis.X), math.abs(axis.Y), math.abs(axis.Z))
   local cur = startSize.X * mask.X + startSize.Y * mask.Y + startSize.Z * mask.Z

   local inc = config.ResizeIncrement
   if config.SV.UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then inc = config.ResizeFineIncrement end
   local d = distance
   if inc and inc > 0 then d = math.floor(d / inc + 0.5) * inc end

   local target = math.clamp(cur + d, config.ResizeMinSize, config.ResizeMaxSize)
   local delta = target - cur

   pcall(function()
    part.Size = startSize + mask * delta
    part.CFrame = startCF * CFrame.new(axis * (delta / 2))
   end)

   local now = os.clock()
   if now - lastProps > 0.15 then
    lastProps = now
    pcall(Explorer.RefreshProperties)
   end
  end))

  table.insert(vis.conns, h.MouseButton1Up:Connect(function()
   startSize, startCF = nil, nil
   pcall(Explorer.RefreshProperties)
  end))
 end

 -- outlines every selected 3D instance, resize handles on each selected BasePart
 local function ShowPVVisuals()
  local vis = { objs = {}, conns = {} }
  config.activePartVisuals = vis

  local list = {}
  if Explorer.Selected then list[1] = Explorer.Selected end
  for v in pairs(Explorer.SelectedSet) do
   if v ~= Explorer.Selected then list[#list + 1] = v end
  end

  local boxes, handles = 0, 0
  for _, v in ipairs(list) do
   local okR, real = pcall(function() return v.Real end)
   if not (okR and real) then real = v end
   if typeof(real) == "Instance" then
    local isPV, isPart = false, false
    pcall(function()
     isPV = real:IsA("PVInstance") and not real:IsA("Terrain")
     isPart = real:IsA("BasePart")
    end)
    if isPV and boxes < config.MaxSelectionBoxes then
     local box = Instance.new("SelectionBox")
     box.LineThickness = 0.05
     box.Color3 = Color3.fromRGB(0, 170, 255)
     box.Archivable = false
     local adorn = pcall(function() box.Adornee = real end)
     if adorn then
      box.Parent = config.folder
      table.insert(vis.objs, box)
      boxes += 1
     else
      pcall(function() box:Destroy() end)
     end
     if isPart and handles < config.MaxResizeHandles then
      AttachResizeHandles(real, vis)
      handles += 1
     end
    end
   end
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
   local function UpdatePos()
    local fn, absPos = pcall(function() return inst.AbsolutePosition end)
    local ok, absSize = pcall(function() return inst.AbsoluteSize end)
    if not (fn and ok) then return end
    local parentAbs = Vector2.new(0, 0)
    pcall(function() parentAbs = outlineFrame.Parent.AbsolutePosition end)
    outlineFrame.Position = UDim2.new(0, absPos.X - parentAbs.X, 0, absPos.Y - parentAbs.Y)
    outlineFrame.Size = UDim2.new(0, absSize.X, 0, absSize.Y)
   end
   outlineFrame, handleConnections = CreateGuiOutline(inst, UpdatePos)
   UpdatePos()

   local posCon, sizeCon
   pcall(function() posCon = inst:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdatePos) end)
   pcall(function() sizeCon = inst:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdatePos) end)

   config.activeGuiOutline = { frame = outlineFrame, posCon = posCon, sizeCon = sizeCon, handleConnections = handleConnections }
  elseif isPV then
   ShowPVVisuals()
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
   if not config.Held(inp) then dragging = false; pvvis.BackgroundColor3 = Color3.fromRGB(90, 90, 90); return end
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
   if not config.Held(inp) then dragging = false; return end
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
  local Dock = config.DockMgr
  if order then config.PDock.Order = order end
  local target
  if order and config.DockSide == side and config.main.Visible then target = Dock.ByGui[config.main] end
  if target then
   Dock.Place(Dock.ByGui[config.pmain], side, target, (order == "above") and "top" or "bottom")
  else
   config.PDock.Side = side
   config.LayoutDocks()
  end
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
   local side, zone, target = config.DockMgr.Resolve(config.pmain, cursor)
   config.DockMgr.ShowHint(config.pmain, target, side, zone)
  end,
  OnEnd = function(didDrag, cursor)
   config.dockHint.Visible = false
   if not didDrag then return end
   local side, zone, target = config.DockMgr.Resolve(config.pmain, cursor)
   if not side then return end
   config.DockMgr.Place(config.DockMgr.ByGui[config.pmain], side, target, zone)
  end,
 })

 local function OnPropsResize(newSize)
  if config.PDock.Side then
   config.DockMgr.Width[config.PDock.Side] = newSize.X.Offset
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
