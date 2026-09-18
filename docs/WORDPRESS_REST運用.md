# WordPress REST API運用

固定ページのHTML更新を、ブラウザ操作ではなくWordPress REST APIで安全に行うための手順です。

対象サイトは `https://cebu-oyako.com/`、現在のTOP固定ページはID `411` です。

## 安全設計

- WordPress本体のログインパスワードは使用しない。
- 専用の「編集者」ユーザーと、そのユーザー専用のアプリケーションパスワードを使う。
- アプリケーションパスワードはGit・チャット・設定ファイルへ保存しない。
- パスワードはmacOSキーチェーンに保存する。
- 更新前に、WordPress上の現在値を `.wp-backups/` へ自動保存する。
- `plan` で差分を確認し、`publish --yes` でのみ公開ページを更新する。
- `.wp-backups/` とローカル設定ファイルは `.gitignore` 対象。

## 1. WordPress側の準備

1. WordPress管理画面で、REST更新専用ユーザーを「編集者」権限で作成する。
2. そのユーザーで「ユーザー」→「プロフィール」を開く。
3. 「アプリケーションパスワード」で `Codex ローカル更新用` を作成する。
4. 表示されたパスワードを一時的にコピーする。

ユーザー名を以下の `YOUR_WP_LOGIN` と置き換えます。

## 2. macOSキーチェーンへ保存

ターミナルで次を実行します。

```bash
security add-generic-password -U -a 'YOUR_WP_LOGIN' -s 'cebu-oyako-wp-rest' -w
```

入力待ちになったら、WordPressで生成したアプリケーションパスワードを貼り付けます。パスワードはコマンド履歴へ残りません。

## 3. 接続確認

```bash
ruby modular/scripts/wp_rest_sync.rb check
```

ユーザー名とパスワードはmacOSキーチェーンから自動取得します。この操作はWordPressを変更しません。

## 4. 現在の固定ページをバックアップ

```bash
ruby modular/scripts/wp_rest_sync.rb backup
```

バックアップは `.wp-backups/page-411/日時/` に保存されます。

## 5. 更新前の差分確認

`CONTENT_FILE`には、Gutenbergコードエディターへ入れる完成ファイルを指定します。

```bash
ruby modular/scripts/wp_rest_sync.rb plan 'CONTENT_FILE'
```

現在の内容と新しい内容、完全な差分が `.wp-backups/` に保存されます。この段階ではWordPressを変更しません。

## 6. 公開ページを更新

差分を確認して本人が公開を承認した場合だけ実行します。

```bash
ruby modular/scripts/wp_rest_sync.rb publish 'CONTENT_FILE' --yes
```

更新後、WordPressから内容を再取得し、送信したHTMLと一致することを検証します。

## 対応範囲

この仕組みで、固定ページ本文の更新・バックアップ・差分確認・保存後検証を行えます。

画像アップロードやアイキャッチ更新はREST APIで追加可能ですが、初期版では誤操作を避けるため未実装です。Rank MathやSWELLのサイト全体設定も対象外です。それらは当面、管理画面で設定します。

## パスワードを無効にする場合

WordPress管理画面の「ユーザー」→「プロフィール」→「アプリケーションパスワード」から、`Codex ローカル更新用` を削除します。通常のログインパスワードには影響しません。

## ステージング環境について

`https://stg.cebu-oyako.com/` はXServerのBasic認証で保護します。WordPress REST APIのアプリケーションパスワードもHTTP Basic認証を使うため、ステージングでは両者を同じリクエストで併用できません。

そのためステージングだけは、外側のBasic認証とWordPress側の認証を分離できるXML-RPC APIを使います。本番用REST APIの設定・スクリプトは変更しません。

### WordPress側の準備

1. ステージング側の `codex-publisher`を「編集者」権限で使用します。
2. 本番とは分離した、長くランダムなステージング専用の通常パスワードを設定します。
3. 本番のアプリケーションパスワードと、ステージングの通常パスワードを混用しません。

### macOSキーチェーンへ保存

Basic認証のユーザー名を `BASIC_LOGIN`、ステージング専用WordPressユーザー名を `STAGING_EDITOR` とした場合：

```bash
security add-generic-password -U -a 'BASIC_LOGIN' -s 'cebu-oyako-stg-basic' -w
security add-generic-password -U -a 'STAGING_EDITOR' -s 'cebu-oyako-stg-wp-xmlrpc' -w
```

1つ目にはXServerアクセス制限のパスワード、2つ目にはステージング専用WordPress編集者のパスワードを入力します。どちらもコマンド履歴やGitには保存されません。

### 接続確認

```bash
ruby modular/scripts/wp_staging_xmlrpc_sync.rb check
```

ユーザー名とパスワードはmacOSキーチェーンから自動取得するため、登録後は毎回の入力は不要です。

### バックアップ・差分確認・更新

```bash
ruby modular/scripts/wp_staging_xmlrpc_sync.rb backup

ruby modular/scripts/wp_staging_xmlrpc_sync.rb plan 'CONTENT_FILE'

ruby modular/scripts/wp_staging_xmlrpc_sync.rb publish 'CONTENT_FILE' --yes
```

更新前のバックアップと差分は `.wp-backups/staging/` に保存されます。`publish` は `--yes` がなければ拒否され、更新後には保存内容を再取得して一致を検証します。
