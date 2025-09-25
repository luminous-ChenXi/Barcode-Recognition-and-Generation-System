@echo off
echo ========================================
echo   条码识别与生成小程序打包工具
echo ========================================
echo.

echo [1/3] 检查Node.js环境...
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ 未检测到Node.js，请先安装Node.js
    echo 下载地址: https://nodejs.org/
    pause
    exit /b 1
)

echo ✅ Node.js环境正常

echo.
echo [2/3] 打包小程序文件...
node package-miniprogram.js

if errorlevel 1 (
    echo ❌ 打包失败
    pause
    exit /b 1
)

echo.
echo [3/3] 打包完成！
echo.
echo 📁 打包目录: miniprogram-package
echo.
echo 📋 使用说明:
echo    1. 使用微信开发者工具打开 miniprogram-package 目录
echo    2. 确保后端服务正在运行 (http://localhost:5000)
echo    3. 编译并预览小程序
echo.
echo 🔗 微信开发者工具下载地址:
echo    https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html
echo.

pause