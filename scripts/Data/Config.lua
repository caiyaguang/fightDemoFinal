--[[ 
    配置文件缓存
]]
Config = {}

function Config:init( confDic )
    if not confDic then
    	return
    end
    Config.version = confDic.settingVersion
    Config.item = confDic.item
    Config.itemType = confDic.item_type
    Config.equip = confDic.equip
    Config.equipEffect = confDic.equipeffect -- 强化价格系数
    Config.skillConfig = confDic.skillConfig
    Config.skillLv = confDic.skilllv -- 参悟配置
    Config.heroConfig = confDic.heroConfig
    Config.heroRecuit = confDic.herorecuit -- 英雄突破，英雄变魂，口诀吃魂获得经验配置
    Config.energy = confDic.energy -- 精力体力上限
    Config.pageConfig = confDic.pageConfig -- 江湖配置
    Config.stageTypeConfig = confDic.stageTypeConfig -- 关卡挑战次数
    Config.stageConfig = confDic.stageConfig -- 关卡配置
    Config.stageNpc = confDic.stage_npc
    Config.freeRecruitCDTime = confDic.freeRecruitCDTime -- 免费刷新cd时间
    Config.freeRecruitTimes = confDic.freeRecruitTimes -- 每日免费刷新次数
    Config.recruitPay = confDic.recruitPay -- 付费刷新配置
    Config.recruitPayFirst = confDic.recruitPayFirst
    Config.goldShop = confDic.goldShop
    Config.vipShop = confDic.vipShop
    Config.cashShop = confDic.cashShop
    Config.levelExp = confDic.levelExp -- value1 掌门升级需要经验 value2 弟子升级经验系数 需要乘弟子初始经验值
    Config.rankScore = confDic.rankScore -- 论剑的一个配置，不知道是啥
    Config.exchange = confDic.exchange -- 论剑兑换奖励配置
    Config.records = confDic.records -- 论剑首次进入排名奖励
    Config.npcList = confDic.npc_list
    Config.thresholdConfig = confDic.thresholdConfig -- 阈值配置
    Config.formMax = confDic.formMax -- 阵容上限配置
    Config.formSevenMax = confDic.formSevenMax -- 七星阵开启配置
    Config.warship_exp = confDic.warship_exp
    Config.warship = confDic.warship
    Config.energy = confDic.energy
    Config.animation = confDic.animation
    Config.titleConfig = confDic.titleConfig  -- 称号配置
    Config.openFormSevenItem = confDic.openFormSevenItem -- 开启七星阵所需道具
    Config.combo = confDic.assist
    Config.formSevenAttr = confDic.formSevenAttr
    Config.storyClearStageLimit = confDic.storyClearStageLimit -- 清除关卡挑战次数
    Config.storyClearBatchCDTime = confDic.storyClearBatchCDTime -- 清除连闯cd
    Config.stageTalk = confDic.stageTalk -- 对话
    Config.upgrade_reward1 = confDic.upgrade_reward1 -- 日常里面的升级奖励配置
    Config.upgrade_reward2 = confDic.upgrade_reward2 -- 每次升级获得奖励配置
    Config.rollGuide = confDic.rollGuide      -- title滚动中的游戏指南信息
    Config.strengthRecoverTime = confDic.strengthRecoverTime -- 体力恢复时间配置
    Config.energyRecoverTime = confDic.energyRecoverTime -- 精力恢复时间配置
    Config.equipStagelMax = confDic.equipStagelMax   --装备最大阶
    Config.vipConfig = confDic.vipconfig
    Config.vipdesp = confDic.vipdesp
    Config.vipaward = confDic.vipaward
    Config.doubleExpCost = confDic.doubleExpCost -- 点拨双倍经验配置
    Config.dianbo = confDic.dianbo -- 点拨文字配置
    if confDic.extraItem and confDic.extraItem[1] then
        Config.extraItem = confDic.extraItem[1].item -- 点拨双倍使用道具
    end
    Config.GoldenBell = confDic.GoldenBell    --黄金钟
    Config.message = confDic.message
    Config.levelguide = confDic.levelguide -- 后续引导
    Config.rollingTable = confDic.rollingTable
    Config.Dreamgift = confDic.Dreamgift
    Config.document = confDic.document    -- 帮助
    Config.customerservice = confDic.customerservice -- 客服信息
    Config.Share = confDic.weibo
    Config.rebate = confDic.rebate
    Config.energyAddWithGold = confDic.energyAddWithGold
    Config.firstCashAward1 = confDic.firstCashAward1 -- 首充翻倍配置
    Config.firstCashAward2 = confDic.firstCashAward2 -- 首充送礼配置
    Config.levelOpen = confDic.levelopen      -- 船长等级开放功能配置 
    Config.pushConfig = confDic.pushConfig    -- 本地推送
    Config.sing = confDic.sing    -- 本地推送
    Config.loading = confDic.loading
    Config.playerlevelMax = confDic.playerlevelMax -- 船长最大等级
    Config.shareAward = confDic.shareAward        -- 分享获得奖励的配置

    Config.bossAttr = confDic.bossattr -- 恶魔谷boss数据
    Config.bossPayAndBuff = confDic.bossPayAndBuff
    Config.invitationAward = confDic.invitationAward --邀请码礼包数据

    ------------------------  联盟信息 begin --------------------------------------
    Config.leagueDefaultNotice = confDic.leagueDefaultNotice  -- 联盟默认公告
    Config.leagueLevelMax = confDic.leagueLevelMax    -- 联盟最高等级
    Config.leagueContributionPay = confDic.leagueContributionPay  -- 联盟点睛
    Config.leagueFingerGuessing = confDic.leagueFingerGuessing    -- 猜拳
    Config.leagueMessage = confDic.leagueMessage  -- 联盟消息
    Config.leaguelevel = confDic.leaguelevel  -- 联盟等级经验
    Config.leagueFingerGuessAward = confDic.leagueFingerGuessAward    -- 猜拳奖励
    Config.leagueDuty = confDic.leagueDuty    -- 联盟职位
    Config.leaguePermission = confDic.leaguePermission    -- 联盟权限
    Config.leagueFuncOpen = confDic.leagueFuncOpen    -- 联盟活动开启配置
    Config.leagueDescription = confDic.leagueDescription  -- 联盟内文案描述
    Config.createLeaguePay = confDic.createLeaguePay  -- 创建联盟所需金币
    Config.leagueDonate = confDic.leagueDonate            -- 联盟捐献限制
    Config.leagueLvup  = confDic.leagueLvup               -- 联盟升级
    Config.leagueFort = confDic.leagueFort
    Config.leagueSiege = confDic.leagueSiege
    Config.leagueDonate = confDic.leagueDonate
    Config.leagueShopLevel = confDic.leagueShopLevel
    Config.leagueDepot = confDic.leagueDepot
    Config.leagueShop = confDic.leagueShop
    Config.leagueShoplv = confDic.leagueShoplv
    ------------------------  联盟信息  end  --------------------------------------

    Config.vipIsOpen = confDic.vipIsOpen              -- 是否屏蔽vip相关显示
    Config.Gspot = confDic.Gspot                      -- 海军支部小关信息 
    Config.nsnpcgroup = confDic.nsnpcgroup              -- 海军支部boss信息 

    -- 寻宝
    Config.qjType = confDic.type 
    Config.qjDegree = confDic.degree

    Config.nsbossfree = confDic.nsbossfree               -- 海军支部boss攻打条件限制

    Config.battleDouble = confDic.battleDouble    -- 战斗双倍经验


    Config.shadowData = confDic.shadowData                -- 练影的配置信息
    Config.shadowLevelMax = confDic.shadowLevelMax
    Config.shadowUpdate = confDic.shadowUpdate
    Config.shadowRand = confDic.shadowRand
    Config.genuineQisMax = confDic.genuineQisMax          -- 能装上的影子数量

    Config.nowindUpdate = confDic.nowindUpdate            -- 无风带升级的数据
    Config.heronowind = confDic.heronowind                -- 每一个英雄对应无风带的属性提升值
    Config.nowindtime = confDic.nowindtime                -- 无风带关于时间的配置
    Config.noWindItemId = confDic.noWindItemId            -- 闭关需要消耗的物品
    Config.noWindReduceItemId = confDic.noWindReduceItemId 
    Config.monthCardShop = confDic.monthCardShop          -- 月卡
    Config.monthCardIsOpen = confDic.monthCardIsOpen
    if Config.monthCardShop then
        if Config.monthCardIsOpen == nil or Config.monthCardIsOpen == true then
            dailyData.daily.yueka = {sort = 0}
        end
    end
    Config.leagueBattleRecordPointer = confDic.leagueBattleRecordPointer
    Config.leagueCandyShopItem = confDic.leagueCandyShopItem
    Config.leagueLvup = confDic.leagueLvup
    Config.leagueSiege = confDic.leagueSiege
    Config.leagueFort = confDic.leagueFort

    Config.fightHelp = confDic.fightHelp -- 盟战进攻帮助文档
    Config.guardHelp = confDic.guardHelp -- 盟战防御帮助文档
    Config.enemyHelp = confDic.enemyHelp -- 盟战宿敌帮助文档
    Config.buildingHelp = confDic.buildingHelp -- 联盟建设帮助文档
    Config.shard = confDic.shard -- 碎片配置
    Config.skill_max_level = confDic.skill_max_level      -- 技能突破最大值
    Config.leagueBattleAllotSweetTimeInterval = confDic.leagueBattleAllotSweetTimeInterval

    Config.bagDelay = confDic.bagDelay -- 延时礼包
end

--[[
    获取英雄配置
]]
function Config.getHeroConfig(heroId)
    return clone(Config.heroConfig[heroId])
end

--[[
    获取装备配置
]]
function Config.getEquipConfig(equipId)
    return clone(Config.equip[equipId])
end

--[[
    获取技能配置
]]
function Config.getSkillConfig(skillId)
    return clone(Config.skillConfig[skillId])
end

--[[
    获取称号配置
]]
function Config.getTitleConfig(titleId)
    return clone(Config.titleConfig[titleId])
end

--[[
    获取影子配置
]]
function Config.getShadowConfig(shadowId)
    return clone(Config.shadowData[shadowId])
end

--[[
    英雄配置身价
    @params: heroId - hero config id
]]
function Config.getHeroPriceConfig(heroId)
    local conf = Config.getHeroConfig(heroId)
    if not conf or not conf.worth then
        return 0
    end
    return conf.worth
end

--[[
    装备身价计算
    @params: equipId - equip config id
    @params: level - equip level
]]
function Config.getEquipPrice(equipId, level)
    local price = 0
    local conf = Config.getEquipConfig(equipId)
    if not conf or not conf.worth or not conf.worthgrow then
        return price
    end
    return conf.worth + math.floor(conf.worthgrow * (level - 1))
end

--[[
    技能身价计算
    @params: skillId - skill config id
    @params: level - skill level
]]
function Config.getSkillPrice(skillId, level)
    local conf = Config.getSkillConfig(skillId)
    if not conf or not conf.worth or not conf.worthgrow then
        return price
    end
    return conf.worth + math.floor(conf.worthgrow * (level - 1))
end

--[[
    获得战舰属性
]]
function Config.getBattleShipAttr(type, level)
    return Config.warship[level + 1][type] or 0
end

--[[
    获取技能信息
    @params: skillId - skill config id
    @params: level - 技能等级
    @params: heroId - hero config id
    @return: table - skill
]]
function Config.getSkill(skillId, level, heroId)
    local conf = Config.getSkillConfig(skillId)
    local skill = {}
    skill.skillId = skillId
    skill.skillType = conf.type
    skill.skillName = conf.name
    skill.skillLevel = level
    skill.skillRank = conf.rank
    skill.attr = {}
    for k,v in pairs(conf.attr) do
        skill.attr[k] = v + conf.attrlv * (level - 1)
    end
    skill.per = conf.trigger
    if heroId and conf.link and conf.link[heroId] then
        skill.per = skill.per + conf.link[heroId]
    end
    if conf.range then
        skill.range = conf.range -- 1:近战 2:远程
    end
    return skill
end

return Config
