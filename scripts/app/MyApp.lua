
require("config")
require("framework.init")
require("framework.shortcodes")
require("framework.cc.init")

local MyApp = class("MyApp", cc.mvc.AppBase)

function MyApp:ctor()
    MyApp.super.ctor(self)
    self.objects_ = {}
end

function MyApp:run()
    CCFileUtils:sharedFileUtils():addSearchPath("res/")
    CCFileUtils:sharedFileUtils():addSearchPath("res/ccb/")
    self:enterMainScene()
end

function setAnchPos(node,x,y,anX,anY)
    local posX , posY , aX , aY = x or 0 , y or 0 , anX or 0 , anY or 0
    node:setAnchorPoint(ccp(aX,aY))
    node:setPosition(ccp(posX,posY))
end

function MyApp:enterMainScene(  )
	self:enterScene("MainScene", nil, "fade", 0.6, display.COLOR_WHITE)
end

function MyApp:enterFightScene(  )
	self:enterScene("FightScene", nil, "fade", 0.6, display.COLOR_WHITE)
end

function MyApp:enterResultScene(  )
	self:enterScene("FightResultScene", nil, "fade", 0.6, display.COLOR_WHITE)
end

function MyApp:setObject(id, object)
    
    assert(self.objects_[id] == nil, string.format("MyApp:setObject() - id \"%s\" already exists", id))
    self.objects_[id] = object
end

function MyApp:getObject(id)
    assert(self.objects_[id] ~= nil, string.format("MyApp:getObject() - id \"%s\" not exists", id))
    return self.objects_[id]
end

function MyApp:isObjectExists(id)
    return self.objects_[id] ~= nil
end

return MyApp
