# FF11-data

『ファイナルファンタジーXI(FF11)』の用語・データを継続的に整理していくリポジトリです。

## 内容

- `data/magic/` — 白魔法・黒魔法・暗黒魔法・忍術・歌・召喚魔法・青魔法・地霊魔法の効果一覧
- `data/abilities/` — 各ジョブのジョブアビリティ・SPアビリティ一覧
- `data/monsters/resistance_table.json` — モンスター種族別の物理/魔法属性耐性・WS特殊効果耐性表(約670件)
- `data/combat_formulas.json` — 実測に基づく戦闘計算式(ステータスランク表・防御規定値・必要命中値など)
- `data/encounters/` — 実戦ログに基づく攻略メモ
- `docs/windower.md` — 非公式クライアント拡張ツール「Windower」の概要メモ

## データソースについて

作業環境のネットワーク制限により、FF11関連の外部wiki(wiki.ffo.jp / wikiwiki.jp /
bg-wiki.com 等)への直接アクセスができなかったため、多くの項目はAIの学習知識ベースで
作成し、`verified: false` などで要検証であることを明示しています。一部データ
(`data/monsters/resistance_table.json`、`data/combat_formulas.json`、
`data/encounters/`)は、以前にユーザー自身が作成した検証済みのArtifact
(実測データ・実戦ログに基づく)から抽出した一次情報です。詳細は `data/README.md` を
参照してください。
