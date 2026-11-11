--!nocheck
--[[
    School Hub - Mechanic Legends | MONEY FARM
    Loadstring:
      loadstring(game:HttpGet("https://raw.githubusercontent.com/bryantcamp321-tech/school-hub/main/mechanic-legends.lua"))()

    Fully automated. Stand in your garage, hit START, walk away.
    Right Shift hides the window.
]]

local Hub = { Version = "2.0.0", Name = "School Hub" }
Hub.__index = Hub

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ENV = (function()
    local ok, value = pcall(function() return getgenv() end)
    if ok and type(value) == "table" then return value end
    return _G
end)()

local LP = Players.LocalPlayer

do
    local previous = ENV.SchoolHub
    if type(previous) == "table" and type(previous.Unload) == "function" then
        pcall(previous.Unload)
        task.wait(0.25)
    end
end

local Connections, Instances, Controls, ThemeHooks = {}, {}, {}, {}

local function conn(c) Connections[#Connections + 1] = c; return c end
local function track(i) Instances[#Instances + 1] = i; return i end

local function create(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then inst[k] = v end
    end
    inst.Parent = parent or (props and props.Parent)
    return track(inst)
end

-- theme ----------------------------------------------------------------------

local Themes = {
    Citron = Color3.fromRGB(198, 255, 74),
    Mint   = Color3.fromRGB(92, 232, 180),
    Azure  = Color3.fromRGB(90, 172, 255),
    Rose   = Color3.fromRGB(255, 118, 158),
    Violet = Color3.fromRGB(172, 128, 255),
    Amber  = Color3.fromRGB(255, 190, 92),
}
local Theme = {
    Bg     = Color3.fromRGB(15, 16, 18),
    Panel  = Color3.fromRGB(22, 24, 27),
    Raised = Color3.fromRGB(29, 32, 36),
    Stroke = Color3.fromRGB(40, 44, 50),
    Text   = Color3.fromRGB(237, 240, 245),
    Sub    = Color3.fromRGB(134, 141, 152),
    Good   = Color3.fromRGB(92, 232, 180),
    Bad    = Color3.fromRGB(255, 118, 158),
    Accent = Themes.Citron,
}

local function tween(obj, props, dur, style)
    local t = TweenService:Create(obj, TweenInfo.new(dur or 0.14,
        style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function corner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 6) }, parent)
end

local function outline(parent, color, thickness)
    return create("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function pad(parent, top, right, bottom, left)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or top or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
        PaddingLeft = UDim.new(0, left or top or 0),
    }, parent)
end

local function list(parent, gap, alignment)
    return create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, gap or 6),
        HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left,
    }, parent)
end

local function label(parent, text, size, color, bold)
    return create("TextLabel", {
        Text = text,
        Size = size or UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextColor3 = color or Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        RichText = true,
    }, parent)
end

function Hub:Notify(title, text, seconds)
    if not self.Gui then return end
    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = Theme.Raised,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, self.Toasts)
    corner(card, 8)
    local edge = create("Frame", {
        Size = UDim2.new(0, 3, 1, -14),
        Position = UDim2.new(0, 7, 0, 7),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, card)
    corner(edge, 2)
    ThemeHooks[#ThemeHooks + 1] = function() edge.BackgroundColor3 = Theme.Accent end

    local t = label(card, title, UDim2.new(1, -26, 0, 18), Theme.Text, true)
    t.Position = UDim2.new(0, 16, 0, 8)
    local b = label(card, text, UDim2.new(1, -26, 0, 16), Theme.Sub)
    b.Position = UDim2.new(0, 16, 0, 27)

    tween(card, { BackgroundTransparency = 0 }, 0.15)
    task.delay(seconds or 3, function()
        if not card.Parent then return end
        tween(card, { BackgroundTransparency = 1 }, 0.2)
        for _, child in ipairs(card:GetDescendants()) do
            if child:IsA("TextLabel") then tween(child, { TextTransparency = 1 }, 0.2) end
        end
        task.delay(0.25, function() card:Destroy() end)
    end)
end

-- controls -------------------------------------------------------------------

local Section = {}
Section.__index = Section

function Section:Toggle(opts)
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, self.Body)
    label(row, opts.Text or "Toggle", UDim2.new(1, -50, 1, 0), Theme.Text)

    local state = opts.Default and true or false
    local trackFrame = create("Frame", {
        Size = UDim2.fromOffset(36, 19),
        Position = UDim2.new(1, -36, 0.5, -10),
        BackgroundColor3 = Theme.Raised,
        BorderSizePixel = 0,
    }, row)
    corner(trackFrame, 10)
    local knob = create("Frame", {
        Size = UDim2.fromOffset(15, 15),
        Position = UDim2.new(0, 2, 0.5, -7.5),
        BackgroundColor3 = Theme.Text,
        BorderSizePixel = 0,
    }, trackFrame)
    corner(knob, 8)

    local function render()
        tween(trackFrame, { BackgroundColor3 = state and Theme.Accent or Theme.Raised }, 0.12)
        tween(knob, { Position = UDim2.new(0, state and 19 or 2, 0.5, -7.5) }, 0.12)
    end
    ThemeHooks[#ThemeHooks + 1] = render

    local function set(value, silent)
        state = value and true or false
        render()
        if not silent and opts.Callback then task.spawn(opts.Callback, state) end
    end

    local click = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, row)
    conn(click.MouseButton1Click:Connect(function() set(not state) end))
    render()

    if opts.Flag then Controls[opts.Flag] = { get = function() return state end, set = set } end
    if opts.Default and opts.Callback then task.spawn(opts.Callback, true) end
    return { Set = set, Get = function() return state end }
end

function Section:Slider(opts)
    local min, max = opts.Min or 0, opts.Max or 100
    local decimals = opts.Decimals or 0
    local step = opts.Step or (decimals > 0 and (10 ^ -decimals) or 1)
    local value = math.clamp(opts.Default or min, min, max)

    local holder = create("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1 }, self.Body)
    label(holder, opts.Text or "Slider", UDim2.new(1, -60, 0, 16), Theme.Text)
    local readout = label(holder, "", UDim2.new(0, 60, 0, 16), Theme.Sub)
    readout.TextXAlignment = Enum.TextXAlignment.Right
    readout.Position = UDim2.new(1, -60, 0, 0)

    local trackFrame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 28),
        BackgroundColor3 = Theme.Raised,
        BorderSizePixel = 0,
    }, holder)
    corner(trackFrame, 3)
    local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0 }, trackFrame)
    corner(fill, 3)
    ThemeHooks[#ThemeHooks + 1] = function() fill.BackgroundColor3 = Theme.Accent end

    local function fmt(n)
        local text = decimals > 0 and string.format("%." .. decimals .. "f", n)
            or tostring(math.floor(n + 0.5))
        return text .. (opts.Suffix or "")
    end

    local function apply(n, silent)
        value = math.clamp(n, min, max)
        fill.Size = UDim2.fromScale((value - min) / (max - min), 1)
        readout.Text = fmt(value)
        if not silent and opts.Callback then task.spawn(opts.Callback, value) end
    end

    local dragging = false
    local function fromInput(x)
        local ratio = math.clamp((x - trackFrame.AbsolutePosition.X) / trackFrame.AbsoluteSize.X, 0, 1)
        apply(math.floor((min + (max - min) * ratio) / step + 0.5) * step)
    end

    conn(trackFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromInput(input.Position.X)
        end
    end))
    conn(UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            fromInput(input.Position.X)
        end
    end))
    conn(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))

    apply(value, true)
    if opts.Flag then Controls[opts.Flag] = { get = function() return value end, set = function(v) apply(v) end } end
    return { Set = apply, Get = function() return value end }
end

function Section:Dropdown(opts)
    local holder = create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex = 2,
    }, self.Body)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Theme.Raised,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, holder)
    corner(button, 6)
    local buttonStroke = outline(button)
    local text = label(button, opts.Text or "Select", UDim2.new(1, -34, 1, 0), Theme.Sub)
    text.Position = UDim2.new(0, 10, 0, 0)
    local arrow = label(button, "+", UDim2.new(0, 20, 1, 0), Theme.Sub)
    arrow.Position = UDim2.new(1, -26, 0, 0)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    local panel = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 34),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 6,
    }, holder)
    corner(panel, 6)
    outline(panel)
    pad(panel, 4)
    list(panel, 2)
    create("UISizeConstraint", { MaxSize = Vector2.new(10000, 160) }, panel)
    local selected

    local function buildItems(items)
        for _, child in ipairs(panel:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for index, item in ipairs(items) do
            local row = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundColor3 = Theme.Raised,
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = index,
            }, panel)
            corner(row, 4)
            local rowText = label(row, tostring(item), UDim2.new(1, -12, 1, 0), Theme.Sub)
            rowText.Position = UDim2.new(0, 8, 0, 0)
            conn(row.MouseEnter:Connect(function() tween(row, { BackgroundTransparency = 0.7 }, 0.1) end))
            conn(row.MouseLeave:Connect(function() tween(row, { BackgroundTransparency = 1 }, 0.1) end))
            conn(row.MouseButton1Click:Connect(function()
                selected = item
                text.Text = tostring(item)
                text.TextColor3 = Theme.Text
                panel.Visible = false
                panel.Size = UDim2.new(1, 0, 0, 0)
                self.Holder.ZIndex = 1
                tween(buttonStroke, { Color = Theme.Stroke }, 0.1)
                if opts.Callback then task.spawn(opts.Callback, item) end
            end))
        end
    end

    conn(button.MouseButton1Click:Connect(function()
        local open = not panel.Visible
        panel.Visible = open
        if open then
            panel.Size = UDim2.new(1, 0, 0, math.min(#panel:GetChildren(), 6) * 26 + 8)
            self.Holder.ZIndex = 20
            tween(buttonStroke, { Color = Theme.Accent }, 0.1)
        else
            panel.Size = UDim2.new(1, 0, 0, 0)
            self.Holder.ZIndex = 1
            tween(buttonStroke, { Color = Theme.Stroke }, 0.1)
        end
    end))

    buildItems(opts.Items or {})
    return { Refresh = buildItems, Get = function() return selected end }
end

function Section:Textbox(opts)
    local holder = create("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, self.Body)
    local box = create("TextBox", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.Raised,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Theme.Text,
        PlaceholderText = opts.Text or "Enter text",
        PlaceholderColor3 = Theme.Sub,
        Text = opts.Default or "",
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    }, holder)
    corner(box, 6)
    local boxStroke = outline(box)
    pad(box, 0, 0, 0, 10)
    conn(box.Focused:Connect(function() tween(boxStroke, { Color = Theme.Accent }, 0.1) end))
    conn(box.FocusLost:Connect(function()
        tween(boxStroke, { Color = Theme.Stroke }, 0.1)
        if opts.Callback then task.spawn(opts.Callback, box.Text) end
    end))
    if opts.Flag then Controls[opts.Flag] = {
        get = function() return box.Text end,
        set = function(v) box.Text = tostring(v) end,
    } end
    return { Get = function() return box.Text end, Set = function(v) box.Text = tostring(v) end }
end

function Section:Button(opts)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = Theme.Raised,
        Text = opts.Text or "Button",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.Text,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, self.Body)
    corner(button, 6)
    local buttonStroke = outline(button)
    conn(button.MouseEnter:Connect(function() tween(buttonStroke, { Color = Theme.Accent }, 0.1) end))
    conn(button.MouseLeave:Connect(function() tween(buttonStroke, { Color = Theme.Stroke }, 0.1) end))
    conn(button.MouseButton1Click:Connect(function()
        if opts.Callback then task.spawn(opts.Callback) end
    end))
    return button
end

function Section:Label(text)
    local holder = create("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1 }, self.Body)
    local t = label(holder, text, UDim2.fromScale(1, 1), Theme.Sub)
    t.TextSize = 12
    return t
end

function Section:Divider()
    local holder = create("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 1 }, self.Body)
    create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0 }, holder)
end

-- tab ------------------------------------------------------------------------

local Tab = {}
Tab.__index = Tab

function Tab:Section(name)
    local holder = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        ZIndex = 1,
    }, self.Scroll)
    corner(holder, 8)
    outline(holder)
    pad(holder, 10)
    list(holder, 6)
    local head = label(holder, name, UDim2.new(1, 0, 0, 16), Theme.Text, true)
    head.TextSize = 12
    local body = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, holder)
    list(body, 6)
    return setmetatable({ Body = body, Holder = holder }, { __index = Section })
end

-- window ---------------------------------------------------------------------

function Hub:Tab(name)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Theme.Raised,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, self.TabList)
    corner(button, 6)
    local marker = create("Frame", {
        Size = UDim2.new(0, 2, 0, 14),
        Position = UDim2.new(0, 6, 0.5, -7),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = false,
    }, button)
    corner(marker, 2)
    ThemeHooks[#ThemeHooks + 1] = function() marker.BackgroundColor3 = Theme.Accent end
    local text = label(button, name, UDim2.new(1, -22, 1, 0), Theme.Sub)
    text.Position = UDim2.new(0, 14, 0, 0)
    text.TextSize = 12
    text.Font = Enum.Font.GothamBold

    local scroll = create("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Stroke,
        Visible = false,
    }, self.Content)
    pad(scroll, 10)
    list(scroll, 8)

    local entry = { Scroll = scroll, Text = text, Marker = marker }
    self.Tabs[#self.Tabs + 1] = entry

    conn(button.MouseButton1Click:Connect(function()
        for _, other in ipairs(self.Tabs) do
            other.Scroll.Visible = false
            other.Text.TextColor3 = Theme.Sub
            other.Marker.Visible = false
        end
        scroll.Visible = true
        text.TextColor3 = Theme.Text
        marker.Visible = true
    end))

    if #self.Tabs == 1 then
        scroll.Visible = true
        text.TextColor3 = Theme.Text
        marker.Visible = true
    end
    return setmetatable({ Scroll = scroll }, { __index = Tab })
end

function Hub:ApplyTheme(name)
    local accent = Themes[name]
    if not accent then return end
    Theme.Accent = accent
    for _, hook in ipairs(ThemeHooks) do pcall(hook) end
end

function Hub:Build()
    local parent = (function()
        local ok, hui = pcall(function() return gethui() end)
        if ok and hui then return hui end
        local pg = LP and LP:FindFirstChildOfClass("PlayerGui")
        return pg or game:GetService("CoreGui")
    end)()

    self.Gui = create("ScreenGui", {
        Name = "SchoolHub",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    }, parent)

    local win = create("Frame", {
        Size = UDim2.fromOffset(600, 420),
        Position = UDim2.new(0.5, -300, 0.5, -210),
        BackgroundColor3 = Theme.Bg,
        BorderSizePixel = 0,
        Active = true,
    }, self.Gui)
    self.Window = win
    corner(win, 10)
    local winStroke = outline(win)
    ThemeHooks[#ThemeHooks + 1] = function() winStroke.Color = Theme.Stroke end

    self.Toasts = create("Frame", {
        Size = UDim2.new(0, 260, 1, -40),
        Position = UDim2.new(1, -272, 0, 20),
        BackgroundTransparency = 1,
        ZIndex = 60,
    }, self.Gui)
    list(self.Toasts, 8, Enum.HorizontalAlignment.Right)

    local bar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, win)
    corner(bar, 10)
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, bar)

    local title = label(bar, "<b>School</b> Hub <font color='#868d98'>| ML Money</font>",
        UDim2.new(1, -160, 1, 0), Theme.Text, true)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.TextSize = 14
    local version = label(bar, "v" .. Hub.Version, UDim2.new(0, 54, 1, 0), Theme.Sub)
    version.Position = UDim2.new(1, -112, 0, 0)
    version.TextXAlignment = Enum.TextXAlignment.Right

    local close = create("TextButton", {
        Size = UDim2.fromOffset(20, 20),
        Position = UDim2.new(1, -28, 0.5, -10),
        BackgroundColor3 = Theme.Raised,
        Text = "x",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Theme.Sub,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, bar)
    corner(close, 5)
    conn(close.MouseButton1Click:Connect(function() self:Unload() end))

    local minimise = create("TextButton", {
        Size = UDim2.fromOffset(20, 20),
        Position = UDim2.new(1, -52, 0.5, -10),
        BackgroundColor3 = Theme.Raised,
        Text = "-",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Theme.Sub,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, bar)
    corner(minimise, 5)
    conn(minimise.MouseButton1Click:Connect(function()
        self.Minimized = not self.Minimized
        tween(win, { Size = self.Minimized and UDim2.fromOffset(600, 38) or UDim2.fromOffset(600, 420) }, 0.18)
        self.Body.Visible = not self.Minimized
    end))

    self.Body = create("Frame", {
        Size = UDim2.new(1, 0, 1, -38),
        Position = UDim2.new(0, 0, 0, 38),
        BackgroundTransparency = 1,
    }, win)

    local rail = create("Frame", {
        Size = UDim2.new(0, 132, 1, 0),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, self.Body)
    corner(rail, 10)
    create("Frame", {
        Size = UDim2.new(0, 12, 1, 0),
        Position = UDim2.new(1, -12, 0, 0),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, rail)
    pad(rail, 10, 8, 10, 8)
    self.TabList = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, rail)
    list(self.TabList, 4)

    self.Content = create("Frame", {
        Size = UDim2.new(1, -132, 1, 0),
        Position = UDim2.new(0, 132, 0, 0),
        BackgroundTransparency = 1,
    }, self.Body)

    self.Tabs = {}

    local dragging, dragStart, origin
    conn(bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, origin = true, input.Position, win.Position
        end
    end))
    conn(UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStart
        win.Position = UDim2.new(origin.X.Scale, origin.X.Offset + delta.X,
            origin.Y.Scale, origin.Y.Offset + delta.Y)
    end))
    conn(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    conn(UIS.InputBegan:Connect(function(input, typing)
        if typing then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            win.Visible = not win.Visible
        end
    end))
end

function Hub:Unload()
    Engine.Stop("unloaded")
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    for _, i in ipairs(Instances) do pcall(function() i:Destroy() end) end
    if ENV.SchoolHub == self then ENV.SchoolHub = nil end
    print("[School Hub] unloaded")
end

function Hub:SaveConfig()
    if type(writefile) ~= "function" then return end
    local data = {}
    for flag, ctl in pairs(Controls) do data[flag] = ctl.get() end
    pcall(writefile, "schoolhub/mechanic-legends.json", HttpService:JSONEncode(data))
end

function Hub:LoadConfig()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then return end
    if not isfile("schoolhub/mechanic-legends.json") then return end
    local ok, raw = pcall(readfile, "schoolhub/mechanic-legends.json")
    if not ok then return end
    local decoded
    ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok or type(decoded) ~= "table" then return end
    for flag, value in pairs(decoded) do
        local ctl = Controls[flag]
        if ctl then pcall(ctl.set, value) end
    end
end

-- ============================================================================
-- prompt driver
-- ============================================================================

local Engine = {
    List = {},
    Cooldown = {},
    Running = false,
    Paused = false,
    Log = {},
    LogLabel = nil,
    StatusLabel = nil,
    StageLabel = nil,
}

local Pat = {
    Job     = { "workbench", "customer", "accept job", "new job", "tablet", "approve", "job" },
    Repair  = { "repair", "install", "reinstall", "mount", "bolt", "fix", "wrench", "reassemble", "attach" },
    Battery = { "battery", "charge" },
    Rust    = { "rust", "clean", "wash", "sand", "ultrasonic", "grind" },
    Polish  = { "polish", "buff", "finish", "shine" },
    Paint   = { "paint", "spray", "strip", "colour", "color" },
    Deliver = { "deliver", "handover", "hand in", "complete job", "done" },
    Sell    = { "sell car", "sell", "dealer", "resale", "trade in" },
    Buy     = { "buy", "purchase", "junk" },
}

function Engine.HRP()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end

function Engine.Humanoid()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end

function Engine.Position(inst)
    local node = inst
    for _ = 1, 5 do
        if not node then return nil end
        if node:IsA("BasePart") then return node.Position end
        if node:IsA("Attachment") then
            local part = node.Parent
            if part and part:IsA("BasePart") then return part.Position end
        end
        node = node.Parent
    end
    return nil
end

function Engine.LogLine(text)
    table.insert(Engine.Log, 1, os.date("%H:%M:%S") .. "  " .. text)
    while #Engine.Log > 60 do table.remove(Engine.Log) end
    if Engine.LogLabel then
        Engine.LogLabel.Text = table.concat(Engine.Log, "\n")
    end
end

function Engine.SetStatus(text)
    if Engine.StatusLabel then Engine.StatusLabel.Text = "Status: " .. text end
end

function Engine.SetStage(text)
    if Engine.StageLabel then Engine.StageLabel.Text = "Step: " .. text end
end

function Engine.Walk(pos)
    local hrp = Engine.HRP()
    if not hrp or not pos then return false end
    local humanoid = Engine.Humanoid()
    if humanoid and humanoid.Sit then pcall(function() humanoid.Sit = false end) end
    local offset = Vector3.new(0, 2.6, 0)
    local away = hrp.Position - pos
    if away.Magnitude > 0.05 then offset = offset + away.Unit * 2.4 end
    pcall(function() hrp.CFrame = CFrame.new(pos + offset) end)
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    return true
end

function Engine.Refresh()
    local built = {}
    pcall(function()
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                local pos = Engine.Position(d)
                if pos then
                    built[#built + 1] = {
                        prompt = d,
                        pos = pos,
                        name = string.lower(table.concat({
                            d.Name, d.ActionText or "", d.ObjectText or "",
                            d.Parent and d.Parent.Name or "",
                            d.Parent and d.Parent.Parent and d.Parent.Parent.Name or "",
                        }, " ")),
                    }
                end
            end
        end
    end)
    Engine.List = built
    for prompt in pairs(Engine.Cooldown) do
        if not prompt.Parent then Engine.Cooldown[prompt] = nil end
    end
end

function Engine.Find(patterns, filter)
    local hrp = Engine.HRP()
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, entry in ipairs(Engine.List) do
        if entry.prompt.Parent and entry.prompt.Enabled ~= false then
            local ok = false
            for _, pat in ipairs(patterns) do
                if string.find(entry.name, pat, 1, true) then ok = true; break end
            end
            if ok and (not filter or filter(entry)) then
                local dist = (entry.pos - hrp.Position).Magnitude
                if dist < bestDist then best, bestDist = entry, dist end
            end
        end
    end
    return best
end

function Engine.Fire(entry, cooldown)
    if type(entry) ~= "table" then return false end
    local prompt = entry.prompt
    if not prompt or not prompt.Parent or prompt.Enabled == false then return false end
    local now = os.clock()
    local last = Engine.Cooldown[prompt]
    if last and now - last < (cooldown or 1.0) then return false end
    Engine.Cooldown[prompt] = now

    Engine.Walk(entry.pos)
    if not Engine.HRP() then return false end

    pcall(function()
        prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, 90)
        prompt.RequiresLineOfSight = false
    end)
    local hold = prompt.HoldDuration
    pcall(function() prompt.HoldDuration = 0 end)
    pcall(function()
        if type(fireproximityprompt) == "function" then
            fireproximityprompt(prompt, 0)
        else
            prompt:InputHoldBegin()
            task.wait(math.max(hold, 0.1))
            prompt:InputHoldEnd()
        end
    end)
    pcall(function() prompt.HoldDuration = hold end)
    return true
end

-- ============================================================================
-- money tracking
-- ============================================================================

local Money = { start = nil, peak = nil, spent = 0, earned = 0, jobs = 0, cars = 0, started = 0 }

function Money.Value()
    local stats = LP:FindFirstChild("leaderstats")
    local sources = {}
    if stats then table.insert(sources, stats) end
    table.insert(sources, LP)
    for _, holder in ipairs(sources) do
        for _, v in ipairs(holder:GetChildren()) do
            if v:IsA("ValueBase") then
                local lower = string.lower(v.Name)
                if string.find(lower, "cash", 1, true) or string.find(lower, "money", 1, true)
                    or string.find(lower, "coin", 1, true) then
                    local n = tonumber(v.Value)
                    if n then return n, v end
                end
            end
        end
    end
    for _, key in ipairs({ "Cash", "Money", "Coins" }) do
        local n = tonumber(LP:GetAttribute(key))
        if n then return n end
    end
    return nil
end

-- ============================================================================
-- runner
-- ============================================================================

local S = {
    mode = "Hybrid",
    reserve = 2500,
    maxBuy = 8000,
    minMargin = 2500,
    cooldown = 3,
    passes = 30,
    rejoin = true,
}

local StallLimit = 6

function Engine.Stop(reason)
    if not Engine.Running then return end
    Engine.Running = false
    Engine.Paused = false
    Engine.SetStatus("stopped")
    Engine.SetStage("-")
    Engine.LogLine("stopped: " .. tostring(reason or "user"))
end

function Engine.Pause(on)
    Engine.Paused = on
    Engine.SetStatus(on and "paused" or "running")
end

local function runStage(stage)
    local deadline = os.clock() + (stage.timeout or 20)
    local fired = 0
    while Engine.Running and not Engine.Paused and os.clock() < deadline do
        local entry = Engine.Find(stage.find, stage.filter)
        if entry then
            Engine.Fire(entry, stage.cooldown)
            fired += 1
            task.wait(stage.delay or 0.45)
            if stage.once and fired >= (stage.hits or 1) then return true end
        else
            if not stage.once then return fired > 0 end
            task.wait(0.25)
        end
    end
    return fired > 0
end

local function carNumbers(model)
    local out = {}
    if not model then return out end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("ValueBase") then
            local n = tonumber(d.Value)
            if n then out[string.lower(d.Name)] = n end
        end
    end
    for k, v in pairs(model:GetAttributes()) do
        local n = tonumber(v)
        if n then out[string.lower(k)] = n end
    end
    return out
end

local function pickNumber(tbl, keys)
    for _, key in ipairs(keys) do
        for name, value in pairs(tbl) do
            if string.find(name, key, 1, true) then return value end
        end
    end
    return nil
end

local function profitableCar(entry)
    local prompt = entry.prompt
    local model = prompt.Parent
    for _ = 1, 4 do
        if not model or model == workspace then break end
        local nums = carNumbers(model)
        local price = pickNumber(nums, { "price", "cost", "buy" })
        local value = pickNumber(nums, { "value", "worth", "market", "estimate" })
        local repair = pickNumber(nums, { "repair", "estimate cost", "damage" }) or 0
        if price and price > 0 then
            if price > S.maxBuy then return false end
            if value then
                return (value - price - repair) >= S.minMargin
            end
            return true
        end
        model = model.Parent
    end
    return true
end

local function cashGuard()
    if S.reserve <= 0 then return true end
    local cash = Money.Value()
    if cash and cash < S.reserve then
        Engine.Stop("cash below reserve ($" .. S.reserve .. ")")
        return false
    end
    return true
end

local function jobStages()
    return {
        { name = "accept job", find = Pat.Job, once = true, timeout = 10, delay = 1.2, cooldown = 0.6 },
        { name = "repair parts", find = Pat.Repair, timeout = 70, delay = 0.4 },
        { name = "charge battery", find = Pat.Battery, timeout = 20, delay = 0.5 },
        { name = "clean rust", find = Pat.Rust, timeout = 70, delay = 0.4 },
        { name = "polish parts", find = Pat.Polish, timeout = 45, delay = 0.4 },
        { name = "paint", find = Pat.Paint, timeout = 60, delay = 0.5 },
        { name = "hand job back", find = Pat.Deliver, once = true, hits = 2, timeout = 15, delay = 1.0 },
    }
end

local function flipStages()
    return {
        { name = "buy junk car", find = Pat.Buy, filter = profitableCar, once = true, timeout = 20, delay = 1.2 },
        { name = "repair parts", find = Pat.Repair, timeout = 80, delay = 0.4 },
        { name = "charge battery", find = Pat.Battery, timeout = 20, delay = 0.5 },
        { name = "clean rust", find = Pat.Rust, timeout = 70, delay = 0.4 },
        { name = "polish parts", find = Pat.Polish, timeout = 45, delay = 0.4 },
        { name = "paint", find = Pat.Paint, timeout = 60, delay = 0.5 },
        { name = "sell car", find = Pat.Sell, once = true, hits = 2, timeout = 20, delay = 1.0 },
    }
end

local function runSet(stages)
    for _, stage in ipairs(stages) do
        if not Engine.Running or Engine.Paused then return end
        Engine.SetStage(stage.name)
        local ok = runStage(stage)
        if not ok and stage.once then
            Engine.LogLine("retry: " .. stage.name)
            ok = runStage(stage)
        end
        if not ok then Engine.LogLine("skip: " .. stage.name) end
    end
end

local function cycle()
    local cashBefore = Money.Value()
    local mode = S.mode

    if mode == "Hybrid" then
        local garageCar = Engine.Find(Pat.Sell)
        if garageCar then
            Engine.LogLine("hybrid: finishing owned car")
            runSet({ table.unpack(flipStages(), 2) })
        else
            local cash = Money.Value()
            if cash and cash > (S.reserve + S.maxBuy) then
                Engine.LogLine("hybrid: buying a flip")
                runSet(flipStages())
            else
                runSet(jobStages())
            end
        end
    elseif mode == "Flips" then
        runSet(flipStages())
    else
        runSet(jobStages())
    end

    local cashAfter = Money.Value()
    if cashBefore and cashAfter then
        local delta = cashAfter - cashBefore
        if delta > 0 then
            Money.earned += delta
            Engine.LogLine("+$" .. math.floor(delta))
        elseif delta < 0 then
            Money.spent += -delta
        else
            Engine.LogLine("no cash change this cycle")
        end
    end
end

function Engine.Start()
    if Engine.Running then return end
    Engine.Running = true
    Engine.Paused = false
    Money.started = os.clock()
    Money.start = Money.Value()
    Engine.SetStatus("running")
    Engine.LogLine("started in " .. S.mode .. " mode")

    task.spawn(function()
        local stalls = 0
        while Engine.Running do
            if Engine.Paused then
                task.wait(0.4)
            else
                Engine.Refresh()
                if cashGuard() then
                    local before = Money.Value()
                    local ok, err = pcall(cycle)
                    if not ok then Engine.LogLine("error: " .. tostring(err)) end
                    local after = Money.Value()
                    if before and after and after <= before then
                        stalls += 1
                    else
                        stalls = 0
                    end
                    if stalls >= StallLimit then
                        stalls = 0
                        Engine.LogLine("stalled " .. StallLimit .. "x, recovering")
                        Engine.SetStatus("recovering")
                        task.wait(2)
                        Engine.Refresh()
                        local board = Engine.Find(Pat.Job)
                        if board then Engine.Fire(board, 0) end
                        if S.rejoin and Engine.Running then
                            Engine.LogLine("rejoin fallback")
                            task.wait(1)
                            pcall(TeleportService.TeleportToPlaceInstance,
                                TeleportService, game.PlaceId, game.JobId, LP)
                            Engine.Stop("rejoining")
                            return
                        end
                    end
                end
                if Engine.Running then
                    Engine.SetStatus("cooldown " .. S.cooldown .. "s")
                    task.wait(S.cooldown)
                    if Engine.Running then Engine.SetStatus("running") end
                end
            end
        end
    end)
end

-- ============================================================================
-- ui features
-- ============================================================================

local Features = {}

function Features.Money(hub)
    local tab = hub:Tab("Money")

    local stats = tab:Section("Session")
    local cashLabel = stats:Label("Cash: --")
    local rateLabel = stats:Label("Per hour: --")
    local runLabel = stats:Label("Runtime: --")
    local spentLabel = stats:Label("Spent: $0")

    local master = tab:Section("Control")
    master:Toggle({
        Text = "MONEY FARM (start/stop)", Flag = "master",
        Callback = function(state)
            if state then Engine.Start() else Engine.Stop("toggle off") end
        end,
    })
    Engine.StatusLabel = master:Label("Status: idle")
    Engine.StageLabel = master:Label("Step: -")
    master:Button({ Text = "Pause / resume", Callback = function()
        if not Engine.Running then return end
        Engine.Pause(not Engine.Paused)
        hub:Notify("Farm", Engine.Paused and "Paused." or "Resumed.")
    end })
    master:Dropdown({
        Text = "Mode",
        Items = { "Hybrid", "Jobs", "Flips" },
        Callback = function(choice)
            S.mode = choice
            Engine.LogLine("mode: " .. choice)
        end,
    })
    master:Label("Hybrid = jobs when broke, flips when you can afford a car.")

    local log = tab:Section("Log")
    local logFrame = create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 150),
        BackgroundColor3 = Theme.Bg,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Stroke,
    }, log.Body)
    corner(logFrame, 6)
    pad(logFrame, 6)
    Engine.LogLabel = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 11,
        TextColor3 = Theme.Sub,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Text = "",
    }, logFrame)

    conn(RunService.Heartbeat:Connect(function()
        local cash = Money.Value()
        cashLabel.Text = cash and ("Cash: $" .. tostring(math.floor(cash))) or "Cash: --"

        local run = Money.started > 0 and (os.clock() - Money.started) or 0
        runLabel.Text = string.format("Runtime: %dm %02ds", math.floor(run / 60), math.floor(run % 60))

        if Money.earned > 0 and run > 20 then
            rateLabel.Text = "Per hour: $" .. tostring(math.floor(Money.earned / run * 3600))
        else
            rateLabel.Text = "Per hour: --"
        end
        spentLabel.Text = "Spent: $" .. tostring(math.floor(Money.spent))
    end))
end

function Features.Limits(hub)
    local tab = hub:Tab("Limits")
    local sec = tab:Section("Spending")

    sec:Slider({
        Text = "Cash reserve", Min = 0, Max = 100000, Default = 2500, Suffix = " $", Flag = "reserve",
        Callback = function(v) S.reserve = math.floor(v) end,
    })
    sec:Label("Farm stops if cash drops under the reserve.")

    sec:Slider({
        Text = "Max car price", Min = 500, Max = 60000, Default = 8000, Suffix = " $", Flag = "maxbuy",
        Callback = function(v) S.maxBuy = math.floor(v) end,
    })
    sec:Slider({
        Text = "Min expected margin", Min = 0, Max = 40000, Default = 2500, Suffix = " $", Flag = "margin",
        Callback = function(v) S.minMargin = math.floor(v) end,
    })
    sec:Label("Junkyard cars are skipped unless value minus price minus repairs clears the margin.")

    local tune = tab:Section("Timing")
    tune:Slider({
        Text = "Cycle cooldown", Min = 0, Max = 15, Default = 3, Suffix = " s", Flag = "cooldown",
        Callback = function(v) S.cooldown = math.floor(v) end,
    })
    tune:Toggle({
        Text = "Rejoin when stalled", Flag = "rejoin", Default = true,
        Callback = function(state) S.rejoin = state end,
    })
end

function Features.Car(hub)
    local tab = hub:Tab("Car")
    local fuel = true
    local boost = false
    local speed = 100

    local function seatPart()
        local humanoid = Engine.Humanoid()
        local seat = humanoid and humanoid.SeatPart
        if seat and seat:IsA("VehicleSeat") then return seat end
        return nil
    end

    tab:Section("Driving"):Toggle({
        Text = "Infinite fuel", Flag = "fuel", Default = true,
        Callback = function(state) fuel = state end,
    })
    tab:Section("Driving"):Toggle({
        Text = "Speed boost", Flag = "vboost",
        Callback = function(state) boost = state end,
    })
    tab:Section("Driving"):Slider({
        Text = "Boost speed", Min = 40, Max = 400, Default = 100, Flag = "vspeed",
        Callback = function(v) speed = v end,
    })
    tab:Section("Driving"):Button({ Text = "Flip car upright", Callback = function()
        local seat = seatPart()
        local model = seat and seat.Parent
        local primary = model and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true))
        if primary then
            primary.CFrame = CFrame.new(primary.Position + Vector3.new(0, 4, 0)) * primary.CFrame.Rotation
            hub:Notify("Car", "Flipped.")
        else
            hub:Notify("Car", "Not in a car.")
        end
    end })

    conn(RunService.Heartbeat:Connect(function()
        if fuel then
            local seat = seatPart()
            local model = seat and seat.Parent
            if model then
                for _, d in ipairs(model:GetDescendants()) do
                    if d:IsA("NumberValue") and string.find(string.lower(d.Name), "fuel", 1, true) then
                        pcall(function() d.Value = 100 end)
                    end
                end
            end
        end
        if boost then
            local seat = seatPart()
            if seat then
                local body = seat:FindFirstChild("SchoolBoost")
                if not body then
                    body = Instance.new("BodyVelocity")
                    body.Name = "SchoolBoost"
                    body.MaxForce = Vector3.new(1e5, 0, 1e5)
                    body.Parent = seat
                end
                body.Velocity = seat.CFrame.LookVector * speed
            end
        end
    end))
end

function Features.Travel(hub)
    local tab = hub:Tab("Travel")
    local target

    local function scan()
        local names, seen = {}, {}
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("Model") then
                local lower = string.lower(d.Name)
                for _, key in ipairs({ "lift", "battery", "charger", "ultrasonic", "polisher",
                    "paint", "booth", "parts", "junkyard", "dealer", "gas", "workbench" }) do
                    if string.find(lower, key, 1, true) and not seen[d.Name] then
                        seen[d.Name] = true
                        names[#names + 1] = d.Name
                        break
                    end
                end
            end
        end
        table.sort(names)
        return names
    end

    local dropdown = tab:Section("Stations"):Dropdown({
        Text = "Station", Items = scan(),
        Callback = function(name) target = name end,
    })
    tab:Section("Stations"):Button({ Text = "Refresh list", Callback = function()
        dropdown.Refresh(scan())
        hub:Notify("Travel", "Rebuilt.")
    end })
    tab:Section("Stations"):Button({ Text = "Teleport", Callback = function()
        if not target then return hub:Notify("Travel", "Pick a station.") end
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("Model") and d.Name == target then
                local pos = Engine.Position(d)
                if pos and Engine.Walk(pos) then return hub:Notify("Travel", "Moved.") end
            end
        end
        hub:Notify("Travel", "Station not loaded.")
    end })
end

function Features.Player(hub)
    local tab = hub:Tab("Player")
    local sec = tab:Section("Character")

    sec:Slider({
        Text = "Walk speed", Min = 16, Max = 250, Default = 16, Suffix = " spd", Flag = "walk",
        Callback = function(v)
            local humanoid = Engine.Humanoid()
            if humanoid then humanoid.WalkSpeed = v end
        end,
    })
    sec:Slider({
        Text = "Jump power", Min = 50, Max = 350, Default = 50, Suffix = " jmp", Flag = "jump",
        Callback = function(v)
            local humanoid = Engine.Humanoid()
            if humanoid then humanoid.JumpPower = v end
        end,
    })

    local infinite, noclip = false, false
    conn(UIS.JumpRequest:Connect(function()
        local humanoid = Engine.Humanoid()
        if infinite and humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
