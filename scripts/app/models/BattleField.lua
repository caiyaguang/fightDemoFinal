--[[保存战场的数据和状态信息，并在状态发生改变的时候，向视图发送通知
战场视图的基类
包含一些可以更新数据的接口  和分发事件的接口
包含一个状态机
数据包括： 战场的状态 英雄的模型数据

内部有一个定时器，用于检测当cd时间结束了，更改状态   
当状态发生改变了，向控制器发送通知，控制器根据状态，调用view的更新接口
]]

local BattleField = class("BattleField", cc.mvc.ModelBase)

-- 常量
-- BattleField.ENTER_BATTLE_EVENT        = "ENTER_BATTLE_EVENT"
-- BattleField.LEAVE_BATTLE_EVENT     = "LEAVE_BATTLE_EVENT"
-- BattleField.ENTER_ATK_EVENT     = "ENTER_ATK_EVENT"
-- BattleField.LEAVE_ATK_EVENT     = "LEAVE_ATK_EVENT"
-- BattleField.FIGHT_END_EVENT     = "FIGHT_END_EVENT"
-- BattleField.PLAY_SKILL_ANI_EVENT = "PLAY_SKILL_ANI_EVENT"
-- BattleField.ENTER_SKILL_ATK_EVENT = "ENTER_SKILL_ATK_EVENT"

-- BattleField.BATTLE_FIELD_LAUNCH_SKILL_ATK = "BATTLE_FIELD_LAUNCH_SKILL_ATK"     -- 英雄发动了一个技能攻击

-- -- 英雄视图做完动作的事件
-- BattleField.HEROVIEW_ACTION_FINISH_F_BATTLEFIELD_EVENT = "HEROVIEW_ACTION_FINISH_F_BATTLEFIELD_EVENT"

-- -- 显示一个攻击的技能名字
-- BattleField.DISPLAY_ATK_SKILL_NAME_EVENT = "DISPLAY_ATK_SKILL_NAME_EVENT"

BattleField.BATTLE_FIELD_ADD_SKILL_EFFECT = "BATTLE_FIELD_ADD_SKILL_EFFECT"

-- BattleField.BATTLE_FIELD_HERO_DIE_EVENT = "BATTLE_FIELD_HERO_DIE_EVENT"

-- BattleField.BATTLE_FIELD_REMOVE_DIE_HERO = "BATTLE_FIELD_REMOVE_DIE_HERO"

-- 初始化事件

--  对战场模型视图的事件
BattleField.BATTLE_FIELD_INIT_EVENT = "BATTLE_FIELD_INIT_EVENT"                   -- 战场开始初始化
BattleField.BATTLE_FIELD_ENTER_FIELD_EVENT = "BATTLE_FIELD_ENTER_FIELD_EVENT"     -- 开始入场事件

-- 对控制器视图的事件
BattleField.BATTLE_FIELD_INIT_ACTION_FINISHED_EVENT = "BATTLE_FIELD_INIT_ACTION_FINISHED_EVENT"  -- 初始化完毕
BattleField.BATTLE_FIELD_ENTER_FIELD_FINISHED_EVENT = "BATTLE_FIELD_ENTER_FIELD_FINISHED_EVENT"  -- 所有英雄入场完毕
-- 定义属性
BattleField.schema = clone(cc.mvc.ModelBase.schema)
BattleField.schema["players"] = {"table",{}}       -- 英雄的模型数组
BattleField.schema["enemys"] = {"table",{}}

function BattleField:ctor(properties, events, callbacks)
    BattleField.super.ctor(self, properties)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
    -- 因为角色存在不同状态，所以这里为 BattleField 绑定了状态机组件
    self:addComponent("components.behavior.StateMachine")
    -- 由于状态机仅供内部使用，所以不应该调用组件的 exportMethods() 方法，改为用内部属性保存状态机组件对象
    self.fsm__ = self:getComponent("components.behavior.StateMachine")
    -- self.playerCount = 0
    -- self.enemyCount = 0
    -- -- 监听来着于战场中所有人物模型的事件
    -- for i=1,#self.players_ do
    --     local player = self.players_[i]
    --     local cls = player.class
    --     cc.EventProxy.new(player,self)
    --         :addEventListener(cls.PLAYER_MODEL_LAUNCH_SKILL_ATK, self.playerLaunchSkillAtk_, self)      -- 监听来着英雄模型的发动技能攻击的信息
    --         :addEventListener(cls.TODO_SKILL_EFFECT_EVENT, self.playSkillAni_, self)
    --         :addEventListener(cls.BEGIN_SKILL_ATK_EVENT, self.enterSkillAtk_, self)
    --         :addEventListener(cls.HEROVIEW_ACTION_FINISH_EVENT, self.onHeroViewActFinish_, self)
    --         :addEventListener(cls.ADD_SKILL_EFFECT_EVENT, self.onAddSkillEffect_, self)
    --         :addEventListener(cls.HERO_DIE_EVENT, self.onHeroDie_, self)
    --     if player:getSide() == 0 then
    --         self.enemyCount = self.enemyCount + 1
    --     else
    --         self.playerCount = self.playerCount + 1
    --     end
    -- end
    

    -- 设定状态机的默认事件
    local defaultEvents = {
        -- 初始化后，角色处于 idle 状态 (闲置)
        {name = "start",  from = "none",    to = "idle" },
        -- 进入战场
        {name = "init",   from = "idle",    to = "inits"},

        {name = "enterfield",   from = "idle",    to = "enterfields"},

        {name = "leavefield",   from = "idle",    to = "leavefields"},

        {name = "enidle",   from = "*",    to = "idle"}
    }
    -- 如果继承类提供了其他事件，则合并
    table.insertTo(defaultEvents, totable(events))

    -- 设定状态机的默认回调
    local defaultCallbacks = {
        onchangestate = handler(self, self.onChangeState_),
        onafterstart = handler(self, self.onAfterStart_),
        onafterinit = handler(self, self.onAfterInit_),
        onafterenterfield = handler(self, self.onAfterEnterField_),
        onafterleavefield = handler(self, self.onAfterLeaveField_),
        onafterenidle = handler(self, self.onAfterIdle_),

        onenteridle = handler(self, self.onEnterIdle_),
        onenterinits = handler(self, self.onEnterInits_),
        onenterenterfields = handler(self, self.onEnterEnterFields_),     -- 进入技能攻击状态
        onenterleavefields = handler(self, self.onEnterLeaveFields_)
    }
    -- 如果继承类提供了其他回调，则合并
    table.merge(defaultCallbacks, totable(callbacks))

    self.fsm__:setupState({
        events = defaultEvents,
        callbacks = defaultCallbacks
    })

    -- 记录进场动作执行完毕的英雄个数
    self.enterFinishNum_ = 0

    -- 初始化血量
    self.round_ = 0       ---   回合数
    self.totalhp_ = self.hp_
    self.fsm__:doEvent("start") -- 启动状态机
end

--[[
        供控制器调用的方法
]]

-- 初始化英雄视图和战场视图
-- 参数：玩家英雄数组 电脑人数组 战斗回合数  
function BattleField:initBattleViewAndHeroView( players,enemys,round )
    self:setPlayers( players )
    self:setEnemys( enemys )
    self.round_ = round
    self.fsm__:doEvent("init")
end

-- 进场动作
function BattleField:enterBattleField( round )
    self.round_ = round
    self.fsm__:doEvent("enterfield")
end

--[[
    供战场视图调用的方法
]]
function BattleField:initActionFinished(  )
    self.fsm__:doEvent("enidle")
    self:dispatchEvent({name = BattleField.BATTLE_FIELD_INIT_ACTION_FINISHED_EVENT})
end

function BattleField:enterBattleFieldFinished( hero )
    -- self.enterFinishNum_ = self.enterFinishNum_ + 1
    -- if self.enterFinishNum_ >= (#self.players_ + #self.enemys_) then
    --     self.enterFinishNum_ = 0
        -- 告诉控制器，所有英雄进场完毕
        self:dispatchEvent({name = BattleField.BATTLE_FIELD_ENTER_FIELD_FINISHED_EVENT, hero = hero})
    -- end
end

--[[
    向战场视图发送状态变换消息的方法
]]

function BattleField:onChangeState_( event )
    
end

function BattleField:onAfterStart_( event )
    
end

function BattleField:onAfterInit_( event )

end

function BattleField:onAfterEnterField_( event )
    
end

function BattleField:onAfterLeaveField_( event )
    
end

function BattleField:onAfterIdle_( event )
    
end

function BattleField:onEnterIdle_( event )
    
end

function BattleField:onEnterInits_( event )
    -- 进入初始化状态
    self:dispatchEvent({name = BattleField.BATTLE_FIELD_INIT_EVENT, player = self:getPlayers(), enemy = self:getEnemys(), round = self.round_})
end

function BattleField:onEnterEnterFields_( event )
    self:dispatchEvent({name = BattleField.BATTLE_FIELD_ENTER_FIELD_EVENT, player = self:getPlayers(), enemy = self:getEnemys(), round = self.round_})
end

function BattleField:onEnterLeaveFields_( event )
    
end

--[[
    get 和 set 方法
]]
function BattleField:setPlayers( value )
    self.players_ = value
end

function BattleField:getPlayers(  )
    return self.players_
end

function BattleField:setEnemys( value )
    self.enemys_ = value
end

function BattleField:getEnemys(  )
    return self.enemys_
end








function BattleField:getStartAtker(  )
    for i=1,#self.players_ do
        local player = self.players_[i]
        if player:getSide() == 1 and player:getPos() == 1 then
            return player
        end
    end
end

-- 计算得出一次攻击的目标对象
function BattleField:getOneAtkTargets( atker,skill )
    local targets = {}
    local side = atker:getSide() == 0 and 1 or 0
    if skill:getAtkType() == 0 then
        for i=1,#self.players_ do
            local player = self.players_[i]
            if player:getSide() == side and not player:isDead() and player:getPos() == atker:getPos() then
                table.insert(targets,player)
            end
        end
        if #targets == 0 then
            for pos=1,4 do
                if atker:getPos() ~= pos then
                    for i=1,#self.players_ do
                        local player = self.players_[i]
                        if player:getSide() == side and not player:isDead() and player:getPos() == pos then
                            table.insert(targets,player)
                        end
                        if #targets > 0 then
                            return targets
                        end
                    end
                end
            end
        end
    else 
        for i=1,#self.players_ do
            local player = self.players_[i]
            if player:getSide() == side and not player:isDead() then
                table.insert(targets,player)
            end
        end
    end
    return targets
end

-- 当英雄离场完毕
function BattleField:tellBattleFieldLvFightEnd(  )
    self.lvedCount_ = self.lvedCount_ + 1 
    if self.lvedCount_ == (self.enemyCount + self.playerCount) then
        self.lvedCount_ = 0
        -- 英雄离场完毕，开始下一轮
    end
end

-- 移除死亡的英雄
function BattleField:removeDieHeroSprite( hero )

    self:dispatchEvent({name = BattleField.BATTLE_FIELD_REMOVE_DIE_HERO, hero = hero})
end

function BattleField:isRoundOver(  )
    return self.enemyCount == 0 or self.playerCount == 0
end

-- 判断那边赢
function BattleField:whichSideWin( )
    if self.enemyCount == 0 then
        return 1      -- 玩家赢
    end
    return 0
end

-- 英雄死亡的回调
function BattleField:onHeroDie_( event )
    local hero = event.hero
    if hero:getSide() == 0 then
        self.enemyCount = self.enemyCount - 1
    else
        self.playerCount = self.playerCount - 1
    end
    self:dispatchEvent({name = BattleField.BATTLE_FIELD_HERO_DIE_EVENT, hero = hero})
end

-- 当一个英雄攻击完毕，进入下一轮的攻击
function BattleField:enterNextAtk_( atker )
    -- atker 为上一次攻击者
    local nextAtker = nil
    local side = atker:getSide() == 0 and 1 or 0
    local pos = atker:getPos() == 1 and 2 or 1
    for i=1,#self.players_ do
        local player = self.players_[i]
        if player:getSide() == side and player:getPos() == pos then
            nextAtker = player
            break
        end
    end
    self:dispatchEvent({name = BattleField.BATTLE_FIELD_LAUNCH_SKILL_ATK, atker = nextAtker, skill = nextAtker:getSkills().commonSkill})
end

-- 对用户发动的技能进行是否允许的判断
function BattleField:isPlayerCanLaunchSkill( atker,skill )
    -- 是在该用户攻击回合
    return true
end

-- 判断一次攻击是否可以打断对方攻击
function BattleField:isCanInterrupAtk( atkskill,targetskill )
    if atkskill:getCanBreak() == 1 and targetskill:getCanInterrupt() == 1 then
        return true
    end
    return false
end

-- 判断英雄是否正在攻击
function BattleField:isTargetAtking( hero,skill )
    return hero:isAtking(skill)
end

-- 取消目标数组的攻击动作
function BattleField:cancelTargetsAtkAction( targets )
    local flag = true
    for i=1,#targets do
        local target = targets[i]
        -- 调用target的取消进攻的方法
        if not target:cancelAtkAction() then
            flag = false
        end
    end
    return flag
end

-- 接收到英雄模型消息后的回调

function BattleField:addSkillEffect( atker,targets,skill )
    self:dispatchEvent({name = BattleField.BATTLE_FIELD_ADD_SKILL_EFFECT, atker = atker,targets = targets,skill = skill})
end

-- 用户发动技能攻击消息的回调
function BattleField:playerLaunchSkillAtk_( event )
    -- 得到发动攻击的英雄和技能
    local skill = event.skill
    local atker = event.atker
    -- 判断是否可以允许用户发动这次攻击
    self:dispatchEvent({name = BattleField.BATTLE_FIELD_LAUNCH_SKILL_ATK, atker = atker, skill = skill})
end


function BattleField:onHeroViewActFinish_( event )
    local actionType = event.actionType
    local hero = event.atker
    self:dispatchEvent({ name = BattleField.HEROVIEW_ACTION_FINISH_F_BATTLEFIELD_EVENT, actionType = actionType, hero = hero })
end
-- 供控制器调用的方法
function BattleField:doPlayerLaunchSkillAtk( atker,targets,skill )
    -- 调用攻击者模型的攻击方法 参数：被攻击者数组 发动的技能
    -- 显示一个技能名字
    self:dispatchEvent({ name = BattleField.DISPLAY_ATK_SKILL_NAME_EVENT, atker = atker,targets = targets,skill = skill})
    -- atker:doHeroStartAtk( targets,skill )
end

-- 当一个英雄被攻击动作结束后，开始自身的攻击
function BattleField:heroBeginSelfCommonSkillAtk( atker )
    if not atker:isDead() and atker:getSkills().commonSkill:isSelfCanAtk() then
        self:dispatchEvent({name = BattleField.BATTLE_FIELD_LAUNCH_SKILL_ATK, atker = atker, skill = atker:getSkills().commonSkill})
    end
end

-- 播完介绍后继续攻击的方法
function BattleField:continueAtk( atker,targets,skill )
    atker:doHeroStartAtk( targets,skill )
end

function BattleField:getState(  )
    self.fsm__:getState()
end

function BattleField:enterBattleFieldEnd_(  )
    -- 进场完毕，改变战场状态
    if self:getState() == "enfield" then
        self.fsm__:doEvent("enterend")
    end
    -- 告诉每个player可以进入战斗状态
    for i=1,#self.players_ do
        local player = self.players_[i]
        player:tellEnterBattleFieldEnd()
        player:getSkills().commonSkill:setCdTime(math.random(1,4))
    end
end

-- get和set方法

-- 获得所有英雄数据信息
function BattleField:getAllHeros(  )
    return self.players_
end
-- 进入闲置的方法
function BattleField:enterIdle(  )
    self.fsm__:doEvent("enidle")
end
-- 进入战场的方法
function BattleField:initAction(  )
    self.fsm__:doEvent("init")
    -- 通知actor开始进场了
    for i=1,#self.players_ do
        self.players_[i]:getSkills().commonSkill:setCdTime(13)
        self.players_[i]:beginEnterBattleField()
    end
end
-- 进入战斗状态
function BattleField:enterAtk(  )
    self.fsm__:doEvent("atking")
end
-- 离开战场状态
function BattleField:leaveAtk(  )
    self.fsm__:doEvent("lvfielding")
    for i=1,#self.players_ do
        local player = self.players_[i]
        if not player:isDead() then
            player:beginEnterBattleField(  )
        end
    end
end
-- 战斗结束
function BattleField:endFight(  )
    self.fsm__:doEvent("endatk")
end

function BattleField:getNickName(  )
    return "BattleField"
end

function BattleField:setPlayerForKey( key,value )
    self.allHero_[key] = value
end

function BattleField:getPlayerForKey( key )
    return self.allHero_[key]
end

-- 显示技能后 继续进行战斗 参数（攻击者，被攻击者）
-- function BattleField:continueAtk( )
--     self.displayPlayer_:enterAtk()
--     self.displaySkill_ = nil
--     self.displayPlayer_ = nil 
-- end

-- 被攻击者进入被攻击的状态
function BattleField:beginEnterDamage( atker,targets,skill )
    -- 计算攻击伤害
    for i=1,#targets do
        local targetObj = targets[i]
        -- 进行战斗计算和数据更改
        local skill = atker:getSkill().skill
        local atk = skill.atk
        local damage = 0
        if targetObj.target:isDead() then
            return
        end
        local armor = targetObj.target:getArmor()
        damage = armor - atk
        if damage >= 0 then
            -- 当没有伤害的时候，设置伤害为1
            damage = -1
        end
        damage = - damage
        targetObj.target:underAtk( damage )
    end
end

-- 收到消息后的回调
function BattleField:playSkillAni_( event )
    self.displaySkill_ = event.params.skill
    self.displayPlayer_ = event.params.player
    self.fsm__:doEvent("playskill")
end

-- 进入技能攻击的回调
function BattleField:enterSkillAtk_( event )
    self.skillAtkAtker_ = event.atker
    self.skillAtkTarget_ = event.targetModel
    self.skillAtkSkill_ = event.skill
    self.fsm__:doEvent("enskillatk")
end
-- 状态发生改变后的回调

-- 当初始化完成之后
function BattleField:onChangeState_( event )
    
end
function BattleField:onAfterStart_( event )
    
end

function BattleField:onAfterEnterEnd_( event )
    -- 当进入完
end

-- 播放战场动画
function BattleField:onAfterPlaySkill_( event )
    
end

function BattleField:onAfterEnSkillAtk_( event )
    
end

function BattleField:onAfterInit_( event )
    
end

function BattleField:onAfterLvfielding_( event )
    
end

function BattleField:onAfterAtking_( event )
end

function BattleField:onAfterEndatk_( event )
    
end

function BattleField:onAfterEnidle_( event )
    
end

function BattleField:onEnteridle_( event )
    -- printf("actor %s state change from %s to %s", self:getNickName(), event.from, event.to)
    
end

function BattleField:onEnterPlaySkillAni_( event )
    self:dispatchEvent({name = BattleField.PLAY_SKILL_ANI_EVENT, playerParam = { player = self.displayPlayer_, skill = self.displaySkill_}})

end

function BattleField:onEnterSkillAtk_( event )
    self:dispatchEvent({name = BattleField.ENTER_SKILL_ATK_EVENT, atker = self.skillAtkAtker_, targetModel = self.skillAtkTarget_, skill = self.skillAtkSkill_})
    self.skillAtkAtker_ = nil
    self.skillAtkTarget_ = nil
    self.skillAtkSkill_ = nil
end

function BattleField:onEnterEnfield_( event )
    self:dispatchEvent({name = BattleField.ENTER_BATTLE_EVENT})
end

function BattleField:onEnterLvfield_( event )
    self:dispatchEvent({name = BattleField.LEAVE_BATTLE_EVENT})
end

function BattleField:onEnteratk_( event )
    self:dispatchEvent({name = BattleField.ENTER_ATK_EVENT})
end

function BattleField:onEnterresult_( event )
    self:dispatchEvent({name = BattleField.FIGHT_END_EVENT})
end


return BattleField
