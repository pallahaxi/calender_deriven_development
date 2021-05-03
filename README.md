# 参考
## bookテーマのgithubページ
https://github.com/alex-shpak/hugo-book

諸設定を確認したい場合にはREADMEを読む  
issueを検索すると、大体のことは解決する

## bookテーマのデモサイト
https://themes.gohugo.io//theme/hugo-book/

上記の `shortcode` はドキュメント作成時、参考になります。  
各ページの `Example` をコピれば、ボタンやtexが書ける。  
また、デフォルトのhugoが用意しているshortcodeは下記リンクにある  
https://gohugo.io/content-management/shortcodes/

# tips
## 画像の貼り付けshortcode
```hugo
{{< figure src="/docs/opt_100/static/short_path_enum/grid.png" title="" >}}
```
特にpathの指定に注意。
一旦、各ページと同じ名前でディレクトリを `static` 下に切って画像を置くルールとする。

## tex
inlineのtexは
```hugo
もがもが{{< katex >}}\pi(x){{< /katex >}}もがもが
```
で、通常の数式(フーリエ変換)は
```hugo
{{< katex display >}}
f(x) = \int_{-\infty}^\infty\hat f(\xi),e^{2 \pi i \xi x},d\xi
{{< /katex >}}
```
