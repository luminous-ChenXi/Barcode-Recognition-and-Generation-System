#!/bin/bash

# 502错误诊断脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查前端服务状态
check_frontend_service() {
    log_info "检查前端服务状态..."
    
    # 检查进程
    if pgrep -f "npm.*run.*dev" > /dev/null; then
        log_success "前端开发服务正在运行"
    else
        log_error "前端开发服务未运行"
        return 1
    fi
    
    # 检查端口监听
    if netstat -tuln 2>/dev/null | grep -q ":3000 "; then
        log_success "端口3000正在监听"
    else
        log_error "端口3000未监听"
        return 1
    fi
}

# 检查本地访问
check_local_access() {
    log_info "检查本地访问..."
    
    if command -v curl &> /dev/null; then
        if curl -s http://localhost:3000 > /dev/null; then
            log_success "本地访问正常 (http://localhost:3000)"
            return 0
        else
            log_error "本地访问失败"
            return 1
        fi
    else
        log_warn "curl未安装，跳过本地访问测试"
        return 0
    fi
}

# 检查防火墙
check_firewall() {
    log_info "检查防火墙设置..."
    
    # 检查ufw（Ubuntu/Debian）
    if command -v ufw &> /dev/null; then
        ufw_status=$(ufw status)
        if echo "$ufw_status" | grep -q "Status: active"; then
            log_info "UFW防火墙已启用"
            if ufw status | grep -q "3000"; then
                log_success "端口3000已放行"
            else
                log_warn "端口3000可能被防火墙阻止"
            fi
        else
            log_info "UFW防火墙未启用"
        fi
    fi
    
    # 检查firewalld（CentOS/RHEL）
    if command -v firewall-cmd &> /dev/null; then
        if firewall-cmd --state &> /dev/null; then
            log_info "Firewalld已启用"
            if firewall-cmd --list-ports | grep -q "3000"; then
                log_success "端口3000已放行"
            else
                log_warn "端口3000可能被防火墙阻止"
            fi
        fi
    fi
}

# 检查Nginx配置
check_nginx_config() {
    log_info "检查Nginx配置..."
    
    if command -v nginx &> /dev/null; then
        # 查找Nginx配置文件
        nginx_conf_files=$(find /etc/nginx -name "*.conf" 2>/dev/null | head -5)
        
        if [[ -n "$nginx_conf_files" ]]; then
            log_info "找到Nginx配置文件"
            
            # 检查是否包含3000端口代理
            for conf_file in $nginx_conf_files; do
                if grep -q "3000" "$conf_file" 2>/dev/null; then
                    log_info "配置文件 $conf_file 包含3000端口配置"
                    grep -A5 -B5 "3000" "$conf_file" | head -20
                fi
            done
        else
            log_info "未找到Nginx配置文件"
        fi
    else
        log_info "Nginx未安装"
    fi
}

# 检查服务器网络
check_network() {
    log_info "检查服务器网络..."
    
    # 获取服务器IP
    server_ip=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    log_info "服务器IP: $server_ip"
    
    # 检查端口外部访问
    if command -v nc &> /dev/null; then
        if nc -z localhost 3000; then
            log_success "端口3000本地可访问"
        else
            log_error "端口3000本地不可访问"
        fi
    fi
}

# 提供解决方案
provide_solutions() {
    echo ""
    echo "=" * 60
    echo "502错误解决方案"
    echo "=" * 60
    echo ""
    
    echo "1. 直接访问前端服务:"
    echo "   http://${server_ip:-服务器IP}:3000"
    echo ""
    
    echo "2. 检查Nginx反向代理配置:"
    echo "   # 确保Nginx配置正确指向3000端口"
    echo "   location / {"
    echo "       proxy_pass http://localhost:3000;"
    echo "       proxy_set_header Host \$host;"
    echo "       proxy_set_header X-Real-IP \$remote_addr;"
    echo "   }"
    echo ""
    
    echo "3. 临时关闭防火墙测试:"
    echo "   # Ubuntu/Debian:"
    echo "   sudo ufw disable"
    echo "   # CentOS/RHEL:"
    echo "   sudo systemctl stop firewalld"
    echo ""
    
    echo "4. 重启前端服务:"
    echo "   cd /www/wwwroot/shujucaiji/frontend"
    echo "   pkill -f 'npm.*run.*dev'"
    echo "   npm run dev"
    echo ""
    
    echo "5. 使用生产模式启动:"
    echo "   cd /www/wwwroot/shujucaiji/frontend"
    echo "   ./simple-start.sh"
    echo ""
}

# 主函数
main() {
    echo "开始诊断502错误..."
    echo ""
    
    check_frontend_service
    check_local_access
    check_firewall
    check_nginx_config
    check_network
    
    provide_solutions
}

# 运行主函数
main