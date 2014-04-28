
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

local SkeletonHeroView = class("SkeletonHeroView", function()
    local layer = display.newNode()
    require("framework.api.EventProtocol").extend(layer)
    return layer
end)

SkeletonHeroView.IMG_URL = "ccb/ccbResources/herobust/"

-- 动作完成后的事件
SkeletonHeroView.ANIMATION_FINISHED_EVENT = "ANIMATION_FINISHED_EVENT"

function SkeletonHeroView:ctor(hero,zorder)
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
        :addEventListener(cls.ENTER_BATTLEFIELD_END, self.onEndEnterField_, self)
        :addEventListener(cls.ENTER_WALK_EVENT, self.enterWalkState_, self)
        :addEventListener(cls.SKILL_ATK_BE_CANCEL_EVENT, self.beCancelAtk_, self)
        :addEventListener(cls.ENTER_IDLE_EVENT, self.enterIdle_, self)

    self.hero_ = hero
    self.content = display.newSprite():addTo(self)  -- 用来放置死亡后灰色的sprite
    self.sprite_ = display.newSprite():addTo(self)  -- 所有sprite的容器
    self.zorder_ = zorder
    -- 这个方法用来设置颜色层叠

    -- 眩晕状态标示

    -- 骨骼动画测试
    local manager = CCArmatureDataManager:sharedArmatureDataManager()

    manager:addArmatureFileInfo("bones/EnemyAnimation0.png","bones/EnemyAnimation0.plist","bones/tauren.ExportJson")

    manager:addArmatureFileInfo("bones/Hero/HeroAnimation0.png","bones/Hero/HeroAnimation0.plist","bones/Hero/Hero.ExportJson")

    -- manager:addArmatureFileInfo("bones/KNight/weapon.png","bones/KNight/weapon.plist","bones/KNight/weapon.xml")

    self.dragon = CCNodeExtend.extend(CCArmature:create("tauren"))
    -- local boneDic = self.dragon:getBoneDic()
    self.dragon:connectMovementEventSignal(function(__evtType, __moveId)
            self:sendAtkInfo(__evtType,__moveId)
        end)
    self.animation = self.dragon:getAnimation()
    self.animation:setAnimationScale(0.3) -- Flash fps is 24, cocos2d-x is 60
    -- self.animation:playByIndex(1)
    -- 播放参数意义
    -- 进入动画需要补的帧数
    -- 动画播放帧数 如果小于0使用编辑器设置的帧数
    -- 是否循环 大于0 循环 等于0不循环 小于0 按编辑器设置
    self.animation:play("loading",6,-1,1)
    self.dragon:setScaleY(0.5)
    if self.hero_:getSide() == 0 then
        self.dragon:setScaleX( -0.5 )
    else
        self.dragon:setScaleX( 0.5 )
    end
    self.sprite_:addChild(self.dragon)

    self.weaponNames_ = {"ax.png", "weapon_f-sword.png", "weapon_f-sword2.png", "weapon_f-sword3.png", "weapon_f-sword4.png", "weapon_f-sword5.png", "weapon_f-knife.png", "weapon_f-hammer.png"}

    -- self.displayData_ = CCSpriteDisplayData:create()
    -- for i=1,#self.weaponNames_ do
    --     self.displayData_:setParam(self.weaponNames_[i])
    --     self.dragon:getBone("ax"):addDisplay(self.displayData_, i)
    -- end

    -- 添加血量条
    self.hpBarBg_ = display.newSprite("pic/hp_bar_bg.png"):pos(0,50):addTo(self.sprite_)

    local progressSize = self.hpBarBg_:getContentSize()
    self.progress_ = CCProgressTimer:create(CCSprite:create("pic/hp_bar.png"))
    self.progress_:setType(kCCProgressTimerTypeBar)
    self.progress_:setMidpoint(CCPointMake(0, 0))
    self.progress_:setBarChangeRate(CCPointMake(1, 0))
    self.progress_:setPosition(ccp(progressSize.width / 2,progressSize.height / 2))
    self.hpBarBg_:addChild(self.progress_,0, 101)
    self.progress_:setPercentage(hero:getHp(  ) / hero:getTotalHp(  ) * 100)

    self.hpBarBg_:setVisible(false)
    self.heroNickName = ui.newTTFLabel({
        text = self.hero_:getNickName(),
        size = 18,
        color = display.COLOR_BLUE,
    }):pos(0,-75)
    :addTo(self, 1000)

    setEnableRecursiveCascading(self,true)
    
    self.dragon:getBone("ax"):changeDisplayByIndex(math.random(0,#self.weaponNames_ - 1),true)

    display.addSpriteFramesWithFile("buff/buff2.plist", "buff/buff2.png")
end

function SkeletonHeroView:sendAtkInfo( evtType,moveId )
    if evtType == 1 and moveId == "attack" then
        self:getHeroInfo(  ):beginEffectAtk( self.targets_,self.skill_ )
    end
    if evtType == 1 and moveId == "run" then
        self.animation:play("loading")
    end 
    if evtType == 2 and moveId == "smitten" then
        self.animation:play("loading")
    end 
    if evtType == 2 and moveId == "death" then
        self.animation:stop()
    end
end

function SkeletonHeroView:getHeroInfo(  )
    return self.hero_
end

function SkeletonHeroView:getZorder(  )
    return self.zorder_
end

function SkeletonHeroView:setCostomColor()

    setEnableRecursiveCascading(self,true)
end

-- 对来着英雄模型消息的回调
function SkeletonHeroView:enterDizzy_(  )
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

function SkeletonHeroView:beCancelAtk_(  )
    local beCancelLabel = ui.newTTFLabel({
        text = "被打断",
        size = 22,
        color = display.COLOR_BLACK,
    }):pos(0,70)
    :addTo(self, 1000)
    transition.moveBy(beCancelLabel, {y = 50, time = 0.8, onComplete = function()
        beCancelLabel:removeSelf()
    end})
end

function SkeletonHeroView:relieveDizzy_(  )
    if self.dizzyStateLabel_ then
        self.dizzyStateLabel_:removeSelf()
        self.dizzyStateLabel_ = nil
    end
end

-- 英雄的魔法值发生改变
function SkeletonHeroView:heroMpChange_(  )
    
end

-- 正在减血
function SkeletonHeroView:decreaseHp_( event )
    local damageLabel = ui.newTTFLabel({
        text = "-"..event.damage,
        size = 22,
        color = display.COLOR_RED,
    }):pos(0,90)
    :addTo(self, 1000)
    damageLabel:setScale(0.2)
    local array = CCArray:create()
    array:addObject(CCScaleTo:create(0.02,1.5))
    array:addObject(CCDelayTime:create(0.2))
    array:addObject(CCScaleTo:create(0.4,1))
    damageLabel:runAction(CCSequence:create(array))
    transition.moveBy(damageLabel, {y = 50, time = 0.8, onComplete = function()
        damageLabel:removeSelf()
    end})
    self.progress_:runAction(CCProgressFromTo:create(0.5, self.progress_:getPercentage(), self:getHeroInfo():getHp(  ) / self:getHeroInfo():getTotalHp(  ) * 100))
end

-- 划刀的攻击
function SkeletonHeroView:onAtacking_( event )
    -- self.animation:resume()
    
    self.animation:play("attack",2,-1,1)
    -- self.animation:playByIndex(1)
    -- self.animation:resume()

    self.targets_ = event.targets
    self.skill_ = event.skill

    -- local targets = event.targets

    -- local skillEffect = display.newSprite("#buff2_0.png"):addTo(self.sprite_)
    -- -- skillEffect:setScale(2)
    -- local frames1 = display.newFrames("buff2_%d.png", 0, 12)
    -- local animation1 = display.newAnimation(frames1, 1 / 12)
    -- local frames3 = display.newFrames("buff2_%d.png", 12, 12)
    -- local animation3 = display.newAnimation(frames3, 1 / 12)

    -- local actions = {}
    -- skillEffect:setVisible(false)
    -- actions[#actions + 1] = CCShow:create()
    -- actions[#actions + 1] = CCAnimate:create(animation1)
    -- actions[#actions + 1] = CCCallFunc:create(function (  )
    --     self:getHeroInfo():addSkillEffect(event.targets,self.skill_)
    --     end)
    -- actions[#actions + 1] = CCAnimate:create(animation3)
    -- actions[#actions + 1] = CCCallFunc:create(function (  )
    --     self:getHeroInfo(  ):onHeroViewActionOver( "atk" )
    --     end)
    -- actions[#actions + 1] = CCRemoveSelf:create()
    -- local action
    -- if #actions > 1 then
    --     action = transition.sequence(actions)
    -- else
    --     action = actions[1]
    -- end
    -- skillEffect:runAction(action)
    
    local actArray = CCArray:create()

    local delayTime1 = CCDelayTime:create(15 * 1 / 24)
    -- 开始对目标进行伤害
    local sendInfoToTarget = CCCallFunc:create(function (  )
        --[[    告诉自己的英雄模型，攻击成功,可以开始对敌方进行减血等操作        ]]
        -- 需要技能攻击特效的攻击
        -- self:getHeroInfo(  ):beginEffectAtk(event.targets,event.skill)
        -- self:getHeroInfo(  ):onAtkSuccess()
        -- 发出技能
        self:getHeroInfo():addSkillEffect(event.targets,self.skill_)
    end)
    local delayTime4 = CCDelayTime:create(6 * 1 / 24)
    local callBack = CCCallFunc:create(function (  )
        -- 告诉英雄模型自己攻击动作执行完毕可以继续下一轮攻击
        self:getHeroInfo(  ):onHeroViewActionOver( "atk" )
    end)
    local tempArray = { delayTime1,sendInfoToTarget,delayTime4,callBack }
    for i=1,#tempArray do
        actArray:addObject(tempArray[i])
    end

    return self:runAction(CCSequence:create(actArray))
end
-- 当英雄死亡的时候的动作
-- 1 使参数图片不可见
-- 2 新建灰白图片
function SkeletonHeroView:onKill_(event)
    -- self.animation:resume()
    self.animation:play("death",6,-1,0)
    self:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1 / 24 * 30),CCCallFunc:create(function (  )
        self:getHeroInfo(  ):onHeroViewActionOver( "kill" )
    end)) )
end

-- 当攻击结束，恢复本来状态
function SkeletonHeroView:onAtkEnd_( event )
    -- 停止自身的所用动作
    -- self.animation:playByIndex(1)
    -- self.animation:resume()
    self.animation:play("loading",6,-1,1)

    self:stopAllActions()
end

function SkeletonHeroView:enterIdle_( event )
    self.animation:play("loading",6,-1,1)
end

-- 进入战场动作结束
function SkeletonHeroView:onEndEnterField_( event )
    self.animation:play("loading",6,-1,1)
end

function SkeletonHeroView:enterWalkState_( event )
    self.animation:play("run",6,-1,1)
end

-- 正在遭受攻击动作
-- 当动作结束会发送动作完成的消息
function SkeletonHeroView:underAtk_( event )
    self.hpBarBg_:setVisible(true)
    local array = CCArray:create()
    local moveUp = CCMoveBy:create(0.1,ccp(0,10))
    local tintToRed = CCTintTo:create(0.01,255,0,0)
    local moveDown = CCMoveBy:create(0.1,ccp(0,-20))
    local tintBack = CCTintTo:create(0.01,255,255,255)
    local moveBack = CCMoveBy:create(0.1,ccp(0,10))
    local delayTime = CCDelayTime:create(0.2)
    local callBack = CCCallFunc:create(function (  )
        self.hpBarBg_:setVisible(false)
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
    -- self.animation:playByIndex(1)
    -- self.animation:pause()
    -- self.animation:resume()
    self.animation:play("smitten",6,-1,0)


end

return SkeletonHeroView
