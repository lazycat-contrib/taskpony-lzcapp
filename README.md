# Taskpony - LazyCat 应用

每天定时检查 Taskpony 稳定版本，并支持 `v*` tag 和手动触发懒猫官方商店与喵喵私有商店发布。

**一个小巧整洁的任务整理器**

---

## 📦 应用信息

- **应用名称**: Taskpony
- **包名**: `cloud.lazycat.app.taskpony`
- **版本**: 0.2.0
- **最低 LazyCat OS**: 1.5.0
- **原始项目**: [digdilem/taskpony](https://github.com/digdilem/taskpony)

## 🚀 快速部署

### 1. 准备图标
准备一个 512x512 PNG 图标文件，命名为 `icon.png`

### 2. 本地安装测试
```bash
# 构建应用
./build.sh
# 选择 1

# 安装到本地
lzc-cli app install taskpony-1.0.0.lpk

# 访问
# https://taskpony.lazycat.cloud
```

### 3. 发布到应用商店
```bash
# 登录
lzc-cli appstore login

# 一键发布
./build.sh
# 选择 4

# 等待审核（1-3个工作日）
```

## 📁 文件说明

| 文件 | 说明 |
|------|------|
| `package.yml` | LPK v2 应用元数据（含中英文） |
| `lzc-manifest.yml` | 应用运行配置 |
| `lzc-build.yml` | 构建配置 |
| `build.sh` | 自动化脚本 |
| `icon.png` | 应用图标（需用户提供） |

## 🔧 配置特点

- ✅ **零配置** - 安装后直接使用
- ✅ **中英文** - 支持多语言
- ✅ **自动监控** - 内置健康检查
- ✅ **资源限制** - 512MB 内存
- ✅ **Upstreams 路由** - 推荐的现代写法

## 📖 使用说明

### 访问地址
```
https://taskpony.lazycat.cloud
```

### 数据存储
- 路径: `/lzcapp/var/taskpony`
- 自动持久化，更新应用不丢失数据

### 资源占用
- CPU: 512 shares (约 0.5 核心)
- 内存: 512 MB
- 存储: 动态增长

## 🛠️ build.sh 脚本

```
1. 📦 构建应用
2. 🔧 镜像复制到懒猫仓库
3. 📤 发布到应用商店
4. 🚀 一键发布（推荐）
5. 📋 查看应用信息
6. ❌ 退出
```

## 📞 获取帮助

- **开发者文档**: https://developer.lazycat.cloud
- **应用商店**: https://gitee.com/lazycatcloud/appdb
- **原始项目**: https://github.com/digdilem/taskpony

---

**版本**: 1.0.0 | **更新**: 2025-12-25
