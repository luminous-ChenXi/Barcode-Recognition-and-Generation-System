#!/bin/bash

# 条码识别与生成系统 - 服务器部署脚本
# 适用于阿里云服务器：39.106.19.163

echo "========================================"
echo "   条码识别与生成系统 - 服务器部署"
echo "========================================"
echo ""

# 检查Python环境
python3 --version
if [ $? -ne 0 ]; then
    echo "❌ Python3 未安装，开始安装..."
    sudo apt update
    sudo apt install -y python3 python3-pip
fi

# 检查是否已安装virtualenv
pip3 list | grep virtualenv
if [ $? -ne 0 ]; then
    echo "📦 安装 virtualenv..."
    pip3 install virtualenv
fi

# 创建项目目录
echo "📁 创建项目目录..."
sudo mkdir -p /opt/barcode-system
sudo chown $USER:$USER /opt/barcode-system
cd /opt/barcode-system

# 创建虚拟环境
echo "🐍 创建Python虚拟环境..."
virtualenv -p python3 venv
source venv/bin/activate

# 安装依赖
echo "📚 安装Python依赖..."
pip install flask opencv-python pyzbar pillow numpy

# 创建应用目录结构
echo "📂 创建应用目录结构..."
mkdir -p backend/uploads

# 创建启动脚本
echo "🚀 创建启动脚本..."
cat > start-server.sh << 'EOF'
#!/bin/bash
cd /opt/barcode-system
source venv/bin/activate
cd backend
python3 app.py --host=0.0.0.0 --port=5000
EOF

chmod +x start-server.sh

# 创建systemd服务
echo "🔧 创建systemd服务..."
sudo cat > /etc/systemd/system/barcode-system.service << EOF
[Unit]
Description=Barcode Recognition and Generation System
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/barcode-system
ExecStart=/opt/barcode-system/start-server.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd
sudo systemctl daemon-reload

# 启用服务
sudo systemctl enable barcode-system.service

echo ""
echo "✅ 服务器环境配置完成！"
echo ""
echo "📋 下一步操作："
echo "1. 将项目文件上传到服务器：/opt/barcode-system/"
echo "2. 启动服务：sudo systemctl start barcode-system.service"
echo "3. 检查服务状态：sudo systemctl status barcode-system.service"
echo "4. 查看日志：sudo journalctl -u barcode-system.service -f"
echo ""
echo "🌐 服务将运行在：http://39.106.19.163:5000"
echo ""