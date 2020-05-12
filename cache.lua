local format = string.format

local cache = {}
cache.__index = cache


function cache.new( )
	local o = {}
	setmetatable(o, cache)
	return o
end

function cache:getLoadValue(strExpr, args)
	local f = self[strExpr]

	if not f then
		local source = format("local args = ...;setmetatable(_ENV, {__index = args});local x = %s; setmetatable(_ENV, nil); return x", strExpr)
		f = load(source, "=test", "t")
		self[strExpr] = f
	end

	return pcall(f, args)
end

return cache
