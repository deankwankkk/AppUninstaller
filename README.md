# AppUninstaller

macOS 原生应用卸载工具，彻底清理应用残留文件。

## 功能

### 卸载应用
- 扫描 `/Applications` 和 `~/Applications` 中的第三方应用
- 以 Bundle ID 为主键深度扫描关联文件：
  - 偏好设置 (Preferences)
  - 缓存 (Caches)
  - 应用支持 (Application Support)
  - 日志 (Logs)
  - 容器 (Containers / Group Containers)
  - 启动代理 (LaunchAgents)
  - 保存状态 (Saved Application State)
  - HTTP 存储 / WebKit / Cookies
- 支持拖放 `.app` 文件直接卸载
- 列出所有关联文件及大小，勾选确认后删除
- 优先移入废纸篓（可恢复）

### 清除缓存
- 扫描系统缓存、应用缓存、日志文件
- 扫描 Xcode DerivedData / Archives / Simulator 缓存
- 扫描浏览器缓存（Chrome、Safari、Firefox、Edge）
- 支持指定自定义目录扫描
- 按分类分组展示，按大小排序

## 要求

- macOS 13+
- Swift 5.9+

## 构建与运行

```bash
# 编译
swift build

# 运行
swift run

# Release 编译
swift build -c release
```

## 技术栈

- Swift + SwiftUI
- Swift Package Manager
- 非沙盒应用（需要访问 ~/Library）
