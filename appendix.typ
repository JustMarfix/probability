#import "config.typ"
#import "utils/core.typ": *

#set heading(numbering: (..numbers) => {
    let numbers = numbers.pos()
    if numbers.len() < 2 {
        none
    } else if numbers.len() == 2 {
        numbering("A.", numbers.at(1))
    }
})

= Приложение

== TODO-шки и упражнения

Все это, по хорошему, надо дописать/доделать/улучшить.

#context{
    let todos = query(selector(<todo-like>))

    list(..todos.map(el => {
        link(el.location(), el)
        box(width: 1fr, repeat[.])
        link(el.location())[#el.location().page()]
    }))
}
