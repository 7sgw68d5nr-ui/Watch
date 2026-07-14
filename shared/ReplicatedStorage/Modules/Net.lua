--!strict
-- Thin wrapper around the Remotes folder so systems don't reach into
-- ReplicatedStorage:WaitForChild(...) chains directly.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = {}

local remotesFolder: Folder? = nil

local function getRemotesFolder(): Folder
	if remotesFolder == nil then
		remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	end
	return remotesFolder :: Folder
end

local function getRemote(name: string): RemoteEvent
	local folder = getRemotesFolder()
	local remote = folder:WaitForChild(name)
	assert(remote:IsA("RemoteEvent"), `Net: "{name}" is not a RemoteEvent`)
	return remote
end

-- Server -> client(s)
function Net.FireClient(name: string, player: Player, ...: any)
	getRemote(name):FireClient(player, ...)
end

function Net.FireAllClients(name: string, ...: any)
	getRemote(name):FireAllClients(...)
end

-- Client -> server
function Net.FireServer(name: string, ...: any)
	getRemote(name):FireServer(...)
end

-- Listen (works on both sides; only the relevant event exists per-side)
function Net.OnServerEvent(name: string, fn: (player: Player, ...any) -> ())
	return getRemote(name).OnServerEvent:Connect(fn)
end

function Net.OnClientEvent(name: string, fn: (...any) -> ())
	return getRemote(name).OnClientEvent:Connect(fn)
end

return Net
