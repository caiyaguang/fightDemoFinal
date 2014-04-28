--[[
	common function
]]

--[[
	输入一个key可转换为数字的字典，对key排序 {k1 = v1, k2 = v2}
	返回一个数组，{1 = {key = k1, value = v1}, 2 = {key = k2, value = v2}}
]]
table.sortKey = function(theTable, bAcs)
    local kArr = table.allKey(theTable)
    local function sortFun( a, b )
        if bAcs then
            return tonumber(a) < tonumber(b)
        else
            return tonumber(a) > tonumber(b)
        end
    end
    table.sort( kArr, sortFun )
    local ret = {}
    for i,v in ipairs(kArr) do
        local dic = {key = v, value = theTable[v]}
        table.insert(ret, dic)
    end
    return ret
end

--[[
	获得table所有的key
]]
table.allKey = function( table )
    -- body
    local keys = {}
    for k,v in pairs(table) do
        keys[#keys + 1] = k
    end
    return keys
end

--[[
	获得table所有的value
]]
table.allValue = function( table )
    local values = {}
    for k,v in pairs(table) do
        values[#values + 1] = v
    end
    return values
end

--[[
	table是否包含元素
]]
table.ContainsObject = function( theTable,object )
    -- body
    if not theTable or table.getTableCount(theTable) <= 0 or type(theTable) ~= "table" then
        return false
    end
    for i,v in pairs(theTable) do
        if v == object then
            return true
        end
    end
    return false
end

--[[
	获取 table 全部元素个数
]]
table.getTableCount = function( tableTmp )
    -- body
    local i = 0
    if tableTmp and type(tableTmp) == "table" then
        for k,v in pairs(tableTmp) do
            if v then
                i = i +1
            end
        end
    end
    return i
end