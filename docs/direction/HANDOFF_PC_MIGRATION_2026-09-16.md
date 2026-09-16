# 別PCへの引き継ぎ｜2026-09-16

## 正本と現在地

- GitHub正本：`https://github.com/gojioki/cebu-oyako-top`
- ブランチ：`main`
- VERSION：`ver27-3`（今回の移行チェックポイントでは番号・タグを動かさない）
- WordPress公開TOP：`https://cebu-oyako.com/`
- GitHub Pages確認用：`https://gojioki.github.io/cebu-oyako-top/`
- ローカル確認用：`modular/preview/ver27-3_全体軽量プレビュー.html`

WordPressの新TOPはβ版として公開済み。SWELL標準ヘッダー左上のサイト名だけをH1とし、FV見出しはH2へ変更した。PC・タブレット・スマホで大きな表示破綻がないことも確認済み。

## WordPressよりローカルが新しい点

次の2点はローカルとGitHubへ保存するが、WordPress公開ページにはまだ反映していない。

1. 小さすぎる文字を見直し、対象箇所の下限を原則11pxへ調整。
2. パスポート説明を「有効期限を確認し、航空会社・入国条件も出発前に再確認します」へ修正。

次のPCで最初に行う作業は、この2点をWordPressへ反映して、PC・タブレット・スマホを再確認すること。

## 新PCでの開始手順

```bash
git clone https://github.com/gojioki/cebu-oyako-top.git
cd cebu-oyako-top
git switch main
git pull --ff-only
ruby modular/scripts/build.rb
```

ローカル確認が必要な場合は、リポジトリ直下で次を実行する。

```bash
python3 -m http.server 4320
```

その後、ブラウザで `http://localhost:4320/modular/preview/ver27-3_全体軽量プレビュー.html` を開く。

## 最初に読むファイル

1. `docs/direction/00_MASTER_STATUS.md`
2. `docs/direction/01_TOP_COMPLETION.md`
3. `docs/direction/02_PRICE_SOURCE_OF_TRUTH.md`
4. `docs/direction/04_DECISION_LOG.md`
5. 本ファイル

実装の正本は `modular/sections/` と `modular/css/site.css`。`index.html`やプレビューはビルド生成物なので直接編集しない。

## 料金・表現の注意

- 親子見積もり、ジュニア料金、4人家族実費は用途が違うため混ぜない。
- 料金の根拠は `modular/data/09_cost_estimates.json` と `docs/direction/02_PRICE_SOURCE_OF_TRUTH.md`を参照する。
- 病歴など本人固有の出来事は、本人確認または一次資料なしに追加しない。
- 未公開記事は非リンクの「（予定）」表示を維持し、公開後だけ絶対URLへ変更する。

## GitとWordPressの境界

- GitHubにはコード・生成物・判断資料を保存する。
- WordPressのログイン情報はGitへ保存しない。
- GitHubへのpushはWordPressを自動更新しない。WordPress反映はSWELL側で別途行う。
- 今回の保存は`ver27-3`後の通常チェックポイントであり、`ver27-3`タグは既存の確定点から動かさない。

## 次の優先順位

1. フォント下限とパスポート文言をWordPressへ反映。
2. 公開TOPをPC・タブレット・スマホで再確認。
3. title・description・OGPを最終確認。
4. 費用記事と中心ガイドをTOP料金へ同期。
5. 未公開記事を整備し、TOPの「（予定）」導線を順番に開通。
