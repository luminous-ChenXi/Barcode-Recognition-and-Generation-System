from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import cv2
import numpy as np
from pyzbar.pyzbar import decode
import qrcode
from PIL import Image
import io
import base64
import os

app = Flask(__name__)
CORS(app)  # 允许跨域请求

# 确保上传目录存在
UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

@app.route('/')
def index():
    return jsonify({"message": "条码识别与生成API服务"})

@app.route('/api/scan-barcode', methods=['POST'])
def scan_barcode():
    """识别条形码/二维码"""
    try:
        # 支持两种方式上传：文件上传和base64
        if 'image' in request.files:
            # 文件上传方式
            file = request.files['image']
            if file.filename == '':
                return jsonify({"error": "未选择文件"}), 400
            
            # 读取图片
            image_data = file.read()
            nparr = np.frombuffer(image_data, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if img is None:
                return jsonify({"error": "无法读取图片"}), 400
                
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
                    return jsonify({"error": "图片解码失败"}), 400
                    
            except Exception as e:
                return jsonify({"error": f"base64解码错误: {str(e)}"}), 400
        else:
            return jsonify({"error": "未上传图片或图片数据"}), 400
        
        # 识别条码
        decoded_objects = decode(img)
        
        results = []
        for obj in decoded_objects:
            result = {
                "type": obj.type,
                "data": obj.data.decode('utf-8'),
                "points": [{"x": point.x, "y": point.y} for point in obj.polygon]
            }
            results.append(result)
        
        return jsonify({
            "success": True,
            "count": len(results),
            "results": results
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/generate-barcode', methods=['POST'])
def generate_barcode():
    """生成条形码/二维码"""
    try:
        data = request.json
        if not data or 'text' not in data:
            return jsonify({"error": "缺少文本内容"}), 400
        
        text = data['text']
        barcode_type = data.get('type', 'QRCODE')  # QRCODE, CODE128等
        
        if barcode_type.upper() == 'QRCODE':
            # 生成二维码
            qr = qrcode.QRCode(
                version=1,
                error_correction=qrcode.constants.ERROR_CORRECT_L,
                box_size=10,
                border=4,
            )
            qr.add_data(text)
            qr.make(fit=True)
            
            img = qr.make_image(fill_color="black", back_color="white")
            
            # 转换为base64
            buffered = io.BytesIO()
            img.save(buffered, format="PNG")
            img_str = base64.b64encode(buffered.getvalue()).decode()
            
            return jsonify({
                "success": True,
                "image": f"data:image/png;base64,{img_str}",
                "type": "QRCODE"
            })
        
        else:
            # 其他类型的条码生成（这里简化处理，实际需要更复杂的库）
            return jsonify({"error": "暂不支持该类型的条码生成"}), 400
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/health')
def health_check():
    """健康检查接口"""
    return jsonify({"status": "healthy", "service": "barcode-api"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)