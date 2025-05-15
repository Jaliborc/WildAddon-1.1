--[[
2019-2024 João Cardoso
WildAddon is distributed under the terms of the GNU General Public License (Version 3).
As a special exception, the copyright holders of this library give you permission to embed it
with independent modules to produce an addon, regardless of the license terms of these
independent modules, and to copy and distribute the resulting software under terms of your
choice, provided that you also meet, for each embedded independent module, the terms and
conditions of the license of that module. Permission is not granted to modify this library.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

This file is part of WildAddon.
]]--

local Lib = LibStub:NewLibrary('WildAddon-1.1', 8)
if not Lib then return end


--[[ Locals ]]--

local setmetatable, type, select, xpcall, pairs, tinsert, tremove = setmetatable, type, select, xpcall, pairs, tinsert, tremove
local EventRegistry, MergeTable, CopyTable, CallErrorHandler = EventRegistry, MergeTable, CopyTable, CallErrorHandler
local Embeds = {}

local function safecall(object, key, ...)
	local func = object[key]
	if type(func) == 'function' then
		xpcall(func, CallErrorHandler, object, ...)
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
		safecall(tremove(Lib.Loading, 1), 'OnLoad')
	end
end

Lib.Loading = Lib.Loading or {}
Embeds.None = Embeds.None or setmetatable({}, {__newindex = function() error('None table is immutable.', 2) end})
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
	for _, table in pairs(EventRegistry:GetCallbackTables()) do
		if table[event][self] then -- EventRegistry does not check, must check ourselves
			return EventRegistry:UnregisterFrameEventAndCallback(event, self)
		end
	end
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
	MergeTable(object, Embeds)
end
