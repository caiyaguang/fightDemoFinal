
--[[--

“英雄”的视图

视图注册模型事件，从而在模型发生变化时自动更新视图

]]
-- 一个设置节点层叠显示颜色的方法，用来解决一个引擎bug
local function setEnableRecursiveCascading(node, enable)
    if node ~= nil then
        node:setCascadeColorEnabled(enable)
        node:setCascadeOpacityEnabled(enable)
    end

    local obj = nil
    local children = node:getChildren()
    if children == nil then
        return
    end

    local i = 0
    local len = children:count()
    for i = 0, len - 1, 1 do
        local  child = tolua.cast(children:objectAtIndex(i), "CCNode")
        setEnableRecursiveCascading(child, enable)
    end
end

local HeroView = class("HeroView", function()
    local layer = display.newNode()
    require("framework.api.EventProtocol").extend(layer)
    return layer
end)

HeroView.IMG_URL = "ccb/ccbResources/herobust/"

-- 动作完成后的事件
HeroView.ANIMATION_FINISHED_EVENT = "ANIMATION_FINISHED_EVENT"

function HeroView:ctor(hero)
    -- self:setCascadeOpacityEnabled(true)
    local cls = hero.class

    -- 通过代理注册事件的好处：可以方便的在视图删除时，清理所以通过该代理注册的事件，
    -- 同时不影响目标对象上注册的其他事件
    --
    -- EventProxy.new() --第一个参数是要注册事件的对象，第二个参数是绑定的视图
    -- 如果指定了第二个参数，那么在视图删除时，会自动清理注册的事件
    cc.EventProxy.new(hero, self)
        :addEventListener(cls.KILL_EVENT, self.onKill_, self)
        :addEventListener(cls.ATACKING_EVENT, self.onAtacking_, self)
        :addEventListener(cls.UNDERATK_EVENT, self.underAtk_, self)
        :addEventListener(cls.DECREASE_HP_EVENT, self.decreaseHp_, self)
        :addEventListener(cls.HERO_CURRENT_IN_DIZZY_EVENT, self.enterDizzy_, self)
        :addEventListener(cls.HERO_RELIEVE_DIZZY_EVENT, self.relieveDizzy_, self)
        :addEventListener(cls.HERO_MP_CHANGE_EVENT, self.heroMpChange_, self)
        :addEventListener(cls.END_ATK_EVENT, self.onAtkEnd_, self)

    self.hero_ = hero
    self.content = display.newSprite():addTo(self)  -- 用来放置死亡后灰色的sprite
    self.sprite_ = display.newSprite():addTo(self)  -- 所有sprite的容器

    -- rankFrame_ 就是最外层的框  rotateBg_ 是为了做一个攻击动画，可以忽略不看
    if self.hero_:getSide() == 1 then
        self.rotateBg_ = display.newSprite():pos(-100,-200):addTo(self.sprite_)
        self.rankFrame_ = display.newSprite("ccb/ccbResources/cardImage/frame_4.png"):pos(100,200):addTo(self.rotateBg_)
        self.heroname_ = ui.newTTFLabel({
            text = self.hero_:getNickName(),
            size = 22,
            color = display.COLOR_BLUE,
        }):pos(0,-70)
        :addTo(self, 1000)

    else 
        self.rotateBg_ = display.newSprite():pos(100,200):addTo(self.sprite_)
        self.rankFrame_ = display.newSprite("ccb/ccbResources/cardImage/frame_4.png"):pos(-100,-200):addTo(self.rotateBg_)
        self.heroname_ = ui.newTTFLabel({
            text = self.hero_:getNickName(),
            size = 22,
            color = display.COLOR_GREEN,
        }):pos(0,-70)
        :addTo(self, 1000)

    end

    
    self.rankFrame_:setScale(0.4)

    self.rankSprite = display.newSprite("ccb/ccbResources/cardImage/rank_4.png"):pos(0,0):addTo(self.rankFrame_)
    display.align(self.rankSprite, display.LEFT_BOTTOM, 0, 0)

    self.heroBust_ = display.newSprite(HeroView.IMG_URL..self.hero_:getImage()):addTo(self.rankFrame_)
    local size = self.rankFrame_:getContentSize()
    display.align(self.heroBust_, display.CENTER, size.width / 2, size.height / 2 + 40)
    
    self.progressBg = display.newLayer():addTo(self.rankFrame_)
    self.progressBg:setContentSize(CCSizeMake(251,29))
    display.align(self.progressBg, display.LEFT_BOTTOM, 65,0)
    self.progressBg:setScaleX(0.86)
    self.progressBg:setScaleY(1.3)

    self.progressBg:setCascadeColorEnabled(true)
    self.progressBg:setCascadeOpacityEnabled(true)

    local progressSize = self.progressBg:getContentSize()

    self.progress_ = CCProgressTimer:create(CCSprite:create("ccb/ccbResources/public/awardPro.png"))
    self.progress_:setType(kCCProgressTimerTypeBar)
    self.progress_:setMidpoint(CCPointMake(0, 0))
    self.progress_:setBarChangeRate(CCPointMake(1, 0))
    self.progress_:setPosition(ccp(progressSize.width / 2,progressSize.height / 2))
    self.progressBg:addChild(self.progress_,0, 101)
    self.progress_:setPercentage(hero:getHp(  ) / hero:getTotalHp(  ) * 100)

    -- 这个方法用来设置颜色层叠
    setEnableRecursiveCascading(self,true)

    -- 眩晕状态标示
    self.dizzyStateLabel_ = nil

end

function HeroView:getHeroInfo(  )
    return self.hero_
end

function HeroView:setCostomColor()

    setEnableRecursiveCascading(self,true)
end

-- 对来着英雄模型消息的回调
function HeroView:enterDizzy_(  )
    -- 进入眩晕模式
    if not self.dizzyStateLabel_ then
        self.dizzyStateLabel_ = ui.newTTFLabel({
            text = "眩晕中",
            size = 22,
            color = display.COLOR_RED,
        }):pos(0,80)
        :addTo(self, 1000)
    end
end

function HeroView:relieveDizzy_(  )
    if self.dizzyStateLabel_ then
        self.dizzyStateLabel_:removeSelf()
        self.dizzyStateLabel_ = nil
    end
end

-- 英雄的魔法值发生改变
function HeroView:heroMpChange_(  )
    
end

-- 正在减血
function HeroView:decreaseHp_( event )
    local damageLabel = ui.newTTFLabel({
        text = "-"..event.damage,
        size = 22,
        color = display.COLOR_RED,
    }):pos(0,90)
    :addTo(self, 1000)
    transition.moveBy(damageLabel, {y = 50, time = 1, onComplete = function()
        damageLabel:removeSelf()
    end})
    self.progress_:runAction(CCProgressFromTo:create(0.5, self.progress_:getPercentage(), self:getHeroInfo():getHp(  ) / self:getHeroInfo():getTotalHp(  ) * 100))
end

-- 划刀的攻击
function HeroView:onAtacking_( event )
    
    local targets = event.targets
    
    local actArray = CCArray:create()

    local scale1 = CCRotateBy:create(0.03,-5)
    local delayTime1 = CCDelayTime:create(0.04)
    local scale2 = CCRotateBy:create(0.03,-5)
    local delayTime2 = CCDelayTime:create(0.03)
    local scale3 = CCRotateBy:create(0.03,-5)
    local delayTime3 = CCDelayTime:create(0.1)
    local scale4 = CCRotateBy:create(0.001,25)
    -- 开始对目标进行伤害
    local sendInfoToTarget = CCCallFunc:create(function (  )
        --[[    告诉自己的英雄模型，攻击成功,可以开始对敌方进行减血等操作        ]]
        -- 需要技能攻击特效的攻击
        self:getHeroInfo(  ):beginEffectAtk(event.targets,event.skill)
        -- self:getHeroInfo(  ):onAtkSuccess()
    end)
    local delayTime4 = CCDelayTime:create(0.1)
    local scale5 = CCRotateBy:create(0.02,-10)
    local delayTime5 = CCDelayTime:create(0.01)
    local scale6 = CCRotateBy:create(0.02, -5)
    local delayTime6 = CCDelayTime:create(0.01)
    local scale7 = CCRotateBy:create(0.01,5)
    local callBack = CCCallFunc:create(function (  )
        -- 告诉英雄模型自己攻击动作执行完毕可以继续下一轮攻击
        self:getHeroInfo(  ):onHeroViewActionOver( "atk" )
    end)
    local tempArray = { scale1,delayTime1,scale2,delayTime2,
                        scale3,delayTime3,scale4,
                        sendInfoToTarget,delayTime4,
                        scale5,delayTime5,scale6,
                        delayTime6,scale7,callBack
                     }
    for i=1,#tempArray do
        actArray:addObject(tempArray[i])
    end

    return self.rotateBg_:runAction(CCSequence:create(actArray))
end
-- 当英雄死亡的时候的动作
-- 1 使参数图片不可见
-- 2 新建灰白图片
function HeroView:onKill_(event)
    self:runAction(CCSequence:createWithTwoActions(CCFadeOut:create(0.05),CCCallFunc:create(function (  )
        self:getHeroInfo(  ):onHeroViewActionOver( "kill" )
    end)) )
    self.rankFrame1_ = CCGraySprite:create("ccb/ccbResources/cardImage/frame_4.png")
    self.rankFrame1_:setScale(0.4)
    self.content:addChild(self.rankFrame1_)
   
    self.rankSprite1 = CCGraySprite:create("ccb/ccbResources/cardImage/rank_4.png")
    self.rankSprite1:setAnchorPoint(ccp(0,0))
    self.rankFrame1_:addChild(self.rankSprite1)

    self.heroBust1_ = CCGraySprite:create(HeroView.IMG_URL..self.hero_:getImage())
    self.rankFrame1_:addChild(self.heroBust1_)
    local size = self.rankFrame1_:getContentSize()
    self.heroBust1_:setPosition(ccp(size.width / 2, size.height / 2 + 40))
    self.animation:playByIndex(1)


end

-- 当攻击结束，恢复本来状态
function HeroView:onAtkEnd_( event )

    self.rotateBg_:stopAllActions()
    local rotateback = CCRotateTo:create(0.1,0)
    self.rotateBg_:runAction(rotateback)
end

-- 正在遭受攻击动作
-- 当动作结束会发送动作完成的消息
function HeroView:underAtk_( event )
    local array = CCArray:create()
    local moveUp = CCMoveBy:create(0.1,ccp(0,10))
    local tintToRed = CCTintTo:create(0.01,255,0,0)
    local moveDown = CCMoveBy:create(0.1,ccp(0,-20))
    local tintBack = CCTintTo:create(0.01,255,255,255)
    local moveBack = CCMoveBy:create(0.1,ccp(0,10))
    local delayTime = CCDelayTime:create(0.2)
    local callBack = CCCallFunc:create(function (  )
        self:getHeroInfo(  ):onHeroViewActionOver( "underatk" )
    end)
    
    array:addObject(moveUp)
    array:addObject(tintToRed)
    array:addObject(moveDown)
    array:addObject(tintBack)
    array:addObject(moveBack)
    array:addObject(delayTime)
    array:addObject(callBack)
    self:runAction(CCSequence:create(array))


end

return HeroView
