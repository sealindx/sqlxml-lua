local sxml = require "sxml"
local helper = require "helper"

local format = string.format


local M = {
	__statementHandle = {
		["select"] = true,
		["update"] = true,
		["delete"] = true,
		["insert"] = true,
	}
}


local mapper = {}
mapper.__index = mapper


local function getNodeId(node)
	local properties = node:properties()
	local id = properties.id
	return id
end

local function assertNodeId(obj, node)
	local id = getNodeId(node)

	assert(id, "sql tag id is nil")
	assert(not obj.__statement[id], format("repeat define %s", id))

	return id
end


--[[
	token like {
		-- #{id}  #{nickeName}
		"id", '#'
		"nickeName", '#'

		-- ${tool.coin}
		{"tool", "coin"}, '$'
	}
]]
local function tokenReplace(content)
	local parameterMapper = {}

	content = string.gsub(content, "%s+", " ")

	content = string.gsub(content, "([#$]){(.-)}", function (sign, v)
		if string.find(v, "%.") then
			local parameter = helper.stringSplit(v, "%.")
			table.insert(parameterMapper, parameter)
		else
			table.insert(parameterMapper, v)
		end

		-- # or $
		table.insert(parameterMapper, sign)
		return "?"
	end)

	-- dynamic sql node
	if #parameterMapper > 0 then
		local tokenNode = {
			name = function ( )
				return "__dynamic"
			end, 
			__name = "__dynamic"
		}

		table.insert(tokenNode, content)
		table.insert(tokenNode, parameterMapper)

		return tokenNode
	end

	-- raw Sql node
	return content
end

local function prepareParseTrim(node)
	if node:name() ~= "trim" then
		return
	end

	local properties = node:properties()
	local prefixOverrides = properties.prefixOverrides
	local suffixOverrides = properties.suffixOverrides

	if prefixOverrides and not helper.stringIsEmpty(prefixOverrides) then
		node.__preOverArray = helper.stringSplit(prefixOverrides, "|")
	end

	if suffixOverrides and not helper.stringIsEmpty(suffixOverrides) then
		node.__sufOverArray = helper.stringSplit(suffixOverrides, "|")
	end
end

local function parseNode(node, tagNode)
	local list = node:children()
	for i=1, #list do
		local cnode = list[i]
		if type(cnode) == "string" then
			local content = tokenReplace(cnode)
			list[i] = content
		else
			prepareParseTrim(cnode)

			local tag = tagNode
			local key = M.__statementHandle
			if not tag and key[cnode:name()] then
				tag = cnode
			end

			parseNode(cnode, tag)
		end
	end
end

function mapper:parse( )
	local root = self.__root
	parseNode(root)
end

function mapper:applyInclude(node, list, idx)
	local id = node:properties().refid
	local sqlElem = self.__statement[id]
	assert(sqlElem, format("id(%s) can't find sql element", refid))

	-- <sql> contents replace <include>
	local children = sqlElem:children()
	list[idx] = children[1]
	for i=2, #children do
		local child = children[i]
		table.insert(list, idx+i-1, child)
	end

	self:includeParser(sqlElem)
end

function mapper:includeParser(node)
	if type(node) == "string"
	or node:name() == "__dynamic" then
		return
	end

	local list = node:children()
	for i=1, #list do
		local child = list[i]
		if type(child) == "table" then
			if child:name() == "include" then
				self:applyInclude(child, list, i)
			else
				self:includeParser(child)
			end
		end
	end
end

function mapper:replaceAllIncludeNode( )
	local root = self.__root
	local list = root:children()
	local key = M.__statementHandle
	for i=1, #list do
		local node = list[i]
		if key[node:name()] then
			self:includeParser(node)
		end
	end
end

function mapper:removeAllSqlNode( )
	local statement = self.__statement
	local root = self.__root
	local list = root:children()

	for i=#list, 1, -1 do
		local node = list[i]
		if node:name() == "sql" then
			table.remove(list, i)

			local properties = node:properties()
			local id = properties.id
			statement[id] = nil
		end
	end
end

function mapper:buildStateMent( )
	local root = self.__root
	local __statement = self.__statement
	local list = root:children()
	local namespace = root:properties().namespace

	assert(namespace, "mapper tag must exist namespace property")

	for i=1, #list do
		local node = list[i]
		local id = assertNodeId(self, node)
		__statement[id] = node
	end

	__statement.namespace = namespace
end

function mapper:resolvingElement(root)
	local rootName = root:name()
	if rootName ~= "mapper" then
		error("can't find root tag(mapper)")
		return
	end

	self.__root = root
	self.__statement = {}

	self:buildStateMent()

	self:parse()

	self:replaceAllIncludeNode()
	self:removeAllSqlNode()

	self.__root = nil
end

function M.new(path)
	local o = {}
	setmetatable(o, mapper)
	o:build(path)
    return o
end

function mapper:build(path)
	local root = sxml.parseXMLByPath(path)
	self:resolvingElement(root)
end

function mapper:statement( )
	return self.__statement
end

return M
