
local helper = {}

function helper.stringSplit(szFullString, szSeparator)
	local nFindStartIndex = 1
	local nFindLastIndex
	local nSplitIndex = 1
	local nSplitArray = {}
	local size = string.len(szFullString)

	while true do
		local i, j = string.find(szFullString, szSeparator, nFindStartIndex)
		if not i then
			nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, size)
			break
		end

		nFindLastIndex = j

		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
		nFindStartIndex = nFindLastIndex + 1
		nSplitIndex = nSplitIndex + 1
	end
	return nSplitArray
end

-- check string is empty
function helper.stringIsEmpty(str)
	if not str or str == '' then
		return true
	end

	if string.find(str, "[^%s]") then
		return false
	end

	return true
end

return helper

