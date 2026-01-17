--[[
2019-2026 João Cardoso
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

local Lib = LibStub:NewLibrary('WildAddon-1.1', 11)
if not Lib then return end


--[[ Locals ]]--

local setmetatable, type, select, xpcall, pcall, pairs, tinsert, tremove = setmetatable, type, select, xpcall, pcall, pairs, tinsert, tremove
local EventRegistry, MergeTable, CopyTable, CallErrorHandler = EventRegistry, MergeTable, CopyTable, CallErrorHandler
local Embeds = {}

local Closures = setmetatable({}, {__index =
	function(t,n)
		local args = {}
		for i = 1, n do
			args[i] = strchar(96 + i)
		end
		
		local argsList = table.concat(args, ', ')
		local code = format([[
			return function(f, %s)
				return function(event, ...)
					return f(%s, ...)
				end
			end
		]], argsList, argsList)

		local func = loadstring(code)()
		t[n] = func
		return func
	end
})

local function getmethod(object, key, call, ...)
	local n = select('#', ...) + 1
	local method = object[call or key] or call
	return Closures[n](method, object, ...)
end

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
Lib.Calls = Lib.Calls or LibStub('CallbackHandler-1.0'):New(Lib, 'Register', 'Unregister', 'UnregisterAll')
Lib.Calls.OnUnused = function(_,_, event) pcall(Lib.Frame.UnregisterEvent, Lib.Frame, event) end
Lib.Frame = Lib.Frame or CreateFrame('Frame')
Lib.Frame:SetScript('OnEvent', Lib.Calls.Fire)


--[[ Addon/Module API ]]--

function Embeds:NewModule(...)
	local module = newobject(self, ...)
	module.Tag = self.Tag
	return module
end

function Embeds:ContinueOn(event, ...)
	local method = getmethod(self, event, ...)
	
	Lib.Frame:RegisterEvent(event)
	Lib.Register(self, event, function(...)
		Lib.Unregister(self, event)
		return method(...)
	end)
end

function Embeds:RegisterEvent(event, ...)
	Lib.Register(self, event, getmethod(self, event, ...))
	Lib.Frame:RegisterEvent(event)
end

function Embeds:RegisterSignal(event, ...)
	Lib.Register(self, self.Tag .. event, getmethod(self, event, ...))
end

function Embeds:UnregisterSignal(event)
	Lib.Unregister(self, self.Tag .. event)
end

function Embeds:SendSignal(event, ...)
	event = self.Tag .. event
	Lib.Calls:Fire(event, ...)

	if EventTrace then
		EventTrace:LogCallbackRegistryEvent('WildAddon', event, ...)
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

Embeds.Yup = function() return true end
Embeds.None = setmetatable({}, {__newindex = function() error('None table is immutable.', 2) end, __metatable = false})
Embeds.UnregisterEvent, Embeds.UnregisterAll = Lib.Unregister, Lib.UnregisterAll
Embeds:ContinueOn('PLAYER_LOGIN', function()
	Embeds:RegisterEvent('ADDON_LOADED', load)
	load()
end)


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
