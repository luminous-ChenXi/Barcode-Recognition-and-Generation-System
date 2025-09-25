# 条码识别与生成小程序打包脚本
Write-Host "========================================" -ForegroundColor Green
Write-Host "   条码识别与生成小程序打包工具" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# 检查Node.js环境
Write-Host "[1/4] 检查Node.js环境..." -ForegroundColor Yellow
$nodeVersion = node --version 2>$null
if (-not $nodeVersion) {
    Write-Host "❌ 未检测到Node.js，请先安装Node.js" -ForegroundColor Red
    Write-Host "下载地址: https://nodejs.org/" -ForegroundColor Cyan
    Read-Host "按任意键退出"
    exit 1
}
Write-Host "✅ Node.js版本: $nodeVersion" -ForegroundColor Green

# 检查后端服务状态
Write-Host "[2/4] 检查后端服务状态..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000" -TimeoutSec 3 -ErrorAction SilentlyContinue
    Write-Host "✅ 后端服务运行正常" -ForegroundColor Green
} catch {
    Write-Host "⚠️  后端服务未运行，请确保已启动后端服务" -ForegroundColor Yellow
    Write-Host "启动命令: cd backend; python app.py" -ForegroundColor Cyan
}

# 打包小程序
Write-Host "[3/4] 打包小程序文件..." -ForegroundColor Yellow
try {
    node package-miniprogram.js
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 小程序打包完成" -ForegroundColor Green
    } else {
        Write-Host "❌ 打包失败" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ 打包过程中出现错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 显示打包结果
Write-Host "[4/4] 打包完成！" -ForegroundColor Green
Write-Host ""
Write-Host "📁 打包目录: miniprogram-package" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 使用说明:" -ForegroundColor White
Write-Host "   1. 使用微信开发者工具打开 miniprogram-package 目录" -ForegroundColor Gray
Write-Host "   2. 确保后端服务正在运行 (http://localhost:5000)" -ForegroundColor Gray
Write-Host "   3. 编译并预览小程序" -ForegroundColor Gray
Write-Host ""
Write-Host "🔗 微信开发者工具下载地址:" -ForegroundColor White
Write-Host "   https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 提示:" -ForegroundColor White
Write-Host "   - 如果使用测试号，AppID可以留空或填写测试号" -ForegroundColor Gray
Write-Host "   - 确保网络连接正常，后端API可访问" -ForegroundColor Gray
Write-Host "   - 首次使用需要授权摄像头和相册权限" -ForegroundColor Gray
Write-Host ""

Read-Host "按任意键退出"