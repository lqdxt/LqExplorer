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
 cell.MouseEnter:Connect(function() hover = true; Paint() end)
 cell.MouseLeave:Connect(function() hover = false; Paint() end)
 return cell, function(on) active = on and true or false; Paint() end
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
