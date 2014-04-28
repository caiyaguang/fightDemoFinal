--[[控制器层
处理用户的输入
与modle层交换更新数据
控制视图的显示，比如卡牌的进入
接受用户状态改变的通知，并调用页面的更新方法，更新页面
]]

local BattleField = import("..models.BattleField")
local BattleView = import("..views.BattleView")
local Actor = import("..models.Actor")
local SkillModel = import("..models.SkillModel")

local FightController = class("FightController", function (  )
    local node = display.newLayer()
    require("framework.api.EventProtocol").extend(node)
    return node
end)

FightController.ACTION_FINISHED_EVENT = "ACTION_FINISHED_EVENT"            -- 动作完成后

function FightController:ctor(  )
    -- 创建战场模型
    self.battleModel_ = BattleField.new()

    -- 监听战场消息
    local cls = self.battleModel_.class
    cc.EventProxy.new(self.battleModel_, self)
        :addEventListener(cls.BATTLE_FIELD_INIT_ACTION_FINISHED_EVENT, self.battleInitFinished_, self)
        :addEventListener(cls.BATTLE_FIELD_ENTER_FIELD_FINISHED_EVENT, self.allHeroEnterFinished_, self)

    -- 创建战场视图
    self.battleView_ = BattleView.new(self.battleModel_)

    self:addChild(self.battleView_)

    -- 保存玩家英雄
    self.playerHeros_ = {}

    -- 保存电脑英雄
    self.enemyHeros_ = {}

    -- 入场动作执行完毕的英雄个数
    self.enterFinishNum_ = 0

    -- 战斗进入第一回合
    self.fightRound_ = 1
    self:enterNextRound( self.fightRound_ )
end

-- 对战场消息的回调方法
function FightController:battleInitFinished_( event )
    -- 初始化完毕
    self.battleModel_:enterBattleField(self.fightRound_)
    -- 更改每个英雄状态
    for k,hero in pairs(self.playerHeros_) do
        hero:enterWalking()
    end
    for k,enemy in pairs(self.enemyHeros_) do
        enemy:enterWalking()
    end
end

-- 所有英雄入场完毕
function FightController:allHeroEnterFinished_( event )
    local hero = event.hero
    hero:enterIdle()
    self.enterFinishNum_ = self.enterFinishNum_ + 1
    if self.enterFinishNum_ >= (table.nums(self.playerHeros_) + table.nums(self.enemyHeros_)) then
        self.enterFinishNum_ = 0
        -- 所有英雄入场完毕
        -- 向每一个英雄发信息，告知可以攻击
        for k,v in pairs(self.playerHeros_) do
            v:canAtk()
        end
        for k,v in pairs(self.enemyHeros_) do
            v:canAtk()
        end
    end
end

--[[
    供自身调用的方法    
]]

function FightController:getOneAtkTargets( atker,skill )
    local targets = {}
    if atker:getSide() == 0 then
        for k,v in pairs(self.enemyHeros_) do
            if not v:isDead() then
                table.insert(targets,v)
            end
        end
    else
        for k,v in pairs(self.playerHeros_) do
            if not v:isDead() then
                table.insert(targets,v)
            end
        end
    end
    return targets
end

-- 开始新一轮战斗
-- 参数：战斗轮数
function FightController:enterNextRound( round )
    -- 读取战场信息，新建英雄对象
    local rulaiSkill = {
            sid = "skill001",
            name = "如来神掌",
            stype = 0,
            rangtype = 0,
            isshow = 0,
            haveeffect = 0,
            atktype = 0,
            damagetype = 0,
            damage = 100,
            cdtime = 2,
            totalmp = 0,
            skilltype = "commonskill",
            caninterrupt = 0
            }
    local kuihuaSkill = {
            sid = "skill002",
            name = "葵花宝典",
            stype = 0,
            rangtype = 0,
            isshow = 0,
            haveeffect = 0,
            atktype = 1,
            damagetype = 0,
            damage = 69,
            cdtime = 5,
            skilltype = "giftskill",
            totalmp = 100
            }
    local jianaiSkill = {
            sid = "skill002",
            name = "兼爱众生",
            stype = 1,
            rangtype = 0,
            isshow = 0,
            haveeffect = 0,
            atktype = 0,
            damagetype = 0,
            damage = 43,
            cdtime = 8,
            skilltype = "commonskill",
            totalmp = 0
            }
    local qishangSkill = {
            sid = "skill002",
            name = "七伤拳",
            stype = 0,
            rangtype = 0,
            isshow = 0,
            haveeffect = 0,
            atktype = 0,
            damagetype = 0,
            damage = 99,
            cdtime = 12,
            skilltype = "giftskill",
            totalmp = 100
            }
    local player1 = Actor.new({
        id = "player1",
        sid = "player1",
        nickname = "player",
        level = 1,
        side = 0,     -- 玩家
        hp = 4000,
        pos = 1,
        image = "hero_000403_bust_1.png",
        skills = {commonSkill = SkillModel.new(rulaiSkill),giftSkill = SkillModel.new(kuihuaSkill)},
        skill = {
            skill = {
                sid = 1,
                name = "万马千军",
                stype = 1,
                atk = 180
            }

        }
    })
    self.playerHeros_[player1:getSid()] = player1
    local player2 = Actor.new({
        id = "player2",
        sid = "player2",
        nickname = "computer",
        level = 1,
        side = 1,       -- 敌人
        hp = 4000,
        pos = 1,
        image = "hero_000404_bust_1.png",
        skills = {commonSkill = SkillModel.new(jianaiSkill),giftSkill = SkillModel.new(qishangSkill)},
        skill = {
            skill = {
                name = "万马千军",
                stype = 0,
                atk = 110
            }

        }
    })
    self.enemyHeros_[player2:getSid()] = player2

    -- 分别建立对玩家和电脑人模型的监听
    for k,v in pairs(self.playerHeros_) do
        local player = v
        local cls = player.class
        cc.EventProxy.new(player, self)
            :addEventListener(cls.PLAYER_MODEL_LAUNCH_SKILL_ATK, self.playerLaunchSkillAtk_, self)
            :addEventListener(cls.ADD_SKILL_EFFECT_EVENT, self.addSkillEffect_, self)
        player:setCanAtkTargets(self:getOneAtkTargets(player,player:getSkills().giftskill))
    end
    for k,v in pairs(self.enemyHeros_) do
        local enemy = v
        local cls = enemy.class
        cc.EventProxy.new(enemy, self)
            :addEventListener(cls.PLAYER_MODEL_LAUNCH_SKILL_ATK, self.playerLaunchSkillAtk_, self)
            :addEventListener(cls.ADD_SKILL_EFFECT_EVENT, self.addSkillEffect_, self)
        enemy:setCanAtkTargets(self:getOneAtkTargets(enemy,enemy:getSkills().giftskill))
    end

    -- 告诉战场模型可以根据英雄模型建立英雄视图等
    self.battleModel_:initBattleViewAndHeroView( self.playerHeros_,self.enemyHeros_,self.fightRound_ )
end

-- -- 接收来自战场模型的消息并处理

function FightController:playerLaunchSkillAtk_( event )
    -- 得到攻击者和技能

    local atker = event.atker
    local skill = event.skill

    --  如果改英雄正在进行攻击，开始调用战场模型的取消攻击方法
    -- 返回turu或者false

    -- if self.battleModel_:isTargetAtking(atker,skill) then
    --     self.battleModel_:cancelTargetsAtkAction({atker})
    -- end
    -- 判断是否能进行攻击
    if atker:isCanLaunchSkillAtk_(skill) then
        -- 计算出攻击对象，并保存到攻击对象的数组中
        local targets = self:getOneAtkTargets( atker,skill )
        -- 如果可以打断对方攻击，先打断对方攻击(需要移动到受到伤害的时候进行取消)
        -- for i=1,#targets do
        --     local target = targets[i]
        --     if target:getCurrentAtkSkill() then
        --         if self.battleModel_:isCanInterrupAtk(skill,target:getCurrentAtkSkill()) then
        --             self.battleModel_:cancelTargetsAtkAction({target})
        --         end
        --     end
        -- end
        -- 调用战场模型中的发动技能攻击的方法
        -- 如果没有目标则不作操作
        if #targets > 0 then
            --[[
                如果需要播放技能介绍，就调用战场视图的播放特效的方法
            ]]
            atker:beginAtkAction(targets,skill)
            -- self.battleModel_:doPlayerLaunchSkillAtk( atker, targets, skill)
        end
    end
end

function FightController:addSkillEffect_( event )
    local atker = event.atker
    local targets = event.targets
    local skill = event.skill
    -- 通知战场播技能特效
    self.battleModel_:addSkillEffect(atker,targets,skill)
end

-- -- 当英雄的动作做完以后的回调   如攻击、受伤害
-- function FightController:onHeroViewActionFinish_( event )
--     local hero = event.hero
--     local actionType = event.actionType
--     -- 调用战场模型的方法，进入下一轮攻击
--     if actionType == "atk" then
--         -- self:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(5),CCCallFunc:create(function (  )
--         --     self.battleModel_:enterNextAtk_(atker)
--         -- end)))
--     elseif actionType == "underatk" then
--         self.battleModel_:heroBeginSelfCommonSkillAtk(hero)
--     end
-- end

-- function FightController:isCanLaunchSkillAtk_( atker,skill )
--     return true
-- end

-- -- 英雄死亡后的回调
-- function FightController:onHeroDieEvent_( event )
--     local hero = event.hero
--     -- 首先把死亡的英雄移除
--     self.battleModel_:removeDieHeroSprite(hero)
--     -- 判断是否可以进入下一轮
--     if self.battleModel_:isRoundOver() then
--         self.battleModel_:leaveAtk()
--     end
-- end
-- --
-- function FightController:getViewBySideAndPos( side,pos )
--     for i=1,#self.heros_ do
--         local hero = self.heros_[i]
--         if hero:getSide() == side and hero:getPos() == pos then
--             return hero
--         end
--     end
-- end
-- -- 进入战场
-- function FightController:entFightScene(  )
--     local i = 1
--     for k,v in pairs(self.heros) do
        
--         local nickname = v:getNickName()
--         local player = self.views_[nickname]
--         local array = CCArray:create()
--         local move
--         if v:getSide() ~= 1 then
--             move = CCMoveTo:create(1,ccp(player:getPositionX(),display.cy + 150))
--         else
--             move = CCMoveTo:create(1,ccp(player:getPositionX(),display.cy - 150))
--         end
        
--         local delay = CCDelayTime:create(1)
--         local callBack = CCCallFunc:create(function(  )
--             -- if v:getSide() == 1 and v:getPos() == 1 then
--             --     -- self:enterNextAtk()
--             -- end

--             self:playerLaunchSkillAtk_({atker = self.battleModel_:getStartAtker(),skill = self.battleModel_:getStartAtker():getSkills().commonSkill})
--         end)
--         array:addObject(move)
--         array:addObject(delay)
        
--         array:addObject(callBack)
--         local seq = CCSequence:create(array)
--         player:runAction(seq)
--         i = i + 1
--     end
-- end

-- -- 进入下一轮的攻击
-- function FightController:enterNextAtk(  )
--     if self.deadCount == 2 then
--         self.stateLabel_ = ui.newTTFLabel({
--             text = "进入下一个回合",
--             size = 22,
--             color = display.COLOR_RED,
--         })
--         :pos(self:getContentSize().width / 2, self:getContentSize().height / 2)
--         :addTo(self)
--         return
--     end 
--     local tSide = self.crtAtkSide_ == 1 and 0 or 1

--     if self.crtAtkSide_ == 0 then
--         local atkPos = self.atkIndexS0_
--         local defPos = self.atkIndexS0_
--         local atker = self:getViewBySideAndPos(self.crtAtkSide_ ,atkPos)
--         local defer = self:getViewBySideAndPos(tSide,atkPos)
--         if self.atkIndexS0_ == 2 then
--             self.atkIndexS0_ = 1
--         else
--             self.atkIndexS0_ = self.atkIndexS0_ + 1
--         end
--         self.crtAtkSide_ = self.crtAtkSide_ == 0 and 1 or 0
--         if atker:isCanAtk() and not defer:isDead() then
--             atker:skillAtk(defer)
--         else
--             -- self:enterNextAtk()
--         end
--     else
--         local atkPos = self.atkIndexS1_
--         local defPos = self.atkIndexS1_
--         local atker = self:getViewBySideAndPos(self.crtAtkSide_ ,atkPos)
--         local defer = self:getViewBySideAndPos(tSide,atkPos)
--         if self.atkIndexS1_ == 2 then
--             self.atkIndexS1_ = 1
--         else
--             self.atkIndexS1_ = self.atkIndexS1_ + 1
--         end
--         self.crtAtkSide_ = self.crtAtkSide_ == 0 and 1 or 0
--         if atker:isCanAtk() and not defer:isDead() then
--             atker:skillAtk(defer)
--         else
--             -- self:enterNextAtk()
--         end
--     end
-- end

-- -- 接受用户输入的处理函数
-- function FightController:skillBtnTaped( tag,sender )
    
-- end

-- -- 
-- function FightController:continueSkillAtk( event )
--     self.battleModel_:beginEnterDamage(event.atker,event.targets,event.skill)
-- end

-- -- 战斗宏观动画做完后的回调
-- function FightController:battleActionFinished( event )
--     if event.actType == "enterbattle" then
--         self.battleActFinishedCount_ = self.battleActFinishedCount_ + 1
--         if self.battleActFinishedCount_ == 4 then
--             self:enterNextAtk()
--             self.battleActFinishedCount_ = 0
--         else
            
--         end
--     elseif event.actType == "playskill" then
--         self.battleModel_:continueAtk()
--     end
    
-- end

-- -- 接受用户动作结束的通知，并调用model的处理方法  如状态改变
-- function FightController:heroActionFinished( event )
--     --[[ 
--         event是一个table，基础包含name和target字段
--         name是事件名称
--         target是分发事件的对象
--         event.target:removeSelf()
--     ]]
--     if event.actType == "atking" then
--         -- 攻击动作完成
--         local atker = event.atker
--         atker:getHeroInfo():enterNextState()
--     elseif event.actType == "kill" then
--         -- 死亡动作完成
--         self.deadCount = self.deadCount + 1
--         local target = event.target
--         local actor = target:getHeroInfo()
--         actor:enterNextState()
--     elseif event.actType == "underatk" then
--         local delayTime = CCDelayTime:create(1)
--         local callBack = CCCallFunc:create(function (  )
--             self:enterNextAtk()
--         end)
--         local target = event.target
--         local actor = target:getHeroInfo()
--         actor:enterNextState()
--         self:runAction(CCSequence:createWithTwoActions(delayTime,callBack))
--     end
-- end
return FightController
