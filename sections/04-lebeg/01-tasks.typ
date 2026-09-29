#import "../../utils/core.typ": *

== Семинар

#let nested-sets = {
  let s = 0.03cm
  let W = 235
  let H = 170
  let ellipses = (
    (117, 90, 212, 150),
    (122, 86, 168, 124),
    (125, 82, 128, 100),
    (126, 78, 88, 74),
    (127, 73, 56, 48),
    (128, 69, 28, 24),
  )
  box(width: (W + 25) * s, height: H * s, {
    place(rect(width: W * s, height: H * s, stroke: black + 0.8pt))
    for (cx, cy, w, h) in ellipses {
      place(
        dx: (cx - w / 2) * s,
        dy: (cy - h / 2) * s,
        ellipse(width: w * s, height: h * s, stroke: black + 0.6pt),
      )
    }
    place(dx: (W + 5) * s, dy: (H - 22) * s, $bold(Omega)$)
  })
}

#def[
  Пусть $Omega$ -- непустое множество, $cal(A)$ -- некоторая $sigma$-алгебра в $Omega$. Пусть $A$, $A_n$, $n in NN$ -- элементы $cal(A)$. Мы пишем:
  - $A_n arrow.tr A$, если $A_n subset.eq A_(n+1)$ для всех $n in NN$ и $A = union.big_(n=1)^(infinity) A_n$;
  - $A_n arrow.br A$, если $A_n supset.eq A_(n+1)$ для всех $n in NN$ и $A = inter.big_(n=1)^(infinity) A_n$;
  #align(nested-sets, center)
]

#th(name: "Свойства мер")[
  #set enum(numbering: "(a)", full: true)
  Верна следующая цепочка импликаций:
  $() <=> (b) <=> (c) <=> (d)$.

  + $mu$ является мерой на $cal(A)$;

  + $mu$ *непрерывна снизу*, т.е. для всех множеств $A, A_n, in cal(A), n in NN$, с $A_n arrow.tr A$ выполнено $mu(A) = lim_(n -> infinity) mu (A_n)$;

  + $mu$ *непрерывна сверху*, т.е. для всех множеств $A, A_n, in cal(A), n in NN$, с $A_n arrow.br A$ и $mu (A_1) < infinity$ выполнено $mu(A) = lim_(n -> infinity) mu (A_n)$;

  + $mu$ *непрерывна в* $emptyset$, т.е. для всех множеств $A_n in cal(A), n in NN$ с $A_n arrow.br emptyset$ и $mu (A_1) < infinity$ выполнено $mu(A) = 0$;

  Если $mu (Omega) < infinity$, то выполнено также (b) $arrow.l.double$ (c).
]

#task(name: "1")[
  Пусть $mu^F$ -- вероятностная мера Лебега на $cal(B)(RR)$, соответствующая функции распределения $F$, т.е. $mu^F ((a, b]) := F(b) - F(a)$ для $a <= b in RR$. Найдите меру $mu^F$ следующих множеств:

  #set enum(numbering: "i.")
  + $(-oo, b]$, $b in RR$;
  + ${x}$, $x in RR$;
  + $[a, b]$, $a <= b in RR$;
  + $(a, +oo)$, а также $[a, +oo)$ и $(-oo, a)$ для $a in RR$;
  + $(a, b)$, $a <= b in RR$.
]

#solve[
  #set enum(numbering: "i.i.", full: true)
  + $(-oo, b]$. Заметим, что $(-n, b] arrow.tr (-oo, b]$. По непрерывности снизу:
    $ mu^F ((-oo, b]) = lim_(n -> oo) (F(b) - F(-n)) = F(b), $
    т.к. $F(-oo) = 0$.

  + ${x}$. Заметим, что $(x - 1/n, x] arrow.br {x}$. По непрерывности сверху:
    $ mu^F ({x}) = lim_(n -> oo) (F(x) - F(x - 1/n)) = F(x) - F(x-), $
    то есть мера точки равна величине скачка $F$ в этой точке.

  + $[a, b]$. Имеем $[a, b] = {a} union (a, b]$, поэтому
    $ mu^F ([a, b]) = F(a) - F(a-) + F(b) - F(a) = F(b) - F(a-). $

  + $(a, +oo)$, $(-oo, a)$, $[a, +oo)$.
    + Заметим, что прямую $RR$ можно разбить на два непересекающихся куска: $(-oo, a] union (a, +oo)$. По аддитивности $1 = F(a) + mu^F ((a, +oo))$, т.е.
      $ mu^F ((a, +oo)) = 1 - mu^F ((-oo, a]) = 1 - F(a). $
      Аналогично:
    + Разобьём $(-oo, a)$ как $(-oo, a] without {a}$, получим:
      $ mu^F ((-oo, a)) = F(a) - (F(a) - F(a-)) = F(a-) $;
    + Разобьём $[a, +oo)$ как ${ a } union (a, +oo)$, получим:
      $ mu^F ([a, +oo)) = F(a) - F(a-) + (1 - F(a)) = 1 - F(a-) $.

  + $(a, b)$. При $a < b$ имеем $(a, b) = (a, b] without {b}$, откуда
    $ mu^F ((a, b)) = F(b-) - F(a). $
    При $a = b$ множество пусто и его мера равна $0$.
]

#exercise[
  Что можно сказать о мере $mu^F$ множеств из предыдущих пунктов, если известно, что $F$ --- непрерывная функция?
]

#solve[
  Если $F$ непрерывна, то $F(x-) = F(x)$ для всех $x in RR$. Поэтому $mu^F ({x}) = 0$ для любой точки, и концы промежутков роли не играют:
  $ mu^F ((a, b)) = mu^F ((a, b]) = mu^F ([a, b)) = mu^F ([a, b]) = F(b) - F(a), $
  $ mu^F ((-oo, b)) = mu^F ((-oo, b]) = F(b), quad mu^F ((a, +oo)) = mu^F ([a, +oo)) = 1 - F(a). $
]

#let dist-graph = {
  let ux = 3.5cm
  let uy = 4cm
  let (x0, x1, y0, y1) = (-1.2, 2.1, -0.3, 1.3)
  let P(x, y) = ((x - x0) * ux, (y1 - y) * uy)

  let seg(a, b, stroke: black + 0.8pt) = place(line(start: P(..a), end: P(..b), stroke: stroke))
  let guide(a, b) = seg(a, b, stroke: gray + 0.5pt)
  let graph(a, b) = seg(a, b, stroke: red + 1.5pt)

  let dot(p, filled: true) = {
    let (x, y) = P(..p)
    let r = 0.09cm
    place(dx: x - r, dy: y - r, circle(
      radius: r,
      fill: if filled { red } else { white },
      stroke: red + 1pt,
    ))
  }

  let lbl(p, body, dx: 0cm, dy: 0cm) = {
    let (x, y) = P(..p)
    place(dx: x + dx - 1cm, dy: y + dy - 0.5cm,
      box(width: 2cm, height: 1cm, align(center + horizon, body)))
  }

  box(width: (x1 - x0) * ux, height: (y1 - y0) * uy, {
    guide((0, 1), (1, 1))
    guide((0, 3/4), (1/2, 3/4))
    guide((1/2, 0), (1/2, 3/4))
    guide((1, 0), (1, 1))

    seg((x0, 0), (x1 - 0.05, 0))
    seg((0, y0), (0, y1 - 0.05))
    let (ax, ay) = P(x1 - 0.05, 0)
    place(dx: ax - 8pt, dy: ay - 3pt, polygon(fill: black, (0pt, 0pt), (8pt, 3pt), (0pt, 6pt)))
    let (bx, by) = P(0, y1 - 0.05)
    place(dx: bx - 3pt, dy: by, polygon(fill: black, (0pt, 8pt), (3pt, 0pt), (6pt, 8pt)))

    graph((x0, 0), (0, 0))
    graph((0, 2/5), (1/2, 2/5))
    graph((1/2, 3/4), (1, 1))
    graph((1, 1), (1.9, 1))

    dot((0, 0), filled: false)
    dot((0, 2/5))
    dot((1/2, 2/5), filled: false)
    dot((1/2, 3/4))

    lbl((0, 0), $0$, dx: -0.3cm, dy: 0.45cm)
    lbl((1/2, 0), $1/2$, dy: 0.5cm)
    lbl((1, 0), $1$, dy: 0.45cm)
    lbl((0, 2/5), $2/5$, dx: -0.6cm)
    lbl((0, 3/4), $3/4$, dx: -0.6cm)
    lbl((0, 1), $1$, dx: -0.4cm)
    lbl((1.8, 1), text(fill: red)[$F$], dy: -0.4cm)
  })
}

#task(name: "3")[
  Пусть задана следующая функция распределения $F$:

  #align(center, dist-graph)

  Определите $mu^F$ для следующих множеств: $(-1, 0]$; $(-1, 1/3]$; $(-1, 1/2]$; $[1/2, 1]$; $[0, 1/2)$; ${1/2}$.
]

#solve[
  $ mu^F ((-1, 0]) = F(0) - F(-1) = 2/5 - 0 = 2/5 $
  $ mu^F ((-1, 1/3]) = F(1/3) - F(-1) = 2/5 - 0 = 2/5 $
  $ mu^F ((-1, 1/2]) = F(1/2) - F(-1) = 3/4 - 0 = 3/4 $
  $ mu^F ([1/2, 1]) = F(1) - F(1/2 - 0) = 1 - 2/5 = 3/5 $
  $ mu^F ([0, 1/2)) = F(1/2 - 0) - F(0 - 0) = 2/5 - 0 = 2/5 $
  $ mu^F ({1/2}) = F(1/2) - F(1/2 - 0) = 3/4 - 2/5 = 7/20 $
]

#task(name: "4")[
  Определите меру Лебега $lambda$ следующих подмножеств $RR$:
  + $QQ$;
  + $union.big_(n = 1)^oo [n - 1/3^n, n + 1/2^n]$;
  + $A := {x in [0, 1] : x "имеет десятичное разложение без цифры 5"}$.
]

#solve[
  Функция распределения меры Лебега -- $F(x) = x$, она непрерывна, поэтому $lambda({x}) = 0$ и $lambda$ любого промежутка равна его длине.

  + $QQ$ счётно: $QQ = union.sq.big_(q in QQ) {q}$. По $sigma$-аддитивности
    $ lambda(QQ) = sum_(q in QQ) lambda({q}) = 0. $

  + Обозначим $I_n := [n - 1/3^n, n + 1/2^n] subset.eq [n - 1/3, n + 1/2]$. Отрезки попарно не пересекаются: $I_(n+1)$ начинается в точке $n + 1 - 1/3^(n+1) >= n + 8/9 > n + 1/2$. Значит,
    $ lambda(union.big_(n = 1)^oo I_n) = sum_(n = 1)^oo (1/3^n + 1/2^n) = 1/2 + 1 = 3/2. $

  + Пусть $A_n$ -- объединение $9^n$ отрезков $[0.d_1 ... d_n, 0.d_1 ... d_n + 10^(-n)]$ по всем наборам цифр $d_1, ..., d_n in {0, ..., 9} without {5}$. Это конечное объединение отрезков, т.е. борелевское множество, и
    $ lambda(A_n) <= 9^n dot 10^(-n) = (9/10)^n. $
    Если $x = 0.d_1 d_2 ...$ -- разложение без пятёрок, то $0.d_1 ... d_n <= x <= 0.d_1 ... d_n + 10^(-n)$, т.е. $x in A_n$ для всех $n$. Итак, $A subset.eq A_n$ и
    $ lambda(A) <= lambda(A_n) <= (9/10)^n -->_(n -> oo) 0 quad => quad lambda(A) = 0. $

    (Измеримость $A$: на самом деле $A_n arrow.br A$. Если $x in inter.big_n A_n$, то для каждого $n$ одно из не более чем двух десятичных разложений $x$ не содержит пятёрок среди первых $n$ цифр; одно из разложений подходит для бесконечно многих $n$, а значит, и для всех. Поэтому $A = inter.big_n A_n in cal(B)(RR)$, и $lambda(A) = lim lambda(A_n) = 0$ по непрерывности сверху.)
]

#exercise[
  Посчитайте меру Лебега множества Кантора $cal(C) subset.eq [0, 1]$.
]

#solve[
  Напомним построение: $C_0 := [0, 1]$, а $C_(n+1)$ получается из $C_n$ выкидыванием открытой средней трети из каждого отрезка:
  $ C_1 = [0, 1/3] union [2/3, 1], quad C_2 = [0, 1/9] union [2/9, 1/3] union [2/3, 7/9] union [8/9, 1], quad ... $
  Множество Кантора -- это $cal(C) := inter.big_(n = 0)^oo C_n$. Каждое $C_n$ -- конечное объединение замкнутых отрезков, поэтому $cal(C)$ замкнуто, а значит, $cal(C) in cal(B)(RR)$.

  $C_n$ состоит из $2^n$ непересекающихся отрезков длины $3^(-n)$, поэтому
  $ lambda(C_n) = 2^n dot 3^(-n) = (2/3)^n. $
  По построению $C_(n+1) subset.eq C_n$, т.е. $C_n arrow.br cal(C)$, и $lambda(C_0) = 1 < oo$. По непрерывности сверху
  $ lambda(cal(C)) = lim_(n -> oo) lambda(C_n) = lim_(n -> oo) (2/3)^n = 0. $

  Проверка через дополнение: на шаге $n$ выкидывается $2^(n-1)$ интервалов длины $3^(-n)$, всего
  $ lambda([0, 1] without cal(C)) = sum_(n = 1)^oo 2^(n-1)/3^n = 1/3 dot 1/(1 - 2\/3) = 1, quad lambda(cal(C)) = 1 - 1 = 0. $

  Заметим, что $cal(C)$ -- это в точности числа из $[0, 1]$, имеющие троичное разложение без цифры $1$ (ср. с задачей 4.3). Такие числа находятся в биекции с последовательностями из $0$ и $2$, поэтому $cal(C)$ несчётно. Итак, в отличие от $QQ$, множество Кантора несчётно, но при этом тоже имеет меру Лебега $0$.
]
