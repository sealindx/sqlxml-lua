# sqlxml-lua
一个生成 sql 语句的小工具

## 介绍
在 xml 文件中编写 sql 片段，然后在通过传递参数去拼接，动态生成 sql 语句，主要参考 mybatis 实现方式

## example
在 xml 中编写 sql
```
    <insert id="inserSysUser">
        insert into sys_user(
        user_name,user_password,user_email)
        values
        <foreach collection="list" item="user" separator="," >
            (
            #{user.userName},#{user.userPassword},#{user.userEmail}
            )
        </foreach>
    </insert>
```

在 lua 中引用 inserSysUser ，动态生成 sql 语句
```
local sqlmgr = require "sqlmgr"
local handler = sqlmgr.new("sql.xml")

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
```

具体调用过程，可以参考 example.lua，或者网上搜索下 mybatis 动态 sql 使用教程

https://www.w3cschool.cn/mybatis/l5cx1ilz.html
