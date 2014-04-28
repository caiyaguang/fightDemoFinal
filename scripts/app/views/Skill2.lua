--[[
    技能的视图，根据技能属性，创建技能视图，支持单个飞出群攻 统一群攻 单攻
    -- 当技能做完，可以对敌方进行伤害的时候，调用父类的方法，把像敌方发送伤害信息的方法打开
]]

local Skill2 = class("Skill2", function()
    local layer = display.newNode()
    require("framework.api.EventProtocol").extend(layer)    -- 添加事件
    return layer
end)

function Skill2:ctor( skillModel,atkerView,targetsView,atker,targets )
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
function Skill2:onRemoveSelf_( event )
    self:removeSelf()
    -- self.skillModel_:endAtk()
end

-- 进入攻击的状态
function Skill2:beginAtk_( event )
    -- 在攻击的动作中会调用父方法
    local atker = event.atker
    local targets = event.targets
    for i=1,#targets do
        local target = targets[i]
        local arraw = display.newSprite("ccb/ccbResources/particle/tauren_effect_2.png")
        arraw:setVisible(false)
        arraw:setScaleY(0.4)
        if atker:getSide() == 0 then
            arraw:setPosition(ccp(self.atkerView_:getPositionX() - 20,self.atkerView_:getPositionY() + 30))
            arraw:setScaleX(-0.4)
        else 
            arraw:setPosition(ccp(self.atkerView_:getPositionX() + 20,self.atkerView_:getPositionY() + 30))
            arraw:setScaleX(0.4)
        end
        self:addChild(arraw)
        local targetview = self.targetsView_[target:getNickName()]
        local delay = CCDelayTime:create(0.7)
        local callBack1 = CCCallFunc:create(function(  )
            arraw:setVisible(true)
        end)
        local moveTo = CCMoveTo:create(0.15,ccp(targetview:getPositionX(),targetview:getPositionY()))
        local callBack2 = CCCallFunc:create(function (  )
            atker:onAtkSuccess(targets,self.skillModel_)
            -- atker:onHeroViewActionOver()
            arraw:removeSelf(true)
            if i == #targets then
                self.skillModel_:endAtk()
            end
        end)
        local array = {callBack1,moveTo,callBack2}
        local actArray = CCArray:create()
        for i=1,#array do
            actArray:addObject(array[i])
        end
        arraw:runAction(CCSequence:create(actArray))
    end
end

function Skill2:cancelSkillAtk_( event )
    self:removeSelf()
end

function Skill2:onEndEvent_( event )
    self:removeSelf()
end

-- 进入死亡的状态
function Skill2:enterDie_( event )
    
end

return Skill2
