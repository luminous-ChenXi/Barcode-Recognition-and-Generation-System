# 条码识别与生成系统

一个基于Python Flask后端和Vue 3前端的Web应用，提供条码识别和生成功能。

## 功能特性

### 条码识别
- 📷 支持图片上传识别条码
- 🔍 支持多种条码格式（QR Code、Code 128、Code 39、EAN-13、EAN-8、UPC-A）
- 📋 显示识别结果和条码位置
- 🖼️ 支持文件上传和base64两种方式

### 条码生成
- 🔧 生成二维码和多种条形码
- 💾 支持条码图片下载
- 🎨 简洁易用的生成界面
- 📊 实时预览生成的条码

## 项目结构

```
shujucaiji/
├── backend/                 # Python后端服务
│   ├── app-server.py       # 服务器部署版本（推荐）
│   ├── app.py              # 开发版本
│   ├── requirements.txt    # Python依赖包
│   └── uploads/            # 文件上传目录
├── frontend/               # Vue前端界面
│   ├── src/
│   │   ├── App.vue         # 主组件
│   │   └── main.js         # 入口文件
│   ├── index.html          # HTML模板
│   ├── package.json        # 前端依赖配置
│   ├── vite.config.js      # Vite配置
│   └── dist/               # 构建输出目录
├── deploy-frontend.sh       # 前端部署脚本
├── deploy-server.sh         # 后端部署脚本
├── quick-deploy.sh         # 快速部署脚本
└── README.md               # 项目说明
```

## 快速开始

### 1. 本地开发环境启动

#### 后端服务启动

```bash
# 进入后端目录
cd backend

# 安装Python依赖
pip install -r requirements.txt

# 启动Flask服务
python app-server.py
```

后端服务将在 http://localhost:5000 启动

#### 前端界面启动

```bash
# 进入前端目录
cd frontend

# 安装Node.js依赖
npm install

# 启动开发服务器
npm run dev
```

前端界面将在 http://localhost:3000 启动

### 2. 阿里云服务器部署

#### 后端部署

```bash
# 上传backend目录到服务器
cd /www/wwwroot/shujucaiji/backend

# 安装Python依赖（推荐使用虚拟环境）
pip install -r requirements.txt

# 启动后端服务
python app-server.py
```

#### 前端部署

```bash
# 上传frontend目录到服务器
cd /www/wwwroot/shujucaiji/frontend

# 安装依赖
npm install

# 构建生产版本
npm run build

# 使用静态文件服务器启动
npm install -g serve
serve -s dist -l 3000

# 或者使用Python HTTP服务器
cd dist
python3 -m http.server 3000
```

### 3. 使用部署脚本

项目提供了完整的部署脚本：

```bash
# 快速部署（包含前后端）
chmod +x quick-deploy.sh
./quick-deploy.sh

# 单独部署前端
chmod +x deploy-frontend.sh
./deploy-frontend.sh

# 单独部署后端
chmod +x deploy-server.sh
./deploy-server.sh
```

## API接口说明

### 健康检查接口

**GET** `/health`

- **返回**: 
  ```json
  {
    "status": "healthy",
    "message": "服务运行正常"
  }
  ```

### 条码识别接口

**POST** `/scan` 或 `/api/scan`

- **参数**: 
  - 文件上传：`file` 字段（支持JPG、PNG格式）
  - Base64数据：`image` 字段（JSON格式）
- **返回**: 
  ```json
  {
    "success": true,
    "count": 1,
    "results": [
      {
        "type": "QRCODE",
        "data": "识别到的内容",
        "points": [[x1, y1], [x2, y2], ...]
      }
    ],
    "message": "成功识别到 1 个条码"
  }
  ```

### 条码生成接口

**POST** `/generate` 或 `/api/generate`

- **参数**: 
  ```json
  {
    "content": "要生成的内容",
    "barcode_type": "QRCODE"
  }
  ```
- **支持的条码类型**: QRCODE, CODE128, CODE39, EAN13, EAN8, UPC-A
- **返回**: 
  ```json
  {
    "success": true,
    "image_url": "data:image/png;base64,...",
    "message": "二维码生成成功"
  }
  ```

### 支持的条码类型接口

**GET** `/supported-types`

- **返回**: 
  ```json
  {
    "success": true,
    "types": {
      "QRCODE": "二维码",
      "CODE128": "Code 128",
      "CODE39": "Code 39",
      "EAN13": "EAN-13",
      "EAN8": "EAN-8",
      "UPC-A": "UPC-A"
    }
  }
  ```

## 技术栈

### 后端
- **Flask**: Python Web框架
- **Flask-CORS**: 跨域请求支持
- **OpenCV**: 图像处理和条码识别
- **PyZBar**: 条码识别库
- **python-barcode**: 条形码生成
- **qrcode**: 二维码生成
- **Pillow**: 图像处理
- **numpy**: 数值计算

### 前端
- **Vue 3**: 渐进式JavaScript框架
- **Element Plus**: UI组件库
- **Vite**: 快速构建工具
- **Axios**: HTTP客户端

## 使用说明

### 条码识别
1. 打开Web界面 http://localhost:3000
2. 点击"条码识别"功能
3. 上传图片文件或粘贴base64数据
4. 系统自动识别并显示结果
5. 查看识别到的条码类型和内容

### 条码生成
1. 打开Web界面 http://localhost:3000
2. 点击"条码生成"功能
3. 输入要生成的内容
4. 选择条码类型（二维码或多种条形码）
5. 点击生成按钮
6. 下载或复制生成的条码图片

## 注意事项

### 部署注意事项

1. **服务器部署**: 
   - 前端服务需要配置 `host: '0.0.0.0'` 支持外部访问
   - 确保防火墙开放3000和5000端口
   - 使用生产模式时注意依赖版本兼容性

2. **依赖版本**: 
   - Pillow 10.0.0+ 移除了 `getsize` 方法，需要兼容版本
   - 推荐使用 requirements.txt 中的锁定版本
   - 注意 numpy 与 opencv-python 的版本兼容性

3. **文件上传**: 
   - 支持JPG、PNG格式，大小不超过16MB
   - 上传目录需要写权限
   - 支持文件上传和base64两种方式

### 常见问题解决

1. **502错误**: 检查前端服务是否绑定到 `0.0.0.0`
2. **条码生成失败**: 检查Pillow和python-barcode版本兼容性
3. **模块导入错误**: 重新安装依赖，确保版本匹配
4. **端口占用**: 检查3000和5000端口是否被占用

## 开发说明

### 环境要求
- **Python**: 3.8+ 
- **Node.js**: 14+
- **操作系统**: Windows/Linux/macOS

### 开发模式
- **后端**: 调试模式自动重载，支持热更新
- **前端**: Vite热重载开发服务器，快速开发
- **API代理**: 前端开发服务器代理后端API请求

### 生产部署
- **后端**: 使用 app-server.py，关闭调试模式
- **前端**: 构建生产版本，使用静态文件服务器
- **性能优化**: 启用Gzip压缩，配置缓存策略

### 部署脚本说明

项目提供了多个部署脚本：
- `quick-deploy.sh`: 快速部署前后端
- `deploy-frontend.sh`: 前端部署脚本
- `deploy-server.sh`: 后端部署脚本
- `diagnose-502.sh`: 502错误诊断脚本
- `fix-vite.sh`: Vite问题修复脚本
- `simple-start.sh`: 简单生产环境启动脚本

## 许可证

MIT License

## 联系方式

如有问题或建议，请联系开发团队。