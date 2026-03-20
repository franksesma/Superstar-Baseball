local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.RemoteEvents

local resetBindable = Instance.new("BindableEvent")
resetBindable.Event:connect(function()
	Remotes.ResetCharacter:FireServer()
end)

repeat 
	local success = pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		StarterGui:SetCore("ResetButtonCallback", resetBindable)
	end)
	wait()
until success