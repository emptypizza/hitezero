@echo off
chcp 65001 >nul
title 콩퍼스의 유성막기
echo.
echo  ========================================
echo    콩퍼스의 유성막기 실행 중...
echo  ========================================
echo.
echo  빈 포트를 찾는 중...

cd /d "%~dp0"

set PORT=4173

:FIND_PORT
netstat -an | findstr ":%PORT% " | findstr "LISTENING" >nul 2>&1
if %errorlevel%==0 (
    set /a PORT+=1
    goto FIND_PORT
)

echo  포트 %PORT% 사용
echo  브라우저가 자동으로 열립니다.
echo  이 창을 닫으면 게임 서버가 종료됩니다.
echo.

start http://localhost:%PORT%
npm run preview -- --port %PORT%
