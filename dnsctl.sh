#!/bin/bash

# ======================
# 配置区（按需修改）
# ======================
REPO_URL="https://raw.githubusercontent.com/c-ujung/scripts-hub/main/dnsctl.sh"
INSTALL_PATH="/usr/local/bin/dnsctl"
CONF_HEAD="/etc/resolvconf/resolv.conf.d/head"
BACKUP_FILE="/etc/resolvconf/resolv.conf.d/head.bak"

# ======================
# 颜色常量
# ======================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ======================
# 安装函数（新增关键部分）
# ======================
install_script() {
  echo -e "${GREEN}▶ 正在安装dnsctl工具...${NC}"
  
  # 强制下载最新版本
  if ! curl -fsSL "$REPO_URL" -o "$INSTALL_PATH"; then
    echo -e "${RED}✗ 下载失败，请检查网络连接和仓库地址${NC}" >&2
    exit 1
  fi

  # 设置可执行权限
  chmod +x "$INSTALL_PATH"

  # 验证安装
  if command -v dnsctl &> /dev/null; then
    echo -e "${GREEN}✔ 安装成功！可通过 dnsctl 命令使用${NC}"
    echo -e "${BLUE}提示：如果提示命令未找到，请执行以下命令："
    echo -e "   source ~/.bashrc 或重新登录终端${NC}"
  else
    echo -e "${RED}✗ 安装异常，请手动检查${NC}" >&2
    exit 1
  fi
}

# ======================
# 核心功能函数
# ======================

check_root() {
  [ "$(id -u)" -ne 0 ] && echo -e "${RED}✗ 请使用sudo执行本命令！${NC}" >&2 && exit 1
}

validate_ip() {
  local ip="$1"
  if ! ip route get "$ip" >/dev/null 2>&1; then
    echo -e "${RED}✗ 无效的IP地址：$ip ${NC}" >&2
    exit 1
  fi
}

set_dns() {
  check_root
  echo -e "${BLUE}▶ 正在设置DNS服务器...${NC}"
  
  [ ! -f "$BACKUP_FILE" ] && cp "$CONF_HEAD" "$BACKUP_FILE" 2>/dev/null
  > "$CONF_HEAD"
  for dns in "$@"; do
    validate_ip "$dns"
    echo "nameserver $dns" >> "$CONF_HEAD"
  done

  resolvconf -u
  echo -e "${GREEN}✔ DNS已更新！当前配置：${NC}"
  check_status
}

restore_dns() {
  check_root
  echo -e "${YELLOW}♻ 正在恢复原始DNS配置...${NC}"
  
  if [ -f "$BACKUP_FILE" ]; then
    cp -f "$BACKUP_FILE" "$CONF_HEAD"
  else
    echo -e "${YELLOW}⚠ 未找到备份文件，正在清空配置...${NC}"
    > "$CONF_HEAD"
  fi
  
  resolvconf -u
  echo -e "${GREEN}✔ 已恢复默认DNS配置${NC}"
}

check_status() {
  echo -e "${BLUE}当前DNS配置：${NC}"
  grep -E 'nameserver\s+([0-9a-fA-F:.]+)' /etc/resolv.conf || 
    echo -e "${YELLOW}未检测到有效DNS配置${NC}"
}

uninstall_script() {
  check_root
  echo -e "${YELLOW}⚠ 开始卸载流程...${NC}"
  
  restore_dns
  [ -f "$INSTALL_PATH" ] && rm -f "$INSTALL_PATH"
  
  if [ -f "$BACKUP_FILE" ]; then
    echo -e "${BLUE}? 是否删除DNS备份文件？ [y/N]${NC}"
    read -r choice
    [[ "$choice" =~ [Yy] ]] && rm -f "$BACKUP_FILE"
  fi

  echo -e "${GREEN}✔ 卸载完成！系统已恢复初始状态${NC}"
}

# ======================
# 主逻辑
# ======================
case "$1" in
  install)    install_script ;;
  set)        shift; set_dns "$@" ;;
  restore)    restore_dns ;;
  status)     check_status ;;
  uninstall)  uninstall_script ;;
  *)
    echo -e "${GREEN}使用方法："
    echo -e "  sudo dnsctl set [DNS列表]  # 设置DNS服务器"
    echo -e "  sudo dnsctl restore       # 恢复原始配置"
    echo -e "  sudo dnsctl uninstall     # 完全卸载工具"
    echo -e "  sudo dnsctl status        # 查看当前配置${NC}"
    ;;
esac
