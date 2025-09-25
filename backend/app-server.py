#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
条码识别与生成系统 - 服务器版本
适用于阿里云服务器部署
"""

import os
import base64
import cv2
import numpy as np
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
try:
    import pyzbar.pyzbar as pyzbar
    ZBAR_AVAILABLE = True
except ImportError:
    ZBAR_AVAILABLE = False
    print("警告: pyzbar库不可用，将使用OpenCV进行基本二维码识别")
from PIL import Image
import qrcode
import barcode
from barcode.writer import ImageWriter
import io

# 创建Flask应用
app = Flask(__name__)
CORS(app)  # 允许跨域请求

# 配置上传文件夹
UPLOAD_FOLDER = '/opt/barcode-system/backend/uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB文件大小限制

# 支持的条码类型
SUPPORTED_BARCODE_TYPES = {
    'QRCODE': '二维码',
    'CODE128': 'Code 128',
    'CODE39': 'Code 39',
    'EAN13': 'EAN-13',
    'EAN8': 'EAN-8',
    'UPC-A': 'UPC-A'
}

@app.route('/')
def index():
    """首页"""
    return jsonify({
        'message': '条码识别与生成系统 API',
        'version': '1.0.0',
        'endpoints': {
            '/scan': 'POST - 识别条码',
            '/api/scan': 'POST - 识别条码',
            '/generate': 'POST - 生成条码',
            '/api/generate': 'POST - 生成条码',
            '/health': 'GET - 健康检查'
        }
    })

@app.route('/health')
def health_check():
    """健康检查接口"""
    return jsonify({'status': 'healthy', 'message': '服务运行正常'})

@app.route('/scan', methods=['POST'])
@app.route('/api/scan', methods=['POST'])
def scan_barcode():
    """识别条形码/二维码"""
    try:
        # 支持两种方式上传：文件上传和base64
        if 'file' in request.files:
            # 文件上传方式（Element Plus el-upload默认字段名为'file'）
            file = request.files['file']
            if file.filename == '':
                return jsonify({'success': False, 'message': '未选择文件'})
            
            # 读取图片
            image_data = file.read()
            nparr = np.frombuffer(image_data, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if img is None:
                return jsonify({'success': False, 'message': '无法读取图片'})
        elif 'image' in request.files:
            # 文件上传方式（兼容旧字段名'image'）
            file = request.files['image']
            if file.filename == '':
                return jsonify({'success': False, 'message': '未选择文件'})
            
            # 读取图片
            image_data = file.read()
            nparr = np.frombuffer(image_data, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if img is None:
                return jsonify({'success': False, 'message': '无法读取图片'})
                
        elif 'image' in request.json:
            # base64方式上传
            base64_data = request.json['image']
            if base64_data.startswith('data:image'):
                # 去除data:image/jpeg;base64,前缀
                base64_data = base64_data.split(',')[1]
            
            try:
                # 解码base64
                image_data = base64.b64decode(base64_data)
                nparr = np.frombuffer(image_data, np.uint8)
                img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                
                if img is None:
                    return jsonify({'success': False, 'message': '图片解码失败'})
                    
            except Exception as e:
                return jsonify({'success': False, 'message': f'base64解码错误: {str(e)}'})
        else:
            return jsonify({'success': False, 'message': '未上传图片或图片数据'})
        
        # 识别条码
        if ZBAR_AVAILABLE:
            # 使用pyzbar进行识别
            barcodes = pyzbar.decode(img)
            
            if barcodes:
                results = []
                for barcode in barcodes:
                    try:
                        barcode_data = barcode.data.decode("utf-8")
                    except:
                        barcode_data = str(barcode.data)
                    
                    barcode_type = barcode.type
                    results.append({
                        'type': barcode_type,
                        'data': barcode_data,
                        'points': [(point.x, point.y) for point in barcode.polygon]
                    })
                
                return jsonify({
                    'success': True, 
                    'results': results,
                    'count': len(results),
                    'message': f'成功识别到 {len(results)} 个条码'
                })
            else:
                return jsonify({'success': False, 'message': '未识别到条码'})
        else:
            # pyzbar不可用时的备用方案：使用OpenCV进行基本二维码识别
            # 这里可以添加简单的二维码识别逻辑，或者返回提示信息
            return jsonify({
                'success': False, 
                'message': '条码识别功能暂不可用，请安装zbar系统库。Ubuntu: sudo apt-get install libzbar-dev, CentOS: sudo yum install zbar-devel'
            })
            
    except Exception as e:
        return jsonify({'success': False, 'message': f'识别错误: {str(e)}'})

@app.route('/generate', methods=['POST'])
@app.route('/api/generate', methods=['POST'])
def generate_barcode():
    """生成条码"""
    try:
        data = request.json
        content = data.get('content', '').strip()
        barcode_type = data.get('barcode_type', 'QRCODE').upper()
        
        if not content:
            return jsonify({'success': False, 'message': '请输入内容'})
        
        # 生成条码
        if barcode_type == 'QRCODE':
            # 生成二维码
            qr = qrcode.QRCode(
                version=1,
                error_correction=qrcode.constants.ERROR_CORRECT_L,
                box_size=10,
                border=4,
            )
            qr.add_data(content)
            qr.make(fit=True)
            
            img = qr.make_image(fill_color="black", back_color="white")
            
            # 保存到内存
            img_buffer = io.BytesIO()
            img.save(img_buffer, format='PNG')
            img_buffer.seek(0)
            
            # 转换为base64
            image_base64 = base64.b64encode(img_buffer.getvalue()).decode('utf-8')
            
            return jsonify({
                'success': True,
                'image_url': f'data:image/png;base64,{image_base64}',
                'message': '二维码生成成功'
            })
            
        else:
            # 生成条形码
            try:
                if barcode_type == 'CODE128':
                    barcode_class = barcode.Code128
                elif barcode_type == 'CODE39':
                    barcode_class = barcode.Code39
                elif barcode_type == 'EAN13':
                    barcode_class = barcode.EAN13
                elif barcode_type == 'EAN8':
                    barcode_class = barcode.EAN8
                elif barcode_type == 'UPC-A':
                    barcode_class = barcode.UPCA
                else:
                    return jsonify({'success': False, 'message': f'不支持的条码类型: {barcode_type}'})
                
                # 生成条码
                barcode_obj = barcode_class(content, writer=ImageWriter())
                
                # 保存到内存
                img_buffer = io.BytesIO()
                barcode_obj.write(img_buffer)
                img_buffer.seek(0)
                
                # 转换为base64
                image_base64 = base64.b64encode(img_buffer.getvalue()).decode('utf-8')
                
                return jsonify({
                    'success': True,
                    'image_url': f'data:image/png;base64,{image_base64}',
                    'message': f'{barcode_type}条码生成成功'
                })
                
            except Exception as e:
                return jsonify({'success': False, 'message': f'条码生成失败: {str(e)}'})
                
    except Exception as e:
        return jsonify({'success': False, 'message': f'生成错误: {str(e)}'})

@app.route('/supported-types')
def get_supported_types():
    """获取支持的条码类型"""
    return jsonify({
        'success': True,
        'types': SUPPORTED_BARCODE_TYPES
    })

if __name__ == '__main__':
    # 服务器配置
    host = '0.0.0.0'  # 允许外部访问
    port = 5000
    
    print(f"🚀 条码识别与生成系统启动中...")
    print(f"🌐 服务地址: http://{host}:{port}")
    print(f"📱 小程序API地址: http://39.106.19.163:5000")
    print("=" * 50)
    
    # 启动Flask应用
    app.run(
        host=host,
        port=port,
        debug=False,  # 生产环境关闭调试模式
        threaded=True
    )