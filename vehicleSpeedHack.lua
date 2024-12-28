local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local velocityMult = 0.05 -- Geschwindigkeitserhöhung pro Tick
local maxSpeed = 200 -- Maximalgeschwindigkeit in Studs pro Sekunde
local scriptEnabled = false -- Steuerung, ob das Skript aktiv ist
local dragging, dragStart, startPos
local isMinimized = false -- Minimierungsstatus des GUIs

-- Funktion, um das Fahrzeug des Spielers zu finden
local function GetVehicleFromDescendant(Descendant)
    return Descendant:FindFirstAncestor(LocalPlayer.Name .. "\'s Car") or
           Descendant:FindFirstAncestorWhichIsA("Model")
end

-- Logik zum Beschleunigen des Fahrzeugs
local function IncreaseSpeed()
    if not scriptEnabled then return end
    local Character = LocalPlayer.Character
    if Character and typeof(Character) == "Instance" then
        local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
        if Humanoid and typeof(Humanoid) == "Instance" then
            local SeatPart = Humanoid.SeatPart
            if SeatPart and SeatPart:IsA("VehicleSeat") then
                local currentSpeed = SeatPart.AssemblyLinearVelocity.Magnitude
                if currentSpeed < maxSpeed then
                    SeatPart.AssemblyLinearVelocity *= Vector3.new(1 + velocityMult, 1, 1 + velocityMult)
                else
                    local direction = SeatPart.AssemblyLinearVelocity.Unit
                    SeatPart.AssemblyLinearVelocity = direction * maxSpeed
                end
            end
        end
    end
end

-- Funktion, um die GUI zu erstellen
local function CreateGUI()
    local ScreenGui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
    ScreenGui.Name = "VehicleControlGUI"

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 300, 0, 200)
    MainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
    MainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    MainFrame.BorderSizePixel = 2
    MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    MainFrame.Active = true

    -- Dragging-Funktion für Maus und Touch
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)

    MainFrame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    MainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- GUI-Elemente erstellen
    local Title = Instance.new("TextLabel", MainFrame)
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.Text = "Vehicle Control"
    Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.SourceSans
    Title.TextSize = 20

    local EnableButton = Instance.new("TextButton", MainFrame)
    EnableButton.Size = UDim2.new(0.8, 0, 0, 30)
    EnableButton.Position = UDim2.new(0.1, 0, 0.3, 0)
    EnableButton.Text = "Enable Script: OFF"
    EnableButton.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
    EnableButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    EnableButton.Font = Enum.Font.SourceSans
    EnableButton.TextSize = 18

    local VelocitySlider = Instance.new("TextBox", MainFrame)
    VelocitySlider.Size = UDim2.new(0.8, 0, 0, 30)
    VelocitySlider.Position = UDim2.new(0.1, 0, 0.5, 0)
    VelocitySlider.Text = "Velocity Multiplier: " .. tostring(velocityMult)
    VelocitySlider.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
    VelocitySlider.TextColor3 = Color3.fromRGB(255, 255, 255)
    VelocitySlider.Font = Enum.Font.SourceSans
    VelocitySlider.TextSize = 18

    local MaxSpeedSlider = Instance.new("TextBox", MainFrame)
    MaxSpeedSlider.Size = UDim2.new(0.8, 0, 0, 30)
    MaxSpeedSlider.Position = UDim2.new(0.1, 0, 0.7, 0)
    MaxSpeedSlider.Text = "Max Speed: " .. tostring(maxSpeed)
    MaxSpeedSlider.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
    MaxSpeedSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
    MaxSpeedSlider.Font = Enum.Font.SourceSans
    MaxSpeedSlider.TextSize = 18

    -- Event-Verbindungen
    EnableButton.MouseButton1Click:Connect(function()
        scriptEnabled = not scriptEnabled
        EnableButton.Text = "Enable Script: " .. (scriptEnabled and "ON" or "OFF")
    end)

    VelocitySlider.FocusLost:Connect(function()
        local newValue = tonumber(VelocitySlider.Text:match("%d+%.?%d*"))
        if newValue then
            velocityMult = newValue
            VelocitySlider.Text = "Velocity Multiplier: " .. tostring(velocityMult)
        else
            VelocitySlider.Text = "Invalid Value!"
        end
    end)

    MaxSpeedSlider.FocusLost:Connect(function()
        local newValue = tonumber(MaxSpeedSlider.Text:match("%d+"))
        if newValue then
            maxSpeed = newValue
            MaxSpeedSlider.Text = "Max Speed: " .. tostring(maxSpeed)
        else
            MaxSpeedSlider.Text = "Invalid Value!"
        end
    end)

    return ScreenGui
end

-- Respawn-Ereignis behandeln
local function OnCharacterAdded()
    local gui = CreateGUI()

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        if input.KeyCode == Enum.KeyCode.W then
            while UserInputService:IsKeyDown(Enum.KeyCode.W) do
                IncreaseSpeed()
                RunService.Stepped:Wait()
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

-- Beim ersten Start GUI erstellen
if LocalPlayer.Character then
    OnCharacterAdded()
end