<template>
  <div id="app">
    <el-container class="app-container">
      <!-- 头部导航 -->
      <el-header class="app-header">
        <div class="header-content">
          <h1 class="title">
            <el-icon><Camera /></el-icon>
            条码识别与生成系统
          </h1>
          <el-button type="primary" @click="switchMode">
            {{ currentMode === 'scan' ? '切换到生成模式' : '切换到识别模式' }}
          </el-button>
        </div>
      </el-header>

      <!-- 主要内容区域 -->
      <el-main class="app-main">
        <!-- 识别模式 -->
        <div v-if="currentMode === 'scan'" class="scan-mode">
          <el-card class="scan-card">
            <template #header>
              <div class="card-header">
                <span>条码识别</span>
                <el-button type="primary" @click="openCamera">
                  <el-icon><Camera /></el-icon>
                  打开摄像头
                </el-button>
              </div>
            </template>

            <!-- 图片上传区域 -->
            <div class="upload-area">
              <el-upload
                class="upload-demo"
                drag
                :http-request="customUpload"
                :before-upload="beforeUpload"
                :show-file-list="false"
              >
                <el-icon class="el-icon--upload"><upload-filled /></el-icon>
                <div class="el-upload__text">
                  拖拽图片到此处或 <em>点击上传</em>
                </div>
                <template #tip>
                  <div class="el-upload__tip">
                    支持 jpg/png 格式的图片，大小不超过 5MB
                  </div>
                </template>
              </el-upload>
            </div>

            <!-- 识别结果 -->
            <div v-if="scanResults.length > 0" class="results-section">
              <h3>识别结果 ({{ scanResults.length }} 个条码)</h3>
              <el-table :data="scanResults" style="width: 100%">
                <el-table-column prop="type" label="类型" width="120" />
                <el-table-column prop="data" label="内容" />
              </el-table>
            </div>
          </el-card>
        </div>
        <!-- 第二块 -->
        <div v-if="currentMode === 'scan'" class="scan-mode">
          <el-card class="scan-card">
            <template #header>
              <div class="card-header">
                <span>第10小组</span>
              </div>
            </template>
          </el-card>
        </div>

        <!-- 生成模式 -->
        <div v-else class="generate-mode">
          <el-card class="generate-card">
            <template #header>
              <div class="card-header">
                <span>条码生成</span>
              </div>
            </template>

            <!-- 生成表单 -->
            <el-form :model="generateForm" label-width="80px">
              <el-form-item label="内容">
                <el-input
                  v-model="generateForm.text"
                  placeholder="请输入要生成条码的内容"
                  type="textarea"
                  :rows="3"
                />
              </el-form-item>
              <el-form-item label="类型">
                <el-select v-model="generateForm.type" placeholder="选择条码类型">
                  <el-option label="二维码 (QR Code)" value="QRCODE" />
                  <el-option label="条形码 (Code 128)" value="CODE128" />
                </el-select>
              </el-form-item>
              <el-form-item>
                <el-button type="primary" @click="generateBarcode" :loading="generating">
                  生成条码
                </el-button>
                <el-button @click="downloadBarcode" :disabled="!generatedImage">
                  下载图片
                </el-button>
              </el-form-item>
            </el-form>

            <!-- 生成的条码图片 -->
            <div v-if="generatedImage" class="generated-image">
              <h4>生成的条码：</h4>
              <img :src="generatedImage" alt="生成的条码" class="barcode-image" />
            </div>
          </el-card>
        </div>
      </el-main>

      <!-- 底部信息 -->
      <el-footer class="app-footer">
        <div class="footer-content">
          <p>条码识别与生成系统 &copy; 2024</p>
        </div>
        <!-- 组员信息 -->
        <div class="group-info">
          <p>——————</p>
        </div>
      </el-footer>
    </el-container>
  </div>
</template>

<script>
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

export default {
  name: 'App',
  data() {
    return {
      currentMode: 'scan', // scan 或 generate
      scanResults: [],
      generateForm: {
        text: '',
        type: 'QRCODE'
      },
      generatedImage: null,
      generating: false
    }
  },
  methods: {
    // 切换模式
    switchMode() {
      this.currentMode = this.currentMode === 'scan' ? 'generate' : 'scan'
      this.scanResults = []
      this.generatedImage = null
    },

    // 打开摄像头（在微信小程序中实现）
    openCamera() {
      ElMessage.info('在微信小程序中，此功能将调用手机摄像头')
    },

    // 上传前验证
    beforeUpload(file) {
      const isJPGOrPNG = file.type === 'image/jpeg' || file.type === 'image/png'
      const isLt5M = file.size / 1024 / 1024 < 5

      if (!isJPGOrPNG) {
        ElMessage.error('只能上传 JPG/PNG 格式的图片!')
        return false
      }
      if (!isLt5M) {
        ElMessage.error('图片大小不能超过 5MB!')
        return false
      }
      return true
    },

    // 自定义上传方法
    async customUpload(options) {
      const { file, onProgress } = options
      
      try {
        // 创建FormData对象
        const formData = new FormData()
        formData.append('file', file)
        
        // 使用axios发送上传请求
        const response = await axios.post('/api/scan', formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          },
          onUploadProgress: (progressEvent) => {
            if (progressEvent.total > 0) {
              const percent = Math.round((progressEvent.loaded * 100) / progressEvent.total)
              onProgress({ percent })
            }
          }
        })
        
        // 直接调用处理函数
        this.handleScanSuccess(response, file)
      } catch (error) {
        // 直接调用错误处理函数
        this.handleScanError(error, file)
      }
    },

    // 识别成功处理
    handleScanSuccess(response, file) {
      console.log('Upload success response:', response)
      
      // 检查响应数据结构
      if (response && response.data && response.data.success) {
        this.scanResults = response.data.results
        ElMessage.success(`成功识别到 ${response.data.count} 个条码`)
      } else if (response && response.success) {
        // 兼容旧的数据结构
        this.scanResults = response.results
        ElMessage.success(`成功识别到 ${response.count} 个条码`)
      } else {
        ElMessage.error(response?.data?.error || response?.error || '识别失败')
      }
    },

    // 识别错误处理
    handleScanError(error, file) {
      console.error('Upload error details:', error)
      
      // 检查错误类型并显示更具体的错误信息
      if (error.response) {
        // 服务器返回了错误状态码
        const status = error.response.status
        const message = error.response.data?.message || error.response.data?.error || '服务器错误'
        
        if (status === 404) {
          ElMessage.error('API接口不存在，请检查后端服务是否正常运行')
        } else if (status === 500) {
          ElMessage.error('服务器内部错误，请稍后重试')
        } else {
          ElMessage.error(`上传失败: ${message} (状态码: ${status})`)
        }
      } else if (error.request) {
        // 请求已发送但没有收到响应
        ElMessage.error('无法连接到服务器，请检查网络连接和后端服务状态')
      } else {
        // 其他错误
        ElMessage.error(`上传失败: ${error.message || '未知错误'}`)
      }
    },

    // 生成条码
    async generateBarcode() {
      if (!this.generateForm.text.trim()) {
        ElMessage.warning('请输入要生成条码的内容')
        return
      }

      this.generating = true
      try {
        // 构建符合后端要求的参数
        const requestData = {
          content: this.generateForm.text,
          barcode_type: this.generateForm.type
        }
        
        const response = await axios.post('/api/generate', requestData)
        if (response.data.success) {
          this.generatedImage = response.data.image_url
          ElMessage.success('条码生成成功!')
        } else {
          ElMessage.error(response.data.message || '生成失败')
        }
      } catch (error) {
        ElMessage.error('生成失败，请检查网络连接')
        console.error('Generate error:', error)
      } finally {
        this.generating = false
      }
    },

    // 下载生成的条码
    downloadBarcode() {
      if (!this.generatedImage) return

      const link = document.createElement('a')
      link.href = this.generatedImage
      link.download = `barcode_${Date.now()}.png`
      link.click()
    }
  }
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

#app {
  font-family: 'Helvetica Neue', Helvetica, 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', '微软雅黑', Arial, sans-serif;
  height: 100vh;
}

.app-container {
  height: 100vh;
  display: flex;
  flex-direction: column;
}

.app-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 0 20px;
  display: flex;
  align-items: center;
}

.header-content {
  width: 100%;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.title {
  font-size: 24px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 10px;
}

.app-main {
  flex: 1;
  padding: 20px;
  background-color: #f5f7fa;
}

.scan-card, .generate-card {
  max-width: 800px;
  margin: 0 auto;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.upload-area {
  margin: 20px 0;
}

.results-section {
  margin-top: 30px;
}

.results-section h3 {
  margin-bottom: 15px;
  color: #303133;
}

.generated-image {
  margin-top: 30px;
  text-align: center;
}

.barcode-image {
  max-width: 300px;
  max-height: 300px;
  border: 1px solid #dcdfe6;
  border-radius: 4px;
  padding: 10px;
  background: white;
}

.app-footer {
  background-color: #909399;
  color: white;
  text-align: center;
  padding: 15px 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}

.footer-content p {
  margin: 0;
  font-size: 14px;
}

.group-info {
  background-color: rgba(255, 255, 255, 0.1);
  padding: 8px 16px;
  border-radius: 20px;
  border: 1px solid rgba(255, 255, 255, 0.3);
}

.group-info p {
  margin: 0;
  font-size: 14px;
  font-weight: 500;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .app-header {
    padding: 0 15px;
  }
  
  .title {
    font-size: 18px;
  }
  
  .app-main {
    padding: 15px;
  }
  
  .barcode-image {
    max-width: 250px;
    max-height: 250px;
  }
}
</style>