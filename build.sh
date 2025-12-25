#!/bin/bash
# Taskpony - LazyCat Application Build & Publish Automation Script
# Complete workflow: Build → Copy Image → Publish

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 应用信息
APP_NAME="Taskpony"
APP_PACKAGE="cloud.lazycat.app.taskpony"
APP_VERSION="1.0.0"
ORIGINAL_IMAGE="digdilem/taskpony:latest"

# 文件检查
REQUIRED_FILES=("lzc-manifest.yml" "lzc-build.yml")

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "\n${BLUE}==>${NC} $1"
}

# 检查必要文件
check_files() {
    print_step "检查必要文件"
    local missing=0

    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$file" ]; then
            print_success "找到: $file"
        else
            print_error "缺少: $file"
            missing=$((missing + 1))
        fi
    done

    if [ ! -f "icon.png" ]; then
        print_warning "缺少: icon.png (512x512 PNG图标)"
        print_info "请准备图标文件后继续"
    else
        print_success "找到: icon.png"
    fi

    if [ $missing -gt 0 ]; then
        print_error "缺少 $missing 个必要文件，无法继续"
        exit 1
    fi
}

# 验证配置文件
validate_config() {
    print_step "验证配置文件格式"

    # 检查 YAML 语法
    if command -v yq &> /dev/null; then
        print_info "使用 yq 验证 YAML 格式..."
        for file in "${REQUIRED_FILES[@]}"; do
            if yq e '.' "$file" > /dev/null 2>&1; then
                print_success "$file 格式正确"
            else
                print_error "$file 格式错误"
                exit 1
            fi
        done
    else
        print_warning "yq 未安装，跳过 YAML 语法验证"
    fi

    # 检查 manifest 必要字段
    print_info "检查 manifest 必要字段..."
    local name=$(yq e '.name' lzc-manifest.yml 2>/dev/null)
    local package=$(yq e '.package' lzc-manifest.yml 2>/dev/null)
    local version=$(yq e '.version' lzc-manifest.yml 2>/dev/null)
    local min_os=$(yq e '.min_os_version' lzc-manifest.yml 2>/dev/null)

    if [ "$name" != "null" ] && [ "$package" != "null" ] && [ "$version" != "null" ] && [ "$min_os" != "null" ]; then
        print_success "Manifest 核心字段完整"
        print_info "应用名称: $name"
        print_info "包名: $package"
        print_info "版本: $version"
        print_info "最低 OS 版本: $min_os"
    else
        print_error "Manifest 缺少必要字段"
        exit 1
    fi
}

# 显示应用信息
show_info() {
    print_step "应用信息概览"

    echo -e "\n${BLUE}=== 应用基本信息 ===${NC}"
    echo "名称: $APP_NAME"
    echo "包名: $APP_PACKAGE"
    echo "版本: $APP_VERSION"
    echo "原始镜像: $ORIGINAL_IMAGE"

    echo -e "\n${BLUE}=== 部署配置 ===${NC}"
    echo "类型: 简单应用（零配置）"
    echo "参数数量: 0"
    echo "说明: 安装后即可直接使用，无需任何配置"

    echo -e "\n${BLUE}=== 服务配置 ===${NC}"
    local services=$(yq e '.services | keys | .[]' lzc-manifest.yml 2>/dev/null)
    if [ -n "$services" ]; then
        echo "服务列表:"
        for svc in $services; do
            local image=$(yq e ".services.$svc.image" lzc-manifest.yml 2>/dev/null)
            echo "  - $svc: $image"
        done
    fi

    echo -e "\n${BLUE}=== 多语言支持 ===${NC}"
    echo "✅ 英文 (English)"
    echo "✅ 中文 (简体中文)"

    echo -e "\n${BLUE}=== 访问方式 ===${NC}"
    local subdomain=$(yq e '.application.subdomain' lzc-manifest.yml 2>/dev/null)
    echo "子域名: $subdomain"
    echo "访问地址: https://$subdomain.lazycat.cloud"
}

# 构建应用
build_app() {
    print_step "构建 LPK 包"

    if [ ! -f "icon.png" ]; then
        print_error "缺少 icon.png 文件，无法构建"
        print_info "请准备 512x512 PNG 图标"
        return 1
    fi

    local version=$(yq e '.version' lzc-manifest.yml)
    local output_file="${APP_NAME,,}-${version}.lpk"

    print_info "构建版本: $version"
    print_info "输出文件: $output_file"

    # 执行构建命令
    if lzc-cli project build -o "$output_file" 2>&1; then
        print_success "构建成功: $output_file"

        if [ -f "$output_file" ]; then
            local size=$(ls -lh "$output_file" | awk '{print $5}')
            print_info "文件大小: $size"
        fi
    else
        print_error "构建失败"
        return 1
    fi
}

# 检查登录状态
check_login() {
    print_info "检查懒猫应用商店登录状态..."

    # 使用 my-images 命令检查登录状态
    if lzc-cli appstore my-images &> /dev/null 2>&1; then
        print_success "已登录懒猫应用商店"
        return 0
    else
        print_warning "未登录懒猫应用商店"
        print_info "请先执行: lzc-cli appstore login"
        return 1
    fi
}

# 复制镜像到懒猫仓库
copy_image() {
    print_step "复制镜像到懒猫仓库"

    # 检查登录状态
    if ! check_login; then
        return 1
    fi

    print_info "原始镜像: $ORIGINAL_IMAGE"
    print_info "正在复制到懒猫官方仓库..."

    # 执行镜像复制
    local copy_output=$(lzc-cli appstore copy-image "$ORIGINAL_IMAGE" 2>&1)
    echo "$copy_output"

    # 提取新镜像地址
    local new_image=$(echo "$copy_output" | grep "lazycat-registry:" | sed 's/.*lazycat-registry: //')

    if [ -n "$new_image" ]; then
        print_success "镜像复制成功"
        print_info "新镜像地址: $new_image"

        # 自动更新 manifest
        update_manifest_image "$new_image"
        return 0
    else
        print_error "镜像复制失败或未找到新镜像地址"
        return 1
    fi
}

# 更新 manifest 中的镜像地址
update_manifest_image() {
    local new_image="$1"

    print_step "自动更新 manifest 镜像地址"
    print_info "新镜像: $new_image"

    # 备份原文件
    cp lzc-manifest.yml lzc-manifest.yml.backup

    # 更新镜像
    sed -i "s|image: .*|image: $new_image|" lzc-manifest.yml

    # 验证更新
    local updated_image=$(yq e '.services.taskpony.image' lzc-manifest.yml)
    if [ "$updated_image" = "$new_image" ]; then
        print_success "manifest 更新成功"
        print_info "旧镜像: $ORIGINAL_IMAGE"
        print_info "新镜像: $updated_image"
    else
        print_error "manifest 更新失败"
        # 恢复备份
        mv lzc-manifest.yml.backup lzc-manifest.yml
        return 1
    fi
}

# 发布到应用商店
publish_app() {
    print_step "发布到懒猫应用商店"

    # 检查登录状态
    if ! check_login; then
        return 1
    fi

    local version=$(yq e '.version' lzc-manifest.yml)
    local lpk_file="${APP_NAME,,}-${version}.lpk"

    if [ ! -f "$lpk_file" ]; then
        print_error "LPK 文件不存在: $lpk_file"
        print_info "请先构建应用"
        return 1
    fi

    print_info "发布文件: $lpk_file"
    print_info "版本: $version"
    print_warning "即将提交审核（审核时间：1-3个工作日）"

    read -p "确认发布? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "已取消发布"
        return 0
    fi

    print_info "正在发布..."
    if lzc-cli appstore publish "$lpk_file" 2>&1; then
        print_success "发布成功！"
        print_info "请等待审核（1-3个工作日）"
        print_info "审核通过后，用户可在应用商店搜索 '$APP_NAME' 安装"
    else
        print_error "发布失败"
        return 1
    fi
}

# 一键发布流程
one_click_publish() {
    print_step "🚀 一键发布流程（4阶段）"

    echo -e "\n${YELLOW}阶段 1: 初始构建（使用原始镜像）${NC}"
    if ! build_app; then
        print_error "阶段 1 失败"
        return 1
    fi

    echo -e "\n${YELLOW}阶段 2: 镜像复制（自动更新 manifest）${NC}"
    if ! copy_image; then
        print_error "阶段 2 失败"
        return 1
    fi

    echo -e "\n${YELLOW}阶段 3: 重新构建（使用新镜像）${NC}"
    if ! build_app; then
        print_error "阶段 3 失败"
        return 1
    fi

    echo -e "\n${YELLOW}阶段 4: 发布审核${NC}"
    if ! publish_app; then
        print_error "阶段 4 失败"
        return 1
    fi

    print_success "🎉 一键发布完成！"
    echo -e "\n${GREEN}=== 发布摘要 ===${NC}"
    echo "✅ 初始构建完成"
    echo "✅ 镜像复制完成"
    echo "✅ 重新构建完成"
    echo "✅ 发布提交完成"
    echo -e "\n${BLUE}下一步: 等待审核（1-3个工作日）${NC}"
}

# 主菜单
main_menu() {
    while true; do
        echo -e "\n${BLUE}=== Taskpony LazyCat 应用发布工具 ===${NC}"
        echo "1. 📦 构建应用 (Build)"
        echo "2. 🔧 镜像复制到懒猫仓库 (Copy Image)"
        echo "3. 📤 发布到应用商店 (Publish)"
        echo "4. 🚀 一键构建+镜像复制+发布 (One-Click)"
        echo "5. 📋 查看应用信息 (Info)"
        echo "6. ❌ 退出"
        echo -e "\n请选择操作 (1-6): "

        read -r choice
        case $choice in
            1)
                check_files
                validate_config
                build_app
                ;;
            2)
                check_files
                copy_image
                ;;
            3)
                check_files
                publish_app
                ;;
            4)
                check_files
                validate_config
                one_click_publish
                ;;
            5)
                show_info
                ;;
            6)
                print_info "再见！"
                exit 0
                ;;
            *)
                print_error "无效选择"
                ;;
        esac
    done
}

# 脚本入口
if [ "$1" = "info" ]; then
    show_info
elif [ "$1" = "build" ]; then
    check_files
    validate_config
    build_app
elif [ "$1" = "copy" ]; then
    check_files
    copy_image
elif [ "$1" = "publish" ]; then
    check_files
    publish_app
elif [ "$1" = "oneclick" ]; then
    check_files
    validate_config
    one_click_publish
else
    main_menu
fi