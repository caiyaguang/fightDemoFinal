@echo off

set DIR=%~dp0
set APP_ROOT=%DIR%..\
set APP_ANDROID_ROOT=%DIR%

echo - config:
echo   ANDROID_NDK_ROOT    = %ANDROID_NDK_ROOT%
echo   QUICK_COCOS2DX_ROOT = %QUICK_COCOS2DX_ROOT%
echo   COCOS2DX_ROOT       = %COCOS2DX_ROOT%
echo   APP_ROOT            = %APP_ROOT%
echo   APP_ANDROID_ROOT    = %APP_ANDROID_ROOT%

rem if use quick-cocos2d-x mini, uncomments line below
rem set NDK_BUILD_FLAGS=CPPFLAGS=-DQUICK_MINI_TARGET=1 QUICK_MINI_TARGET=1

rem if use DEBUG, set NDK_DEBUG=1, otherwise set NDK_DEBUG=0
set NDK_DEBUG=1

echo - cleanup
if exist "%APP_ANDROID_ROOT%bin" rmdir /s /q "%APP_ANDROID_ROOT%bin"
mkdir "%APP_ANDROID_ROOT%bin"
if exist "%APP_ANDROID_ROOT%assets" rmdir /s /q "%APP_ANDROID_ROOT%assets"
mkdir "%APP_ANDROID_ROOT%assets"

echo - copy scripts
mkdir "%APP_ANDROID_ROOT%assets\scripts"
xcopy /s /q "%APP_ROOT%scripts\*.*" "%APP_ANDROID_ROOT%assets\scripts\"
echo - copy resources
mkdir "%APP_ANDROID_ROOT%assets\res"
xcopy /s /q "%APP_ROOT%res\*.*" "%APP_ANDROID_ROOT%assets\res\"

echo Using prebuilt externals
"%ANDROID_NDK_ROOT%\ndk-build" %ANDROID_NDK_BUILD_FLAGS% NDK_DEBUG=%NDK_DEBUG% %NDK_BUILD_FLAGS% -C %APP_ANDROID_ROOT% NDK_MODULE_PATH=%QUICK_COCOS2DX_ROOT%;%COCOS2DX_ROOT%;%COCOS2DX_ROOT%\cocos2dx\platform\third_party\android\prebuilt
