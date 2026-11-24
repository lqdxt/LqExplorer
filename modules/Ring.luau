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
