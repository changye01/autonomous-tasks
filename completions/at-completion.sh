#!/bin/bash
# at-completion.sh - Autonomous Tasks 命令补全
# 安装: source at-completion.sh

_at() {
    local -a commands
    commands=(
        'status:显示当前目标和阶段'
        'execute:显示执行摘要'
        'log:查看最近任务日志'
        'list:列出待完成任务'
        'milestone:显示里程碑进度'
        'version:显示版本信息'
        'health:运行健康检查'
        'stats:显示任务统计'
        'help:显示帮助信息'
    )
    _describe 'command' commands
}

compdef _at at
