--[[
    技能的视图，根据技能属性，创建技能视图，支持单个飞出群攻 统一群攻 单攻
    -- 当技能做完，可以对敌方进行伤害的时候，调用父类的方法，把像敌方发送伤害信息的方法打开
]]

local Skill5 = class("Skill5", function()
    local layer = display.newNode()
    require("framework.api.EventProtocol").extend(layer)    -- 添加事件
    return layer
end)

function Skill5:ctor( skillModel,atkerView,targetsView,atker,targets )
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
    self.bgLayer_ = display.newColorLayer(ccc4(255,255,255,0)):pos(0,0):addTo(self)
    self.skillModel_:enterAtk(atker,targets)
end

-- 移除自身的方法
function Skill5:onRemoveSelf_( event )
    self:removeSelf()
    -- self.skillModel_:endAtk()
end

-- 进入攻击的状态
function Skill5:beginAtk_( event )
    -- 在攻击的动作中会调用父方法
    display.addSpriteFramesWithFile("frames/frame4.plist", "frames/frame4.png")
    local atker = event.atker
    local targets = event.targets
    for i=1,#targets do
        local target = targets[i]
        local targetview = self.targetsView_[target:getNickName()]
        local skillEffect = display.newSprite("#0.png"):addTo(self)

        local side = target:getSide() == 0 and 1 or -1
        -- skillEffect:setScaleX(side)
        skillEffect:setPosition(ccp(targetview:getPositionX() + side * 30,targetview:getPositionY() + 90))
        -- local angle = math.deg(math.atan(math.abs(targetview:getPositionY() - self.atkerView_:getPositionY() + 60) / math.abs( targetview:getPositionX() -self.atkerView_:getPositionX() - side * 100)))
        -- skillEffect:setRotation(angle * (-side))

        local frames1 = display.newFrames("%d.png", 0, 3)
        local animation1 = display.newAnimation(frames1, 1 / 24)
        local frames2 = display.newFrames("%d.png", 3, 6)
        local animation2 = display.newAnimation(frames2, 1 / 24)
        local frames3 = display.newFrames("%d.png", 12, 9)
        local animation3 = display.newAnimation(frames3, 1 / 24)
        local frames4 = display.newFrames("%d.png", 15, 3)
        local animation4 = display.newAnimation(frames4, 1 / 24)
        local frames5 = display.newFrames("%d.png", 18, 3)
        local animation5 = display.newAnimation(frames5, 1 / 24)
        local frames6 = display.newFrames("%d.png", 19, 1)
        local animation6 = display.newAnimation(frames6, 1 / 24)
        local frames7 = display.newFrames("%d.png", 23, 4)
        local animation7 = display.newAnimation(frames7, 1 / 24)

        local actions = {}
        skillEffect:setVisible(false)
        actions[#actions + 1] = CCShow:create()
        actions[#actions + 1] = CCAnimate:create(animation1)
        actions[#actions + 1] = CCCallFunc:create(function (  )
            atker:onAtkSuccess(targets,self.skillModel_)
        end)
        actions[#actions + 1] = CCAnimate:create(animation2)
        actions[#actions + 1] = CCCallFunc:create(function (  )
            atker:onAtkSuccess(targets,self.skillModel_)
        end)
        actions[#actions + 1] = CCAnimate:create(animation3)
        actions[#actions + 1] = CCCallFunc:create(function (  )
            atker:onAtkSuccess(targets,self.skillModel_)
        end)
        actions[#actions + 1] = CCAnimate:create(animation4)
        actions[#actions + 1] = CCCallFunc:create(function (  )
            atker:onAtkSuccess(targets,self.skillModel_)
        end)
        actions[#actions + 1] = CCAnimate:create(animation5)
        actions[#actions + 1] = CCCallFunc:create(function (  )
            atker:onAtkSuccess(targets,self.skillModel_)
        end)
        actions[#actions + 1] = CCAnimate:create(animation6)
        actions[#actions + 1] = CCCallFunc:create(function (  )
            atker:onAtkSuccess(targets,self.skillModel_)
        end)
        actions[#actions + 1] = CCAnimate:create(animation7)

        actions[#actions + 1] = CCCallFunc:create(function (  )
            display.removeSpriteFramesWithFile("frames/frame4.plist", "frames/frame4.png")
        end)
        actions[#actions + 1] = CCRemoveSelf:create()
        local action
        if #actions > 1 then
            action = transition.sequence(actions)
        else
            action = actions[1]
        end
        skillEffect:runAction(action)
    end
end

function Skill5:cancelSkillAtk_( event )
    self:removeSelf()
end

function Skill5:onEndEvent_( event )
    self:removeSelf()
end

-- 进入死亡的状态
function Skill5:enterDie_( event )
    
end

return Skill5
