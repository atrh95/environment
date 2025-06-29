#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../" && pwd )"

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# Cursor のセットアップ
setup_cursor() {
    log_start "Cursor のセットアップを開始します..."
    local config_dir="$REPO_ROOT/config/vscode"
    local cursor_target_dir="$HOME/Library/Application Support/Cursor/User"

    # リポジトリに設定ファイルがあるか確認
    if [ ! -d "$config_dir" ]; then
        log_warning "設定ディレクトリが見つかりません: $config_dir"
        log_info "Cursor設定のセットアップをスキップします。"
        return 0
    fi

    # Cursor アプリケーションの存在確認
    if ! ls /Applications/Cursor.app &>/dev/null; then
        log_warning "Cursor がインストールされていません。スキップします。"
        return 0 # インストールされていなければエラーではない
    fi
    log_installed "Cursor"

    # ターゲットディレクトリの作成
    mkdir -p "$cursor_target_dir"

    # 設定ファイルのシンボリックリンクを作成
    shopt -s nullglob   # マッチしない場合は展開結果を空にする
    local linked_count=0
    for file in "$config_dir"/*; do
        if [[ -f "$file" ]]; then
            local filename
            filename=$(basename "$file")  
            local target_file="$cursor_target_dir/$filename"
            
            # 既存のファイルを削除
            if [ -f "$target_file" ] || [ -L "$target_file" ]; then
                rm -f "$target_file"
            fi
            
            # シンボリックリンクの作成
            if ln -s "$file" "$target_file"; then
                ((linked_count++))
            else
                log_error "Cursor設定ファイル $filename のシンボリックリンク作成に失敗しました。"
                return 1
            fi
        fi
    done
    shopt -u nullglob
    
    log_success "Cursor設定ファイル ${linked_count}個のシンボリックリンクを作成しました"
    return 0
}

# Cursor環境を検証
verify_cursor_setup() {
    log_start "Cursor環境を検証中..."
    local verification_failed=false
    local config_dir="$REPO_ROOT/config/vscode"
    local cursor_target_dir="$HOME/Library/Application Support/Cursor/User"

    # アプリケーションがインストールされているかを確認
    if ! ls /Applications/Cursor.app &>/dev/null; then
        log_error "Cursor.appが見つかりません"
        return 1
    fi
    log_installed "Cursor"

    # リポジトリに設定ファイルがない場合はスキップ
    if [ ! -d "$config_dir" ]; then
        log_info "リポジトリにCursor設定が見つからないため、設定の検証はスキップします。"
        return 0
    fi

    # 設定ディレクトリの存在確認
    if [ ! -d "$cursor_target_dir" ]; then
        log_error "Cursor設定ディレクトリが作成されていません: $cursor_target_dir"
        verification_failed=true
    else
        log_success "Cursor設定ディレクトリが存在します: $cursor_target_dir"

        # 実際にシンボリックリンクが作成されているかを確認
        shopt -s nullglob   # マッチしない場合は展開結果を空にする
        local linked_files=0
        for file in "$config_dir"/*; do
            if [[ -f "$file" ]]; then
                local filename
                filename=$(basename "$file")
                local target_file="$cursor_target_dir/$filename"
                
                if [ -L "$target_file" ]; then
                    local link_target
                    link_target=$(readlink "$target_file")
                    if [ "$link_target" = "$file" ]; then
                        log_success "Cursor設定ファイル $filename が正しくリンクされています。"
                        ((linked_files++))
                    else
                        log_error "Cursor設定ファイル $filename のリンク先が不正です: $link_target (期待値: $file)"
                        verification_failed=true
                    fi
                else
                    log_error "Cursor設定ファイル $filename のシンボリックリンクが作成されていません。"
                    verification_failed=true
                fi
            fi
        done
        shopt -u nullglob

        if [ "$linked_files" -eq 0 ]; then
            log_error "Cursor用のシンボリックリンクが一つも作成されていません。"
            verification_failed=true
        fi
    fi

    if [ "$verification_failed" = "true" ]; then
        log_error "Cursor環境の検証に失敗しました"
        return 1
    else
        log_success "Cursor環境の検証が完了しました"
        return 0
    fi
}

# メイン関数
main() {
    log_start "Cursor環境のセットアップを開始します"
    
    setup_cursor
    
    log_success "Cursor環境のセットアップが完了しました"
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 