# ttl2html-mod
@Mizuna-m

[ttl2html](https://github.com/masao/ttl2html/) の動作を拡張します。RubyGemsでの動作は未確認です。`bin/`以下の実行ファイルを直接利用します。

## xlsx2shape
- `sh:NodeShape` クラスのインスタンスを、URIだけでなくQNameでも処理できるようにしました。
- xlsxで、1つのセルに複数の値が改行区切りで入っている場合、複数値を並列に出力できるようにしました。（ttl2htmlでは`<ul>`タグで構造化しHTML化にそのまま使う仕様のようです。）
- セルにアットマーク `@` が含まれる場合、それ以降の文字列を言語タグとして処理します。平文としてアットマークを利用したい場合は、バックスラッシュでエスケープします（`\@`）。
  > 入力例:
  > ```
  > 高等学校用教科書目録(平成29年度使用)@ja
  > こうとうがっこうようきょうかしょもくろく（へいせい29ねんどしよう）@ja-Hira
  > Textbook Catalogue for Upper Secondary School of 2017 School Year@en
  > ```
  >
  > 出力例:
  > ```
  > skos:example "高等学校用教科書目録(平成29年度使用)"@ja, "こうとうがっこうようきょうかしょもくろく（へいせい29ねんどしよう）"@ja-Hira, "Textbook Catalogue for Upper Secondary School of 2017 School Year"@en;
  > ```
  
  ※ ttl2htmlでは、表のヘッダ行でプロパティ名に対してアットマークで言語タグを指定する仕様となっています（例: `skos:example@ja`）。
- `sh:targetClass` 行の2列目の値を、Shapeの `rdfs:label` の値として利用します。
- [SHACL Advanced Features](https://www.w3.org/TR/shacl-af/) の機能である `sh:filterShape` プロパティを受け付けます。
- `sh:or` の出力をSHACLに準拠させました。collectionの要素を直接Blank Node (`[]`) で記述します。
