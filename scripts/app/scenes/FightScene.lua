local FightViewBg = import("..views.FightViewBg")
local FightController = import("..controller.FightController")
local BattleView = import("..views.BattleView")
local BattleField = import("..models.BattleField")
local Actor = import("..models.Actor")
local SkillModel = import("..models.SkillModel")

FightSceneOwner = FightSceneOwner or {}
ccb["FightSceneOwner"] = FightSceneOwner

local MainScene = class("MainScene", function()
    local node = display.newScene("MainScene")
    require("framework.api.EventProtocol").extend(node)
    return node
end)

function MainScene:ctor()
    local  proxy = CCBProxy:create()
    local  node  = CCBuilderReaderLoad("FightScene.ccbi",proxy,FightSceneOwner)
    local  layer = tolua.cast(node,"CCLayer")
    self:addChild(layer)

    self.contentLayer_ = tolua.cast(FightSceneOwner["contentLayer"],"CCLayer")       -- 盛放所有界面元素的容器

    self.FightBg_ = FightViewBg.new()           -- 战斗背景图片
    self.contentLayer_:addChild(self.FightBg_)
    local size = self.contentLayer_:getContentSize()
    self.FightBg_:setPosition(ccp( size.width / 2,size.height / 2 ))

    -- -- 获得每一个英雄的属性信息

    -- self.views_ = {}        -- 存放所有英雄卡片视图
    -- self.heros = {}
    -- -- -- 创建英雄对象，并存储在self.heros数组中
    -- local rulaiSkill = {
    --         sid = "skill001",
    --         name = "如来神掌",
    --         stype = 0,
    --         rangtype = 0,
    --         isshow = 0,
    --         haveeffect = 0,
    --         atktype = 0,
    --         damagetype = 0,
    --         damage = 1000000,
    --         cdtime = 2,
    --         totalmp = 0,
    --         caninterrupt = 0
    --         }
    -- local kuihuaSkill = {
    --         sid = "skill002",
    --         name = "葵花宝典",
    --         stype = 0,
    --         rangtype = 0,
    --         isshow = 0,
    --         haveeffect = 0,
    --         atktype = 1,
    --         damagetype = 0,
    --         damage = 6900000,
    --         cdtime = 5,
    --         totalmp = 0
    --         }
    -- local jianaiSkill = {
    --         sid = "skill002",
    --         name = "兼爱众生",
    --         stype = 1,
    --         rangtype = 0,
    --         isshow = 0,
    --         haveeffect = 0,
    --         atktype = 0,
    --         damagetype = 0,
    --         damage = 43,
    --         cdtime = 8,
    --         totalmp = 0
    --         }
    -- local qishangSkill = {
    --         sid = "skill002",
    --         name = "七伤拳",
    --         stype = 0,
    --         rangtype = 0,
    --         isshow = 0,
    --         haveeffect = 0,
    --         atktype = 0,
    --         damagetype = 0,
    --         damage = 99,
    --         cdtime = 12,
    --         totalmp = 0
    --         }
    -- local Skill5 = {
    --         sid = "skill001",
    --         name = "技能5",
    --         stype = 0,
    --         rangtype = 0,
    --         isshow = 0,
    --         haveeffect = 0,
    --         atktype = 0,
    --         damagetype = 0,
    --         damage = 120,
    --         cdtime = 3,
    --         totalmp = 0
    --         }
    -- local Skill6 = {
    --         sid = "skill001",
    --         name = "技能6",
    --         stype = 0,
    --         rangtype = 0,
    --         isshow = 0,
    --         haveeffect = 0,
    --         atktype = 0,
    --         damagetype = 0,
    --         damage = 120,
    --         cdtime = 7,
    --         totalmp = 0
    --         }
    -- local Skill7 = {
    --         sid = "skill001",
    --         name = "技能7",
    --         stype = 0,
    --         rangtype = 0,
    --         isshow = 0,
    --         haveeffect = 0,
    --         atktype = 0,
    --         damagetype = 0,
    --         damage = 120,
    --         cdtime = 9,
    --         totalmp = 0
    --         }
    -- local Skill8 = {
    --         sid = "skill001",
    --         name = "技能8",
    --         stype = 0,
    --         rangtype = 0,
    --         isshow = 0,
    --         haveeffect = 0,
    --         atktype = 2,
    --         damagetype = 0,
    --         damage = 1,
    --         cdtime = 1,
    --         totalmp = 0
    --         }

    -- local gouheSkill = {
    --         sid = "skill003",
    --         name = "沟壑",
    --         stype = 0,
    --         rangtype = 0,
    --         isshow = 0,
    --         haveeffect = 0,
    --         atktype = 0,
    --         damagetype = 8,
    --         damage = 55,
    --         cdtime = 8,
    --         totalmp = 79,
    --         caninterrupt = 0
    --         }
    -- local zongshengSkill = {
    --         sid = "skill004",
    --         name = "众生平等",
    --         stype = 0,
    --         rangtype = 0,
    --         isshow = 0,
    --         haveeffect = 0,
    --         atktype = 0,
    --         damagetype = 8,
    --         damage = 78,
    --         cdtime = 9,
    --         totalmp = 85,
    --         caninterrupt = 0
    --         }
    -- local ruyingSkill = {
    --         sid = "skill005",
    --         name = "如影随行",
    --         stype = 0,
    --         rangtype = 0,
    --         isshow = 0,
    --         haveeffect = 0,
    --         atktype = 0,
    --         damagetype = 8,
    --         damage = 34,
    --         cdtime = 4,
    --         totalmp = 66,
    --         caninterrupt = 0
    --         }


    -- local player = Actor.new({
    --     id = "player",
    --     sid = "player1",
    --     nickname = "dualface1",
    --     level = 1,
    --     side = 0,
    --     hp = 4000,
    --     pos = 1,
    --     image = "hero_000403_bust_1.png",
    --     skills = {commonSkill = SkillModel.new(rulaiSkill),giftSkill = SkillModel.new(gouheSkill)},
    --     skill = {
    --         skill = {
    --             sid = 1,
    --             name = "万马千军",
    --             stype = 1,
    --             atk = 180
    --         }

    --     }
    -- })
    -- table.insert(self.heros,player)

    -- local player = Actor.new({
    --     id = "player",
    --     sid = "player2",
    --     nickname = "dualface2",
    --     level = 1,
    --     side = 0,
    --     hp = 4000,
    --     pos = 2,
    --     image = "hero_000404_bust_1.png",
    --     skills = {commonSkill = SkillModel.new(kuihuaSkill),giftSkill = SkillModel.new(gouheSkill)},
    --     skill = {
    --         skill = {
    --             name = "万马千军",
    --             stype = 0,
    --             atk = 110
    --         }

    --     }
    -- })
    -- table.insert(self.heros,player)


    -- local player = Actor.new({
    --     id = "player",
    --     sid = "player3",
    --     nickname = "fuck1",
    --     level = 1,
    --     side = 0,
    --     hp = 4000,
    --     pos = 3,
    --     image = "hero_000405_bust_1.png",
    --     skills = {commonSkill = SkillModel.new(jianaiSkill),giftSkill = SkillModel.new(ruyingSkill)},
    --     skill = {
    --         skill = {
    --             name = "万马千军",
    --             stype = 0,
    --             atk = 150
    --         }

    --     }
    -- })
    -- table.insert(self.heros,player)

    -- local player = Actor.new({
    --     id = "player",
    --     sid = "player4",
    --     nickname = "fuck2",
    --     level = 1,
    --     side = 0,
    --     hp = 4000,
    --     pos = 4,
    --     image = "hero_000406_bust_1.png",
    --     skills = {commonSkill = SkillModel.new(qishangSkill),giftSkill = SkillModel.new(zongshengSkill)},
    --     skill = {
    --         skill = {
    --             name = "万马千军",
    --             stype = 0,
    --             atk = 130
    --         }

    --     }
    -- })

    -- table.insert(self.heros,player)

    -- -- 敌方配置
    --     local player = Actor.new({
    --     id = "player",
    --     sid = "player5",
    --     nickname = "dualface1",
    --     level = 1,
    --     side = 1,
    --     hp = 4000,
    --     pos = 1,
    --     image = "hero_000403_bust_1.png",
    --     skills = {commonSkill = SkillModel.new(Skill5),giftSkill = SkillModel.new(gouheSkill)},
    --     skill = {
    --         skill = {
    --             sid = 1,
    --             name = "万马千军",
    --             stype = 1,
    --             atk = 180
    --         }

    --     }
    -- })
    -- table.insert(self.heros,player)

    -- local player = Actor.new({
    --     id = "player",
    --     sid = "player6",
    --     nickname = "dualface2",
    --     level = 1,
    --     side = 1,
    --     hp = 4000,
    --     pos = 2,
    --     image = "hero_000404_bust_1.png",
    --     skills = {commonSkill = SkillModel.new(Skill6),giftSkill = SkillModel.new(gouheSkill)},
    --     skill = {
    --         skill = {
    --             name = "万马千军",
    --             stype = 0,
    --             atk = 110
    --         }

    --     }
    -- })
    -- table.insert(self.heros,player)


    -- local player = Actor.new({
    --     id = "player",
    --     sid = "player7",
    --     nickname = "fuck1",
    --     level = 1,
    --     side = 1,
    --     hp = 4000,
    --     pos = 3,
    --     image = "hero_000405_bust_1.png",
    --     skills = {commonSkill = SkillModel.new(Skill7),giftSkill = SkillModel.new(ruyingSkill)},
    --     skill = {
    --         skill = {
    --             name = "万马千军",
    --             stype = 0,
    --             atk = 150
    --         }

    --     }
    -- })
    -- table.insert(self.heros,player)

    -- local player = Actor.new({
    --     id = "player",
    --     sid = "player8",
    --     nickname = "fuck2",
    --     level = 1,
    --     side = 1,
    --     hp = 4000,
    --     pos = 4,
    --     image = "hero_000406_bust_1.png",
    --     skills = {commonSkill = SkillModel.new(Skill8),giftSkill = SkillModel.new(zongshengSkill)},
    --     skill = {
    --         skill = {
    --             name = "万马千军",
    --             stype = 0,
    --             atk = 130
    --         }

    --     }
    -- })

    -- table.insert(self.heros,player)

    -- -- 加入战斗动画层
    -- self.battleFieldObj_ = BattleField.new({ players = self.heros})
    -- -- 根据战场模型对象创建战场视图对象
    -- self.battleView_ = BattleView.new(self.battleFieldObj_)

    -- self:addChild(self.battleView_)

    -- 创建控制器层
    self.controllerView_ = FightController.new()
    self:addChild(self.controllerView_)
end

function MainScene:onEnter()
    if device.platform == "android" then
        -- avoid unmeant back
        self:performWithDelay(function()
            -- keypad layer, for android
            local layer = display.newLayer()
            layer:addKeypadEventListener(function(event)
                if event == "back" then app.exit() end
            end)
            self:addChild(layer)

            layer:setKeypadEnabled(true)
        end, 0.5)
    end
end

function MainScene:onExit()
end

return MainScene
