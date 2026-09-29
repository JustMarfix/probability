#import "utils/core.typ": notes
#import "config.typ"

#show: notes.with(
  name: "Конспекты семинаров по ТВиМС",
  short-name: "Семинары по ТВиМС",
  lector: "Киндеркнехт Яна Анатольевна",
  info: "2026-2027",
)

#include "sections/01-sigma/!sec.typ"
#include "sections/02-prob-space/!sec.typ"
#include "sections/03-discrete/!sec.typ"
#include "sections/04-lebeg/!sec.typ"
#include "sections/05-depend/!sec.typ"

#if config.appendix {
  include "appendix.typ"
}
