--[[
2019-2024 João Cardoso
A library inspired in AceAddon-3.0, but that uses the global callback registry
for events and has behavior changes plus additional features I wanted that were
incompatible with Ace.
]]--

local Lib = LibStub:NewLibrary('WildAddon-1.1', 3)
if not Lib then return end


--[[ Locals ]]--

local type, tinsert, tremove, pairs = type, tinsert, tremove, pairs
local Embeds = {}

local function safecall(object, key, ...)
	local func = object[key]
	if type(func) == 'function' then
		func(object, ...)
	end	
end

local function embed(object, ...)
	for i= 1, select('#', ...) do
		local lib = select(i, ...)
		if type(lib) == 'string' then
			lib = LibStub(lib)
		end

		if type(lib) == 'table' then
			safecall(lib, 'Embed', object)
		end
	end
	return object
end

local function newobject(domain, id, object, ...)
	if type(object) == 'string' then
		object = embed({}, Lib, object, ...)
	else
		object = embed(object or {}, Lib, ...)
	end

	if domain then
		domain[id] = object
	end

	tinsert(Lib.Loading, object)
	return object
end

local function load()
	while (#Lib.Loading > 0) do
		local module = tremove(Lib.Loading, 1)
		safecall(module, 'OnLoad')
		module.OnLoad = nil
	end
end

Lib.Loading = Lib.Loading or {}
EventUtil.RegisterOnceFrameEventAndCallback('PLAYER_LOGIN', function()
	EventRegistry:RegisterFrameEventAndCallback('ADDON_LOADED', load, Lib)
	load()
end)


--[[ Addon/Module API ]]--

function Embeds:NewModule(...)
	local module = newobject(self, ...)
	module.Tag = self.Tag
	return module
end

function Embeds:RegisterEvent(event, call, ...)
	EventRegistry:RegisterFrameEventAndCallback(event, self[call or event] or call, self, ...)
end

function Embeds:UnregisterEvent(event)
	EventRegistry:UnregisterFrameEventAndCallback(event, self)
end

function Embeds:ContinueOn(event, call, ...)
	EventUtil.RegisterOnceFrameEventAndCallback(event, GenerateClosure(self[call or event] or call, self), ...)
end

function Embeds:RegisterSignal(event, call, ...)
	EventRegistry:RegisterCallback(self.Tag .. event, self[call or event] or call, self, ...)
end

function Embeds:UnregisterSignal(event)
	EventRegistry:UnregisterCallback(self.Tag .. event, self)
end

function Embeds:SendSignal(event, ...)
	EventRegistry:TriggerEvent(self.Tag .. event, ...)
end

function Embeds:UnregisterAll()
	for _, table in pairs(EventRegistry:GetCallbackTables()) do
		for event, callbacks in pairs(table) do
			if callbacks[self] then
				EventRegistry:UnregisterFrameEventAndCallback(event, self)
			end
		end
	end
end

function Embeds:SetDefaults(target, defaults)
	defaults.__index = nil

	for k, v in pairs(defaults) do
		if type(v) == 'table' then
			if getmetatable(v) == false then
				target[k] = target[k] or setmetatable(CopyTable(v), {__metatable = false})
			else
				target[k] = self:SetDefaults(target[k] or {}, v)
			end
		end
	end

	defaults.__index = defaults
	return setmetatable(target, defaults)
end


--[[ Public API ]]--

function Lib:NewAddon(name, ...)
	local addon = newobject(_G, name, ...)
	addon.Tag = name .. '.'
	addon.Name = name
	return addon
end

function Lib:Embed(object)
	for k,v in pairs(Embeds) do
		object[k] = v
	end
end
