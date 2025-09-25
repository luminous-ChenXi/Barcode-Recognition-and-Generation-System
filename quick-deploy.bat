@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: 阿里云服务器快速部署脚本 (Windows版本)
:: 适用于Windows Server系统

:: 颜色定义
for /f "delims=#" %%a in ('"prompt #$h#$e# & echo on & for %%b in (1) do rem"') do set "BS=%%a"
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

:: 日志函数
:log_info
echo %BS%!GREEN![INFO]!NC! %*
goto :eof

:log_warn
echo %BS%!YELLOW![WARN]!NC! %*
goto :eof

:log_error
echo %BS%!RED![ERROR]!NC! %*
goto :eof

:: 服务器信息
set "SERVER_IP=39.106.19.163"
set "SERVER_PORT=5000"
set "PROJECT_NAME=barcode-system"
set "PROJECT_DIR=C:\%PROJECT_NAME%"

:: 检查管理员权限
call :check_admin

:: 主部署流程
call :main

goto :eof

:check_admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 请使用管理员权限运行此脚本
    pause
    exit /b 1
)
call :log_info "管理员权限检查通过"
goto :eof

:check_python
call :log_info "检查Python环境..."
python --version >nul 2>&1
if %errorlevel% equ 0 (
    python --version
    call :log_info "Python已安装"
    goto :eof
)

pip --version >nul 2>&1
if %errorlevel% equ 0 (
    pip --version
    call :log_info "pip已安装"
    goto :eof
)

call :log_error "未检测到Python，请先安装Python 3.6或更高版本"
echo.
echo 可以从以下地址下载Python:
echo https://www.python.org/downloads/
echo.
pause
exit /b 1

:create_project_dir
call :log_info "创建项目目录..."
if not exist "%PROJECT_DIR%" (
    mkdir "%PROJECT_DIR%"
    mkdir "%PROJECT_DIR%\backend"
    mkdir "%PROJECT_DIR%\logs"
    call :log_info "项目目录创建成功"
) else (
    call :log_warn "项目目录已存在"
)
goto :eof

:install_python_deps
call :log_info "安装Python依赖..."

:: 创建requirements.txt
echo flask==2.3.3 > "%PROJECT_DIR%\backend\requirements.txt"
echo flask-cors==4.0.0 >> "%PROJECT_DIR%\backend\requirements.txt"
echo opencv-python==4.8.1.78 >> "%PROJECT_DIR%\backend\requirements.txt"
echo numpy==1.24.3 >> "%PROJECT_DIR%\backend\requirements.txt"
echo pyzbar==0.1.9 >> "%PROJECT_DIR%\backend\requirements.txt"
echo Pillow==10.0.1 >> "%PROJECT_DIR%\backend\requirements.txt"

:: 安装依赖
pip install -r "%PROJECT_DIR%\backend\requirements.txt"
if %errorlevel% equ 0 (
    call :log_info "Python依赖安装成功"
) else (
    call :log_error "Python依赖安装失败"
    goto :error_handling
)
goto :eof

:deploy_app_files
call :log_info "部署应用文件..."

:: 创建应用主文件
(
echo from flask import Flask, request, jsonify
echo from flask_cors import CORS
echo import cv2
echo import numpy as np
echo from pyzbar.pyzbar import decode
echo from PIL import Image
echo import io
echo import base64
echo import os
echo.
echo app = Flask^(__name__^\)
echo CORS^(app^)  # 允许跨域请求
echo.
echo @app.route^('/health', methods=['GET']^\)
echo def health_check^(^):
echo     """健康检查接口"""
echo     return jsonify^(^\{
echo         'status': 'healthy',
echo         'service': 'Barcode Recognition System',
echo         'version': '1.0.0'
echo     \}^)
echo.
echo @app.route^('/supported-types', methods=['GET']^\)
echo def supported_types^(^):
echo     """获取支持的条码类型"""
echo     return jsonify^(^\{
echo         'supported_barcode_types': [
echo             'QRCODE', 'CODE128', 'CODE39', 'EAN13', 'EAN8', 
echo             'UPC-A', 'UPC-E', 'CODE93', 'PDF417', 'DATAMATRIX'
echo         ]
echo     \}^)
echo.
echo @app.route^('/scan', methods=['POST']^\)
echo def scan_barcode^(^):
echo     """识别条码接口"""
echo     try:
echo         # 检查是否有文件上传
echo         if 'file' in request.files:
echo             file = request.files['file']
echo             if file.filename == '':
echo                 return jsonify^(\{'error': '未选择文件'\}^), 400
echo             
echo             # 读取图片数据
echo             image_data = file.read^(^)
echo             
echo         # 检查是否有base64数据
echo         elif 'image' in request.json:
echo             image_data_base64 = request.json['image']
echo             # 移除base64前缀
echo             if ',' in image_data_base64:
echo                 image_data_base64 = image_data_base64.split^(','^)[1]
echo             image_data = base64.b64decode^(image_data_base64^)
echo             
echo         else:
echo             return jsonify^(\{'error': '请提供图片文件或base64数据'\}^), 400
echo         
echo         # 将图片数据转换为numpy数组
echo         nparr = np.frombuffer^(image_data, np.uint8^)
echo         image = cv2.imdecode^(nparr, cv2.IMREAD_COLOR^)
echo         
echo         if image is None:
echo             return jsonify^(\{'error': '无法解码图片'\}^), 400
echo         
echo         # 识别条码
echo         decoded_objects = decode^(image^)
echo         
echo         if not decoded_objects:
echo             return jsonify^(\^\{
echo                 'success': False,
echo                 'message': '未识别到条码',
echo                 'barcodes': []
echo             \}^)
echo         
echo         # 处理识别结果
echo         barcodes = []
echo         for obj in decoded_objects:
echo             barcodes.append^(^\{
echo                 'type': obj.type,
echo                 'data': obj.data.decode^('utf-8'^),
echo                 'rect': \^\{
echo                     'left': obj.rect.left,
echo                     'top': obj.rect.top,
echo                     'width': obj.rect.width,
echo                     'height': obj.rect.height
echo                 \^\}
echo             \}^)
echo         
echo         return jsonify^(^\{
echo             'success': True,
echo             'message': f'识别到 ^\{len^(barcodes^)\} 个条码',
echo             'barcodes': barcodes
echo         \}^)
echo         
echo     except Exception as e:
echo         return jsonify^(^\{
echo             'error': f'识别失败: ^\{str^(e^)\}'
echo         \}^), 500
echo.
echo @app.route^('/generate', methods=['POST']^\)
echo def generate_barcode^(^):
echo     """生成条码接口"""
echo     try:
echo         data = request.json
echo         
echo         if not data or 'text' not in data:
echo             return jsonify^(\{'error': '请提供要生成的文本'\}^), 400
echo         
echo         text = data['text']
echo         barcode_type = data.get^('type', 'CODE128'^)
echo         
echo         # 这里可以添加条码生成逻辑
echo         # 由于条码生成需要额外的库，这里先返回成功响应
echo         
echo         return jsonify^(^\{
echo             'success': True,
echo             'message': '条码生成功能待实现',
echo             'data': text,
echo             'type': barcode_type
echo         \}^)
echo         
echo     except Exception as e:
echo         return jsonify^(^\{
echo             'error': f'生成失败: ^\{str^(e^)\}'
echo         \}^), 500
echo.
echo if __name__ == '__main__':
echo     # 生产环境配置
echo     app.run^(^
echo         host='0.0.0.0',
echo         port=5000,
echo         debug=False,
echo         threaded=True
echo     ^)
) > "%PROJECT_DIR%\backend\app.py"

call :log_info "应用文件部署成功"
goto :eof

:create_startup_script
call :log_info "创建启动脚本..."

:: 创建启动脚本
(
echo @echo off
echo cd /d "%PROJECT_DIR%\backend"
echo python app.py
echo pause
) > "%PROJECT_DIR%\start-server.bat"

:: 创建Windows服务安装脚本
(
echo @echo off
echo set SERVICE_NAME="BarcodeSystem"
echo set DISPLAY_NAME="Barcode Recognition System"
echo set PROJECT_PATH="%PROJECT_DIR%"
echo.
echo echo 正在安装 ^%SERVICE_NAME^% 服务...
echo.
echo sc create ^%SERVICE_NAME^% binPath= "cmd /k cd ^%PROJECT_PATH^%\backend ^&^& python app.py" DisplayName= ^%DISPLAY_NAME^% start= auto
echo.
echo if ^%errorlevel^% equ 0 ^(
echo     echo 服务创建成功
echo     echo 启动服务: sc start ^%SERVICE_NAME^%
echo     echo 停止服务: sc stop ^%SERVICE_NAME^%
echo     echo 删除服务: sc delete ^%SERVICE_NAME^%
echo ^) else ^(
echo     echo 服务创建失败
echo ^)
echo.
echo pause
) > "%PROJECT_DIR%\install-service.bat"

call :log_info "启动脚本创建成功"
goto :eof

:configure_firewall
call :log_info "配置防火墙..."

:: 开放5000端口
netsh advfirewall firewall add rule name="Barcode System" dir=in action=allow protocol=TCP localport=%SERVER_PORT%
if %errorlevel% equ 0 (
    call :log_info "防火墙规则添加成功"
) else (
    call :log_warn "防火墙规则添加失败（可能已存在）"
)
goto :eof

:test_service
call :log_info "测试服务..."

:: 启动服务进行测试
start "" cmd /k "cd /d "%PROJECT_DIR%\backend" ^&^& python app.py"

:: 等待服务启动
timeout /t 5 /nobreak >nul

:: 测试健康检查接口
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://localhost:%SERVER_PORT%/health' -UseBasicParsing; Write-Host '服务测试通过 - HTTP状态码:' $response.StatusCode } catch { Write-Host '服务测试失败:' $_.Exception.Message }"

if %errorlevel% equ 0 (
    call :log_info "服务测试通过"
    
    echo.
    echo ==================================================
    echo 部署完成！
    echo 服务地址: http://%SERVER_IP%:%SERVER_PORT%
    echo 健康检查: http://%SERVER_IP%:%SERVER_PORT%/health
    echo 支持的条码类型: http://%SERVER_IP%:%SERVER_PORT%/supported-types
    echo ==================================================
    echo.
    echo 手动启动服务: 运行 "%PROJECT_DIR%\start-server.bat"
    echo 安装Windows服务: 运行 "%PROJECT_DIR%\install-service.bat"
    echo.
) else (
    call :log_error "服务测试失败"
    goto :error_handling
)

goto :eof

:main
call :log_info "开始部署条码识别系统到阿里云服务器 %SERVER_IP%"

:: 执行部署步骤
call :check_python
call :create_project_dir
call :install_python_deps
call :deploy_app_files
call :create_startup_script
call :configure_firewall
call :test_service

call :log_info "部署完成！"
echo.
echo 下一步操作：
echo 1. 在微信公众平台配置服务器域名: http://%SERVER_IP%:%SERVER_PORT%
echo 2. 修改小程序配置文件中的baseURL为上述地址
echo 3. 测试小程序功能
echo.
pause
goto :eof

:error_handling
call :log_error "部署过程中出现错误"
echo.
echo 故障排除建议：
echo 1. 检查Python是否正确安装
echo 2. 检查网络连接
echo 3. 检查5000端口是否被占用
echo 4. 查看日志文件: %PROJECT_DIR%\logs\
echo.
pause
exit /b 1