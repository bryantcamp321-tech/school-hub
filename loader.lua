--!nocheck
--[[
    School Hub - single-file hub
    Framework + features in one chunk. No remote fetch.

    loadstring(game:HttpGet("<raw url of loader.lua>"))()

    Right Shift hides the window. Settings tab saves config.
]]

local Hub = { Version = "1.2.0", Name = "School Hub" }
Hub.__index = Hub

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local ENV = (function()
    local ok, value = pcall(function() return getgenv() end)
    if ok and type(value) == "table" then return value end
    return _G
end)()

local LP = Players.LocalPlayer

do -- single instance
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

-- notifications --------------------------------------------------------------

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

function Section:Keybind(opts)
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, self.Body)
    label(row, opts.Text or "Keybind", UDim2.new(1, -90, 1, 0), Theme.Text)
    local button = create("TextButton", {
        Size = UDim2.fromOffset(80, 22),
        Position = UDim2.new(1, -80, 0.5, -11),
        BackgroundColor3 = Theme.Raised,
        Text = opts.Default and opts.Default.Name or "None",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Theme.Sub,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, row)
    corner(button, 5)
    local buttonStroke = outline(button)
    local current = opts.Default
    local listening = false
    local hold = opts.Mode == "hold"

    conn(button.MouseButton1Click:Connect(function()
        listening = true
        button.Text = "..."
        tween(buttonStroke, { Color = Theme.Accent }, 0.1)
    end))

    conn(UIS.InputBegan:Connect(function(input, typing)
        if listening then
            if typing then return end
            listening = false
            current = input.KeyCode
            button.Text = current.Name
            tween(buttonStroke, { Color = Theme.Stroke }, 0.1)
            if opts.Callback then task.spawn(opts.Callback, current) end
            return
        end
        if not hold or typing or not current then return end
        if input.KeyCode ~= current then return end
        if opts.Callback then task.spawn(opts.Callback, true) end
    end))

    conn(UIS.InputEnded:Connect(function(input)
        if not hold or not current then return end
        if input.KeyCode ~= current then return end
        if opts.Callback then task.spawn(opts.Callback, false) end
    end))

    return { Get = function() return current end }
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
        Size = UDim2.fromOffset(560, 380),
        Position = UDim2.new(0.5, -280, 0.5, -190),
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

    local title = label(bar, "<b>School</b> Hub", UDim2.new(1, -130, 1, 0), Theme.Text, true)
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
        tween(win, { Size = self.Minimized and UDim2.fromOffset(560, 38) or UDim2.fromOffset(560, 380) }, 0.18)
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
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    for _, i in ipairs(Instances) do pcall(function() i:Destroy() end) end
    if ENV.SchoolHub == self then ENV.SchoolHub = nil end
    print("[School Hub] unloaded")
end

-- config ---------------------------------------------------------------------

function Hub:SaveConfig()
    if type(writefile) ~= "function" then return end
    local data = {}
    for flag, ctl in pairs(Controls) do data[flag] = ctl.get() end
    pcall(writefile, "schoolhub/config.json", HttpService:JSONEncode(data))
end

function Hub:LoadConfig()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then return end
    if not isfile("schoolhub/config.json") then return end
    local ok, raw = pcall(readfile, "schoolhub/config.json")
    if not ok then return end
    local decoded
    ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok or type(decoded) ~= "table" then return end
    for flag, value in pairs(decoded) do
        local ctl = Controls[flag]
        if ctl then pcall(ctl.set, value) end
    end
end

-- boot -----------------------------------------------------------------------

function Hub:Init()
    ENV.SchoolHub = self
    self:Build()

    local settings = self:Tab("Settings")
    local appearance = settings:Section("Appearance")
    appearance:Dropdown({
        Text = "Accent colour",
        Items = { "Citron", "Mint", "Azure", "Rose", "Violet", "Amber" },
        Callback = function(choice) self:ApplyTheme(choice) end,
    })
    appearance:Label("Right Shift hides the window.")

    local config = settings:Section("Config")
    config:Button({ Text = "Save settings", Callback = function()
        self:SaveConfig()
        self:Notify("Config", "Saved.")
    end })
    config:Button({ Text = "Load settings", Callback = function()
        self:LoadConfig()
        self:Notify("Config", "Loaded.")
    end })
    config:Button({ Text = "Unload hub", Callback = function() self:Unload() end })

    self:Notify("School Hub", "Loaded v" .. self.Version .. " - Right Shift to hide.")
    return self
end

-- features -------------------------------------------------------------------

local Features = {}

function Features.Movement(hub)
    local tab = hub:Tab("Movement")
    local character = tab:Section("Character")

    local humanoid
    local function bind()
        local model = LP and LP.Character
        humanoid = model and model:FindFirstChildOfClass("Humanoid") or nil
    end
    bind()
    conn(LP.CharacterAdded:Connect(function()
        task.wait(0.6)
        bind()
    end))

    character:Slider({
        Text = "Walk speed", Min = 16, Max = 250, Default = 16, Suffix = " spd", Flag = "walk",
        Callback = function(value)
            if humanoid then humanoid.WalkSpeed = value end
        end,
    })
    character:Slider({
        Text = "Jump power", Min = 50, Max = 350, Default = 50, Suffix = " jmp", Flag = "jump",
        Callback = function(value)
            if humanoid then humanoid.JumpPower = value end
        end,
    })

    local infinite
    conn(UIS.JumpRequest:Connect(function()
        if infinite and humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end))
    character:Toggle({
        Text = "Infinite jump", Flag = "infjump",
        Callback = function(state) infinite = state end,
    })

    local world = tab:Section("World")
    local baseline
    world:Toggle({
        Text = "Fullbright", Flag = "fullbright",
        Callback = function(state)
            if state then
                baseline = baseline or {
                    Brightness = Lighting.Brightness,
                    ClockTime = Lighting.ClockTime,
                    GlobalShadows = Lighting.GlobalShadows,
                }
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.GlobalShadows = false
            elseif baseline then
                Lighting.Brightness = baseline.Brightness
                Lighting.ClockTime = baseline.ClockTime
                Lighting.GlobalShadows = baseline.GlobalShadows
            end
        end,
    })
    world:Slider({
        Text = "Field of view", Min = 40, Max = 120, Default = 70, Flag = "fov",
        Callback = function(value)
            if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = value end
        end,
    })
end

function Features.Players(hub)
    local tab = hub:Tab("Players")
    local section = tab:Section("Teleport")
    local target

    local function names()
        local out = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP then out[#out + 1] = player.Name end
        end
        return out
    end

    local dropdown = section:Dropdown({
        Text = "Target", Items = names(),
        Callback = function(name) target = name end,
    })
    section:Button({ Text = "Refresh list", Callback = function() dropdown.Refresh(names()) end })
    section:Button({
        Text = "Teleport to target",
        Callback = function()
            local player = target and Players:FindFirstChild(target)
            local character = player and player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local mine = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if root and mine then
                mine.CFrame = root.CFrame * CFrame.new(0, 0, 3)
                hub:Notify("Teleport", "Moved to " .. player.Name)
            else
                hub:Notify("Teleport", "Target not available.")
            end
        end,
    })

    local info = tab:Section("Info")
    local fps = info:Label("FPS: --")
    local frames, clock = 0, os.clock()
    conn(RunService.RenderStepped:Connect(function()
        frames += 1
        if os.clock() - clock >= 1 then
            fps.Text = "FPS: " .. frames
            frames, clock = 0, os.clock()
        end
    end))

    info:Button({
        Text = "Copy JobId",
        Callback = function()
            if type(setclipboard) == "function" then
                pcall(setclipboard, game.JobId)
                hub:Notify("Clipboard", "JobId copied.")
            end
        end,
    })
    info:Button({
        Text = "Rejoin server",
        Callback = function()
            pcall(TeleportService.TeleportToPlaceInstance,
                TeleportService, game.PlaceId, game.JobId, LP)
        end,
    })
end

function Features.Combat(hub)
    local tab = hub:Tab("Combat")
    local swinging = false

    local function swingRemote()
        local folder = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        local remote = folder and folder:FindFirstChild("Swing")
        return remote
    end

    tab:Section("Melee"):Toggle({
        Text = "Auto swing", Flag = "swing",
        Callback = function(on)
            swinging = on
            if not on then return end
            task.spawn(function()
                while swinging and getgenv().SchoolHub do
                    local remote = swingRemote()
                    if remote then pcall(remote.FireServer, remote) end
                    task.wait(0.1)
                end
            end)
        end,
    })
end

-- start ----------------------------------------------------------------------

local hub = setmetatable({ Tabs = {} }, Hub)
hub:Init()
Features.Movement(hub)
Features.Players(hub)
Features.Combat(hub)

hub:LoadConfig()

return hub
