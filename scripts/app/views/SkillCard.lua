
--[[--

“英雄”的技能卡片视图

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

local SkillCard = class("SkillCard", function()
    local layer = display.newNode()
    require("framework.api.EventProtocol").extend(layer)
    return layer
end)

SkillCard.IMG_URL = "ccb/ccbResources/public/"
SkillCard.AVATAR_IMG_URL = "ccb/ccbResources/avatar/"

-- 动作完成后的事件
SkillCard.ANIMATION_FINISHED_EVENT = "ANIMATION_FINISHED_EVENT"



function SkillCard:ctor(skill,hero)
    local cls = skill.class
    cc.EventProxy.new(skill, self)
        :addEventListener(cls.MP_CHANGE_EVENT, self.onMPChange_, self)
        :addEventListener(cls.SKILL_CD_CHANGE_EVENT, self.skillCdTimeChange_, self)
        :addEventListener(cls.SKILL_ENABLE_ATK_EVENT, self.enableAtkState_, self)
        :addEventListener(cls.SKILL_DISABLE_ATK_EVENT, self.disableAtkState_, self)

    local cls = hero.class
    cc.EventProxy.new(hero, self)
        :addEventListener(cls.HERO_HP_CHANGE_EVENT, self.onHeroHpChange_, self)
        :addEventListener(cls.HERO_MP_CHANGE_EVENT, self.onMPChange_, self)
        :addEventListener(cls.HERO_CURRENT_IN_DIZZY_EVENT, self.onHeroInDizzy_, self)
        :addEventListener(cls.HERO_RELIEVE_DIZZY_EVENT, self.onHeroLeaveDizzy_, self)

    self.skill_ = skill
    self.hero_ = hero
    self.sprite_ = display.newSprite():addTo(self)  -- 所有sprite的容器

    self.releaseSkillFlag_ = false

    local rank = math.random(1,4)

    self.rankFrame_ = display.newSprite(SkillCard.AVATAR_IMG_URL.."avatar_"..rank..".jpg"):pos(0,0):addTo(self.sprite_)
    
    self.skillBtn_ = ui.newImageMenuItem({
        image = SkillCard.IMG_URL.."frame_"..rank..".png",
        imageSelected = SkillCard.IMG_URL.."frame_"..rank..".png",
        x = 0,
        y = 0,
        tag = 1,
        listener = function ( tag )
            self:onSkillTaped_(tag)
        end ,
    })


    local menu = ui.newMenu({self.skillBtn_})
    self:addChild(menu)


    -- 冷却时间
    self.skillCDLabel_ = ui.newTTFLabel({
        text = "",
        size = 22,
        color = display.COLOR_RED,
    }):pos(0,0)
    :addTo(self.sprite_, 1000)

    self.hpProgress_ = CCProgressTimer:create(CCSprite:create("pic/hp_green.png"))
    self.hpProgress_:setType(kCCProgressTimerTypeBar)
    self.hpProgress_:setMidpoint(CCPointMake(0, 0))
    self.hpProgress_:setBarChangeRate(CCPointMake(1, 0))
    self.hpProgress_:setPosition(ccp(0,-63))
    self.sprite_:addChild(self.hpProgress_,0, 101)
    self.hpProgress_:setPercentage(0)

    self.mpProgress_ = CCProgressTimer:create(CCSprite:create("pic/yellow_bar.png"))
    self.mpProgress_:setType(kCCProgressTimerTypeBar)
    self.mpProgress_:setMidpoint(CCPointMake(0, 0))
    self.mpProgress_:setBarChangeRate(CCPointMake(1, 0))
    self.mpProgress_:setPosition(ccp(0,-80))
    self.sprite_:addChild(self.mpProgress_,0, 101)
    self.mpProgress_:setPercentage(self.hero_:getMp(  ) / self.skill_:getTotalMp(  ) * 100)
    -- -- 这个方法用来设置颜色层叠
    -- setEnableRecursiveCascading(self,true)
    self.canReleaseSkill_ = 0   -- 是否可以点击释放技能

    self.heroNameLabel = ui.newTTFLabel({
        text = self.skill_:getNickName(),
        size = 12,
        color = display.COLOR_GREEN,
    }):pos(0,-40)
    :addTo(self.sprite_, 1000)

    -- 添加可点击提示
    local cache = CCSpriteFrameCache:sharedSpriteFrameCache()
    cache:addSpriteFramesWithFile("pic/treasureCard.plist")
    self.lightSprite_ = CCSprite:createWithSpriteFrameName("treasureCard_roundFrame_1.png")
    self.lightSprite_:setScale(1.1)
    local animFrames = CCArray:create()
    for j = 1, 3 do
        local frameName = string.format("treasureCard_roundFrame_%d.png",j)
        local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(frameName)
        animFrames:addObject(frame)
    end
    local animation = CCAnimation:createWithSpriteFrames(animFrames, 0.5)
    local animate = CCAnimate:create(animation)
    self.lightSprite_:runAction(CCRepeatForever:create(animate))
    self.sprite_:addChild(self.lightSprite_)
    self.lightSprite_:setVisible(false)
end


function SkillCard:onMpOrCDChange_( event )
    -- if self.skill_:getCdTime() <= 0 and self.hero_:getMp() >= self.skill_:getTotalMp() and self.hero_:getDizzy() <= 0 then
    --     self.lightSprite_:setVisible(true)
    -- else
    --     self.lightSprite_:setVisible(false)
    -- end
end

-- 对技能模型的消息的处理
function SkillCard:enableAtkState_( event )
    self.releaseSkillFlag_ = true
    self.lightSprite_:setVisible(true)
end

function SkillCard:disableAtkState_( event )
    self.releaseSkillFlag_ = false
    self.lightSprite_:setVisible(false)
end

function SkillCard:skillCdTimeChange_(  )
    self.skillCDLabel_:setString(self.skill_:getCdTime() > 0 and math.ceil(self.skill_:getCdTime()) or "")
end

function SkillCard:onHeroHpChange_( event )
    self.hpProgress_:runAction(CCProgressFromTo:create(0.1, self.hpProgress_:getPercentage(), event.hp / event.totalhp * 100))
end
-- 判断技能是否可以释放
function SkillCard:getReleaseSkillFlag( )
    -- return self.skill_:getMp(  )  >= self.skill_:getTotalMp(  ) and self.skill_:getCdTime() <= 0 
end

function SkillCard:onSkillTaped_( tag )
    if self.releaseSkillFlag_ then
        self.skill_:playerLaunchAtk()
    end
end
function SkillCard:onMPChange_( event )
    self.mpProgress_:setPercentage(self.hero_:getMp(  ) / self.skill_:getTotalMp(  ) * 100)
end
function SkillCard:onMPFull_( event )
    self.mpProgress_:setPercentage(self.skill_:getMp(  ) / self.skill_:getTotalMp(  ) * 100)
end

function SkillCard:setCostomColor()
    setEnableRecursiveCascading(self,true)
end

function SkillCard:onHeroInDizzy_( event )

end

function SkillCard:onHeroLeaveDizzy_( event )

end

return SkillCard
