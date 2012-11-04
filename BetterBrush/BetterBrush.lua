local Plugin = PluginManager():CreatePlugin()
local Toolbar = Plugin:CreateToolbar("Terrain")
local ActivateButton = Toolbar:CreateButton("", "Brush", "brush.png")
local Mouse = Plugin:GetMouse()

local plugin_loaded = false
local plugin_active = false

local Terrain = game.Workspace.Terrain
local SetCell = Terrain.SetCell
local SetCells = Terrain.SetCells
local GetCell = Terrain.GetCell
local AutowedgeCells = Terrain.AutowedgeCells
local WorldToCellPreferSolid = Terrain.WorldToCellPreferSolid

local MAX_HEIGHT = Terrain.MaxExtents.Max.Y

local brushRadius = 4
local maxBrushRadius = 16
local minBrushRadius = 1

local heightOffset = 0
local maxHeightOffset = 32
local minHeightOffset = -32

local brushMaterial = 1
local clearAbove = false
local fillBelow = true
local autoSmooth = true

local Region3i = Region3int16.new
local Vector3i = Vector3int16.new
local function R3(a,b,c,x,y,z)
	return Region3i(
		Vector3i(a,b,c),
		Vector3i(x,y,z)
	)
end

-- returns distance^2 between the two points
local function dist(x1, y1, x2, y2)
	local x = x2-x1
	local y = y2-y1
	return x*x + y*y
end

-- makes a column of blocks from 0 up to height at location (x,z)
-- if clearAbove is true, blocks above height will be cleared
local function PaintColumn(x, z, height)
	if clearAbove then
		SetCells(Terrain,R3(x,height+1,z,x,MAX_HEIGHT,z),0,0,0)
	end
	if fillBelow then
		SetCells(Terrain,R3(x,0,z,x,height,z),brushMaterial,0,0)
	end
end

-- brushes terrain at point (x, y, z) in cluster c
local function Brush(x, y, z, r)
	local r2 = r*r
	for i = x - r, x + r do
		for k = z - r, z + r do
			if dist(x, z, i, k) < r2 then
				PaintColumn(i, k, y, add)
			end
		end
	end
	if autoSmooth then
		AutowedgeCells(Terrain, R3(x - r, 0, z - r, x + r, clearAbove and MAX_HEIGHT or y, z + r))
	end
end

local function getPlaneCell(hit)
	if hit.y < 0 then
		local ray = Mouse.UnitRay
		local n = Vector3.new(0,1,0)
		local s = (-n:Dot(ray.Origin)/n:Dot(ray.Direction))
		if s >= 0 then
			hit = s*ray.Direction+ray.Origin
		end
	end
	return WorldToCellPreferSolid(Terrain, hit)
end

local mouseDown = false
local move_con
Mouse.Button1Down:connect(function()
	if plugin_active then
		mouseDown = true

		local clickedCell = getPlaneCell(Mouse.Hit.p)
		local brushHeight = clickedCell.y
		local cellMat = GetCell(Terrain, clickedCell.x, clickedCell.y, clickedCell.z).Value
		if cellMat > 0 then
			brushMaterial = cellMat
		end

		if move_con then
			move_con:disconnect()
			move_con = nil
		end
		move_con = Mouse.Move:connect(function()
			if mouseDown then
				local cellPos = getPlaneCell(Mouse.Hit.p)
				Brush(cellPos.x,brushHeight + heightOffset,cellPos.z,brushRadius)
			end
		end)
		Brush(clickedCell.x,brushHeight + heightOffset,clickedCell.z,brushRadius)
	end
end)

Mouse.Button1Up:connect(function()
	mouseDown = false
	if move_con then
		move_con:disconnect()
		move_con = nil
	end
end)


---- GUI

local RbxGui = LoadLibrary("RbxGui")

local function Create(ty)
	return function(data)
		local obj = Instance.new(ty)
		for k, v in pairs(data) do
			if type(k) == 'number' then
				v.Parent = obj
			else
				obj[k] = v
			end
		end
		return obj
	end
end

local Screen = Instance.new("ScreenGui")
Screen.Name = "TerrainBrushGUI"
local SettingsFrame = Create'Frame'{
	Position = UDim2.new(0.3,0,0.8,0);
	Size = UDim2.new(0.4,0,0.15,0);
	BackgroundColor3 = Color3.new(0,0,0);
	BorderColor3 = Color3.new(1,1,1);
	Transparency = 0.5;
	Parent = Screen;
	Create'Frame'{
		Name = "Container";
		Transparency = 1;
		Size = UDim2.new(1,-8,1,-8);
		Position = UDim2.new(0,4,0,4);
	};
	Create'TextLabel'{
		Name = "InfoBox";
		Position = UDim2.new(0,0,0,-18);
		Size = UDim2.new(1,0,0,18);
		BackgroundTransparency = 1;
		Font = Enum.Font.ArialBold;
		FontSize = Enum.FontSize.Size14;
		TextColor3 = Color3.new(1,1,1);
		TextStrokeTransparency = 0;
		TextStrokeColor3 = Color3.new(0,0,0);
		TextXAlignment = Enum.TextXAlignment.Left;
		Text = "";
	};
}

local InfoBox = SettingsFrame.InfoBox
local function setupInfoBox(frame,info)
	local hover_id = 0
	frame.MouseEnter:connect(function()
		local cid = hover_id + 1
		hover_id = cid
		wait(0.5)
		if hover_id == cid then
			InfoBox.Text = info
		end
	end)
	frame.MouseLeave:connect(function()
		hover_id = hover_id + 1
		InfoBox.Text = ""
	end)
end

do	-- clearAbove
	local frame = Create'Frame'{
		Transparency = 1;
		Position = UDim2.new(0,0,0,0);
		Size = UDim2.new(0.5,0,1/4,0);
		Create'TextLabel'{
			Size = UDim2.new(0,90,1,0);
			BackgroundTransparency = 1;
			TextColor3 = Color3.new(1,1,1);
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size14;
			TextXAlignment = Enum.TextXAlignment.Right;
			Text = "Clear Above:";
		};
		Create'TextButton'{
			Position = UDim2.new(0,94,0,0);
			Size = UDim2.new(0,40,1,0);
			Style = Enum.ButtonStyle.RobloxButton;
			TextColor3 = Color3.new(1,1,1);
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size14;
			Text = tostring(clearAbove);
			Selected = clearAbove;
		};
	}
	frame.Parent = SettingsFrame.Container
	local button = frame.TextButton
	button.MouseButton1Click:connect(function()
		clearAbove = not clearAbove
		button.Text = tostring(clearAbove)
		button.Selected = clearAbove
	end)
	setupInfoBox(frame,"If true, cells above brush height will be cleared")
end

do	-- fillBelow
	local frame = Create'Frame'{
		Transparency = 1;
		Position = UDim2.new(0.5,0,0,0);
		Size = UDim2.new(0.5,0,1/4,0);
		Create'TextLabel'{
			Size = UDim2.new(0,90,1,0);
			BackgroundTransparency = 1;
			TextColor3 = Color3.new(1,1,1);
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size14;
			TextXAlignment = Enum.TextXAlignment.Right;
			Text = "Fill Below:";
		};
		Create'TextButton'{
			Position = UDim2.new(0,94,0,0);
			Size = UDim2.new(0,40,1,0);
			Style = Enum.ButtonStyle.RobloxButton;
			TextColor3 = Color3.new(1,1,1);
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size14;
			Text = tostring(fillBelow);
			Selected = fillBelow;
		};
	}
	frame.Parent = SettingsFrame.Container
	local button = frame.TextButton
	button.MouseButton1Click:connect(function()
		fillBelow = not fillBelow
		button.Text = tostring(fillBelow)
		button.Selected = fillBelow
	end)
	setupInfoBox(frame,"If true, cells below brush height will be filled")
end

do	-- autoSmooth
	local frame = Create'Frame'{
		Transparency = 1;
		Position = UDim2.new(0,0,1/4,0);
		Size = UDim2.new(1,0,1/4,0);
		Create'TextLabel'{
			Size = UDim2.new(0,90,1,0);
			BackgroundTransparency = 1;
			TextColor3 = Color3.new(1,1,1);
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size14;
			TextXAlignment = Enum.TextXAlignment.Right;
			Text = "Auto-Smooth:";
		};
		Create'TextButton'{
			Position = UDim2.new(0,94,0,0);
			Size = UDim2.new(0,40,1,0);
			Style = Enum.ButtonStyle.RobloxButton;
			TextColor3 = Color3.new(1,1,1);
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size14;
			Text = tostring(autoSmooth);
			Selected = autoSmooth;
		};
	}
	frame.Parent = SettingsFrame.Container
	local button = frame.TextButton
	button.MouseButton1Click:connect(function()
		autoSmooth = not autoSmooth
		button.Text = tostring(autoSmooth)
		button.Selected = autoSmooth
	end)
	setupInfoBox(frame,"If true, brushed cells will automatically be smoothed")
end

do	-- brushRadius
	local frame = Create'Frame'{
		Transparency = 1;
		Position = UDim2.new(0,0,2/4,0);
		Size = UDim2.new(1,0,1/4,0);
		Create'TextLabel'{
			Size = UDim2.new(0,90,1,0);
			BackgroundTransparency = 1;
			TextColor3 = Color3.new(1,1,1);
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size14;
			TextXAlignment = Enum.TextXAlignment.Right;
			Text = "Radius: " .. brushRadius;
		};
	}
	frame.Parent = SettingsFrame.Container
	local label = frame.TextLabel
	local Slider, sliderPosition = RbxGui.CreateSlider(maxBrushRadius-(minBrushRadius-1), 0, UDim2.new(0,0,0,0))
	Slider.Parent = frame
	Slider.Position = UDim2.new(0,94,0,0)
	Slider.Size = UDim2.new(1,-94,1,0)
	Slider.Bar.Position = UDim2.new(0,10,0.5,-3)
	Slider.Bar.Size = UDim2.new(1,-20,0,6)
	sliderPosition.Changed:connect(function(value)
		brushRadius = value + (minBrushRadius-1)
		label.Text = "Radius: " .. brushRadius
	end)
	sliderPosition.Value = (brushRadius+1) - minBrushRadius
	setupInfoBox(frame,"Determines the size of the brush")
end

do	-- heightOffset
	local frame = Create'Frame'{
		Transparency = 1;
		Position = UDim2.new(0,0,3/4,0);
		Size = UDim2.new(1,0,1/4,0);
		Create'TextLabel'{
			Size = UDim2.new(0,90,1,0);
			BackgroundTransparency = 1;
			TextColor3 = Color3.new(1,1,1);
			Font = Enum.Font.ArialBold;
			FontSize = Enum.FontSize.Size14;
			TextXAlignment = Enum.TextXAlignment.Right;
			Text = "Height: " .. heightOffset;
		};
	}
	frame.Parent = SettingsFrame.Container
	local label = frame.TextLabel
	local Slider, sliderPosition = RbxGui.CreateSlider(maxHeightOffset-(minHeightOffset-1), 0, UDim2.new(0,0,0,0))
	Slider.Parent = frame
	Slider.Position = UDim2.new(0,94,0,0)
	Slider.Size = UDim2.new(1,-94,1,0)
	Slider.Bar.Position = UDim2.new(0,10,0.5,-3)
	Slider.Bar.Size = UDim2.new(1,-20,0,6)
	sliderPosition.Changed:connect(function(value)
		heightOffset = value + (minHeightOffset-1)
		label.Text = "Height: " .. heightOffset
	end)
	sliderPosition.Value = (heightOffset+1) - minHeightOffset
	setupInfoBox(frame,"Determines the height of the brush, offset from where you clicked")
end

local function Deactivate()
	plugin_active = false
	ActivateButton:SetActive(false)
	Screen.Parent = nil
end

local CoreGui = Game:GetService("CoreGui")
ActivateButton.Click:connect(function()
	if plugin_loaded then
		if plugin_active then
			Deactivate()
		else
			plugin_active = true
			Plugin:Activate(true)
			ActivateButton:SetActive(true)
			Screen.Parent = CoreGui
		end
	end
end)

Plugin.Deactivation:connect(Deactivate)

plugin_loaded = true
