local mapper = require "mapper"
local handler = require "handler"
local cache = require "cache"

local format = string.format

local sqlmgr = {}



local function genSql(obj, id, args)
	local statement = obj.__statement
	local path = obj.__path
	local xnode = statement[id]

	assert(xnode, format("can't find id(%s) by %s", id, path))

	args = args or {}
	return handler.genSql(xnode, args, obj)
end


sqlmgr.__index = function (t, k)
	local f = function (obj, args)
		return genSql(obj, k, args)
	end

	t[k] = f
	return f
end


function sqlmgr.new(path)
	local parser = mapper.new(path)
	local o = {
		__path = path,
		__statement = parser:statement(),
		__cache = cache.new(),
	}
	setmetatable(o, sqlmgr)
    return o
end




return sqlmgr

