#import "../../utils/core.typ": *

== Задачи

#def[
  Пусть $Omega$ -- непустое множество. Система $cal(A)$ подмножеств множества $Omega$ называется *$sigma$-алгеброй* (в $Omega$), если
  + $Omega in cal(A)$;
  + $A in cal(A) => A^C := Omega without A in cal(A)$;
  + $A_1, ..., A_n, ... in cal(A) => union.big_(n = 1)^oo A_n in cal(A)$.
]

#task(name: "1")[
  Покажите, что $A, B in cal(A) => A inter B, A without B, B without A, A triangle.stroked.small B in cal(A)$.
]

#solve[
  Сначала заметим, что $emptyset = Omega^C in cal(A)$, а значит, $cal(A)$ замкнута и относительно *конечных* объединений: $A union B = A union B union emptyset union emptyset union ... in cal(A)$.

  - $A inter B = (A^C union B^C)^C in cal(A)$ по закону де Моргана.
  - $A without B = A inter B^C in cal(A)$, аналогично $B without A = B inter A^C in cal(A)$.
  - $A triangle.stroked.small B = (A without B) union (B without A) in cal(A)$.
]

#task(name: "2")[
  Пусть $A subset Omega$ непусто. Какова наименьшая $sigma$-алгебра в $Omega$, содержащая $A$?
]

#solve[
  $sigma(A) = #boxed(${emptyset, A, A^C, Omega}$)$.

  Это $sigma$-алгебра: $Omega$ в ней есть, дополнение любого элемента снова в ней, а объединение любого набора её элементов -- снова один из этих четырёх множеств (например, $A union A^C = Omega$, $A union emptyset = A$).

  Она наименьшая: любая $sigma$-алгебра, содержащая $A$, содержит и $A^C$, $Omega$ и $emptyset = Omega^C$.

  (Если $A = Omega$, то получается тривиальная $sigma$-алгебра ${emptyset, Omega}$.)
]

#task(name: "3")[
  Пусть $cal(A)$ -- некоторая $sigma$-алгебра в $Omega$, $Omega^* subset Omega$ непусто. Покажите, что следующая система множеств
  $ cal(A)^* := {A inter Omega^* : A in cal(A)} $
  является $sigma$-алгеброй в $Omega^*$. Такая $sigma$-алгебра называется *следовой*, или *следом $sigma$-алгебры $cal(A)$ в $Omega^*$*.
]

#solve[
  + $Omega^* = Omega inter Omega^* in cal(A)^*$, т.к. $Omega in cal(A)$.
  + Дополнение берётся в $Omega^*$: $Omega^* without (A inter Omega^*) = A^C inter Omega^* in cal(A)^*$, т.к. $A^C in cal(A)$.
  + $union.big_(n = 1)^oo (A_n inter Omega^*) = (union.big_(n = 1)^oo A_n) inter Omega^* in cal(A)^*$, т.к. $union.big_n A_n in cal(A)$.
]

#task(name: "4")[
  Пусть $Omega, Omega'$ -- непустые множества, $cal(A)'$ -- некоторая $sigma$-алгебра в $Omega'$, $f : Omega -> Omega'$ -- некоторое отображение. Покажите, что следующая система множеств
  $ sigma(f) := f^(-1)(cal(A)') := {f^(-1)(A') : A' in cal(A)'} $
  является $sigma$-алгеброй в $Omega$. Такая $sigma$-алгебра называется *сигма-алгеброй прообразов отображения $f$*. При решении необходимо проверить и использовать свойства прообразов отображений:
  $ f^(-1)(A union B) = f^(-1)(A) union f^(-1)(B), quad f^(-1)(A inter B) = f^(-1)(A) inter f^(-1)(B), $
  $ A subset.eq B => f^(-1)(A) subset.eq f^(-1)(B), quad f^(-1)(A^C) = (f^(-1)(A))^C, quad f^(-1)(A without B) = f^(-1)(A) without f^(-1)(B). $
]

#notice[
  В листке семинара последнее свойство записано с опечаткой: $f^(-1)(A) without f^(-1)(A) without f^(-1)(B)$. Правильно -- как выше.
]

#solve[
  *Свойства прообразов.* Все они следуют из определения $x in f^(-1)(A) <=> f(x) in A$. Причём объединения и пересечения можно брать сразу по любому (в том числе счётному) семейству:
  - $x in f^(-1)(union.big_i A_i) <=> f(x) in union.big_i A_i <=> exists i : f(x) in A_i <=> x in union.big_i f^(-1)(A_i)$;
  - $x in f^(-1)(inter.big_i A_i) <=> forall i : f(x) in A_i <=> x in inter.big_i f^(-1)(A_i)$;
  - если $A subset.eq B$ и $f(x) in A$, то $f(x) in B$;
  - $x in f^(-1)(Omega' without A) <=> f(x) in.not A <=> x in.not f^(-1)(A)$;
  - $f^(-1)(A without B) = f^(-1)(A inter B^C) = f^(-1)(A) inter (f^(-1)(B))^C = f^(-1)(A) without f^(-1)(B)$.

  *Аксиомы $sigma$-алгебры.*
  + $Omega = f^(-1)(Omega') in sigma(f)$, т.к. $Omega' in cal(A)'$.
  + $(f^(-1)(A'))^C = f^(-1)(A'^C) in sigma(f)$, т.к. $A'^C in cal(A)'$.
  + $union.big_n f^(-1)(A'_n) = f^(-1)(union.big_n A'_n) in sigma(f)$, т.к. $union.big_n A'_n in cal(A)'$.
]

#task(name: "5")[
  Пусть $(cal(A)_lambda)_(lambda in Lambda)$ -- некоторое семейство $sigma$-алгебр (в некотором $Omega$). Покажите, что система $inter.big_(lambda in Lambda) cal(A)_lambda$ также является $sigma$-алгеброй.
]

#solve[
  Обозначим $cal(A) := inter.big_(lambda in Lambda) cal(A)_lambda$. Каждая аксиома проверяется «покомпонентно»:
  + $Omega in cal(A)_lambda$ для всех $lambda$, значит, $Omega in cal(A)$.
  + Если $A in cal(A)$, то $A in cal(A)_lambda$ для всех $lambda$, значит, $A^C in cal(A)_lambda$ для всех $lambda$, т.е. $A^C in cal(A)$.
  + Если $A_n in cal(A)$, то $A_n in cal(A)_lambda$ для всех $lambda$ и $n$, значит, $union.big_n A_n in cal(A)_lambda$ для всех $lambda$, т.е. $union.big_n A_n in cal(A)$.

  В частности, отсюда следует, что для любой системы множеств $cal(S)$ существует наименьшая $sigma$-алгебра $sigma(cal(S))$, её содержащая: это пересечение всех $sigma$-алгебр, содержащих $cal(S)$ (таких есть хотя бы одна -- $2^Omega$).
]

#def[
  Пусть $X subset.eq RR^d$, $d in NN$. *Борелевской $sigma$-алгеброй* в $X$ называется наименьшая $sigma$-алгебра, содержащая все открытые множества $X$ (т.е. $sigma$-алгебра, *порождённая* открытыми множествами). Обозначение: $cal(B)(X)$.
]

#task(name: "6")[
  Проверьте, являются ли следующие множества элементами борелевской $sigma$-алгебры $cal(B)(RR^d)$:
  + $d = 1$, $A_0 :=$ все натуральные числа;
  + $d = 1$, $A_1 := QQ =$ все рациональные числа;
  + $d = 1$, $A_2 :=$ все иррациональные числа;
  + $d = 1$, $A_3 := union.big_(n = 1)^oo ([n^2, n^2 + 1/ln(n + 1)] inter QQ)$;
  + $d = 2$, $A_4 := RR times [0, 1]$;
  + $d = 2$, $A_5 := {(x, y) in RR^2 : x^2 + y^2 < 1}$;
  + $d = 2$, $A_6 := {(x, y) in RR^2 : x + y in ZZ}$.
]

#solve[
  #boxed[Все семь множеств борелевские.] Будем пользоваться тем, что точка ${x}$ замкнута (её дополнение открыто), а значит, ${x} in cal(B)(RR)$.

  + $NN = union.big_(n in NN) {n}$ -- счётное объединение точек, $NN in cal(B)(RR)$.
  + $QQ = union.big_(q in QQ) {q}$ -- тоже счётное объединение точек, $QQ in cal(B)(RR)$.
  + $RR without QQ = QQ^C in cal(B)(RR)$ как дополнение.
  + Каждое множество $[n^2, n^2 + 1/ln(n + 1)] inter QQ$ -- пересечение отрезка (замкнут) и $QQ$, т.е. борелевское; счётное объединение борелевских -- борелевское. (Или проще: $A_3 subset.eq QQ$ счётно, а любое счётное множество -- счётное объединение точек.)
  + $RR times [0, 1]$ замкнуто в $RR^2$: его дополнение $RR times ((-oo, 0) union (1, +oo))$ открыто. Значит, $A_4 in cal(B)(RR^2)$. (Или: $A_4 = union.big_n [-n, n] times [0, 1]$ -- счётное объединение брусов.)
  + $A_5 = B_1 (0)$ -- открытый шар, $A_5 in cal(B)(RR^2)$.
  + $A_6 = g^(-1)(ZZ)$, где $g(x, y) := x + y$ непрерывна, а $ZZ$ замкнуто в $RR$. Прообраз замкнутого множества при непрерывном отображении замкнут, поэтому $A_6$ замкнуто и $A_6 in cal(B)(RR^2)$. (Иначе: $A_6 = union.big_(k in ZZ) {x + y = k}$ -- счётное объединение замкнутых прямых.)
]
