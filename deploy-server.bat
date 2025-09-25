@echo off
echo ========================================
echo   条码识别与生成系统 - 服务器部署脚本
echo ========================================
echo 适用于阿里云服务器：39.106.19.163
echo.

echo [1/5] 检查Python环境...
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python未安装，请先安装Python 3.7+
    echo 下载地址: https://www.python.org/downloads/
    pause
    exit /b 1
)

echo ✅ Python环境正常
echo.

echo [2/5] 安装Python依赖...
pip install flask opencv-python pyzbar pillow numpy
if errorlevel 1 (
    echo ❌ 依赖安装失败
    pause
    exit /b 1
)

echo ✅ 依赖安装完成
echo.

echo [3/5] 创建项目目录结构...
if not exist "C:\barcode-system" mkdir "C:\barcode-system"
if not exist "C:\barcode-system\backend\uploads" mkdir "C:\barcode-system\backend\uploads"

echo ✅ 目录结构创建完成
echo.

echo [4/5] 创建启动脚本...
echo @echo off > "C:\barcode-system\start-server.bat"
echo cd /d "C:\barcode-system\backend" >> "C:\barcode-system\start-server.bat"
echo python app.py --host=0.0.0.0 --port=5000 >> "C:\barcode-system\start-server.bat"
echo pause >> "C:\barcode-system\start-server.bat"

echo ✅ 启动脚本创建完成
echo.

echo [5/5] 部署完成！
echo.
echo 📋 下一步操作：
echo 1. 将项目文件复制到：C:\barcode-system\
echo 2. 运行启动脚本：C:\barcode-system\start-server.bat
echo 3. 服务将运行在：http://39.106.19.163:5000
echo.
echo 💡 提示：
echo   - 确保防火墙已开放5000端口
echo   - 可以使用nssm创建Windows服务
echo   - 生产环境建议使用nginx反向代理
echo.

pause