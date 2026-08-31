# FF11-data / data ディレクトリについて

このディレクトリには『ファイナルファンタジーXI(FF11)』の魔法・アビリティに関する
用語辞典的データを、JSON形式で整理しています。

## データソースについて(重要)

この作業を行った実行環境では、ネットワークプロキシの制限により
`wiki.ffo.jp`(FF11用語辞典)、`wikiwiki.jp`、`bg-wiki.com`、`fandom.com`、
`windower.net`、個人ブログ等、一般的なWebサイトへの直接アクセス(WebFetch)が
ブロックされていました。

そのため、このデータは以下の方法で作成しています。

1. WebSearch(検索結果の要約スニペット)で得られる情報
2. Claude(Anthropic)が学習時点(〜2026年1月)までに獲得した、FF11に関する
   一般知識

**数値情報(消費MP・詠唱時間・リキャスト・習得レベル等)は記憶に基づく概算であり、
バージョンアップや記憶違いにより実際の値と異なる場合があります。** 各エントリの
`verified` フィールドが `false` のものは、一次情報(公式サイト・wiki本文)での
裏付けが取れていないことを示します。今後、本文を貼り付けてもらう・別環境で
wikiにアクセスできる場合に、内容を検証・更新していく想定です。

## ディレクトリ構成

```
data/
  magic/
    white_magic.json      白魔法(回復・防御強化・蘇生・状態異常回復・神聖魔法)
    black_magic.json      黒魔法(精霊魔法・弱体魔法・エンスペル)
    dark_magic.json       暗黒魔法(ドレイン・アスピル系)
    ninjutsu.json         忍術
    songs.json            歌(吟遊詩人)
    summoning_magic.json  召喚魔法(召喚獣・アストラルフロウ)
    blue_magic.json       青魔法(代表的なもの・全196種のうち抜粋)
    geomancy.json         地霊魔法(ジオマンサー)
  abilities/
    job_abilities.json    各ジョブのジョブアビリティ・SPアビリティ
```

## スキーマ

各魔法エントリは概ね以下の形式です。

```json
{
  "name_ja": "ケアル",
  "name_en": "Cure",
  "category": "回復魔法",
  "jobs": ["WHM", "PLD", "RDM", "SCH", "BRD", "COR"],
  "effect": "対象のHPを回復する。",
  "notes": "",
  "verified": false
}
```

アビリティエントリは以下の形式です。

```json
{
  "job": "戦士(WAR)",
  "name_ja": "挑発",
  "name_en": "Provoke",
  "type": "ジョブアビリティ",
  "effect": "対象のヘイトを大きく上昇させる。",
  "verified": false
}
```

## 今後の拡張方針

このデータは一括で完成させるものではなく、継続的に学習・追記していく前提です。
特に青魔法(196種)・歌(多数の階級)・ジョブ特性(traits)・ブラッドパクトなどは
今回のデータでは代表的なものに絞っています。
