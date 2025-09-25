#!/bin/bash

# 阿里云服务器前端部署脚本
# 适用于 Ubuntu/CentOS 系统

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 服务器信息
SERVER_IP="39.106.19.163"
FRONTEND_PORT="3000"
BACKEND_PORT="5000"
PROJECT_DIR="/www/wwwroot/shujucaiji"

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Node.js环境
check_nodejs() {
    if ! command -v node &> /dev/null; then
        log_error "Node.js未安装，请先安装Node.js"
        log_info "安装命令参考："
        echo "Ubuntu/Debian: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs"
        echo "CentOS/RHEL: curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash - && sudo yum install -y nodejs"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        log_error "npm未安装"
        exit 1
    fi
    
    log_info "Node.js版本: $(node --version)"
    log_info "npm版本: $(npm --version)"
}

# 安装前端依赖
install_frontend_deps() {
    log_info "安装前端依赖..."
    
    cd "${PROJECT_DIR}/frontend"
    
    # 检查package.json是否存在
    if [[ ! -f "package.json" ]]; then
        log_error "package.json文件不存在"
        exit 1
    fi
    
    # 安装依赖
    npm install
    
    if [[ $? -eq 0 ]]; then
        log_info "前端依赖安装成功"
    else
        log_error "前端依赖安装失败"
        exit 1
    fi
}

# 构建生产版本
build_production() {
    log_info "构建生产版本..."
    
    cd "${PROJECT_DIR}/frontend"
    
    # 构建生产版本
    npm run build
    
    if [[ $? -eq 0 ]]; then
        log_info "生产版本构建成功"
    else
        log_error "生产版本构建失败"
        exit 1
    fi
}

# 安装serve静态文件服务器
install_serve() {
    log_info "安装serve静态文件服务器..."
    
    # 全局安装serve
    npm install -g serve
    
    if [[ $? -eq 0 ]]; then
        log_info "serve安装成功"
    else
        log_warn "serve安装失败，将尝试使用其他方式启动"
    fi
}

# 创建前端启动脚本
create_frontend_startup_script() {
    log_info "创建前端启动脚本..."
    
    cd "${PROJECT_DIR}"
    
    # 创建启动脚本
    cat > start-frontend.sh << 'EOF'
#!/bin/bash
cd /www/wwwroot/shujucaiji/frontend

# 检查是否已构建生产版本
if [[ ! -d "dist" ]]; then
    echo "未找到dist目录，请先运行npm run build构建生产版本"
    exit 1
fi

# 使用serve启动（如果已安装）
if command -v serve &> /dev/null; then
    serve -s dist -l 3000
else
    # 如果没有serve，使用Python内置HTTP服务器（备用方案）
    echo "使用Python HTTP服务器启动前端..."
    cd dist
    python3 -m http.server 3000
fi
EOF
    
    chmod +x start-frontend.sh
}

# 创建systemd服务
create_frontend_service() {
    log_info "创建前端systemd服务..."
    
    # 创建服务文件
    cat > /etc/systemd/system/barcode-frontend.service << EOF
[Unit]
Description=Barcode System Frontend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${PROJECT_DIR}/frontend
ExecStart=${PROJECT_DIR}/start-frontend.sh
Restart=always
RestartSec=5
StandardOutput=file:${PROJECT_DIR}/logs/frontend.log
StandardError=file:${PROJECT_DIR}/logs/frontend-error.log

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载systemd
    systemctl daemon-reload
    systemctl enable barcode-frontend.service
}

# 配置防火墙
configure_frontend_firewall() {
    log_info "配置前端防火墙..."
    
    # 检测操作系统
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
    else
        log_error "无法检测操作系统"
        exit 1
    fi
    
    case $OS in
        ubuntu|debian)
            if command -v ufw >/dev/null 2>&1; then
                ufw allow ${FRONTEND_PORT}/tcp
                ufw reload
            fi
            ;;
        centos|rhel|fedora)
            if command -v firewall-cmd >/dev/null 2>&1; then
                firewall-cmd --permanent --add-port=${FRONTEND_PORT}/tcp
                firewall-cmd --reload
            elif command -v iptables >/dev/null 2>&1; then
                iptables -A INPUT -p tcp --dport ${FRONTEND_PORT} -j ACCEPT
                service iptables save
            fi
            ;;
    esac
}

# 启动前端服务
start_frontend_service() {
    log_info "启动前端服务..."
    
    systemctl start barcode-frontend.service
    sleep 3
    
    # 检查服务状态
    if systemctl is-active --quiet barcode-frontend.service; then
        log_info "前端服务启动成功"
    else
        log_error "前端服务启动失败"
        journalctl -u barcode-frontend.service --no-pager -n 20
        exit 1
    fi
}

# 测试前端服务
test_frontend_service() {
    log_info "测试前端服务..."
    
    # 等待服务完全启动
    sleep 5
    
    # 测试前端服务
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${FRONTEND_PORT})
    
    if [[ $response -eq 200 ]] || [[ $response -eq 304 ]]; then
        log_info "前端服务测试通过"
        
        # 显示服务信息
        echo ""
        echo "=" * 50
        echo "前端部署完成！"
        echo "前端地址: http://${SERVER_IP}:${FRONTEND_PORT}"
        echo "后端地址: http://${SERVER_IP}:${BACKEND_PORT}"
        echo "=" * 50
        echo ""
        
        # 显示服务状态
        systemctl status barcode-frontend.service --no-pager
        
    else
        log_warn "前端服务测试失败，HTTP状态码: $response"
        log_info "请检查前端服务日志：journalctl -u barcode-frontend.service -f"
    fi
}

# 主函数
main() {
    log_info "开始部署前端服务到阿里云服务器 ${SERVER_IP}"
    
    # 执行部署步骤
    check_nodejs
    install_frontend_deps
    build_production
    install_serve
    create_frontend_startup_script
    create_frontend_service
    configure_frontend_firewall
    start_frontend_service
    test_frontend_service
    
    log_info "前端部署完成！"
}

# 运行主函数
main