--[[
    技能的视图，根据技能属性，创建技能视图，支持单个飞出群攻 统一群攻 单攻
    -- 当技能做完，可以对敌方进行伤害的时候，调用父类的方法，把像敌方发送伤害信息的方法打开
]]

local Skill4 = class("Skill4", function()
    local layer = display.newNode()
    require("framework.api.EventProtocol").extend(layer)    -- 添加事件
    return layer
end)


local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")

function Skill4:ctor( skillModel,atkerView,targetsView,atker,targets )
	self.skillModel_ = skillModel
    self.atkerView_ = atkerView
    self.targetsView_ = targetsView
	-- 通过代理注册事件的好处：可以方便的在视图删除时，清理所以通过该代理注册的事件，
    -- 同时不影响目标对象上注册的其他事件
    --
    local cls = self.skillModel_.class

	cc.EventProxy.new(self.skillModel_, self)
            :addEventListener(cls.BEGIN_ATK_EVENT, self.beginAtk_, self)
            :addEventListener(cls.ENTER_DIE_EVENT, self.enterDie_, self)
            :addEventListener(cls.END_ATK_EVENT, self.onEndEvent_, self)
            :addEventListener(cls.REMOVE_SELF_SKILL_VIEW, self.onRemoveSelf_, self)
            :addEventListener(cls.HERO_HP_CHANGE_EVENT, self.onHeroHpChange_, self)
    self.bgLayer_ = display.newColorLayer(ccc4(255,255,255,0)):pos(0,0):addTo(self)
    self.skillModel_:enterAtk(atker,targets)
    self.isOneWork_ = 0
end

-- 移除自身的方法
function Skill4:onRemoveSelf_( event )
    self:removeSelf()
    if self.schedulerHandle_ then
        scheduler.unscheduleGlobal(self.schedulerHandle_)
        self.schedulerHandle_ = nil
    end
end

-- 进入攻击的状态
function Skill4:beginAtk_( event )
    -- 在攻击的动作中会调用父方法
    display.addSpriteFramesWithFile("frames/frame3.plist", "frames/frame3.png")
    local atker = event.atker
    local targets = event.targets

    -- 一个人会发出十只箭
    local function generateArraws(  )
        if self.skillModel_ and self.skillModel_:getHeroHp() > 0 then
            local target = targets[math.random(1,#targets)]
            local targetview = self.targetsView_[target:getNickName()]
            local skillEffect = display.newSprite("#frame3_0.png"):addTo(self)
            local frames = display.newFrames("frame3_%d.png", 0, 3 )
            local animation = display.newAnimation(frames, 0.1)
            transition.playAnimationForever(skillEffect, animation, 0)

            skillEffect:setPosition(ccp(self.atkerView_:getPositionX(),self.atkerView_:getPositionY()))
            local bezierForward3
            local distance = math.abs(targetview:getPositionX() - self.atkerView_:getPositionX())
            local time = distance / 600
            if target:getSide() == 1 then
                local bezier = ccBezierConfig()
                if distance <= 300 then
                    bezier.controlPoint_1 = ccp(0,60)
                    bezier.controlPoint_2 = ccp(targetview:getPositionX() - self.atkerView_:getPositionX(),targetview:getPositionY() - self.atkerView_:getPositionY() + 60)
                    bezier.endPosition = ccp(targetview:getPositionX() - self.atkerView_:getPositionX(),targetview:getPositionY() - self.atkerView_:getPositionY())
                else
                    bezier.controlPoint_1 = ccp(0,150)
                    bezier.controlPoint_2 = ccp(targetview:getPositionX() - self.atkerView_:getPositionX(),targetview:getPositionY() - self.atkerView_:getPositionY() + 150)
                    bezier.endPosition = ccp(targetview:getPositionX() - self.atkerView_:getPositionX(),targetview:getPositionY() - self.atkerView_:getPositionY())
                end
                bezierForward3 = CCBezierBy:create(time, bezier)
            else
                local bezier = ccBezierConfig()
                if distance > 300 then
                    bezier.controlPoint_1 = ccp(0,150)
                    bezier.controlPoint_2 = ccp(targetview:getPositionX() - self.atkerView_:getPositionX(),targetview:getPositionY() - self.atkerView_:getPositionY() + 150)
                    bezier.endPosition = ccp(targetview:getPositionX() - self.atkerView_:getPositionX(),targetview:getPositionY() - self.atkerView_:getPositionY())
                else
                    bezier.controlPoint_1 = ccp(0,60)
                    bezier.controlPoint_2 = ccp(targetview:getPositionX() - self.atkerView_:getPositionX(),targetview:getPositionY() - self.atkerView_:getPositionY() + 60)
                    bezier.endPosition = ccp(targetview:getPositionX() - self.atkerView_:getPositionX(),targetview:getPositionY() - self.atkerView_:getPositionY())
                end
                bezierForward3 = CCBezierBy:create(time, bezier)
            end

            local side = target:getSide() == 0 and -1 or 1
            skillEffect:setScaleX(side * 0.7)
            skillEffect:setScaleY(side * 0.7)

            local actions = {}
            skillEffect:setVisible(false)
            actions[#actions + 1] = CCCallFunc:create(function (  )
            end)
            actions[#actions + 1] = CCShow:create()
            if distance > 300 then
                skillEffect:setRotation(40 * side)
                actions[#actions + 1] = CCSpawn:createWithTwoActions(bezierForward3,CCRotateBy:create(time,-side * 90))
            else
                skillEffect:setRotation(40 * side)
                actions[#actions + 1] = CCSpawn:createWithTwoActions(bezierForward3,CCRotateBy:create(time,-side * 80))
            end
            actions[#actions + 1] = CCCallFunc:create(function (  )
                atker:onAtkSuccess(targets,self.skillModel_)
            end)
            actions[#actions + 1] = CCCallFunc:create(function (  )
                -- display.removeSpriteFramesWithFile("frames/frame3.plist", "frames/frame3.png")
            end)
            actions[#actions + 1] = CCRemoveSelf:create()
            local action
            if #actions > 1 then
                action = transition.sequence(actions)
            else
                action = actions[1]
            end
            skillEffect:runAction(action)
            self.isOneWork_ = self.isOneWork_ + 1
        end
        if self.isOneWork_ == 3 then
            scheduler.unscheduleGlobal(self.schedulerHandle_)
            self.schedulerHandle_ = nil
        end
    end

    self.schedulerHandle_ = scheduler.scheduleGlobal(generateArraws, 0.3) 
end

function Skill4:onHeroHpChange_( event )
    if self.skillModel_:getHeroHp() <= 0 then
        self:removeSelf()
        if self.schedulerHandle_ then
            scheduler.unscheduleGlobal(self.schedulerHandle_)
            self.schedulerHandle_ = nil
        end
        display.removeSpriteFramesWithFile("frames/frame3.plist", "frames/frame3.png")
    end
end

function Skill4:cancelSkillAtk_( event )
    self:removeSelf()
    if self.schedulerHandle_ then
        scheduler.unscheduleGlobal(self.schedulerHandle_)
        self.schedulerHandle_ = nil
    end
end

function Skill4:onEndEvent_( event )
    self:removeSelf()
    if self.schedulerHandle_ then
        scheduler.unscheduleGlobal(self.schedulerHandle_)
        self.schedulerHandle_ = nil
    end
end

-- 进入死亡的状态
function Skill4:enterDie_( event )
    
end

return Skill4
