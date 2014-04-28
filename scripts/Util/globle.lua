--[[
	globle lua
    保存一些全局变量
]]

--[[
    英雄连携类型
]]
ENUM_COMBO_TYPE = {
    HERO = 1,
    EQUIP = 2,
    SKILL = 3,
}

--[[
    技能类型
]]
ENUM_SKILL_TYPE = {
    PER_BUFF = 1,       -- 百分比buff
    ALL = 2,            -- 全体伤害
    SINGLE = 3,         -- 单体伤害
    FIELD_BUFF = 4,     -- 全体buff
    BUFF = 5,           -- 数值buff
}
