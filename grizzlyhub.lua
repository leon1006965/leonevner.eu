--[[
    Grizzly Hub
    Features: Fly, Noclip, WalkSpeed, Base Teleports, and Clone Desync.
    UI Library: Rayfield
]]

local Player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- Load Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🐻 Grizzly Hub",
    LoadingTitle = "Loading Grizzly Hub...",
    LoadingSubtitle = "by You",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "GrizzlyHub"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false
})

-------------------------------------------------------------------------
-- [ TABS ]
-------------------------------------------------------------------------
local MainTab = Window:CreateTab("Main", 4483362458) -- Icon ID
local TeleportTab = Window:CreateTab("Teleports", 4483362458)
local DesyncTab = Window:CreateTab("Desync", 4483362458)

-------------------------------------------------------------------------
-- [ MAIN TAB: Fly, Noclip, Speed ]
-------------------------------------------------------------------------

-- Noclip Logic
local noclipEnabled = false
RunService.Stepped:Connect(function()
    if noclipEnabled then
        local char = Player.Character
        if char then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then
                    v.CanCollide = false
                end
            end
        end
    end
end)

MainTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(Value)
        noclipEnabled = Value
    end,
})

-- Speed Logic
MainTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 250},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "SpeedSlider",
    Callback = function(Value)
        local char = Player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = Value
        end
    end,
})

-- Keep Speed Loop (Prevents anti-cheats from setting it back)
RunService.Stepped:Connect(function()
    local char = Player.Character
    if char and char:FindFirstChild("Humanoid") then
        local speedVal = Rayfield.Flags["SpeedSlider"] and Rayfield.Flags["SpeedSlider"].CurrentValue or 16
        if speedVal > 16 then
            char.Humanoid.WalkSpeed = speedVal
        end
    end
end)

-- Fly Logic
local flying = false
local flySpeed = 50
local flyBodyVel, flyBodyGyro, flyConn
local flyCtrl = {W=false, A=false, S=false, D=false}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.W then flyCtrl.W = true end
    if input.KeyCode == Enum.KeyCode.S then flyCtrl.S = true end
    if input.KeyCode == Enum.KeyCode.A then flyCtrl.A = true end
    if input.KeyCode == Enum.KeyCode.D then flyCtrl.D = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then flyCtrl.W = false end
    if input.KeyCode == Enum.KeyCode.S then flyCtrl.S = false end
    if input.KeyCode == Enum.KeyCode.A then flyCtrl.A = false end
    if input.KeyCode == Enum.KeyCode.D then flyCtrl.D = false end
end)

MainTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(Value)
        flying = Value
        local char = Player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart
        
        if flying then
            char.Humanoid.PlatformStand = true
            
            flyBodyVel = Instance.new("BodyVelocity")
            flyBodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            flyBodyVel.Velocity = Vector3.new(0,0,0)
            flyBodyVel.Parent = hrp
            
            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            flyBodyGyro.P = 10000
            flyBodyGyro.CFrame = Camera.CFrame
            flyBodyGyro.Parent = hrp
            
            flyConn = RunService.RenderStepped:Connect(function()
                local camCF = Camera.CFrame
                flyBodyGyro.CFrame = camCF
                local moveDir = Vector3.new(0,0,0)
                if flyCtrl.W then moveDir = moveDir + camCF.LookVector end
                if flyCtrl.S then moveDir = moveDir - camCF.LookVector end
                if flyCtrl.A then moveDir = moveDir - camCF.RightVector end
                if flyCtrl.D then moveDir = moveDir + camCF.RightVector end
                
                if moveDir.Magnitude > 0 then
                    flyBodyVel.Velocity = moveDir.Unit * flySpeed
                else
                    flyBodyVel.Velocity = Vector3.new(0,0,0)
                end
            end)
        else
            char.Humanoid.PlatformStand = false
            if flyBodyVel then flyBodyVel:Destroy() end
            if flyBodyGyro then flyBodyGyro:Destroy() end
            if flyConn then flyConn:Disconnect() flyConn = nil end
        end
    end,
})

MainTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300},
    Increment = 5,
    Suffix = "Speed",
    CurrentValue = 50,
    Flag = "FlySpeedSlider",
    Callback = function(Value)
        flySpeed = Value
    end,
})


-------------------------------------------------------------------------
-- [ TELEPORT TAB: Select Base & Teleport To Base ]
-------------------------------------------------------------------------
local savedBaseCFrame = nil

TeleportTab:CreateButton({
    Name = "1. Select Base Position",
    Callback = function()
        local char = Player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            savedBaseCFrame = char.HumanoidRootPart.CFrame
            Rayfield:Notify({
                Title = "Base Saved",
                Content = "Your current standing position has been marked.",
                Duration = 4,
            })
        end
    end,
})

TeleportTab:CreateButton({
    Name = "2. Teleport To Base",
    Callback = function()
        if savedBaseCFrame then
            local char = Player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                -- Disable fly temporally to prevent glitching into ground
                if flying then 
                    char.Humanoid.PlatformStand = false
                    task.wait(0.1)
                end
                
                char.HumanoidRootPart.CFrame = savedBaseCFrame
                
                if flying then 
                    char.Humanoid.PlatformStand = true
                end
                
                Rayfield:Notify({
                    Title = "Teleported",
                    Content = "Moved to selected base.",
                    Duration = 2,
                })
            end
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "You haven't selected a base position yet! Click Button 1 first.",
                Duration = 4,
            })
        end
    end,
})


-------------------------------------------------------------------------
-- [ DESYNC TAB: Skidded & Adapted Ghost Desync ]
-------------------------------------------------------------------------
local isDesyncOn = false
local autoDesyncActive = false
local autoDesyncWait = 5
local RealChar = nil
local FakeChar = nil
local DesyncConnections = {} 
local AnimTracks = {} 

local function GetAnimID(char, name, subName)
    local animScript = char:FindFirstChild("Animate")
    if animScript then
        local value = animScript:FindFirstChild(name)
        if value then
            local anim = value:FindFirstChild(subName) or value:FindFirstChildOfClass("Animation")
            if anim then return anim.AnimationId end
        end
    end
    return nil
end

local function StopDesyncAnims()
    for _, track in pairs(AnimTracks) do
        if track then track:Stop(0.1) end
    end
end

local function DisableDesync()
    if not isDesyncOn then return end
    isDesyncOn = false
    
    for _, conn in pairs(DesyncConnections) do conn:Disconnect() end
    DesyncConnections = {}
    StopDesyncAnims()
    AnimTracks = {}
    
    local targetCF = FakeChar and FakeChar:FindFirstChild("HumanoidRootPart") and FakeChar.HumanoidRootPart.CFrame
    if FakeChar then FakeChar:Destroy() FakeChar = nil end
    
    if RealChar and RealChar:FindFirstChild("HumanoidRootPart") then
        RealChar.HumanoidRootPart.Anchored = false
        if targetCF then RealChar.HumanoidRootPart.CFrame = targetCF end
        Player.Character = RealChar
        Camera.CameraSubject = RealChar:FindFirstChild("Humanoid")
    end
end

local function EnableDesync()
    RealChar = Player.Character
    if not RealChar or not RealChar:FindFirstChild("HumanoidRootPart") then return end
    
    isDesyncOn = true
    
    RealChar.HumanoidRootPart.Anchored = true
    RealChar.Archivable = true
    FakeChar = RealChar:Clone()
    FakeChar.Name = "Grizzly_Desync_Ghost"
    FakeChar.Parent = workspace
    
    for _, v in pairs(FakeChar:GetDescendants()) do
        if v:IsA("LocalScript") or v:IsA("Script") then v:Destroy() end
    end
    
    for _, part in pairs(FakeChar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = (part.Name == "HumanoidRootPart")
            if part.Name == "HumanoidRootPart" then
                part.Transparency = 1
                for _, c in pairs(part:GetChildren()) do if c:IsA("Decal") or c:IsA("Texture") then c:Destroy() end end
            end
        end
    end

    local fakeHum = FakeChar:FindFirstChild("Humanoid")
    local fakeRoot = FakeChar:FindFirstChild("HumanoidRootPart")
    
    if fakeHum then
        fakeHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        local function Load(id)
            if not id then return nil end
            local a = Instance.new("Animation") a.AnimationId = id
            return fakeHum:LoadAnimation(a)
        end
        
        AnimTracks.Run = Load(GetAnimID(RealChar, "run", "RunAnim") or GetAnimID(RealChar, "walk", "WalkAnim") or "rbxassetid://180426354")
        AnimTracks.Idle = Load(GetAnimID(RealChar, "idle", "Animation1") or "rbxassetid://180435571")
        AnimTracks.Jump = Load(GetAnimID(RealChar, "jump", "JumpAnim") or "rbxassetid://125750702")
        AnimTracks.Climb = Load(GetAnimID(RealChar, "climb", "ClimbAnim") or "rbxassetid://180436334")
        if AnimTracks.Idle then AnimTracks.Idle:Play() end
    end
    
    Camera.CameraSubject = fakeHum

    table.insert(DesyncConnections, UserInputService.JumpRequest:Connect(function()
        if isDesyncOn and fakeHum then fakeHum.Jump = true end
    end))

    table.insert(DesyncConnections, RunService.RenderStepped:Connect(function()
        if not isDesyncOn or not FakeChar or not fakeHum or not fakeRoot then return end
        
        -- Custom Move Logic for Clone
        local moveDir = Vector3.new(0,0,0)
        local camCF = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
        
        local finalDir = Vector3.new(moveDir.X, 0, moveDir.Z)
        fakeHum:Move(finalDir.Magnitude > 0 and finalDir.Unit or Vector3.new(0,0,0), false)

        -- Switch Animations dynamically based on Clone velocity
        local velocity = fakeRoot.Velocity
        local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
        local isClimbing = fakeHum:GetState() == Enum.HumanoidStateType.Climbing

        if isClimbing then
            if AnimTracks.Climb and not AnimTracks.Climb.IsPlaying then StopDesyncAnims() AnimTracks.Climb:Play() end
        elseif velocity.Y > 5 then
            if AnimTracks.Jump and not AnimTracks.Jump.IsPlaying then StopDesyncAnims() AnimTracks.Jump:Play() end
        elseif speed > 0.5 then
            if AnimTracks.Run and not AnimTracks.Run.IsPlaying then StopDesyncAnims() AnimTracks.Run:Play() end
        else
            if AnimTracks.Idle and not AnimTracks.Idle.IsPlaying then StopDesyncAnims() AnimTracks.Idle:Play() end
        end
    end))
end

DesyncTab:CreateToggle({
    Name = "Manual Ghost Desync",
    CurrentValue = false,
    Flag = "DesyncToggle",
    Callback = function(Value)
        if Value then
            EnableDesync()
        else
            DisableDesync()
        end
    end,
})

DesyncTab:CreateLabel("--- Auto Desync Settings ---")

DesyncTab:CreateSlider({
    Name = "Auto Desync Timer (Seconds)",
    Range = {1, 15},
    Increment = 1,
    Suffix = "s",
    CurrentValue = 5,
    Flag = "AutoDesyncTimer",
    Callback = function(Value)
        autoDesyncWait = Value
    end,
})

local function StartAutoLoop()
    while autoDesyncActive do
        if not isDesyncOn then EnableDesync() end
        
        local elapsed = 0
        while elapsed < autoDesyncWait and autoDesyncActive do
            task.wait(0.1)
            elapsed = elapsed + 0.1
        end
        
        if autoDesyncActive then 
            DisableDesync()
            task.wait(1) -- Fixed 1 second wait to update real hitbox/position
        end
    end
end

DesyncTab:CreateToggle({
    Name = "Auto Loop Ghost Desync",
    CurrentValue = false,
    Flag = "AutoDesyncToggle",
    Callback = function(Value)
        autoDesyncActive = Value
        if autoDesyncActive then
            task.spawn(StartAutoLoop)
            Rayfield:Notify({Title = "Desync", Content = "Auto Loop Started", Duration = 2})
        else
            DisableDesync()
            Rayfield:Notify({Title = "Desync", Content = "Auto Loop Stopped", Duration = 2})
        end
    end,
})
