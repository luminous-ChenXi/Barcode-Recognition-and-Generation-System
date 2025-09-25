import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 3000,
    allowedHosts: [
            'tiaoma.luminouschenxi.com',  // 允许这个主机
            'localhost',                  // 保留本地访问
            '127.0.0.1'                   // 保留本地IP访问
        ],
    proxy: {
      '/api': {
        target: 'http://localhost:5000',
        changeOrigin: true,
      }
    }
  }
})