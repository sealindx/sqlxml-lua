


local sqlmgr = require "sqlmgr"
local handler = sqlmgr.new("sql.xml")


local data = {
	u_name = "张三",
	u_sex = "男",
	p = {
		_start = 12,
		_end = 39,
	},
}

local sql = handler:selectAllUser(data)
print(sql)



local data = {list = {}}
for i=1,5 do
	table.insert(data.list, {
		userName = "abc" .. i,
		userPassword = "532" .. i,
		userEmail = "3029" .. i .. "@qq.com",
	})
end

sql = handler:inserSysUser(data)
print(sql)


