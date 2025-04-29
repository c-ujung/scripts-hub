#!/bin/bash

# ======================
# 配置区（按需修改）
# ======================
REPO_URL="https://raw.githubusercontent.com/yourname/dns-manager/main"  # ← 修改为实际仓库地址
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
# 核心功能函数
# ======================

# 检查root权限
check_root() {
  [ "$(id -u)" -ne 0 ] && echo -e "${RED}✗ 请使用sudo执行本命令！${NC}" >&2 && exit 1
}

# 验证IP地址（支持IPv4/IPv6）
validate_ip() {
  local ip="$1"
  if ! ip route get "$ip" >/dev/null 2>&1; then
    echo -e "${RED}✗ 无效的IP地址：$ip ${NC}" >&2
    exit 1
  fi
}

# ======================
# DNS操作函数
# ======================

# 设置DNS
set_dns() {
  check_root
  echo -e "${BLUE}▶ 正在设置DNS服务器...${NC}"
  
  # 首次备份
  [ ! -f "$BACKUP_FILE" ] && cp "$CONF_HEAD" "$BACKUP_FILE" 2>/dev/null

  # 写入新配置
  > "$CONF_HEAD"
  for dns in "$@"; do
    validate_ip "$dns"
    echo "nameserver $dns" >> "$CONF_HEAD"
  done

  resolvconf -u
  echo -e "${GREEN}✔ DNS已更新！当前配置：${NC}"
  check_status
}

# 恢复默认（强化版）
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

# 查看状态
check_status() {
  echo -e "${BLUE}当前DNS配置：${NC}"
  grep -E 'nameserver\s+([0-9a-fA-F:.]+)' /etc/resolv.conf || 
    echo -e "${YELLOW}未检测到有效DNS配置${NC}"
}

# ======================
# 脚本管理函数
# ======================

# 卸载脚本（增强版）
uninstall_script() {
  check_root
  echo -e "${YELLOW}⚠ 开始卸载流程...${NC}"
  
  # 第一步：强制恢复DNS
  restore_dns
  
  # 第二步：删除主程序
  [ -f "$INSTALL_PATH" ] && rm -f "$INSTALL_PATH"
  
  # 第三步：清理备份文件
  if [ -f "$BACKUP_FILE" ]; then
    echo -e "${BLUE}? 是否删除DNS备份文件？ [y/N]${NC}"
    read -r choice
    [[ "$choice" =~ [Yy] ]] && rm -f "$BACKUP_FILE"
  fi

  echo -e "${GREEN}✔ 卸载完成！系统已恢复初始状态${NC}"
}

# ======================
# 主逻辑流程
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
