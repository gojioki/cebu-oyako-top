# 別PCへの引き継ぎ｜2026-09-16

## 正本と現在地

- GitHub正本：`https://github.com/gojioki/cebu-oyako-top`
- ブランチ：`main`
- 公開実装チェックポイント：`73fa260`（`fix: finalize audited top page content`）
- VERSION：`ver27-3`（今回の移行チェックポイントでは番号・タグを動かさない）
- WordPress公開TOP：`https://cebu-oyako.com/`
- GitHub Pages確認用：`https://gojioki.github.io/cebu-oyako-top/`
- ローカル確認用：`modular/preview/ver27-3_全体軽量プレビュー.html`

WordPressの新TOPはβ版として公開済み。SWELL標準ヘッダー左上のサイト名だけをH1とし、FV見出しはH2へ変更した。PC・タブレット・スマホで大きな表示破綻がないことも確認済み。最小フォント調整、パスポート文言、ロードマップ時期表記、旧セクション除去までWordPress・GitHubへ反映済み。

## WordPress・GitHub・ローカルの同期状態

- ローカル `main`、`origin/main` は公開実装チェックポイント `73fa260` を含む。
- WordPress公開TOPへ同内容を反映済み。
- GitHub Pagesも反映済み。
- 作業ツリーはクリーン。
- `ver27-3`タグは既存確定点 `2d39bcd` のまま動かしていない。`73fa260`は同VERSION内の監査・公開確定チェックポイント。

公開後の最終監査結果：

- H1は「ぶっ飛びセブ島親子留学」1件。
- 旧ロードマップセクション0件、重複ID0件、壊れた画像0件、横はみ出し0件、コンソールエラー0件。
- 「ジアルジア」「点滴」「3歳前後」など否定済み表現0件。
- FAQは9件で、1件を開くと他が閉じる。
- 料金3回分は `650,856円 / 931,741円 / 973,104円`、合計 `2,555,701円`。宿泊・光熱費合計 `1,142,000円`、構成比45%と整合。

次のPCで最初に行う作業は、同期状態を確認してから、title・description・OGPの最終確認へ進むこと。

## 新PCでの開始手順

```bash
git clone https://github.com/gojioki/cebu-oyako-top.git
cd cebu-oyako-top
git switch main
git pull --ff-only
git log -1 --oneline
git merge-base --is-ancestor 73fa260 HEAD && echo "公開実装チェックポイント確認OK"
ruby modular/scripts/build.rb
```

次が表示されれば、公開実装を含む正しい履歴を取得できている。

```text
公開実装チェックポイント確認OK
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

## iCloudとGitHubの役割分担

### GitHubへ保存するもの

- `modular/`、`assets/`、`docs/`、生成済み `index.html`
- 確定コピー、料金根拠、判断履歴、引き継ぎ文書
- 小さく、サイトから直接参照する画像

### iCloud Driveへ保存するもの

- 原寸写真と本人選定用素材ライブラリ
- Excel・スプレッドシートの原本や書き出し
- 参考スクリーンショットなど、Gitに入れない大型素材

既存素材の基準フォルダは、iCloud Drive内の `2026 仕事/ぶっとび親子留学/素材ライブラリ/`。新PCでは素材を使う前に、対象ファイルがローカルへダウンロード済みであることを確認する。

リポジトリ本体はiCloud Driveへ置かない。GitとiCloudの二重同期による競合を避けるため、新PCの通常フォルダへGitHubからcloneする。

## ChatGPT / Codexでの再開方法

ChatGPTのプロジェクトやメモリは補助として使い、正本にはしない。新PCではcloneしたリポジトリをローカルプロジェクトとして開き、新しいチャットの冒頭で次を指示する。

```text
この案件を引き継ぎます。
最初にAGENTS.mdと
docs/direction/HANDOFF_PC_MIGRATION_2026-09-16.md、
docs/direction/00_MASTER_STATUS.mdを読んでください。
作業を始める前に、現在地と次の優先順位を要約してください。
```

会話履歴やChatGPTのメモリだけには依存しない。長期ルールは `AGENTS.md`、案件の現在地は本書、実装状態はGitを正とする。

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

1. title・description・OGPを最終確認。
2. 費用記事と中心ガイドをTOP料金へ同期。
3. 未公開記事を整備し、TOPの「（予定）」導線を順番に開通。
4. 記事公開のたびにPC・タブレット・スマホとリンクを再確認。
