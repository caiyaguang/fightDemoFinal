--[[
    群体技能
]]

local Skill8 = class("Skill8", function()
    local layer = display.newNode()
    require("framework.api.EventProtocol").extend(layer)    -- 添加事件
    return layer
end)

function Skill8:ctor( skillModel,atkerView,targetsView,atker,targets )
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
function Skill8:onRemoveSelf_( event )
    self:removeSelf()
    -- self.skillModel_:endAtk()
end

-- 进入攻击的状态
function Skill8:beginAtk_( event )
    -- 在攻击的动作中会调用父方法
    display.addSpriteFramesWithFile("frames/frame8.plist", "frames/frame8.png")
    local atker = event.atker
    local targets = event.targets
    local distance = 0
    for i=1,#targets do
        local target = targets[i]
        local targetview = self.targetsView_[target:getNickName()]
        distance = distance + targetview:getPositionX()
    end
    local posx = distance / #targets

    local skillEffect = display.newSprite("#frame8_0.png"):addTo(self)

    local side = atker:getSide() == 0 and -1 or 1
    skillEffect:setScaleX(side * 1)
    skillEffect:setScaleY(1)
    skillEffect:setPosition(ccp(posx,display.cy + 100))


    local frames1 = display.newFrames("frame8_%d.png", 0, 12)
    local animation1 = display.newAnimation(frames1, 1 / 12)
    local frames2 = display.newFrames("frame8_%d.png", 12, 1)
    local animation2 = display.newAnimation(frames2, 1 / 12)

    local actions = {}
    skillEffect:setVisible(false)
    actions[#actions + 1] = CCShow:create()
    actions[#actions + 1] = CCAnimate:create(animation1)
    actions[#actions + 1] = CCCallFunc:create(function (  )
        atker:onAtkSuccess(targets,self.skillModel_)
    end)
    actions[#actions + 1] = CCAnimate:create(animation2)
    actions[#actions + 1] = CCCallFunc:create(function (  )
        display.removeSpriteFramesWithFile("frames/frame8.plist", "frames/frame8.png")
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

function Skill8:cancelSkillAtk_( event )
    self:removeSelf()
end

function Skill8:onEndEvent_( event )
    self:removeSelf()
end

-- 进入死亡的状态
function Skill8:enterDie_( event )
    
end

return Skill8
