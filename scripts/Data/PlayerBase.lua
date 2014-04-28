--[[
	base player data
]]
local player = class("PlayerBase", function()
	local data = {
		heroes = {}, -- 拥有的英雄
	    form = {}, -- 阵法中的英雄
	    sevenForm = {}, -- 七星阵上阵的英雄
	    attrFix = {}, -- 战舰
	    equips = {}, -- 装备
	    skills = {}, -- 技能书
	    shadows = {}, -- 真气
	    titles = {}, -- 称号，计算气势值
	    level = 0,
	    name = nil, 
	    extraBuff = {},	-- 额外属性增幅
	} 
	return data
end)

-- init
function player:ctor(info)
	self.heroes = info.heros or {}
    self.form = info.form or {}
    self.sevenForm = info.form_seven or {}
    self.attrFix = info.attrFix or {}
    self.equips = info.equips or {}
    self.skills = info.books or {}
    self.shadows = info.shadows or {}
    self.titles = info.titles or {}
    self.name = info.name or ""
    self.level = info.level or 0
    self.self = info.extraBuff or {}
end

--[[
	获取英雄装备的技能
	@params: hid - hero uid
	@return: table
]]
function player:getHeroSkills(hid)
	local dic = {}
	local hero = self.heroes[hid]
	if hero.skill_default then
		dic["0"] = hero.skill_default
	end
	if hero.skills_ex then
		for i=1,2 do
            local sid = hero.skills_ex[tostring(i)]
            if sid then
                dic[tostring(i)] = self.skills[sid]
            end
		end
	end
	return dic
end

--[[
	获取英雄的净身价（除开装备奥义影子等） 
	@params: hid - hero uid
	@return: int
]]
function player:getHeroAttrPrice(hid)
    local hero = self.heroes[hid]
    local price = Config.getHeroPriceConfig(hero.heroId)
    local heroConfig = Config.getHeroConfig(hero.heroId)
    local attr = 0
    -- 升级提升属性
    for k,v in pairs(heroConfig.grow) do
        attr = attr + math.floor(v * (hero.level - 1))
    end
    -- 培养的属性
    for k,v in pairs(hero.attrFix) do
        attr = attr + tonumber(v)
    end
    return price + math.floor(attr * 0.75)
end

--[[
	身价计算
	@params: hid - hero uid
	@return: int
]]
function player:getHeroPrice(hid)
    local price = self:getHeroAttrPrice(hid) -- 英雄净身价
    local hero = self.heroes[hid]
    -- 武器的身价
    for k,eid in pairs(hero.equip) do
        local equip = self.equips[eid]
        price = price + Config.getEquipPrice(equip.equipId, equip.level)
    end
    -- 技能的身价
    for k,skill in pairs(self:getHeroSkills(hid)) do
        price = price + Config.getSkillPrice(skill.skillId, skill.level)
    end
    return price
end

--[[
	获取英雄详细信息
	@params: hid - hero uid
	@return: table
]]
function player:getHero(hid)
	local hero = clone(self.heroes[hid])
	local conf = Config.getHeroConfig(hero.heroId)
	hero.name = conf.name
	hero.rank = conf.rank
	hero.desp = conf.desp
	hero.expMax = Config.levelExp[tostring(hero.level)].value2 * conf.exp
	hero.price = self:getHeroPrice(hero.id)
	return hero
end

--[[
	查询英雄是否上阵
	@params: heroId - hero config id
	@return: bool
]]
function player:bHeroOnForm(heroId)
	local function onForm(form)
		for _,id in pairs(form) do
			if id and id ~= "" and self.heroes[id].heroId == heroId then
				return true
			end	
		end
		return false
	end
	return onForm(self.form) or onForm(self.sevenForm)
end

--[[
	得到装备所在的hero
	@params: eid - equip uid
	@return: table
]]
function player:getOwnerByEid(eid)
	for _,hid in pairs(self.form) do
		local hero = self:getHero(hid)
		if hero.equip then
			for i=0,2 do
				if hero.equip[tostring(i)] and hero.equip[tostring(i)] == eid then
					return hero
				end
			end
		end
	end
	return nil
end

--[[
	是否开启影子系统
	@return: bool
]]
function player:bOpenShadow()
	if Config.levelOpen["shadow"] then
		return self.level >= Config.levelOpen["shadow"].level
	end
	return false
end

--[[
	得到称号页面默认显示称号
	@return: table
]]
function player:getDefaultTitles()
	local array = {}
	for tid,v in pairs(Config.titleConfig) do
		if v.outer ~= 0 then
			local conf = Config.getTitleConfig(tid)
			local content = clone(self.titles[tid])
			local dic = {["conf"] = conf, ["title"] = content}
			table.insert(array, dic)
		end
	end
	local function sortFun(a, b)
		return a.conf.outer < b.conf.outer
	end
	table.sort(array, sortFun)
	return array
end

--[[
	啦啦队上限
	@return: int
]]
function player:getFormSevenMax()
	local limit = 0
	for i,v in ipairs(table.sortKey(Config.formSevenMax, true)) do
		if self.level < tonumber(v.key) then
			break
		end
		limit = v.value
	end
	return limit
end

--[[
	获得啦啦队上的英雄id
	@params: index - 啦啦队索引
	@params: string
]]
function player:getHidOnFormSeven(index)
	return self.sevenForm[tostring(index - 1)]
end

--[[
	啦啦队状态
	@params: index - 啦啦队索引
	@return: int 0 - 等级未到锁住 1 - 未使用道具开启 2 - 开启未上阵 3 - 已上阵英雄
]]
function player:formSevenState(index)
	local sevenFormMax = self:getFormSevenMax()
	if index > sevenFormMax then
		return 0
	else
		local hid = self:getHidOnFormSeven(index)
		if not hid then
			return 1
		elseif hid == "" then
			return 2
		else
			return 3
		end
	end
end

--[[
	计算装备的属性
	@params: equip - 装备table
	@return: table - attr
]]
local function _calcEquipAttr(equip)
    local level = equip.level
    local stage = equip.stage
    local attr = {}
    for k,v in pairs(conf.initial) do
        local value
        if conf.refine then
            value = v + math.floor((conf.updateEffect + conf.refine * stage) * (level - 1))
        else
            value = v + math.floor(conf.updateEffect * (level - 1))
        end
        if attr[k] then
            attr[k] = attr[k] + value
        else
            attr[k] = value
        end
    end
    return attr
end

--[[
	获取装备信息
	@params: eid - equip uid
	@params: table
]]
function player:getEquip(eid)
	local equip = clone(self.equips[eid])
	local conf = Config.getEquipConfig(equip.equipId)
	equip.rank = conf.rank
    equip.name = conf.name
    equip.updateSilver = conf.updateSilver
    equip.icon = conf.icon
    equip.updateEffect = conf.updateEffect
    equip["type"] = conf["type"]
    equip.desp = conf.desp
    local level = equip.level
    local stage = equip.stage
    equip.attr = _calcEquipAttr(equip)
    equip.refinelv = conf.refinelv
    equip.price = Config.getEquipPrice(equip.equipId, equip.level)
    equip.owner = self:getOwnerByEid(eid)
    return equip
end

--[[
	获取英雄身上所有的装备
	@params: hid - hero uid
	@return: table
]]
function player:getHeroEquips(hid)
	local dic = {}
	local hero = self:getHero(hid)
	for i=0,2 do
		local eid = hero.equip[tostring(i)]
		if eid then
			dic[tostring(i)] = self:getEquip(eid)
		end
	end
	return dic
end

--[[
	英雄是否穿了指定装备
	@params: equipId - equip config id
	@params: hid - hero uid
	@return: bool
]]
function player:bEquipOnHero(equipId, hid)
	local equips = self.heroes[hid].equip
	for _,eid in pairs(equips) do
		if self.equips[eid].equipId == equipId then
			return true
		end
	end
	return false
end

--[[
	英雄是否学习了指定技能
	@params: skillId - skill config id
	@params: hid - hero uid
	@return: bool
]]
function player:bSkillOnHero(skillId, hid)
	for k,skill in pairs(self:getHeroSkills(hid)) do
        if skill.skillId == skillId then
            return true
        end
    end
    return false
end

--[[
	获取英雄缘分
	@params: hid - hero uid
	@return: table
]]
function player:getCombo(hid)
	local heroId = self.heroes[hid].heroId
	local array = {}
	for _,conf in ipairs(Config.combo[heroId]) do
		local flag = false
		if conf.type == ENUM_COMBO_TYPE.HERO then
			for _,v in ipairs(conf.heroes) do
				if not self.bHeroOnForm(v) then
					flag = false
					break
				else
					flag = true
				end
			end
		elseif conf.type == ENUM_COMBO_TYPE.EQUIP then
			for _,v in ipairs(conf.equips) do
				if not self:bEquipOnHero(v, hid) then
					flag = false
					break
				else
					flag = true
				end
			end
		elseif conf.type == ENUM_COMBO_TYPE.SKILL then
			for _,v in ipairs(conf.books) do
				if not self:bSkillOnHero(v, hid) then
					flag = false
					break
				else
					flag = true
				end
			end
		end
		local dic = {["name"] = conf.name, ["flag"] = flag, ["param"] = conf.param}
		table.insert(array, dic)
	end
	return array
end

--[[
	获取英雄基础属性值，不包含装备等加成
	@params: hid - hero uid
	@return: table
]]
function player:getHeroBasicAttrs(hid)
	if not hid or string.len(hid) == 0 then
		return nil
	end
	local hero = self.heroes[hid]
	if not hero or not hero.heroId or string.len(hero.heroId) == 0 then
		return nil
	end
	local conf = Config.getHeroConfig(hero.heroId)
	local attr = clone(conf.attr)
	-- 升级提升属性
    for k,v in pairs(conf.grow) do
        if attr[k] then
            attr[k] = attr[k] + math.floor(v * (hero.level - 1))
        else
            attr[k] = math.floor(v * (hero.level - 1))
        end
    end
    -- 培养的属性
    for k,v in pairs(self.heroes[heroUId].attrFix) do
        if attr[k] then
            attr[k] = attr[k] + tonumber(v)
        else
            attr[k] = tonumber(v)
        end
    end
    -- 突破获得属性提升
    if hero["break"] and hero["break"] > 0 then
        local bAttr = conf.breakattr
        for k,v in pairs(bAttr) do
            if attr[k] then
                attr[k] = attr[k] + v * hero["break"]
            else
                attr[k] = v * hero["break"]
            end
        end
    end
    return attr
end

--[[
	获得啦啦队属性
	@return: table
]]
function player:getSevenFormAttr()
	local attr = {}
	if not self.sevenForm then
		return attr
	end
	for i=1,7 do
		local hid = self.sevenForm[tostring(i - 1)]
		if hid and hid ~= "" then
			local key = Config.formSevenAttr[i].attr
			local per = Config.formSevenAttr[i].per
			local base = self:getHeroBasicAttrs(hid)
			local value = 0
			if base[key] then
				value = math.max(math.floor(base[key] * per), 1)
			end
			attr[key] = attr[key] ~= nil and attr[key] + value or value
		end
	end
	return attr
end

--[[
	获得总气势值
	@return: int
]]
function player:getAllFame()
	local fame = 0
    local famePer = 0
    for k,v in pairs(self.titles) do
        if v.level > 0 then
            local conf = Config.getTitleConfig(k)
            if conf.baseValue < 1 then
                if conf.targetID then
                    for i,id in ipairs(conf.targetID) do
                        local data = self.titles[id]
                        if data then
                            local targetConf = Config.getTitleConfig(id)
                            local targetFame = targetConf.baseValue + targetConf.updateValue * (data.level - 1)
                            fame = fame + math.floor(targetFame * (conf.baseValue + conf.updateValue * (v.level - 1)))
                        end
                    end
                else
                    famePer = famePer + conf.baseValue + conf.updateValue * (v.level - 1)
                end
            else
                fame = fame + conf.baseValue + conf.updateValue * (v.level - 1)    
            end
        end
    end
    fame = math.floor(fame * (1 + famePer))
    return fame
end

--[[
	获得影子的属性
	@params: shadowId - shadow config id
	@params: level - 影子的等级
]]
function player:getShadowAttr(shadowId, level)
	local conf = Config.getShadowConfig(shadowId)
	local array = {["type"] = conf.property, ["value"] = conf.level[tostring(level)]}
	return array
end

--[[
	获得英雄的修炼等级
	@params: hid - hero id
	@return: int
]]
function player:getHeroTrainLevel(hid)
	local level = 0
	if not hid or string.len(hid) == 0 then
		return 0
	end
	local hero = self.heroes[hid]
	if not hero then
		return 0
	end
	if not hero.discipline or table.getTableCount(hero.discipline) == 0 then
		return 0
	end
	return hero.discipline.level
end

--[[
	获取英雄的属性
	@params: hid - hero uid
	@return: table - attr - 属性值
	@return: table - addAttr - 属性提升百分比
]]
function player:getHeroAttrs(hid)
	if not hid or string.len(hid) == 0 then
		return nil
	end
	local hero = self.heroes[hid]
	if not hero.heroId or string.len(hero.heroId) == 0 then
		return nil
	end
	local conf = Config.getHeroConfig(hero.heroId)
	local attr = self:getHeroBasicAttrs(hid)

	local addAttr = {} -- 百分比属性

	-- 闭关
	if hero.discipline and hero.discipline.level and hero.discipline.level > 0 then
		local value = math.floor(conf.specialadd["value"] + (hero.discipline.level - 1) * conf.specialadd["lv"])
		attr[conf.specialadd["attr"]] = attr[conf.specialadd["attr"]] ~= nil and attr[conf.specialadd["attr"]] + value or value
	end

	-- 装备
	for _,id in ipairs(hero.equip) do
		local equip = self.equips[id]
		if equip then
			local eAttr = _calcEquipAttr(equip)
			for k,v in pairs(eAttr) do
				attr[k] = attr[k] ~= nil and attr[k] + v or v
			end
		end
	end

	-- 战舰
	for k,v in pairs(self.attrFix) do
		local add = Config.getBattleShipAttr(k, v.level)
		attr[k] = attr[k] ~= nil and attr[k] + add or add
	end

	--啦啦队
	for k,v in pairs(self:getSevenFormAttr()) do
		attr[k] = attr[k] ~= nil and attr[k] + v or v
	end

	-- 影子
	if hero.shadows then
		for _,v in pairs(hero.shadows) do
			local shadow = self.shadows[v]
			local dic = self:getShadowAttr(shadow.shadowId, shadow.level)
			attr[dic["type"]] = attr[dic["type"]] ~= nil and attr[dic["type"]] + dic["value"] or dic["value"]
		end
	end

	-- 缘分
	local combos = self:getCombo(hid)
	for _,combo in ipairs(combos) do
		if combo.flag then
			for k,v in pairs(combo.param) do
				addAttr[k] = addAttr[k] ~= nil and addAttr[k] + v or v
			end
		end
	end

	-- 技能
	local skills = self:getHeroSkills(hid)
	for i=0,2 do
		local dic = skills[tostring(j)]
		if dic then
			local skill = Config.getSkill(dic.skillId, dic.level, hero.heroId)
			if skill.skillType == ENUM_SKILL_TYPE.PER_BUFF then
				for k,v in pairs(skill.attr) do
					addAttr[k] = addAttr[k] ~= nil and addAttr[k] + v or v
				end
			elseif skill.skillType == ENUM_SKILL_TYPE.BUFF then
				for k,v in pairs(skill.attr) do
					attr[k] = attr[k] ~= nil and attr[k] + v or v
				end
			end
		end
	end

	return attr, addAttr
end

--[[
	获取计算后的属性
	@params: hid - hero uid
	@return: table - attr - 百分比加成后的属性值
]]
function player:getHeroCalc(hid)
	local attr, addAttr = self:getHeroAttrs(hid)
	for k,v in pairs(addAttr) do
		attr[k] = attr[k] ~= nil and math.floor(attr[k] * (1 + v)) or 0
	end
	return attr
end


return player
