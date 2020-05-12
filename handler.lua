local helper = require "helper"

local format = string.format
local gsub = string.gsub
local upper = string.upper
local concat = table.concat

local handler


local function findV(args, map)
	local source = args
	local key, val

	for i=1, #map do
		key = map[i]
		val = source[key]

		if type(val) == "table" then
			source = val
		end
	end

	return val
end


local function dynamicHandler(node, args)
	local content, parameters = node[1], node[2]
	local idx = 1
	local _param = {}

	for i=1, #parameters, 2 do
		local p = parameters[i]
		local sign = parameters[i+1]
		local val

		if type(p) == "string" then
			val = args[p]
		else
			val = findV(args, p)
		end

		if sign == '#' and type(val) == "string" then
			val = "'" .. val .. "'"
		end

		_param[idx] = val or ""
		idx = idx + 1
	end

	idx = 1

	content = gsub(content, "%?", function ( )
		local p = _param[idx]
		idx = idx + 1

		return p
	end)

	return content
end

-- analytic expression
local function parseExpression(strExpr, args, obj)
	local cache = obj.__cache

	local ok, boolean = cache:getLoadValue(strExpr, args)
	assert(ok, boolean)
	return boolean
end

local function ifHandler(node, args, obj)
	local test = node.__props.test

	assert(test)

	if parseExpression(test, args, obj) then
		return handler.execute(node, args, obj)
	end

	return ""
end

local function chooseHandler(node, args, obj)
	local contents = node:children()

	for i=1, #contents do
		local sqlNode = contents[i]
		local name = sqlNode.__name
		name = upper(name)
		if i == 1 then
			assert(name == "WHEN", "choose tag: the first child node must exist when")
		end

		if name == "WHEN" then
			local test = sqlNode.__props.test
			assert(test, "when tag must exist test property")

			if parseExpression(test, args, obj) then
				return handler.execute(sqlNode, args, obj)
			end
		elseif name == "OTHERWISE" then
			return handler.execute(sqlNode, args, obj)
		else
			error("choose tag can only contain when tag and otherwise tag")
		end
	end
end

local function foreachHandler(node, args, obj)
	local properties = node.__props
	local collection = properties.collection
	local item = properties.item
	local index = properties.index
	local separator = properties.separator
	local open = properties.open
	local close = properties.close

	assert(collection, "foreach tag must exist collection property")
	assert(item, "foreach tag must exist item property")

	local map = args[collection]
	local contents = node:children()
	local sql = ""

	if open then
		sql = open .. sql
	end

	local tcache = {}
	local execute = handler.execute

	for k,v in pairs(map) do
		local newArgs = {}
		if index then
			newArgs[index] = k
		end

		newArgs[item] = v

		local oneSql = execute(node, newArgs, obj)
		tcache[#tcache+1] = oneSql

	end

	sql = concat(tcache, separator)

	if close then
		sql = sql .. close
	end

	return sql
end

local function whereHandler(node, args, obj)
	local sql = handler.execute(node, args, obj)
	if helper.stringIsEmpty(sql) then
		return ""
	end

	local count
	sql, count = gsub(sql, "^(%s*)[aA][nN][dD]", "%1", 1)
	if count and count == 0 then
		sql, count = gsub(sql, "^(%s*)[oO][rR]", "%1", 1)
	end

	return " WHERE " .. sql
end

local function setHandler(node, args, obj)
	local sql = handler.execute(node, args, obj)
	if helper.stringIsEmpty(sql) then
		error("set tag resolved content is empty")
	end

	sql = gsub(sql, "%s*,%s*$", " ", 1)

	return " SET " .. sql
end

local function trimHandler(node, args, obj)
	local properties = node.__props
	local prefix = properties.prefix
	local suffix = properties.suffix
	local preOverArray = node.__preOverArray
	local sufOverArray = node.__sufOverArray

	local sql = handler.execute(node, args, obj)
	local count

	if preOverArray then
		for i=1, #preOverArray do
			local removeElem = preOverArray[i]
			sql, count = gsub(sql, "^%s*" .. removeElem .. "%s+", " ", 1)
			if count == 1 then
				break
			end
		end
	end

	if sufOverArray then
		for i=1, #sufOverArray do
			local removeElem = sufOverArray[i]

			-- like remove ','
			-- string: aaaddd  ,
			sql, count = gsub(sql, "%s+" .. removeElem .."%s*$", " ", 1)
			if count == 1 then
				break
			else
				-- like remove ',' 
				-- string: aaaddd,
				sql, count = gsub(sql, "[^%s]" .. removeElem .."%s*$", " ", 1)
				if count == 1 then
					break
				end
			end
		end
	end

	if prefix then
		sql = format(" %s %s", prefix, sql)
	end

	if suffix then
		sql = format("%s %s ", sql, suffix)
	end

	return sql
end

handler = {
	["__dynamic"] = dynamicHandler,

	["if"] = ifHandler,
	["choose"] = chooseHandler,
	["foreach"] = foreachHandler,

	["where"] = whereHandler,
	["set"] = setHandler,
	["trim"] = trimHandler,

}

function handler.execute(xnode, args, obj)
	local contents = xnode:children()
	local sql = ""

	for i=1, #contents do
		local node = contents[i]
		local ntype = type(node)

		if ntype == "string" then
			sql = sql .. node
		elseif ntype == "table" then
			local f = handler[node.__name]
			assert(f, format("can't find %s tag", node.__name))
			sql = sql .. f(node, args, obj)
		end
	end

	return sql
end

local M = {}

function M.genSql(xnode, args, obj)
	return handler.execute(xnode, args, obj)
end

return M
