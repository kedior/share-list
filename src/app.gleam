// IMPORTS ---------------------------------------------------------------------

import lustre
import lustre/attribute
import lustre/element
import lustre/element/html
import router
import styles/katex_css
import styles/modules/global_module_css

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let assert Ok(_) = router.register()
  let assert Ok(_) = app() |> lustre.element |> lustre.start("html", Nil)
  Nil
}

fn app() {
  element.fragment([
    html.head([], [
      html.meta([attribute.charset("utf-8")]),
      html.meta([
        attribute.http_equiv("X-UA-Compatible"),
        attribute.content("IE=edge"),
      ]),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width, initial-scale=1.0"),
      ]),
      html.meta([
        attribute.name("apple-mobile-web-app-capable"),
        attribute.content("yes"),
      ]),
      html.meta([
        attribute.name("mobile-web-app-capable"),
        attribute.content("yes"),
      ]),
      html.meta([attribute.name("theme-color"), attribute.content("#f1f7fe")]),
      html.link([
        attribute.rel("icon"),
        attribute.type_("image/png"),
        attribute.href("unicorn.png"),
      ]),
      html.link([
        attribute.rel("apple-touch-icon"),
        attribute.href("unicorn.png"),
      ]),
    ]),
    html.body([], [
      html.style([], global_module_css.css),
      // fuck katex fonts, must inject to global body
      html.style([], katex_css.css),
      router.element(),
    ]),
  ])
}
