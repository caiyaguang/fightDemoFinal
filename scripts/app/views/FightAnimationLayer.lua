
require("config")
require("framework.init")
require("framework.shortcodes")
require("framework.cc.init")

local MyApp = class("MyApp", cc.mvc.AppBase)

function MyApp:ctor()
    MyApp.super.ctor(self)
end

function MyApp:run()
    CCFileUtils:sharedFileUtils():addSearchPath("res/")
    CCFileUtils:sharedFileUtils():addSearchPath("res/ccb/")
    self:enterMainScene()
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

return MyApp
