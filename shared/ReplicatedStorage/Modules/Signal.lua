--!strict
-- Lightweight pub/sub used by server systems to broadcast state changes
-- (e.g. RoundManager's RoundStateChanged) without wiring every listener manually.

local Signal = {}
Signal.__index = Signal

export type Signal<T...> = {
	Connect: (self: Signal<T...>, fn: (T...) -> ()) -> { Disconnect: (self: any) -> () },
	Fire: (self: Signal<T...>, T...) -> (),
	DisconnectAll: (self: Signal<T...>) -> (),
}

function Signal.new()
	local self = setmetatable({}, Signal)
	self._listeners = {}
	return self
end

function Signal:Connect(fn)
	local listeners = self._listeners
	local id = #listeners + 1
	listeners[id] = fn

	local connection = {}
	function connection.Disconnect()
		listeners[id] = nil
	end

	return connection
end

function Signal:Fire(...)
	for _, fn in pairs(self._listeners) do
		local ok, err = pcall(fn, ...)
		if not ok then
			warn("[Signal] listener error:", err)
		end
	end
end

function Signal:DisconnectAll()
	table.clear(self._listeners)
end

return Signal
