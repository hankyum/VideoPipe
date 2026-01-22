# VideoPipe2 Docker X11 Forwarding (macOS)

## 快速开始

### 1. 首次设置（只需一次）

```bash
# 安装 XQuartz（如果尚未安装）
brew install --cask xquartz

# 启用 XQuartz TCP 连接
defaults write org.xquartz.X11 nolisten_tcp 0

# 重启 XQuartz
pkill Xquartz && sleep 2 && open -a XQuartz
```

### 2. 启动容器

```bash
# 方式 1：使用 docker-run.sh（推荐）
./docker-run.sh

# 方式 2：使用 docker-compose
docker-compose -f docker-compose-dev.yml up -d
docker exec -it videopipe2_dev bash
```

### 3. 运行示例程序

在容器内或从主机终端执行：

```bash
# 列出所有可用示例
./docker-exec.sh list-samples

# 运行特定示例
./docker-exec.sh run face_tracking_sample
./docker-exec.sh run 1-1-1_sample
```

## 验证 X11 转发

运行测试脚本：

```bash
./docker-test-x11.sh
```

如果看到 X11 窗口弹出，说明配置成功！

## 常见问题

### GTK 错误：Can't initialize GTK backend

**解决方法：**

1. 确保 XQuartz 正在运行：
   ```bash
   ps aux | grep Xquartz
   ```

2. 确认 XQuartz 监听 TCP 端口：
   ```bash
   lsof -i -P | grep LISTEN | grep 6000
   ```

3. 重启 XQuartz：
   ```bash
   pkill Xquartz && sleep 2 && open -a XQuartz
   ```

### 授权错误：Authorization required

这是正常的，因为使用 `host.docker.internal:0` 模式不需要 XAUTHORITY 文件。如果仍然遇到此错误，重启容器即可。

### 容器内显示设备错误

确保容器使用 `host.docker.internal:0` 作为 DISPLAY：

```bash
docker exec videopipe2_dev echo $DISPLAY
# 应该输出：host.docker.internal:0
```

## 技术细节

### macOS Docker Desktop 配置

- **DISPLAY**: `host.docker.internal:0`（Docker Desktop 特殊域名）
- **网络模式**: 不使用 `--network host`
- **XAUTHORITY**: 不需要（使用 host.docker.internal 时）
- **XQuartz**: 需要启用 TCP 连接（nolisten_tcp=0）

### Linux 配置

- **DISPLAY**: `${DISPLAY:-:0}`
- **网络模式**: `--network host`
- **X11 Socket**: `/tmp/.X11-unix/X0`
- **权限**: 使用 `xhost +local:docker`

## 文件说明

- `docker-run.sh`: 启动容器的脚本
- `docker-exec.sh`: 在容器内执行命令的便捷脚本
- `docker-setup-x11.sh`: X11 转发配置脚本
- `docker-test-x11.sh`: X11 转发测试脚本
- `docker-x11-quick.sh`: 简化的 X11 快速设置脚本

## 注意事项

1. **首次设置**: 只需运行一次 XQuartz TCP 配置
2. **XQuartz 重启**: 每次重启 Mac 后可能需要重新启动 XQuartz
3. **视频文件**: 某些示例需要测试视频文件，请将其放在 `vp_data` 目录
4. **模型文件**: AI 功能需要模型文件，请根据需要下载

## 获取帮助

如果遇到问题：

1. 检查容器状态：`docker ps`
2. 查看容器日志：`docker logs videopipe2_dev`
3. 测试 X11 配置：`./docker-test-x11.sh`
4. 查看详细文档：`cat DOCKER_README.md`

祝使用愉快！
