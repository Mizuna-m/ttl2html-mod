# ttl2html-mod
@Mizuna-m

[ttl2html](https://github.com/masao/ttl2html/) の動作を拡張します。

## xlsx2shape
- `sh:NodeShape` クラスのインスタンスを、URIだけでなくQNameでも処理できるようにしました。
- xlsxで、1つのセルに複数の値が改行区切りで入っている場合、複数値を並列に出力できるようにしました。（ttl2htmlでは`<ul>`タグで構造化しHTML化にそのまま使う仕様のようです。）
