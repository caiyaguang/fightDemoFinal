
-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 2
DEBUG_FPS = false
DEBUG_MEM = false

CONFIG_SCREEN_WIDTH  = 960
CONFIG_SCREEN_HEIGHT = 640

-- auto scale mode
local function SCREEN_AUTO_FIT_HEIGHT( w,h )
	local sharedDirector = CCDirector:sharedDirector()
	local glview = sharedDirector:getOpenGLView()
	local sizeIphone = CCSizeMake(480,320)
    local sizeIphoneHD = CCSizeMake(960, 640)
    local sizeIphone5 = CCSizeMake(1136, 640)
    local sizeIpad = CCSizeMake(1024, 768)
    local sizeIpadHD = CCSizeMake(2048, 1536)
    local designSize = sizeIphoneHD
    local resourceSize = sizeIphoneHD
    if w == 2048 then
        designSize = sizeIpadHD
        resourceSize = sizeIpadHD
        CCBReader:setResolutionScale(2)
    elseif w == 1024 then
        designSize = sizeIpad
        resourceSize = sizeIpad
        CCBReader:setResolutionScale(1)
    elseif w == 960 then
        designSize = sizeIphoneHD
        resourceSize = sizeIphoneHD
        CCBReader:setResolutionScale(1)
    elseif w == 1136 then
        designSize = sizeIphone5
        resourceSize = sizeIphone5
        CCBReader:setResolutionScale(1)
    elseif w == 480 then
        designSize = sizeIphone
        resourceSize = sizeIphone
        CCBReader:setResolutionScale(0.5)
    else
        designSize = sizeIphoneHD
        resourceSize = sizeIphoneHD
        CCBReader:setResolutionScale(1)
    end
    sharedDirector:setContentScaleFactor(1)
    CONFIG_SCREEN_WIDTH = designSize.width
    CONFIG_SCREEN_HEIGHT = designSize.height
end

local function SCREEN_AUTO_FIT_WIDTH( w,h )

    local sharedDirector = CCDirector:sharedDirector()
    local screenSize = sharedDirector:getWinSizeInPixels()
    local glview = sharedDirector:getOpenGLView()
    local designSize = screenSize
    local resourceSize = screenSize
    sharedDirector:setContentScaleFactor(resourceSize.width / designSize.width)
    CONFIG_SCREEN_WIDTH = designSize.width
    CONFIG_SCREEN_HEIGHT = designSize.height
    CCBReader:setResolutionScale(screenSize.height / 640)
end

local platform = "unknown"
local sharedApplication = CCApplication:sharedApplication()
local target = sharedApplication:getTargetPlatform()
if target == kTargetWindows then
    platform = "windows"
elseif target == kTargetMacOS then
    platform = "mac"
elseif target == kTargetAndroid then
    platform = "android"
elseif target == kTargetIphone or target == kTargetIpad then
    platform = "ios"
end

if platform == "android" then
    CONFIG_SCREEN_AUTOSCALE = SCREEN_AUTO_FIT_WIDTH
else
    CONFIG_SCREEN_AUTOSCALE = SCREEN_AUTO_FIT_HEIGHT
end
