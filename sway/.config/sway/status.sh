#!/bin/sh

# ============================================================
# Sway status
# CPU | GPU | RAM | Network | Volume | Time
# ============================================================

find_hwmon() {
    target="$1"

    for h in /sys/class/hwmon/hwmon*; do
        [ -r "$h/name" ] || continue

        if [ "$(cat "$h/name" 2>/dev/null)" = "$target" ]; then
            printf '%s\n' "$h"
            return
        fi
    done
}

find_amdgpu_device() {
    for d in /sys/class/drm/card*/device; do
        [ -r "$d/vendor" ] || continue

        if [ "$(cat "$d/vendor" 2>/dev/null)" = "0x1002" ]; then
            printf '%s\n' "$d"
            return
        fi
    done
}

get_rx() {
    awk '
        NR > 2 && $1 !~ /lo:/ {
            rx += $2
        }
        END {
            print rx + 0
        }
    ' /proc/net/dev
}

get_tx() {
    awk '
        NR > 2 && $1 !~ /lo:/ {
            tx += $10
        }
        END {
            print tx + 0
        }
    ' /proc/net/dev
}

format_speed() {
    bytes="$1"

    awk -v b="$bytes" '
        BEGIN {
            if (b >= 1073741824)
                printf "%.1fG", b / 1073741824
            else if (b >= 1048576)
                printf "%.1fM", b / 1048576
            else if (b >= 1024)
                printf "%.0fK", b / 1024
            else
                printf "0K"
        }
    '
}


# ------------------------------------------------------------
# 查找硬件
# ------------------------------------------------------------

CPU_HWMON=$(find_hwmon "k10temp")
GPU_HWMON=$(find_hwmon "amdgpu")
GPU_DEVICE=$(find_amdgpu_device)


# ------------------------------------------------------------
# CPU 初始值
# ------------------------------------------------------------

read _ user nice system idle iowait irq softirq steal _ < /proc/stat

prev_idle=$((idle + iowait))
prev_total=$((user + nice + system + idle + iowait + irq + softirq + steal))


# ------------------------------------------------------------
# 网络初始值
# ------------------------------------------------------------

prev_rx=$(get_rx)
prev_tx=$(get_tx)


# ============================================================
# 主循环
# ============================================================

while true; do
    sleep 1

    # --------------------------------------------------------
    # CPU 使用率
    # --------------------------------------------------------

    read _ user nice system idle iowait irq softirq steal _ < /proc/stat

    idle_now=$((idle + iowait))
    total_now=$((user + nice + system + idle + iowait + irq + softirq + steal))

    diff_idle=$((idle_now - prev_idle))
    diff_total=$((total_now - prev_total))

    if [ "$diff_total" -gt 0 ]; then
        cpu_usage=$((100 * (diff_total - diff_idle) / diff_total))
    else
        cpu_usage=0
    fi

    prev_idle=$idle_now
    prev_total=$total_now


    # --------------------------------------------------------
    # CPU 温度
    # --------------------------------------------------------

    if [ -n "$CPU_HWMON" ] && [ -r "$CPU_HWMON/temp1_input" ]; then
        cpu_temp_raw=$(cat "$CPU_HWMON/temp1_input")

        cpu_temp=$(awk -v t="$cpu_temp_raw" \
            'BEGIN { printf "%.0f", t / 1000 }')
    else
        cpu_temp="?"
    fi


    # --------------------------------------------------------
    # AMD GPU 使用率
    # --------------------------------------------------------

    if [ -n "$GPU_DEVICE" ] && [ -r "$GPU_DEVICE/gpu_busy_percent" ]; then
        gpu_usage=$(cat "$GPU_DEVICE/gpu_busy_percent")
    else
        gpu_usage="?"
    fi


    # --------------------------------------------------------
    # AMD GPU 温度
    # --------------------------------------------------------

    if [ -n "$GPU_HWMON" ] && [ -r "$GPU_HWMON/temp1_input" ]; then
        gpu_temp_raw=$(cat "$GPU_HWMON/temp1_input")

        gpu_temp=$(awk -v t="$gpu_temp_raw" \
            'BEGIN { printf "%.0f", t / 1000 }')
    else
        gpu_temp="?"
    fi


    # --------------------------------------------------------
    # 内存
    # --------------------------------------------------------

    mem=$(free | awk '/Mem:/ {
        printf "%.0f", $3 / $2 * 100
    }')


    # --------------------------------------------------------
    # 网络
    # --------------------------------------------------------

    rx=$(get_rx)
    tx=$(get_tx)

    rx_speed=$((rx - prev_rx))
    tx_speed=$((tx - prev_tx))

    prev_rx=$rx
    prev_tx=$tx

    [ "$rx_speed" -lt 0 ] && rx_speed=0
    [ "$tx_speed" -lt 0 ] && tx_speed=0

    rx_h=$(format_speed "$rx_speed")
    tx_h=$(format_speed "$tx_speed")


    # --------------------------------------------------------
    # 音量
    # --------------------------------------------------------

    volume_info=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)

    if printf '%s\n' "$volume_info" | grep -q "MUTED"; then
        volume_text="󰝟 MUTE"

    elif [ -n "$volume_info" ]; then
        volume=$(printf '%s\n' "$volume_info" |
            awk '{ printf "%.0f", $2 * 100 }')

        volume_text=" ${volume}%"

    else
        volume_text=" ?"
    fi


    # --------------------------------------------------------
    # 输出
    # --------------------------------------------------------

    printf ' CPU %s%% %s°C | 󰍹 GPU %s%% %s°C |  RAM %s%% |  %s  %s | %s |  %s\n' \
        "$cpu_usage" \
        "$cpu_temp" \
        "$gpu_usage" \
        "$gpu_temp" \
        "$mem" \
        "$rx_h" \
        "$tx_h" \
        "$volume_text" \
        "$(date '+%Y-%m-%d %H:%M')"

done

