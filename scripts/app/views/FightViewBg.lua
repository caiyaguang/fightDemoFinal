local FightViewBg = class("FightViewBg", function(  )
	return display.newLayer()
end)

function FightViewBg:ctor()
    local FightingBg = display.newSprite("ccb/ccbResources/battleBg/bbg_fall_cityofmage2.jpg"):addTo(self)
end

return FightViewBg
