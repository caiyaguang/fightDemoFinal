--[[
	player data 
	玩家的数据
	带有一些Opponent.lua不包含的方法
]]

local PlayerBase = import(".PlayerBase")
local player = class("Player", PlayerBase)

--[[
	伙伴加经验
]]
function player:addExp(hero, exp)
	hero.exp_now = hero.exp_now + exp
	hero.exp_all = hero.exp_all + exp
	local conf = Config.getHeroConfig(hero.heroId)
    while true do
        local expMax = Config.levelExp[tostring(hero.level)].value2 * conf.exp
        if hero.level >= self.level * 3 then
            if hero.exp_now > expMax then
                local overExp = hero.exp_now - expMax + 1
                hero.exp_now = expMax - 1
                hero.exp_all = hero.exp_all - overExp
            end
            break
        end
        if hero.exp_now < expMax then
            break
        end
        hero.exp_now = hero.exp_now - expMax
        hero.level = hero.level + 1
        hero.point = hero.point + ConfigureStorage.heroRecuit[tostring(conf.rank)].capacity
    end
end

--[[
	伙伴升级
]]
function player:upgradeHeroes()
	for _,hero in pairs(self.heroes) do
		self:addExp(hero,)
	end
end

return player
