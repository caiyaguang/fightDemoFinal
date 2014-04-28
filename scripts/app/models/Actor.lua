-- 保存用户的数据和状态信息，并在状态发生改变的时候，向视图发送通知
-- 英雄的基类
-- 包含英雄的共同特征
-- 包含一些可以更新数据的接口  和分发事件的接口
-- 包含一个状态机
-- 数据包括： 等级 攻击力 血量 魔法值 

-- 内部有一个定时器，用于检测当cd时间结束了，更改状态   
-- 当状态发生改变了，向控制器发送通知，控制器根据状态，调用view的更新接口

local SkillModel = import("..models.SkillModel")

local Actor = class("Actor", cc.mvc.ModelBase)

local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")

-- 常量
Actor.CHANGE_STATE_EVENT = "CHANGE_STATE_EVENT"
Actor.START_EVENT         = "START_EVENT"
Actor.READY_EVENT         = "READY_EVENT"
Actor.FIRE_EVENT          = "FIRE_EVENT"
Actor.FREEZE_EVENT        = "FREEZE_EVENT"
Actor.THAW_EVENT          = "THAW_EVENT"
Actor.KILL_EVENT          = "KILL_EVENT"
Actor.RELIVE_EVENT        = "RELIVE_EVENT"
Actor.HP_CHANGED_EVENT    = "HP_CHANGED_EVENT"
Actor.ATTACK_EVENT        = "ATTACK_EVENT"
Actor.UNDER_ATTACK_EVENT  = "UNDER_ATTACK_EVENT"
Actor.UNDER_VERTIGO_EVENT  = "UNDER_VERTIGO_EVENT"
Actor.RELEASE_VERTIGO_EVENT  = "RELEASE_VERTIGO_EVENT"
Actor.ATACKING_EVENT        = "ATACKING_EVENT"

Actor.UNDERATK_EVENT        = "UNDERATK_EVENT"          -- 受到攻击事件
Actor.DECREASE_HP_EVENT     = "DECREASE_HP_EVENT"       -- 减少血量事件
Actor.TODO_SKILL_EFFECT_EVENT = "TODO_SKILL_EFFECT_EVENT"   -- 做播放技能特效的事件
Actor.BEGIN_SKILL_ATK_EVENT = "BEGIN_SKILL_ATK_EVENT" -- 进入技能攻击的事件

Actor.PLAYER_MODEL_LAUNCH_SKILL_ATK = "PLAYER_MODEL_LAUNCH_SKILL_ATK"   -- 玩家发动技能攻击

Actor.ENTER_BATTLEFIELD_END = "ENTER_BATTLEFIELD_END"
-- 魔法值回满
Actor.HERO_MP_FULL_EVENT = "HERO_MP_FULL_EVENT"

Actor.ENTER_WALK_EVENT = "ENTER_WALK_EVENT"

Actor.HERO_DIE_EVENT = "HERO_DIE_EVENT"

-- 结束攻击动作的事件
Actor.END_ATK_EVENT = "END_ATK_EVENT"

-- 特殊状态事件
-- 眩晕
Actor.HERO_CURRENT_IN_DIZZY_EVENT = "HERO_CURRENT_IN_DIZZY_EVENT"
-- 英雄解除眩晕状态
Actor.HERO_RELIEVE_DIZZY_EVENT = "HERO_RELIEVE_DIZZY_EVENT"

-- 视图攻击动作做完毕
Actor.HEROVIEW_ACTION_FINISH_EVENT = "HEROVIEW_ACTION_FINISH_EVENT"

Actor.ADD_SKILL_EFFECT_EVENT = "ADD_SKILL_EFFECT_EVENT"

Actor.SKILL_ATK_BE_CANCEL_EVENT = "SKILL_ATK_BE_CANCEL_EVENT"

Actor.ENTER_IDLE_EVENT = "ENTER_IDLE_EVENT"

-- 血量发生改变
Actor.HERO_HP_CHANGE_EVENT = "HERO_HP_CHANGE_EVENT"
Actor.HERO_MP_CHANGE_EVENT = "HERO_MP_CHANGE_EVENT"


--[[
    向控制器发送的消息
]]
Actor.PLAYER_LAUNCH_SKILL_ATK = "PLAYER_LAUNCH_SKILL_ATK"

-- 定义属性
Actor.schema = clone(cc.mvc.ModelBase.schema)
Actor.schema["nickname"] = {"string"} -- 字符串类型，没有默认值
Actor.schema["sid"]      = {"string"}
Actor.schema["level"]    = {"number", 1} -- 数值类型，默认值 1
Actor.schema["totalhp"]       = {"number", 100}
Actor.schema["hp"]       = {"number", 1}
Actor.schema["mp"]       = {"number", 0}        -- 魔法值
Actor.schema["totalmp"]     = {"number", 0}     -- 一个英雄总的魔法值
Actor.schema["exp"]       = {"number", 0}       -- 经验值
Actor.schema["cardIcon"] = {"string"}           -- 技能图片
local mytable = {
    skill = {
        atk = 10000,
    }
}
Actor.schema["skill"]       = {"table", mytable}        -- 技能信息
Actor.schema["def"]        = {"number",0}       -- 防御
Actor.schema["pos"]        = {"number",1}       -- 位置
Actor.schema["atk"]         = {"number", 0}     -- 攻击力
Actor.schema["side"]         = {"number", 0}    -- 所处阵容
Actor.schema["image"]       = {"string", ""}    -- 人物头像
Actor.schema["skills"]      = {"table"}      -- 技能对象

-- 没一个人都有眩晕时间
Actor.schema["dizzy"]       = {"number",0}      -- 初始眩晕时间为0

Actor.schema["mp"]          = {"number",100}
Actor.schema["totalmp"]     = {"number", 100}

-- 英雄一次攻击的攻击对象，默认为nil
Actor.schema["targets"] = {"table",nil}
-- 英雄本次攻击发动的技能
Actor.schema["currentAtkSkill"] = {"table",nil}


function Actor:ctor(properties, events, callbacks)
    Actor.super.ctor(self, properties)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
    -- 因为角色存在不同状态，所以这里为 Actor 绑定了状态机组件
    self:addComponent("components.behavior.StateMachine")
    -- 由于状态机仅供内部使用，所以不应该调用组件的 exportMethods() 方法，改为用内部属性保存状态机组件对象
    self.fsm__ = self:getComponent("components.behavior.StateMachine")

    -- 设定状态机的默认事件
    local defaultEvents = {
        -- 初始化后，角色处于 idle 状态
        {name = "start",  from = "none",    to = "idle" },
        -- 走
        {name = "walking",   from = "idle",    to = "walk"},
        -- 站立
        {name = "endwalk",   from = "walk",    to = "idle"},
        -- 开始攻击
        {name = "atking",   from = "idle",    to = "atk"},
        -- 攻击结束
        {name = "endatk",   from = "atk",    to = "idle"},
        -- 受到攻击
        {name = "beatk",    from = {"idle","underatk"},      to = "underatk"},
        -- 从攻击回复
        {name = "backidle", from = "underatk",      to = "idle"},
        -- 死亡
        {name = "kill",  from = "underatk",  to = "dead"},
    }
    -- 如果继承类提供了其他事件，则合并
    table.insertTo(defaultEvents, totable(events))

    -- 设定状态机的默认回调
    local defaultCallbacks = {
        onchangestate = handler(self, self.onChangeState_),
        onafterstart = handler(self, self.onAfterStart_),
        onafterwalking = handler(self, self.onAfterWalking_),
        onafterendwalk = handler(self, self.onAfterEndwalk_),
        onafteratking = handler(self, self.onAfterAtking_),
        onafterendatk = handler(self, self.onAfterEndatk_),
        onafterbeatk = handler(self, self.onAfterBeatk_),
        onafterBackidle = handler(self, self.onAfterBackidle_),
        onafterkill = handler(self, self.onAfterKill_),
        onenteridle = handler(self, self.onEnteridle_),
        onenterwalk = handler(self, self.onEnterwalk_),
        onenteratk = handler(self, self.onEnteratk_),
        onenterunderatk = handler(self, self.onEnterunderatk_),
        onenterdead = handler(self, self.onEnterdead_),
    }
    -- 如果继承类提供了其他回调，则合并
    table.merge(defaultCallbacks, totable(callbacks))

    self.fsm__:setupState({
        events = defaultEvents,
        callbacks = defaultCallbacks
    })

    -- 让每一个英雄模型对象监听来着技能模型的消息
    -- 监听天赋技能的信息
    local cls = self:getSkills().giftSkill.class
    cc.EventProxy.new(self:getSkills().giftSkill, self)  
            :addEventListener(cls.PLAYER_LAUNCH_SKILL_ATK, self.onPlayerLaunchSkillAtk_,self)

    local cls = self:getSkills().commonSkill.class
    cc.EventProxy.new(self:getSkills().commonSkill, self)  
            :addEventListener(cls.PLAYER_LAUNCH_SKILL_ATK, self.onPlayerLaunchSkillAtk_,self)
            :addEventListener(cls.SKILL_CD_OVER_EVENT, self.onSkillCdTimeOver_, self)
            :addEventListener(cls.MP_FULL_EVENT, self.onSkillMpFull_, self)

    -- 自己的天赋技能对象
    self.giftSkill_ = SkillModel.new()
    
    -- 初始化血量
    self.totalhp_ = self.hp_
    self:getSkills().giftSkill:updateHeroHp(self:getHp())
    self:getSkills().giftSkill:setHeroTotalHp(self:getTotalHp())
    self.fsm__:doEvent("start") -- 启动状态机

    function updateProperty(  )
        local dt = 0.1
        if self.dizzy_ > 0 then
            -- 向英雄视图发送正在眩晕中的消息
            self:dispatchEvent({name = Actor.HERO_CURRENT_IN_DIZZY_EVENT})
            self.dizzy_ = self.dizzy_ - dt
            if self.dizzy_ <= 0 then
                self:dispatchEvent({name = Actor.HERO_RELIEVE_DIZZY_EVENT})
                -- 判断解除眩晕后能否继续攻击
                self:heroLeaveDizzy()
            end
        end
        self:addMp(1)
        self:dispatchEvent({ name = Actor.HERO_HP_CHANGE_EVENT, hp = self.hp_, totalhp = self.totalhp_})
        self:getSkills().giftSkill:updateSkillMp(self.mp_)
        self:getSkills().commonSkill:updateSkillMp(self.mp_)
    end

    self.schedulerCDHandle_ = scheduler.scheduleGlobal(updateProperty, 0.1) 


end

--[[
        供控制器调用的方法
]]

-- 进入跑的状态
function Actor:enterWalking(  )
    self.fsm__:doEvent("walking")
end

-- 进入站立状态
function Actor:enterIdle(  )
    self.fsm__:doEvent("endwalk")
end

-- 接受控制器告知可以攻击的消息
function Actor:canAtk(  )
    
end

function Actor:beginAtkAction( targets,skill )
    -- 记录这次攻击的目标和技能
    self:setTargets(targets)
    self:setCurrentAtkSkill(skill)
    -- 减魔法和增加cd值

    self:getCurrentAtkSkill():setCdTime(math.random(1,6))
    self:decreaseMp(1000)
    self.fsm__:doEvent("atking")
end

-- 判断是否可以进行攻击
function Actor:isCanLaunchSkillAtk_( skill )
    return skill:getCdTime() <= 0 and self:getMp() >= skill:getTotalMp() and self:getDizzy() <= 0
end


-- 供战场模型调用的方法

-- 英雄开始发动一个技能攻击的方法
function Actor:doHeroStartAtk( targes,skill )
    -- 取消正在进行的攻击
    if not self:getTargets() and not self:getCurrentAtkSkill() then
        if self:isCanAtk() then
            -- 保存本次攻击的目标和发动的技能      
            self:setTargets(targes)
            self:setCurrentAtkSkill(skill)
            -- 计算并扣除本次攻击的法力值消耗
            local cost = self:oneShortAtkCost( self:getCurrentAtkSkill() )
            self:decreaseMp( cost )
            skill:updateSkillMp(self:getMp())
            -- 设置释放后的技能的cd时间
            skill:setCdTime(math.random(1,6))
            -- 英雄进入攻击状态
            self:enterAtk()
        end
    end
end

-- 添加技能特效
function Actor:addSkillEffect( targets,skill )
    self:dispatchEvent({name = Actor.ADD_SKILL_EFFECT_EVENT,atker = self,targets = targets,skill = skill})
end

function Actor:beginEnterBattleField(  )
    self.fsm__:doEvent("walking")
end

function Actor:tellEnterBattleFieldEnd(  )
    -- 通知视图，进入战场完毕
    if self:getState() == "walk" then
        self.fsm__:doEvent("endwalk")
    end
    self:dispatchEvent({name = Actor.ENTER_BATTLEFIELD_END})
end

function Actor:isInDizzy(  )
    return self.dizzy_ > 0
end

function Actor:isAtking( skill )
    return self:getState() == "atk" and true or false
end
-- 操作技能模型的方法


-- 对技能模型消息的处理方法
function Actor:onPlayerLaunchSkillAtk_( event )
    -- 得到发动攻击的技能
    local skill = event.skill
    -- 判断是否可以发动某个技能攻击
    -- if self:isOneSkillCanAtk( skill ) then
        -- 向战场模型发送发动某个技能攻击的消息 参数：该技能 英雄本身
        self:dispatchEvent({name = Actor.PLAYER_MODEL_LAUNCH_SKILL_ATK, atker = self, skill = skill})
    -- end
end

-- 一个英雄离开眩晕状态的方法
function Actor:heroLeaveDizzy(  )
    -- 得到可以自动打的技能
    local skill = self:getSkills().commonSkill
    if self:isOneSkillCanAtk( skill ) then
        self:dispatchEvent({name = Actor.PLAYER_MODEL_LAUNCH_SKILL_ATK, atker = self, skill = skill})
    end
end

-- 判断一个技能是否可以开始攻击
function Actor:isOneSkillCanAtk( skill )
    if skill:isMpFull() and skill:isCdOver() and self:getDizzy() <= 0 and not self:isDead() then
        return true
    end
    return false
end

function Actor:onSkillMpFull_( event )
    if self:isOneSkillCanAtk(event.skill) then
        self:dispatchEvent({name = Actor.PLAYER_MODEL_LAUNCH_SKILL_ATK, atker = self, skill = event.skill})
    end
end

function Actor:onSkillCdTimeOver_( event )
    -- local skill = event.skill
    -- if skill:getMp() >= skill:getTotalMp() then
    --     if self:isCanLaunchSkillAtk( skill ) then
    --         -- 向战场模型发送发动某个技能攻击的消息 参数：该技能 英雄本身
    --         self:dispatchEvent({name = Actor.PLAYER_MODEL_LAUNCH_SKILL_ATK, atker = self, skill = skill})
    --     end
    -- end
    -- 
    if self:isOneSkillCanAtk(event.skill) then
        self:dispatchEvent({name = Actor.PLAYER_MODEL_LAUNCH_SKILL_ATK, atker = self, skill = event.skill})
    end
    -- 得到发动攻击的技能
    -- 判断是否可以发动某个技能攻击
    
end

-- 取消英雄的攻击动作（打断）
function Actor:cancelAtkAction(  )
    if self:getState() == "atk" then
        self.fsm__:doEvent("endatk")
        -- 告诉视图自己被打断
        self:dispatchEvent({name = Actor.SKILL_ATK_BE_CANCEL_EVENT})
        -- self:getCurrentAtkSkill():removeOwnSkillView()
        self:setTargets(nil)
        self:setCurrentAtkSkill(nil)
    end
end

-- 对英雄模型属性进行操作的方法

-- 减少魔法值
function Actor:decreaseMp( value )
    self.mp_ = self.mp_ - value
    if self.mp_ < 0 then
        self.mp_ = 0
    end
    self:getCurrentAtkSkill():updateSkillMp(self:getMp())
    -- 发送魔法值改变的消息
    if value > 0 then
        self:dispatchEvent({ name = Actor.HERO_MP_CHANGE_EVENT})
    end
end

function Actor:addMp( value )
    if self.mp_ < self.totalmp_ then
        self.mp_ = self.mp_ + value
        if self.mp_ >= self.totalmp_ then
            self.mp_ = self.totalmp_
        end
        if value > 0 then
            self:dispatchEvent({ name = Actor.HERO_MP_CHANGE_EVENT})
        end
    end
end

-- 计算发动一次攻击消耗的魔法值
function Actor:oneShortAtkCost( skill )
    local cost = skill:getTotalMp()
    return cost
end

-- 供视图模型调用的方法
-- 当英雄攻击成功的方法
function Actor:onAtkSuccess( targets,skill )
    for i=1,#targets do
        local target = targets[i]
        -- 调用一个英雄对象的受攻击方法
        target:beUnderAtk( self,skill)
    end
end

-- 当视图做完攻击动作后的回调
function Actor:onHeroViewActionOver( actionType )
    -- 告诉战场模型，自己攻击动作完毕
    if actionType == "atk" then
        self:setTargets(nil)
        self:setCurrentAtkSkill(nil)
    elseif actionType == "kill" then
        -- 死亡以后 通知战场模型
        self:dispatchEvent({ name = Actor.HERO_DIE_EVENT, hero = self })
    elseif actionType == "underatk" then

    end

    self:enterNextState()
    self:dispatchEvent({ name = Actor.HEROVIEW_ACTION_FINISH_EVENT, actionType = actionType, atker = self })
end
-- 判断一个英雄的攻击能否打断另外一个英雄的攻击
function Actor:isCanInterruptAtk( atker,target,skill )
    -- 判断
    return true
end

-- 当英雄对象被成功攻击的方法
function Actor:beUnderAtk( atker,skill )
    -- 计算受到的伤害和伤害类型
    if self:getState() ~= "dead" then
        -- 如果当前英雄状态是攻击，判断该技能能否打断改英雄的攻击
        if self:isCanInterruptAtk() then
            self:cancelAtkAction()
            -- 进入被攻击的状态
            self.fsm__:doEvent("beatk")
            local damage = skill:getDamege()
            self:decreaseHp(damage)
            self:getSkills().giftSkill:updateHeroHp(self:getHp())
            self:dispatchEvent({name = Actor.DECREASE_HP_EVENT,damage = damage})

            -- 判断是否被眩晕
            if skill:getDamageType() == 8 then
                self:setDizzy(5)
                -- 立刻更新界面显示
                self:dispatchEvent({name = Actor.HERO_CURRENT_IN_DIZZY_EVENT})
            end
        else
            -- 继续自己的攻击
            local damage = skill:getDamege()
            self:decreaseHp(damage)
            self:getSkills().giftSkill:updateHeroHp(self:getHp())
            self:dispatchEvent({name = Actor.DECREASE_HP_EVENT,damage = damage})

            -- 判断是否被眩晕
            if skill:getDamageType() == 8 then
                self:setDizzy(5)
                -- 立刻更新界面显示
                self:dispatchEvent({name = Actor.HERO_CURRENT_IN_DIZZY_EVENT})
            end
        end
    end
end

-- 供英雄视图调用的方法
function Actor:beginEffectAtk( targes,skill )
    -- 调用技能模型的开始播特效的方法
    skill:enterAtk( self,targes)
end

function Actor:getDizzy(  )
    return self.dizzy_
end

function Actor:setDizzy( value )
    self.dizzy_ = value
end

function Actor:getSkills(  )
    return self.skills_
end

-- 进行cd时间更新
-- cd结束，修改英雄的状态
-- 参数： dt 时间间隔
function Actor:updateCdTimeAndHeroState( dt )
    
end

-- 判断一个英雄是否可以进行攻击
function Actor:isCanAtk(  )
    return self.fsm__:canDoEvent("atking")
end

function Actor:isDead(  )
    return self:getState() == "dead"
end
-- 接受controller的通知，进入下一个状态
function Actor:enterNextState(  )
    local currentState = self:getState()
    if currentState == "underatk" then
        if self.hp_ <= 0 then
            self.fsm__:doEvent("kill")
        else
            self.fsm__:doEvent("backidle")
        end
    elseif currentState == "atk" then
        self.fsm__:doEvent("endatk")
    elseif currentState == "walk" then
        self.fsm__:doEvent("endwalk")
    end
end

function Actor:enterAtk(  )
    self.fsm__:doEvent("atking")
end
-- 普通攻击
function Actor:noramlAtk( target )
    local skill = self.skill_.normalSkill
    local atk = skill.atk
    local damage = 0
    local armor = target:getArmor()
    damage = armor - atk
    if damage >= 0 then
        -- 当没有伤害的时候，设置伤害为1
        damage = 1
    end
    -- target:underAtk(damage)
    -- 普通攻击直接进入攻击状态
    self:enterAtk()
end
-- 技能攻击
function Actor:skillAtk( target )
    -- 根据技能信息计算伤害，并把攻击者置为攻击状态
    local skill = self.skill_.skill
    local atk = skill.atk
    local damage = 0
    if target:isDead() then
        return
    end
    local armor = target:getArmor()
    damage = armor - atk
    if damage >= 0 then
        -- 当没有伤害的时候，设置伤害为1
        damage = -1
    end
    damage = - damage
    -- target:underAtk(damage)
    -- 把伤害值保存到目标数组里边
    local target = {target = target,damage = damage}
    table.insert(self.targets_,target)
    -- 技能攻击等播完技能显示动画后开始进入攻击状态
    -- 向战场模型对象发送要播放技能显示特效的消息  
    -- 参数 自身信息 技能信息
    -- self:enterAtk()
    self:dispatchEvent({name = Actor.TODO_SKILL_EFFECT_EVENT, params = { player = self,skill = self.skill_.skill }})
end

-- 受到攻击的方法
function Actor:underAtk( damage )
    self.fsm__:doEvent("beatk")
    self:decreaseHp(damage)
    self:dispatchEvent({name = Actor.DECREASE_HP_EVENT,damage = damage})
end

-- 减血
function Actor:decreaseHp( damage )
    self.hp_ = self.hp_ - damage
end

-- 加血
function Actor:increaseHp(  )
    
end

function Actor:getMp(  )
    return self.mp_
end

function Actor.getTotalMp(  )
    return self.totalmp_
end

-- =进入走路状态
function Actor:initWalkState(  )
    self.fsm__:doEvent("walking")
end

-- get和set方法
function Actor:setTargets( value )
    self.targets_ = value
end
function Actor:getTargets(  )
    return self.targets_
end
function Actor:setCurrentAtkSkill( value )
    self.currentAtkSkill_ = value
end
function Actor:getCurrentAtkSkill(  )
    return self.currentAtkSkill_
end
-- 获得防御
function Actor:getArmor(  )
    return self.def_
end
function Actor:setArmor( value )
    self.def_ = value
end
function Actor:getPos(  )
    return self.pos_
end
function Actor:setPos( value )
    self.pos_ = value
end
-- 获得经验
function Actor:getExp(  )
    return self.exp_
end
function Actor:setExp( value )
    self.exp_ = value
end
-- 英雄头像
function Actor:setImage( image )
    self.image_ = image
end
function Actor:getImage(  )
    return self.image_
end

function Actor:getHp(  )
    return self.hp_
end

function Actor:setHp( value )
    self.hp_ = value
end

function Actor:getTotalHp(  )
    return self.totalhp_
end
-- 获得等级
function Actor:getLevel(  )
    return self.level_
end
function Actor:setLevel( value )
    self.level_ = value
end
-- -- 获得名字
function Actor:getNickName(  )
    return self.sid_
end
-- 获得英雄所处状态
function Actor:getState(  )
    return self.fsm__:getState()
end

function Actor:getSid(  )
    return self.sid_
end

-- 获得所处阵容
function Actor:getSide(  )
    return self.side_
end

function Actor:getSkill(  )
    return self.skill_
end


-- 命中的方法

-- 状态发生改变后的回调

-- 当初始化完成之后
function Actor:onChangeState_( event )
    
end
function Actor:onAfterStart_( event )
    
end

function Actor:onAfterWalking_( event )
    
end

function Actor:onAfterEndwalk_( event )
    
end

function Actor:onAfterAtking_( event )
    -- self:dispatchEvent({name = Actor.BEGIN_SKILL_ATK_EVENT})
end

function Actor:onAfterEndatk_( event )
    -- 当结束攻击的状态
    self:dispatchEvent({name = Actor.END_ATK_EVENT})
end

function Actor:onAfterBeatk_( event )
    self:dispatchEvent({name = Actor.UNDERATK_EVENT})
end

function Actor:onAfterBackidle_( event )
    
end

function Actor:onAfterKill_( event )
    
end

function Actor:onEnteridle_( event )
    self:dispatchEvent({name = Actor.ENTER_IDLE_EVENT})
end

function Actor:onEnterwalk_( event )
    self:dispatchEvent({name = Actor.ENTER_WALK_EVENT})
end

function Actor:onEnterunderatk_( event )
    -- 进入被攻击的状态
end

function Actor:onEnteratk_( event )
    self:dispatchEvent({name = Actor.ATACKING_EVENT, targets = self:getTargets(), skill = self:getCurrentAtkSkill()})     -- 向自己的视图发消息

end

function Actor:onEnterdead_( event )
    self:dispatchEvent({name = Actor.KILL_EVENT})
end

return Actor
