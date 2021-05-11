# ホームページ
- [Juliaで数理最適化](https://pallahaxi.github.io/calender_deriven_development/)
- [Python言語による実務で使える100+の最適化問題](https://mikiokubo.github.io/opt100/index.html)

# 参考
## bookテーマのgithubページ
https://github.com/alex-shpak/hugo-book

諸設定を確認したい場合にはREADMEを読む
issueを検索すると、大体のことは解決する

## bookテーマのデモサイト
https://themes.gohugo.io//theme/hugo-book/

上記の `shortcode` はドキュメント作成時、参考になる。
各ページの `Example` をコピれば、ボタンやtexが書ける。
また、デフォルトのhugoが用意しているshortcodeは下記リンクにある
https://gohugo.io/content-management/shortcodes/

# tips
## 新規ページ作成
```bash
hugo new docs/opt_100/mogamoga.md
```
上記で `content/docs/opt_100/mogamoga.md` が作成される。これを編集する。


## 画像の貼り付けshortcode
```hugo
{{< figure src="/docs/opt_100/static/k_short_paths/grid.png" title="" >}}
```
特にpathの指定に注意。
一旦、`static` 以下に作成したページ名(上の例では `k_short_paths` )と同名のディレクトリを切って、そのディレクトリにページで使用した画像を置くルールとする。

## texのshortcode
inlineのtexは
```hugo
もがもが{{< katex >}}\pi(x){{< /katex >}}もがもが
```
で、通常の数式(例：フーリエ変換)は
```hugo
{{< katex display >}}
f(x) = \int_{-\infty}^\infty\hat f(\xi),e^{2 \pi i \xi x},d\xi
{{< /katex >}}
```
