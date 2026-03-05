#!/bin/bash
# at-cli.sh - Autonomous Tasks 命令行工具

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 显示帮助
show_help() {
    echo "Autonomous Tasks CLI"
    echo ""
    echo "用法: at <command>"
    echo ""
    echo "命令:"
    echo "  status     显示当前目标和阶段"
    echo "  execute    显示执行摘要"
    echo "  log        查看最近任务日志"
    echo "  list       列出待完成任务"
    echo "  milestone  显示里程碑进度"
    echo "  version    显示版本信息"
    echo "  health     运行健康检查"
    echo "  stats      显示任务统计"
    echo "  help       显示帮助信息"
}

# 版本
cmd_version() {
    local version=$(grep -o '"version": *"[^"]*"' "$PROJECT_DIR/_meta.json" 2>/dev/null | cut -d'"' -f4)
    echo "Autonomous Tasks v${version:-unknown}"
}

# 状态
cmd_status() {
    local autonomous="$PROJECT_DIR/AUTONOMOUS.md"
    if [ ! -f "$autonomous" ]; then
        echo "AUTONOMOUS.md 不存在"
        return 1
    fi

    cmd_version
    echo ""

    local phase=$(grep "## 当前阶段" "$autonomous" 2>/dev/null | sed 's/## 当前阶段：//')
    [ -n "$phase" ] && echo "阶段: $phase"

    echo ""
    echo "待改进项:"
    grep -A 20 "### 当前待改进项" "$autonomous" 2>/dev/null | grep -E "^\s*-\s*\[" | head -5
}

# 里程碑
cmd_milestone() {
    local autonomous="$PROJECT_DIR/AUTONOMOUS.md"
    if [ ! -f "$autonomous" ]; then
        echo "AUTONOMOUS.md 不存在"
        return 1
    fi

    echo "里程碑进度"
    echo ""
    grep -A 20 "## 里程碑" "$autonomous" 2>/dev/null | grep "^\- " | head -10
}

# 待办列表
cmd_list() {
    local autonomous="$PROJECT_DIR/AUTONOMOUS.md"
    local backlog="$PROJECT_DIR/memory/backlog.md"

    echo "待完成任务:"
    echo ""

    if [ -f "$autonomous" ]; then
        grep -A 20 "### 当前待改进项" "$autonomous" 2>/dev/null | grep -E "^\s*-\s*\[" | head -5
    fi

    if [ -f "$backlog" ]; then
        grep -E "^\s*-\s*\[\s*\]" "$backlog" 2>/dev/null | head -5
    fi
}

# 执行摘要
cmd_execute() {
    cmd_status
    echo ""
    echo "---"
    echo ""
    echo "最近完成:"
    local log="$PROJECT_DIR/memory/tasks-log.md"
    [ -f "$log" ] && tail -5 "$log" | grep "TASK-"
    echo ""
    echo "完整执行: openclaw agent --message '执行自主任务'"
}

# 日志
cmd_log() {
    local lines="${1:-10}"
    local log="$PROJECT_DIR/memory/tasks-log.md"
    if [ ! -f "$log" ]; then
        echo "日志文件不存在"
        return 1
    fi
    echo "最近 $lines 条记录:"
    echo ""
    tail -n "$lines" "$log"
}

# 健康检查
cmd_health() {
    "$SCRIPT_DIR/health-check.sh"
}

# 统计
cmd_stats() {
    local log="$PROJECT_DIR/memory/tasks-log.md"
    if [ ! -f "$log" ]; then
        echo "日志文件不存在"
        return 1
    fi
    local total=$(grep -c "TASK-" "$log" 2>/dev/null || echo "0")
    local today=$(grep -c "$(date +%Y-%m-%d)" "$log" 2>/dev/null || echo "0")
    cmd_version
    echo ""
    echo "总完成: $total"
    echo "今日: $today"
}

# 主函数
main() {
    local command="${1:-help}"
    shift 2>/dev/null || true

    case "$command" in
        status)    cmd_status ;;
        execute)   cmd_execute ;;
        log)       cmd_log "$@" ;;
        list)      cmd_list ;;
        milestone) cmd_milestone ;;
        version)   cmd_version ;;
        health)    cmd_health ;;
        stats)     cmd_stats ;;
        help|-h|--help) show_help ;;
        *) echo "未知命令: $command"; show_help; exit 1 ;;
    esac
}

main "$@"
