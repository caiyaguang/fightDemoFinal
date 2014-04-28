--[[
    技能的视图，根据技能属性，创建技能视图，支持单个飞出群攻 统一群攻 单攻
    -- 当技能做完，可以对敌方进行伤害的时候，调用父类的方法，把像敌方发送伤害信息的方法打开
]]

local Skill1 = class("Skill1", function()
    local layer = display.newNode()
    require("framework.api.EventProtocol").extend(layer)    -- 添加事件
    return layer
end)

function Skill1:ctor( skillModel,atkerView,targetsView,atker,targets )
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
            -- :addEventListener(cls.SKILL_ATK_CANCEL_EVENT, self.cancelSkillAtk_, self)
    self.bgLayer_ = display.newColorLayer(ccc4(255,255,255,0)):pos(0,0):addTo(self)
    -- self.bgLayer_:setVisible(false)
    self.skillModel_:enterAtk(atker,targets)
end

-- 移除自身的方法
function Skill1:onRemoveSelf_( event )
    self:removeSelf()
    -- self.skillModel_:endAtk()
end

-- 进入攻击的状态
function Skill1:beginAtk_( event )
    -- 在攻击的动作中会调用父方法
    display.addSpriteFramesWithFile("frames/frame1.plist", "frames/frame1.png")
    local atker = event.atker
    local targets = event.targets
    for i=1,#targets do
        local target = targets[i]
        local skillEffect = display.newSprite("#frame1_0.png"):addTo(self)
        skillEffect:setScale(1.3)

        local targetview = self.targetsView_[target:getNickName()]
        local side = target:getSide() == 0 and 1 or -1

        skillEffect:setPosition(ccp(targetview:getPositionX() + side * 20,targetview:getPositionY() + 100))

        local frames1 = display.newFrames("frame1_%d.png", 0, 4)
        local animation1 = display.newAnimation(frames1, 1 / 24)
        local frames2 = display.newFrames("frame1_%d.png", 4, 6)
        local animation2 = display.newAnimation(frames2, 1 / 24)

        local actions = {}
        skillEffect:setVisible(false)
        actions[#actions + 1] = CCShow:create()
        actions[#actions + 1] = CCAnimate:create(animation1)
        actions[#actions + 1] = CCCallFunc:create(function (  )
            atker:onAtkSuccess(targets,self.skillModel_)
        end)
        actions[#actions + 1] = CCAnimate:create(animation2)
        actions[#actions + 1] = CCCallFunc:create(function (  )
            display.removeSpriteFramesWithFile("frames/frame1.plist", "frames/frame1.png")
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

function Skill1:cancelSkillAtk_( event )
    self:removeSelf()
end

function Skill1:onEndEvent_( event )
    self:removeSelf()
end

-- 进入死亡的状态
function Skill1:enterDie_( event )
    
end

return Skill1
