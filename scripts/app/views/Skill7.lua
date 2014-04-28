--[[
    群体技能
]]

local Skill7 = class("Skill7", function()
    local layer = display.newNode()
    require("framework.api.EventProtocol").extend(layer)    -- 添加事件
    return layer
end)

function Skill7:ctor( skillModel,atkerView,targetView,atker,target )
	self.skillModel_ = skillModel
    self.atkerView_ = atkerView
    self.targetView_ = targetView
    self.atker_ = atker
    self.target_ = target
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
end

-- 移除自身的方法
function Skill7:onRemoveSelf_( event )
    self.skillModel_:endAtk()
    self:removeSelf()
end

-- 进入攻击的状态
function Skill7:beginAtk_( event )
    -- 在攻击的动作中会调用父方法
    display.addSpriteFramesWithFile("frames/frame7.plist", "frames/frame7.png")
    local atker = self.atker_
    local target = self.target_
    local targetview = self.targetView_
    local skillEffect = display.newSprite("#frame7_0.png"):addTo(self)

    local side = target:getSide() == 0 and -1 or 1
    skillEffect:setScaleX(side * 1.5)
    skillEffect:setScaleY(1.7)
    skillEffect:setPosition(ccp(targetview:getPositionX() - side * 25 ,targetview:getPositionY() + 30))


    local frames1 = display.newFrames("frame7_%d.png", 0, 7)
    local animation1 = display.newAnimation(frames1, 1 / 24)
    local frames2 = display.newFrames("frame7_%d.png", 7, 2)
    local animation2 = display.newAnimation(frames2, 1 / 24)

    local actions = {}
    skillEffect:setVisible(false)
    actions[#actions + 1] = CCShow:create()
    actions[#actions + 1] = CCAnimate:create(animation1)
    actions[#actions + 1] = CCCallFunc:create(function (  )
        atker:onAtkSuccess({target},self.skillModel_)
    end)
    actions[#actions + 1] = CCAnimate:create(animation2)
    actions[#actions + 1] = CCCallFunc:create(function (  )
        -- display.removeSpriteFramesWithFile("frames/frame7.plist", "frames/frame7.png")
        self.skillModel_:endAtk()
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

function Skill7:cancelSkillAtk_( event )

    self.skillModel_:endAtk()
    self:removeSelf()
end

function Skill7:onEndEvent_( event )
    self:removeSelf()
end

-- 进入死亡的状态
function Skill7:enterDie_( event )
    
end

return Skill7
