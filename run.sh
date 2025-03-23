#!/bin/bash
cd $(dirname "$0")

# 使用方法を表示する関数
show_usage() {
  echo "使用方法: $0 [-o|--output <output_dir>] [<url_list_file>]"
  echo "  -o, --output <output_dir> 出力先ディレクトリ（デフォルト: ./output）"
  echo "  <url_list_file>           URLが1行に1つずつ記載されたファイル (デフォルト: ./urls)"
  exit 1
}

# デフォルト値の設定
OUTPUT_DIR="./output"
TEMP_DIR="./temp_downloads"
URL_LIST_FILE="./urls"


# 引数のパース
while [[ $# -gt 0 ]]; do
  case $1 in
    -o|--output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      show_usage
      ;;
    *)
      if [[ -z "$URL_LIST_FILE" ]]; then
        URL_LIST_FILE="$1"
      else
        echo "エラー: 不明な引数: $1"
        show_usage
      fi
      shift
      ;;
  esac
done

# URLリストファイルの確認
if [[ -z "$URL_LIST_FILE" || ! -f "$URL_LIST_FILE" ]]; then
  echo "エラー: URLリストファイルが指定されていないか、存在しません ($URL_LIST_FILE)"
  show_usage
fi

# URLからファイル名を生成する関数
get_filename_from_url() {
  local url="$1"
  local format="$2"
  local filename

  # URLからベース名を抽出
  filename=$(echo "$url" | sed -e 's/[^A-Za-z0-9._-]/_/g' -e 's/__*/_/g')

  # ファイル名が長すぎる場合は切り詰める
  if [[ ${#filename} -gt 100 ]]; then
    filename="${filename:0:100}"
  fi

  # 拡張子を追加
  filename="${filename}.md"

  echo "$filename"
}

# URLをダウンロードしてMarkdownまたはPDFに変換する関数
download_and_convert() {
  local url="$1"
  local output_dir="$2"
  local temp_dir="$3"
  local filename
  local temp_file

  filename=$(get_filename_from_url "$url" "$output_format")
  temp_file="${temp_dir}/$(basename "$filename" .$output_format).html"
  output_file="${output_dir}/${filename}"

  echo "処理中: $url -> $output_file"

  # URLコンテンツのダウンロード
  if ! curl -L --max-redirs 5 -o "${temp_file}" "$url"; then
    echo "警告: $url のダウンロードに失敗しました"
    return 1
  fi

  # 日本語変換
  docker run --rm -v "$(cwd):/data" url2aidoc_nkf -w --overwrite "/data/$temp_file"

  # Pandocを使用して変換
  docker run --rm -v "$(cwd):/data" pandoc/extra -f html -t markdown "/data/$temp_file" -o "$output_file"

  if [[ $? -eq 0 ]]; then
    echo "変換成功: $output_file"
  else
    echo "警告: $url の変換に失敗しました"
    return 1
  fi
}

# メイン処理
main() {
  local total_urls=0
  local success_count=0

  # ディレクトリの作成
  mkdir -p "$OUTPUT_DIR"
  mkdir -p "$TEMP_DIR"

  # URLリストの処理
  total_urls=$(wc -l < "$URL_LIST_FILE")

  echo "処理を開始: $total_urls 件のURL"
  echo "出力先: $OUTPUT_DIR"

  # 各URLを処理
  while read -r url; do
    # 空行または#で始まる行（コメント）をスキップ
    if [[ -z "$url" || "$url" =~ ^# ]]; then
      continue
    fi

    if download_and_convert "$url" "$OUTPUT_DIR" "$TEMP_DIR"; then
      ((success_count++))
    fi
  done < "$URL_LIST_FILE"

  echo "処理完了: $success_count / $total_urls 件のURLが正常に変換されました"

  # 一時ファイルの削除
  read -rp "一時ファイルを削除しますか？ (y/n): " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    rm -rf "$TEMP_DIR"
    echo "一時ファイルを削除しました。"
  else
    echo "一時ファイルは $TEMP_DIR に残っています。"
  fi

  open_folder
}

cwd() {
  case "$OSTYPE" in
  cygwin) cygpath -w "$(pwd)" ;;
  *) pwd
  esac
}

open_folder() {
  case "$OSTYPE" in
  cygwin) explorer.exe $(cygpath -w "$OUTPUT_DIR");;
  darwin) open "$OUTPUT_DIR";;
  esac
}

# スクリプト実行
main
