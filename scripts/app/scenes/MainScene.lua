require "Util/CCBReaderLoad"

MainViewOwner = MainViewOwner or {}
ccb["MainViewOwner"] = MainViewOwner

local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
    local  proxy = CCBProxy:create()
    local  node  = CCBuilderReaderLoad("MainView.ccbi",proxy,MainViewOwner)
    local  layer = tolua.cast(node,"CCLayer")
    self:addChild(layer)
end

local function enterGameAction(  )
    app:enterFightScene()
end
MainViewOwner["enterGameAction"] = enterGameAction

function MainScene:onEnter()
    if device.platform == "android" then
        -- avoid unmeant back
        self:performWithDelay(function()
            -- keypad layer, for android
            local layer = display.newLayer()
            layer:addKeypadEventListener(function(event)
                if event == "back" then app.exit() end
            end)
            self:addChild(layer)

            layer:setKeypadEnabled(true)
        end, 0.5)
    end
end

function MainScene:onExit()
end

return MainScene
