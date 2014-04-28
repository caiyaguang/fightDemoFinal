--[[
    技能模型
    包含技能信息
    包含一个状态机 用来管理技能的产生和消亡
    有一个定时器 按时间向控制器发送伤害值

    近程/远程
    单体/群体
    是否显示攻击特效
    一次性攻击/持续性攻击
    物理伤害（减血）/魔法伤害（减血，减防，减魔，加防，加血，加魔，眩晕，解除眩晕）
    需要释放者类型（拳，刀，剑，箭）

]]

--[[
    当技能模型的
]]
local SkillModel = class("SkillModel", cc.mvc.ModelBase)

local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")

-- 常量
SkillModel.PLAYER_LAUNCH_SKILL_ATK = "PLAYER_LAUNCH_SKILL_ATK"    -- 用户发动攻击的方法

SkillModel.SENT_TO_CONTROLLER_DAMAGE = "SENT_TO_CONTROLLER_DAMAGE"            -- 向控制器发送伤害信息
SkillModel.BEGIN_ATK_EVENT = "BEGIN_ATK_EVENT"                                -- 向自身视图发送开始攻击的方法
SkillModel.ENTER_DIE_EVENT = "ENTER_DIE_EVENT"                                -- 向自身视图发送死亡信息
SkillModel.MP_CHANGE_EVENT = "MP_CHANGE_EVENT"
SkillModel.MP_FULL_EVENT = "MP_FULL_EVENT"

SkillModel.SKILL_ATK_CANCEL_EVENT = "SKILL_ATK_CANCEL_EVENT"
-- cd时间改变
SkillModel.SKILL_CD_CHANGE_EVENT = "SKILL_CD_CHANGE_EVENT"
SkillModel.SKILL_CD_OVER_EVENT =  "SKILL_CD_OVER_EVENT"

SkillModel.END_ATK_EVENT = "END_ATK_EVENT"

SkillModel.HERO_HP_CHANGE_EVENT = "HERO_HP_CHANGE_EVENT"

SkillModel.REMOVE_SELF_SKILL_VIEW = "REMOVE_SELF_SKILL_VIEW"

SkillModel.SKILL_CAN_ATK_STATE_CHANGE_EVENT = "SKILL_CAN_ATK_STATE_CHANGE_EVENT"

SkillModel.SKILL_WANT_ATK_EVENT = "SKILL_WANT_ATK_EVENT"

SkillModel.SKILL_ENABLE_ATK_EVENT = "SKILL_ENABLE_ATK_EVENT"

SkillModel.SKILL_DISABLE_ATK_EVENT = "SKILL_DISABLE_ATK_EVENT"

SkillModel.ONE_SORT_ATK = 0         -- 一次性攻击
SkillModel.CONTINUE_ATK = 1         -- 持续性攻击
-- 技能的模型类   

-- 定义属性
SkillModel.schema = clone(cc.mvc.ModelBase.schema)
SkillModel.schema["name"] = {"string"}          -- 名字
SkillModel.schema["stype"] = {"number",0}          -- 类型： 0 一次性攻击   1 持续性攻击
SkillModel.schema["rangtype"] = {"number",0}         -- 攻击范围：0 近程     1 远程
SkillModel.schema["isshow"] = {"number",0}        -- 是否进行技能显示 0 不显示  1显示
SkillModel.schema["haveeffect"] = {"number",0}    -- 是否显示攻击效果 0 不显示  1显示
SkillModel.schema["atktype"] = {"number",0}     -- 攻击类型 0 单体攻击 1 群体攻击（多个特效） 2 群体攻击（单个特效）
SkillModel.schema["damagetype"] = {"number",0}    -- 伤害类型 0 物理伤害 1   减血， 2    减防，3    减魔，4    加防，5    加血，6    加魔，7    眩晕，8    解除眩晕
SkillModel.schema["damage"] = {"number"}        -- 每次攻击的伤害值
SkillModel.schema["skill"] = {"table"}          -- 保存技能的原始数据
SkillModel.schema["canbreak"] = {"number",1}    -- 是否可以打断别的技能攻击 0 不可以 1 可以
SkillModel.schema["caninterrupt"] = {"number",1}-- 是否可以被打断      0 不可以 1 可以
SkillModel.schema["herohp"] = {"number",100}
SkillModel.schema["herototalhp"] = {"number",100}
-- 技能的冷却时间
SkillModel.schema["cdtime"] = {"number",0}
SkillModel.schema["iscanatk"] = {"boolean",false}
SkillModel.schema["skilltype"] = {"string"}
--[[
    target的范例
    {
        {
            target = target,
            damage = damage
        },
        {
            target = target,
            damage = damage
        }
    }
]]
SkillModel.schema["mp"] = {"number",0}
SkillModel.schema["totalmp"] = {"number",100}
-- SkillModel.schema["battleview"] = {"userdata"}     -- 保存战场视图对象 

SkillModel.DISABLE_STATE = {
    onenterFun = nil,
    state = nil,
    oneLeaveFun = nil,
}

SkillModel.ENABLE_STATE = {
    onenterFun = nil,
    state = nil,
    oneLeaveFun = nil,
}

function SkillModel:ctor(properties, events, callbacks)
    SkillModel.super.ctor(self, properties)
    self:addComponent("components.behavior.EventProtocol"):exportMethods()
    -- 因为角色存在不同状态，所以这里为 SkillModel 绑定了状态机组件
    self:addComponent("components.behavior.StateMachine")
    -- 由于状态机仅供内部使用，所以不应该调用组件的 exportMethods() 方法，改为用内部属性保存状态机组件对象
    self.fsm__ = self:getComponent("components.behavior.StateMachine")

    -- 设定状态机的默认事件
    local defaultEvents = {
        -- 初始化后，角色处于 攻击 状态
        {name = "start",  from = "none",    to = "idle" },
        {name = "enatk",    from = "idle",  to = "atk"},
        {name = "endatk",   from = "atk",   to = "idle"},
        {name = "todie",    from = "*",      to = "die"}
    }
    -- 如果继承类提供了其他事件，则合并
    table.insertTo(defaultEvents, totable(events))

    -- 设定状态机的默认回调
    local defaultCallbacks = {
        onchangestate = handler(self, self.onChangeState_),
        onafterstart = handler(self, self.onAfterStart_),
        onafterenatk = handler(self, self.onAfterEnatk_),
        onafterendatk = handler(self, self.onAfterEndatk_),
        onaftertodie = handler(self, self.onAfterTodie_),
        onenteratk = handler(self, self.onEnteratk_),
        onenterdie = handler(self, self.onEnterdie_),
    }
    -- 如果继承类提供了其他回调，则合并
    table.merge(defaultCallbacks, totable(callbacks))

    self.fsm__:setupState({
        events = defaultEvents,
        callbacks = defaultCallbacks
    })
    self.canSentAtkInfo_ = 0 -- 用以管理是否可以向目标发送伤害信息

    self.mpCdTime_ = 0 -- 魔法值的cd时间 为零可以释放
    self.fsm__:doEvent("start") -- 启动状态机 直接闲置状态

    self.cdtime_ = math.random(5,7)

    self.DISABLE_STATE = {
        onenterFun = function (  )
            self:dispatchEvent({name = SkillModel.SKILL_DISABLE_ATK_EVENT, skill = self})
        end,
        state = "disable",
        oneLeaveFun = self.leaveDisableStateFun,
    }

    self.ENABLE_STATE = {
        onenterFun = function(  )
            self:dispatchEvent({name = SkillModel.SKILL_ENABLE_ATK_EVENT, skill = self})
        end,
        state = "enable",
        oneLeaveFun = self.leaveEnableStateFun,
    }
    self.enableState_ = self.DISABLE_STATE

    -- 一个定时器，用来向控制器发送是否已伤害的信息
    local function sentDamage(  )
        if self:isCanSentDamage() then
            -- 发送伤害信息  from: SkillModel   to: FightControllergetMp
            self:dispatchEvent({name = SkillModel.SENT_TO_CONTROLLER_DAMAGE, atker = self.atker_, targets = self.target_, skill = self.skill_})
            if self.stype_ == SkillModel.ONE_SORT_ATK then
                self:switchSendInfo(false)
            end
        end
    end
    self.schedulerHandle_ = scheduler.scheduleGlobal(sentDamage, 0.5)   -- 每0.1秒就发送一次

    local function coolDownCD(  )
        -- cd时间管理
        if self.cdtime_ > 0 then
            self.cdtime_ = self.cdtime_ - 0.1
            self:dispatchEvent({name = SkillModel.SKILL_CD_CHANGE_EVENT, skill = self})
            -- 发出可以攻击的通知
        end
        if self.cdtime_ <= 0 then
            -- 当cd时间结束的时候，每一次循环都会向英雄发送攻击的请求
            self:wantToAtk()
        end
    end

    self.schedulerCDHandle_ = scheduler.scheduleGlobal(coolDownCD, 0.1)   -- cd循环
end

-- 供英雄模型调用的方法
function SkillModel:isMpFull(  )
    if self.mp_ >= self.totalmp_ then
        return true
    end
    return false
end

-- 更改技能是否可以攻击的状态
function SkillModel:setSkillAtkState( flag )
    if flag then
        self:changeState(self.ENABLE_STATE)
    else
        self:changeState(self.DISABLE_STATE)
    end
end

function SkillModel:getIsCanAtk(  )
    return self.enableState_.state == "enable"
end

-- 取消了技能释放
function SkillModel:cancelSkillAtk(  )
    -- self:dispatchEvent({name = SkillModel.SKILL_ATK_CANCEL_EVENT})
    self.fsm__:doEvent("todie")
end

-- 判断自身是否可以开始攻击
function SkillModel:isSelfCanAtk(  )
    return self:isMpFull() and self:isCdOver()
end

function SkillModel:wantToAtk(  )
    if self:isSelfCanAtk() then
        self:dispatchEvent({name = SkillModel.SKILL_WANT_ATK_EVENT, skill = self})
    end
end

function SkillModel:isCdOver(  )
    return self.cdtime_ <= 0
end

function SkillModel:updateHeroHp( value )
    self:setHeroHp(value)
    self:dispatchEvent({ name = SkillModel.HERO_HP_CHANGE_EVENT })
end

function SkillModel:updateSkillMp( heroMp )
    -- 更新技能魔法值的显示
    if heroMp >= self.totalmp_ then
        self.mp_ = self.totalmp_
        -- 如果魔法值满，可以攻击,发出可以攻击的通知
        self:wantToAtk()
    else 
        self.mp_ = heroMp
    end
    -- self:dispatchEvent({ name = SkillModel.MP_CHANGE_EVENT })
end

-- 改变是否可以攻击状态的方法
function SkillModel:changeState( state_ )
    if state_.state ~= self.enableState_.state then
        if self.enableState_.oneLeaveFun then
            self.enableState_.oneLeaveFun()
        end
        if state_.onenterFun then
            state_.onenterFun()
        end
        self.enableState_ = state_
    end
end

function SkillModel:enterEnableStateFun(  )
    -- 进入可以激活攻击的状态
    self:dispatchEvent({name = SkillModel.SKILL_ENABLE_ATK_EVENT})
    -- self:dispatchEvent({name = SkillModel.SKILL_ENABLE_ATK_EVENT, skill = self})
end

function SkillModel:leaveEnableStateFun(  )
    
end

function SkillModel:enterDisableStateFun(  )
    -- 进入不可以激活攻击的状态
    -- self:dispatchEvent({name = SkillModel.SKILL_DISABLE_ATK_EVENT, skill = self})
end

function SkillModel:leaveDisableStateFun(  )
    
end

-- 用户发动攻击的方法
function SkillModel:playerLaunchAtk(  )
    -- 当用户发动技能攻击，将会向英雄模型发送消息，参数为技能本身
    self:dispatchEvent({name = SkillModel.PLAYER_LAUNCH_SKILL_ATK, skill = self})
end

function SkillModel:isCanLaunchSkillAtk(  )
    return self:isOneSkillCanAtk( self )
end

function SkillModel:isCanAtk(  )
    return self.iscanatk_
end

-- get和set方法
function SkillModel:setHeroHp( value )
    self.herohp_ = value
end

function SkillModel:getHeroHp(  )
    return self.herohp_
end

function SkillModel:getHeroTotalHp(  )
    return self.herototalhp_
end

function SkillModel:setHeroTotalHp( value )
    self.herototalhp_ = value
end

function SkillModel:getNickName()
    return self.name_
end

function SkillModel:getCdTime(  )
    return self.cdtime_
end

function SkillModel:setCdTime( value )
    self.cdtime_ = value
end

function SkillModel:getSkillType(  )
    return self.stype_
end

function SkillModel:getCanBreak(  )
    return self.canbreak
end

-- function function_name( ... )
--     -- body
-- end

function SkillModel:getCanInterrupt(  )
    return self.caninterrupt_
end

function SkillModel:getDamege(  )
    return self.damage_
end

function SkillModel:getAtker(  )
    return self.atker_
end

function SkillModel:getTargets(  )
    return self.target_
end

function SkillModel:getMp(  )
    return self.mp_
end

function SkillModel:setMp( value )
    self.mp_ = value
end

function SkillModel:getDamageType(  )
    return self.damagetype_
end

function SkillModel:removeOwnSkillView(  )
    -- 向自己的视图发送移除自身的方法
    self:dispatchEvent({ name = SkillModel.REMOVE_SELF_SKILL_VIEW})
end

function SkillModel:getTotalMp(  )
    return self.totalmp_
end

-- 被打断的回调
function SkillModel:interruptSkillAction_( event )
    self.fsm__:doEvent("todie")
end

-- 是否可以开始发送伤害信息
function SkillModel:isCanSentDamage(  )
    return self.canSentAtkInfo_ == 1
end

-- 打开或者关系是否可以发送伤害信息的开关
function SkillModel:switchSendInfo( flag )
    self.canSentAtkInfo_ = flag and  1 or 0
end

function SkillModel:getState(  )
    return self.fsm__:getState()
end

function SkillModel:heroSkillType(  )
    return self.skilltype_
end

-- 获取攻击类型
function SkillModel:getAtkType(  )
    return self.atktype_
end

-- 开始攻击
function SkillModel:enterAtk( atker,targets )
    if self:getState() == "atk" then
        self.fsm__:doEvent("endatk")
    end
    self.atker_ = atker
    self.targets_ = targets
    self.fsm__:doEvent("enatk")
end

-- 结束攻击
function SkillModel:endAtk(  )
    self.fsm__:doEvent("endatk")
end

-- 状态发生改变后的回调

-- 当初始化完成之后
function SkillModel:onChangeState_( event )
    
end
function SkillModel:onAfterStart_( event )
    
end

function SkillModel:onAfterTodie_( event )
    
end

function SkillModel:onAfterEndatk_( event )
    self:dispatchEvent({name = SkillModel.END_ATK_EVENT})
end

function SkillModel:onAfterEnatk_( event )
    
end

function SkillModel:onEnteratk_( event )
    -- 通知视图开始攻击了
    self:dispatchEvent({name = SkillModel.BEGIN_ATK_EVENT, atker = self.atker_, targets = self.targets_})
end

function SkillModel:onEnterdie_( event )
    -- 通知视图可以死亡把自己移除了
    self:dispatchEvent({name = SkillModel.ENTER_DIE_EVENT})
end

function SkillModel:removeSelf(  )
    scheduler.unscheduleGlobal(self.schedulerHandle_)
end
return SkillModel
