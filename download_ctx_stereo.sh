#!/bin/bash

# Author: Lejun Lu
# Email: lulj8@mail2.sysu.edu.cn
# First version released: 2025-04-01

# ========== 用法说明 ==========
if [[ $# = 0 ]]; then
    echo "Usage: download_ctx_stereo.sh <aaaa> <bbbb>"
    echo " "
    echo "请输入四位数字作为起始编号<aaaa>和结束编号<bbbb>，均为MRO CTX mission number（e.g., mrox_xxxx)"
    echo "例如：bash download_ctx_stereo.sh 0001 0010"
    echo " "
    echo "该代码需要提前配置wget, Aria2:"
    echo "sudo apt install wget aria2"
    exit 1
fi

# ========== 参数校验 ==========
if [[ ! "$1" =~ ^[0-9]{4}$ || ! "$2" =~ ^[0-9]{4}$ ]]; then
    echo "❌ 参数错误：请输入四位数字作为起始和结束编号，例如：bash download_ctx.sh 0001 0010"
    exit 1
fi


START_STR=$1
END_STR=$2
START_NUM=$((10#$START_STR))  # 10# 防止前导0被当作八进制
END_NUM=$((10#$END_STR))
BASE_URL="https://d32ky7zsovnyu5.cloudfront.net/CTX" # USGS所提供，无需VPN下载
# BASE_URL="https://planetarydata.jpl.nasa.gov/img/data/mro/ctx" # NASA所提供，需要VPN下载，备用
LOGFILE="ctx_download.log"


# ========== 创建总目录 ==========
mkdir -p ctx_img_downloads
cd ctx_img_downloads || exit

echo "开始下载范围：$START_STR 到 $END_STR" | tee -a "$LOGFILE"

for ((i=START_NUM; i<=END_NUM; i++)); do
    num=$(printf "%04d" "$i")
    folder="mrox_${num}"
    index_url="${BASE_URL}/${folder}/index/index.tab"

    echo "处理 ${folder} ..." | tee -a "$LOGFILE"
    mkdir -p "${folder}"
    mkdir -p "${folder}/data"
    cd "${folder}" || continue

    # 下载 index.tab（自动续传 & 静默）
    wget -c -q -O index.tab "$index_url"

    # 检查是否下载成功
    if [[ ! -s index.tab ]]; then
        echo "❌ 未找到 ${folder}/index/index.tab，跳过。" | tee -a "../$LOGFILE"
        cd ..
        continue
    fi

    # 提取 .IMG 文件名，写入临时列表
    grep ".IMG" index.tab | grep -oP '[A-Z0-9_]+\.IMG' | sort -u > img_list.txt

    echo "共发现 $(wc -l < img_list.txt) 个 .IMG 文件，准备下载..." | tee -a "../$LOGFILE"

    # 加上 URL 前缀
    sed -i "s|^|${BASE_URL}/${folder}/data/|" img_list.txt

    # 使用 aria2c 多线程下载
    aria2c -c -x 8 -s 8 -j 4 -i img_list.txt --dir=./data \
        --log="../$LOGFILE" --log-level=notice \
        --referer="${BASE_URL}/${folder}/" \
        --auto-file-renaming=false \
        --conditional-get=true \
        --continue=true \
        --header="User-Agent: ctx_downloader"

    cd ..
done

echo "✅ 所有任务完成。" | tee -a "$LOGFILE"

