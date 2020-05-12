
local function newNode(name)
    local node = {}
    node.__name = name
    node.__children = {}
    node.__props = {}
    node.__props_num = 0


    function node:name() return self.__name end

    function node:children() return self.__children end
    function node:numChildren() return #self.__children end

    function node:addChild(child)
        table.insert(self.__children, child)
    end

    function node:addProperty(lName, value)
    	if self.__props[lName] ~= nil then
			local tempTable = {}

			table.insert(tempTable, self.__props[lName])
			self.__props[lName] = tempTable

			table.insert(self.__props[lName], value)
		else
			self.__props[lName] = value
		end

		self.__props_num = self.__props_num + 1
	end

    function node:properties() return self.__props end
    function node:numProperties() return self.__props_num end

	function node:getProperty(key)
		return self.__props[key]
	end

	return node
end

local function loadFile(xmlFilename)
    local path = xmlFilename
    local hFile, err = io.open(path, "r")

    if hFile and not err then
        local xmlText = hFile:read("*a") -- read file content
        io.close(hFile)
        return xmlText
    else
        print(err)
        return nil
    end
end

local function findTagBegin(xmlText, i)
	return string.find(xmlText, "<([%w_:]+)(.-)(%/?)>", i)
end

local function findTagEnd(xmlText, i)
	return string.find(xmlText, "<%/([%w_:]+)>", i)
end

local function findStrText(xmlText, i)
	local findStart, findEnd = string.find(xmlText, "<", i)
	local str = string.sub(xmlText, i, findEnd-1)

	if string.find(str, "[^%s]") then
		return i, findEnd-1, string.sub(xmlText, i, findEnd-1)
	end
end

local function fromXmlString(value)
    value = string.gsub(value, "&#x([%x]+)%;", function(h)
		return string.char(tonumber(h, 16))
	end)

    value = string.gsub(value, "&#([0-9]+)%;", function(h)
		return string.char(tonumber(h, 10))
	end)

	value = string.gsub(value, "&quot;", "\"")
	value = string.gsub(value, "&apos;", "'")
	value = string.gsub(value, "&gt;", ">")
	value = string.gsub(value, "&lt;", "<")
	value = string.gsub(value, "&amp;", "&")
    return value
end

local function parseArgs(node, s)
	string.gsub(s, "(%w+)%s*=%s*([\"'])(.-)%2", function(w, _, a)
		node:addProperty(w, fromXmlString(a))
	end)
end

local function tipsRemove(xmlText)
	xmlText = string.gsub(xmlText, "<!%-%-(.-)%-%->", "")
	xmlText = string.gsub(xmlText, "<%?xml%s*.-%?>", "")
	return xmlText
end

function parseOneNode(xmlText, startPos)
	local i = startPos
	local ni, j, label, xarg, empty, tend

	local _, tj, strText

	-- find start tag
	ni, j, label, xarg, empty = findTagBegin(xmlText, i)
	if not ni then
		return
	end

	local node = newNode(label)

	parseArgs(node, xarg)

	i = j + 1
	-- one tag end
	if empty == "/" then
		return node, i
	end

	while true do
		-- find string text
		_, tj, strText = findStrText(xmlText, i)

		if strText and strText ~= "" then
			node:addChild(fromXmlString(strText))
			i = tj
		end

		-- find start tag, double check
		i = string.find(xmlText, "<", i)
		if string.sub(xmlText, i+1, i+1) ~= "/" then
			local child, childPos = parseOneNode(xmlText, i)
			node:addChild(child)
			i = childPos
		else
			break
		end
	end

	-- one tag end
	_, tj, tend = findTagEnd(xmlText, i)

	assert(tend == label)

	i = tj + 1
	return node, i
end

local function _parseXML(xmlText)
	xmlText = tipsRemove(xmlText)
	return parseOneNode(xmlText, 1)
end


local M = {}


function M.parseXML(xmlText)
	_parseXML(xmlText)
end

function M.parseXMLByPath(path)
	local xmlText = loadFile(path)
	if xmlText then
		return _parseXML(xmlText)
	end
end

return M
