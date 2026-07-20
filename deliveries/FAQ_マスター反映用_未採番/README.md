# FAQ マスター反映用データ（未採番）

この一式は、「ぶっ飛びセブ島親子留学」TOPページのFAQを、確定v2仕様の9問へ差し替えるためのブロック納品物です。

## 重要

- この納品物ではVERSION番号を採番していません。総合スレ側でマスター反映時に採番してください。
- `modular/css/site.css`の完成ファイルは同梱していません。
- `patches/10_faq_append.css`は、Claude側マスターの`modular/css/site.css`末尾へ追記してください。site.cssを丸ごと上書きしないでください。
- FAQ以外のHTML・CSS・画像・リンクは変更しないでください。

## 同梱物

| ファイル | 用途 |
|---|---|
| `modular/sections/10_faq.html` | 既存FAQセクションとの全差し替え用 |
| `patches/10_faq_append.css` | Claude側の`modular/css/site.css`末尾への追記用 |
| `preview/10_faq_preview.html` | FAQ単体の表示確認用 |
| `source/cebu_parent_child_top_faq_final_spec_v2.md` | 確定原稿・実装仕様の正本 |

## 反映手順

1. Claude側マスターの`modular/sections/10_faq.html`を、同梱の`modular/sections/10_faq.html`へ差し替える。
2. `patches/10_faq_append.css`の全文を、Claude側マスターの`modular/css/site.css`末尾へ追記する。
3. すでに同じFAQ v2 CSSが追記済みの場合は、二重追記しない。
4. 総合スレ側で`modular/VERSION.txt`を次の番号へ更新する。
5. `LANG=C.UTF-8 LC_ALL=C.UTF-8 ruby modular/scripts/build.rb`でプレビューと統合HTMLを再生成する。

## 確定仕様

- FAQは9問。
- PC・タブレット・スマホとも1カラム。
- 初期状態は9問すべて閉じる。
- 各回答は「青文字の短答／通常本文／薄グレーの関連記事」の3層。
- 未公開の関連記事はクリック不可。`href="#"`や架空URLを使わない。
- 質問はPC 16.5px・スマホ16px。
- 青文字短答はPC 16px・スマホ15.5px。
- 通常本文はPC 14.5px・スマホ14px。
- FAQ本文の最大幅は960px。
- クラス名はすべて`btv3-`接頭辞。

## 反映後の確認項目

- FAQが9問だけになっている。
- 旧仮FAQ4問が残っていない。
- 全問が初期状態で閉じている。
- 全9問に短答・詳細本文・関連記事枠がある。
- 関連記事枠が薄グレーで表示され、未公開記事はクリックできない。
- PC表示が1カラムになっている。
- 1600px、1280px、1024pxで表示が崩れない。
- 375pxで横スクロール、はみ出し、読めない文字がない。
- キーボードで各`summary`を開閉でき、フォーカス枠が見える。
- コンソールエラーがない。
- `href="#"`、未解決プレースホルダー、架空URLがない。
- FAQ以外のセクションに表示回帰がない。

## 現時点の検証済み内容

- v2仕様書と、9問の質問・短答・通常本文・関連記事タイトルが全文一致。
- 9問、短答9件、本文9件、関連記事枠9件。
- 初期状態で開いている質問は0件。
- 仮URLと`href="#"`は0件。
- `btv3-`以外のクラスは0件。

