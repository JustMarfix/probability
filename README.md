# practicum

> Конспекты практикумов по ТВиМС - Киндеркнехт Я. А.

**Читать онлайн:** <https://justmarfix.github.io/probability/>

Актуальные PDF также лежат в [релизах](https://github.com/JustMarfix/probability/releases/latest).

## Сборка

```sh
python compile_all.py       # собирает prob-all.pdf и prob-monochrome.pdf
python build_site.py        # собирает сайт-читалку в ./_site
python -m http.server -d _site 4173
```

Обе команды выполняет CI при пуше в `main`: PDF уходят в релиз, `_site` — на GitHub Pages.
Исходники читалки — в [`site/`](site/); pdf.js подкладывается в сайт на этапе сборки,
так что страница не ходит на сторонние CDN. Читалка умеет оглавление в боковой панели,
ссылки внутри PDF и наружу, выделение текста, тёмную тему и ссылки вида
`#v=prob-monochrome&p=20`.
