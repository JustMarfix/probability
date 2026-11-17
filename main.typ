#import "utils/core.typ": notes
#import "config.typ"

#show: notes.with(
  name: "Конспекты семинаров по ТВиМС (ИБ, 2 курс)",
  short-name: "Семинары по ТВиМС",
  lector: "Киндеркнехт Яна Анатольевна",
  info: "2026-2027",
  editor: "Михаил Резниченко, БИБ252"
)

#include "sections/01-sigma/!sec.typ"
#include "sections/02-prob-space/!sec.typ"
#include "sections/03-discrete/!sec.typ"
#include "sections/04-lebeg/!sec.typ"
#include "sections/05-depend/!sec.typ"
#include "sections/06-simulation/!sec.typ"
#include "sections/07-random/!sec.typ"
#include "sections/08-expectance/!sec.typ"
#include "sections/09-mgf/!sec.typ"
#include "sections/10-multivariate/!sec.typ"
#include "sections/11-conditional/!sec.typ"
#include "sections/12-simulation-2/!sec.typ"

#if config.appendix {
  include "appendix.typ"
}
