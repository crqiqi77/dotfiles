#!/bin/sh

STATE="${XDG_RUNTIME_DIR:-/tmp}/sway-caffeine"

if [ -f "$STATE" ]; then
    # 恢复 swayidle
    pkill -CONT swayidle
    rm -f "$STATE"

    notify-send -t 3000 "防熄屏" "已关闭"
else
    # 暂停 swayidle
    pkill -STOP swayidle
    touch "$STATE"

    notify-send -t 3000 "防熄屏" "已开启"
fi

