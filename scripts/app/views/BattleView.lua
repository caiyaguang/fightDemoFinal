-- 战场视图是BattleField的一个视图对象，对应着BattleField模型对象
-- 保存每一个英雄对象
-- 用来管理英雄对象的宏观运动

local HeroView = import("..views.HeroView")
local SkillModel = import("..models.SkillModel")
local Skill1 = import("..views.Skill1")
local Skill2 = import("..views.Skill2")
local Skill3 = import("..views.Skill3")
local Skill4 = import("..views.Skill4")
local Skill5 = import("..views.Skill5")
local Skill6 = import("..views.Skill6")
local Skill7 = import("..views.Skill7")
local Skill8 = import("..views.Skill8")
local Skill9 = import("..views.Skill9")
local SkillCard = import("..views.SkillCard")
local SkeletonHeroView = import("..views.SkeletonHeroView")

BattleViewOwner = BattleViewOwner or {}
ccb["BattleViewOwner"] = BattleViewOwner

local BattleView = class("BattleView", function()
    local layer = display.newNode()
    require("framework.api.EventProtocol").extend(layer)    -- 添加事件
    return layer
end)

BattleView.BATTLE_ANIMATION_FINISHED = "BATTLE_ANIMATION_FINISHED"
BattleView.INTERRUPT_SKILL_EVENT = "INTERRUPT_SKILL_EVENT"
BattleView.SKILL_ATK_FROM_SM_TO_C_EVENT = "SKILL_ATK_FROM_SM_TO_C_EVENT"

function BattleView:ctor( battleField )
    local  proxy = CCBProxy:create()
    local  node  = CCBuilderReaderLoad("BattleView.ccbi",proxy,BattleViewOwner)
    self.contentLayer_ = tolua.cast(node,"CCLayer")
    self:addChild(self.contentLayer_)

	self.heroViews_ = {}
	self.battleObj_ = battleField
	-- 通过代理注册事件的好处：可以方便的在视图删除时，清理所以通过该代理注册的事件，
    -- 同时不影响目标对象上注册的其他事件
    --
    -- EventProxy.new() --第一个参数是要注册事件的对象，第二个参数是绑定的视图
    -- 如果指定了第二个参数，那么在视图删除时，会自动清理注册的事件
    		-- 进入战场事件的监听

    -- 添加各个英雄视图
    -- self.heros_ = self.battleObj_:getAllHeros() 
 	local cls = self.battleObj_.class
	cc.EventProxy.new(self.battleObj_, self)  
	        -- :addEventListener(cls.ENTER_BATTLE_EVENT, function ( event )
	        -- 	self:onEnterBattleAction_(event)
	        -- end,self)
            :addEventListener(cls.BATTLE_FIELD_INIT_EVENT, self.initHeroViews_,self)
            :addEventListener(cls.BATTLE_FIELD_ENTER_FIELD_EVENT, self.enterFieldAction, self)
            -- :addEventListener(cls.ENTER_SKILL_ATK_EVENT, self.enterSkillAtk_,self)
            -- :addEventListener(cls.DISPLAY_ATK_SKILL_NAME_EVENT, self.displayAtkSkillName_, self)
            :addEventListener(cls.BATTLE_FIELD_ADD_SKILL_EFFECT, self.addEffectLayer, self)
            -- :addEventListener(cls.BATTLE_FIELD_REMOVE_DIE_HERO, self.removeDieHero_, self)
            -- :addEventListener(cls.LEAVE_BATTLE_EVENT, self.heroLvBattleField_, self)


    -- for i=1,#self.heros_ do
    -- 	local hero = self.heros_[i]
    --     -- 创建每个英雄的视图
    -- 	-- local playerView = HeroView.new(hero):pos(0,0):addTo(self)
    --     local playerView = SkeletonHeroView.new(hero,(i - 1) * 10):pos(0,0):addTo(self,(i - 1) * 10,(i - 1) * 10)
    --     self.views_[hero:getNickName()] = playerView
    -- 	-- table.insert(self.views_,playerView)

    --     -- 存储英雄视图到战场模型中
    --     if hero:getSide() == 1 then
    --     --     -- 被动打的
    --         local pos = hero:getPos()
    --         local skillcard = tolua.cast(BattleViewOwner["skillcard"..pos],"CCSprite")
    --         local skillCardView = SkillCard.new(hero:getSkills().giftSkill):pos(skillcard:getPositionX(),skillcard:getPositionY()):addTo(self)
    --         self.battleObj_:setPlayerForKey(hero:getSid(),{model = hero,view = playerView, skillView = skillCardView})
    --     else
    --         self.battleObj_:setPlayerForKey(hero:getSid(),{model = hero,view = playerView})
    --     end
    
    --     if hero:getSide() == 1 then
    --         local pos = hero:getPos()
    --         local scard = tolua.cast(BattleViewOwner["scard"..pos],"CCSprite")
    --         playerView:setPosition(ccp( scard:getPositionX() - display.width / 2, scard:getPositionY() ))
    --     else
    --         local pos = hero:getPos()
    --         local ecard = tolua.cast(BattleViewOwner["ecard"..pos],"CCSprite")
    --         playerView:setPosition(ccp( ecard:getPositionX() + display.width / 2, ecard:getPositionY() ))
    --     end
    -- end

    -- -- 添加技能显示层
    -- self.skillDisplayLayer_ = display.newColorLayer(ccc4(0,0,0,150)):pos(0,0):addTo(self)
    
    -- self.skillDisplayLayer_:setVisible(false)

    -- self.effectView_ = display.newNode():pos(0,0):addTo(self)
    self.players_ = {}
    self.enemys_ = {}
end

-- 对战场模型对象消息的处理方法

-- 初始化各个英雄视图
function BattleView:initHeroViews_( event )
    self.players_ = event.player
    self.enemys_ = event.enemy
    local i = 1
    for k,v in pairs(self.players_) do
        -- 创建每个英雄的视图
        local hero = v
        local playerView = SkeletonHeroView.new(hero,(i - 1) * 10):pos(0,0):addTo(self,(i - 1) * 10,(i - 1) * 10)
        self.heroViews_[hero:getSid()] = playerView
        local pos = hero:getPos()
        local scard = tolua.cast(BattleViewOwner["scard"..pos],"CCSprite")
        playerView:setPosition(ccp( scard:getPositionX() - display.width / 2, scard:getPositionY() ))

        -- 创建每个技能卡的视图
        local skillcard = tolua.cast(BattleViewOwner["skillcard"..pos],"CCSprite")
        local skillCardView = SkillCard.new( hero:getSkills().giftSkill,hero ):pos( skillcard:getPositionX(),skillcard:getPositionY() ):addTo(self)
        i = i + 1
    end

    local i = 1
    for k,enemy in pairs(self.enemys_) do
        -- 创建每个英雄的视图
        local playerView = SkeletonHeroView.new(enemy,(i - 1) * 10):pos(0,0):addTo(self,(i - 1) * 10,(i - 1) * 10)
        self.heroViews_[enemy:getSid()] = playerView
        local pos = enemy:getPos()
        local ecard = tolua.cast(BattleViewOwner["ecard"..pos],"CCSprite")
        playerView:setPosition(ccp( ecard:getPositionX() + display.width / 2, ecard:getPositionY() ))
        i = i + 1
    end
    self.battleObj_:initActionFinished()
end

-- 开始进场的动作
function BattleView:enterFieldAction( event )
    for k,hero in pairs(self.players_) do
        local heroView = self.heroViews_[hero:getSid()]
        local pos = hero:getPos()
        local scard = tolua.cast(BattleViewOwner["scard"..pos],"CCSprite")
        heroView:runAction(CCSequence:createWithTwoActions(CCMoveTo:create(2.5,ccp( scard:getPositionX(),scard:getPositionY() )),CCCallFunc:create(function (  )
            -- 入场完毕
            self.battleObj_:enterBattleFieldFinished( hero )
        end)) )
    end
    for k,enemy in pairs(self.enemys_) do
        local enemyView = self.heroViews_[enemy:getSid()]
        local pos = enemy:getPos()
        local ecard = tolua.cast(BattleViewOwner["ecard"..pos],"CCSprite")
        enemyView:runAction(CCSequence:createWithTwoActions(CCMoveTo:create(2.5,ccp( ecard:getPositionX(),ecard:getPositionY() )),CCCallFunc:create(function (  )
            -- 入场完毕
            self.battleObj_:enterBattleFieldFinished( enemy )
        end)) )
    end
end



-- 返回战场视图对应的战场对象
function BattleView:getBattleField(  )
	return self.battleObj_
end

-- 返回战场视图对应的所有英雄视图
function BattleView:getAllHeroView(  )
	return self.views_
end

function BattleView:HLAddParticleScale( plist, node, pos, duration, z, tag, scaleX, scaleY )
    local ps = CCParticleSystemQuad:create(plist)
    ps:setPosition(pos)
    node:addChild(ps, z, tag)
end

-- 显示一个技能释放提示动画
function BattleView:displayAtkSkillName_( event )
    -- self.skillDisplayLayer_:setVisible(false)
    -- if not self.skillName then
    --     self.skillName = ui.newTTFLabel({
    --             text = event.skill:getNickName(),
    --             size = 48,
    --             color = display.COLOR_RED,
    --         })
    --         :pos(display.cx, display.cy)
    --         :addTo(self.skillDisplayLayer_)
    --     transition.moveBy(self.skillName, {x = -100, y = 0, time = 1, onComplete = function()
    --         self.battleObj_:continueAtk(event.atker,event.targets,event.skill)
    --         self.skillName:removeSelf()
    --         self.skillName = nil
    --         self.skillDisplayLayer_:setVisible(false)
    --         -- 添加技能视图
    --         local atkerView = self.views_[event.atker:getNickName()]
    --         local targetsView = {}
    --         for i=1,#event.targets do
    --             local target = event.targets[i]
    --             targetsView[target:getNickName()] = self.views_[target:getNickName()]
    --         end
    --         self.effectView_:addChild(SkillView.new(event.skill,atkerView,targetsView,event.atker,event.targets))
    --     end})
    -- else
    self.battleObj_:continueAtk(event.atker,event.targets,event.skill)
        -- 
        -- local atkerView = self.views_[event.atker:getNickName()]
        -- local targetsView = {}
        -- for i=1,#event.targets do
        --     local target = event.targets[i]
        --     targetsView[target:getNickName()] = self.views_[target:getNickName()]
        -- end
        -- self.effectView_:addChild(SkillView.new(event.skill,atkerView,targetsView,event.atker,event.targets))
    -- end
    -- local skillName_ = ui.newTTFLabel({
    --             text = "攻击中",
    --             size = 20,
    --             color = display.COLOR_RED,
    --         })
    --         :pos(0,0)
    --         :addTo(self.views_[event.atker:getNickName()])
    -- transition.moveBy(skillName_, {x = -100, y = 0, time = 1, onComplete = function()
    --         skillName_:removeSelf()
    --     end
    --     })
end

-- 技能显示的方法
function BattleView:addEffectLayer( event)
    local atkerView = self.heroViews_[event.atker:getSid()]
    local skill = event.skill
    local targetsView = {}
    if skill:getAtkType() == 0 then
        for i=1,#event.targets do
            -- 单攻和需要播很多单个视图的群攻技能
            local target = event.targets[i]
            targetsView[target:getSid()] = self.heroViews_[target:getSid()]
        end
        local flag = math.random(1,7)
        if flag == 1 then
            self:addChild(Skill3.new(event.skill,atkerView,targetsView,event.atker,event.targets),targetsView[event.targets[1]:getNickName()]:getZorder() + 2)
        elseif  flag == 2 then
            self:addChild(Skill1.new(event.skill,atkerView,targetsView,event.atker,event.targets),targetsView[event.targets[1]:getNickName()]:getZorder() + 2)
        elseif  flag == 3 then
            self:addChild(Skill2.new(event.skill,atkerView,targetsView,event.atker,event.targets),targetsView[event.targets[1]:getNickName()]:getZorder() + 2)
        elseif  flag == 4 then
            self:addChild(Skill4.new(event.skill,atkerView,targetsView,event.atker,event.targets),targetsView[event.targets[1]:getNickName()]:getZorder() + 2)
        elseif  flag == 5 then
            self:addChild(Skill5.new(event.skill,atkerView,targetsView,event.atker,event.targets),targetsView[event.targets[1]:getNickName()]:getZorder() + 2)
        elseif  flag == 6 then
            self:addChild(Skill6.new(event.skill,atkerView,targetsView,event.atker,event.targets),targetsView[event.targets[1]:getNickName()]:getZorder() + 2)
        -- elseif  flag == 7 then
        --     self:addChild(Skill7.new(event.skill,atkerView,targetsView,event.atker,event.targets),targetsView[target:getNickName()]:getZorder() + 2)
        elseif  flag == 7 then
            self:addChild(Skill8.new(event.skill,atkerView,targetsView,event.atker,event.targets),targetsView[event.targets[1]:getNickName()]:getZorder() + 2)
        end
        -- end

        -- self:addChild(Skill9.new(event.skill,atkerView,targetsView,event.atker,event.targets))
    elseif skill:getAtkType() == 1 then
        for i=1,#event.targets do
            local target = event.targets[i]
            targetsView[target:getNickName()] = self.heroViews_[target:getNickName()]
            self:addChild(Skill7.new(event.skill,atkerView,targetsView[target:getNickName()],event.atker,target),targetsView[target:getNickName()]:getZorder() + 2)
        end
        event.skill:enterAtk()
    else
        for i=1,#event.targets do
            local target = event.targets[i]
            targetsView[target:getNickName()] = self.heroViews_[target:getNickName()]
        end
        self:addChild(Skill9.new(event.skill,atkerView,targetsView,event.atker,event.targets),100)
    end
end

-- 播放显示技能动画
function BattleView:playSkillDisplayAni_( event )
    local player = event.playerParam.player
    local skill = event.playerParam.skill
    -- 开始技能显示动画
    self.skillDisplayLayer_:setVisible(true)
    self:HLAddParticleScale( "ccb/ccbResources/particle/eff_page_504.plist", self.skillDisplayLayer_, ccp(display.cx,display.cy), 5, 102, 100,1,1 )


    local skillName = ui.newTTFLabel({
            text = "葵花宝典",
            size = 48,
            color = display.COLOR_RED,
        })
        :pos(display.cx, display.cy)
        :addTo(self.skillDisplayLayer_)
    transition.moveBy(skillName, {x = -100, y = 0, time = 1.5, onComplete = function()
        skillName:removeSelf()
    end})

    local actArray = CCArray:create()
    local delayTime = CCDelayTime:create(1)
    local callBack = CCCallFunc:create(function(  )
        self:dispatchEvent({name = BattleView.BATTLE_ANIMATION_FINISHED,actType = "playskill"})
        self.skillDisplayLayer_:setVisible(false)
    end)
    actArray:addObject(delayTime)
    actArray:addObject(callBack)
    self:runAction(CCSequence:create(actArray))
end

-- 当释放技能的时候创建技能图像
function BattleView:addSkillView( atker,target )
    -- 创建技能的对象
end
-- 进入技能攻击的状态
function BattleView:enterSkillAtk_( event )
    self.skillAtkAtker_ = event.atker
    self.skillAtkTarget_ = event.targetModel
    self.skillAtkSkill_ = event.skill
    -- 创建技能对象
    self.currentAtkSkill_ = SkillModel.new({
            name = self.skillAtkSkill_.name,
            stype = self.skillAtkSkill_.stype,
            damage = self.skillAtkSkill_.atk,
            atker = self.skillAtkAtker_,
            target = self.skillAtkTarget_,
            skill = self.skillAtkSkill_,
            battleview = self
        })
    self.currentAtkSkillView_ = SkillView.new(self.currentAtkSkill_,self.battleObj_)
    self:addChild(self.currentAtkSkillView_)
    self.currentAtkSkill_:enterAtk()
    -- 让自身监听技能动作的变化
    local cls = self.currentAtkSkill_.class
    cc.EventProxy.new(self.currentAtkSkill_, self)  
        :addEventListener(cls.SENT_TO_CONTROLLER_DAMAGE, self.reciveInfoFromSkill_,self)
    -- self.currentAtkSkill_ = nil
    -- 设置攻击者和被攻击者的z值
end

-- 英雄死亡后消失的方法
function BattleView:removeDieHero_( event )
    local hero = event.hero
    self.views_[hero:getNickName()]:runAction(CCFadeOut:create(1.5))
end

function BattleView:reciveInfoFromSkill_( event )
    self:dispatchEvent({name = BattleView.SKILL_ATK_FROM_SM_TO_C_EVENT , atker = event.atker, targets = event.targets, skill = event.skill})

end

-- 进入战场的动作
function BattleView:onEnterBattleAction_( event )
    for k,v in pairs(self.views_) do
        local playerView = v
        local hero = playerView:getHeroInfo()
        local array = CCArray:create()
        local move
        if hero:getSide() ~= 1 then
            local pos = hero:getPos()
            local ecard = tolua.cast(BattleViewOwner["ecard"..pos],"CCSprite")
            move = CCMoveTo:create(4,ccp(ecard:getPositionX(),ecard:getPositionY()))
        else
            local pos = hero:getPos()
            local scard = tolua.cast(BattleViewOwner["scard"..pos],"CCSprite")
            move = CCMoveTo:create(4,ccp(scard:getPositionX(),scard:getPositionY()))
        end
        
        local delay = CCDelayTime:create(1)
        local callBack = CCCallFunc:create(function(  )
            -- 进场完毕，通知战场模型进场完毕
            self.battleObj_:enterBattleFieldEnd_()
        end)
        array:addObject(move)
        array:addObject(callBack)
        array:addObject(delay)
        
        local seq = CCSequence:create(array)
        playerView:runAction(seq)
    end
end

-- 战斗结束，立场动画
function BattleView:heroLvBattleField_(  )
    local flag = 1
    if self.battleObj_:whichSideWin() == 1 then
        flag = 1
    else
        flag = -1
    end
    for k,v in pairs(self.views_) do
        local playerView = v
        local move
        local hero = playerView:getHeroInfo()
        if not hero:isDead() then
            local pos = hero:getPos()
            local ecard = tolua.cast(BattleViewOwner["ecard"..pos],"CCSprite")
            move = CCMoveBy:create(4,ccp(1000 * flag,0))
            playerView:runAction(CCSequence:createWithTwoActions(move,CCCallFunc:create(function (  )
                -- 离场完毕
                -- playerView:setPosition(ccp(ecard:getPositionX() + display.width / 2,ecard:getPositionY()))
                -- 通知战场模型可以进行下一轮
                self.battleObj_:tellBattleFieldLvFightEnd()
            end)))
        end
    end
end

return BattleView
