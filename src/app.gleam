// IMPORTS ---------------------------------------------------------------------

import gleam/json
import listener
import lustre
import lustre/attribute
import lustre/element
import lustre/element/html
import page
import pages/download
import pages/encrypted
import pages/fallback
import pages/loading
import pages/markdown
import pages/rawhtml
import router
import styles/katex_css
import styles/modules/global_module_css

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let enc_r = {
    let markdown_name = markdown.register()
    let raw_html_name = rawhtml.register()
    router.new(
      [
        #(["md", "markdown"], page.new(markdown_name)),
        #(["html"], page.new(raw_html_name)),
      ],
      "md",
    )
  }

  let r = {
    let download_name = download.register()
    let fallback_name = fallback.register()
    let loading_name = loading.register()
    let enc_name = encrypted.register()

    router.new(
      [
        #(["fallback", "404"], page.new(fallback_name)),
        #(["loading", "load"], page.new(loading_name)),
        #(["download"], page.new(download_name)),
        #(
          [""],
          page.new(enc_name)
            |> page.with_props([
              #("router", enc_r |> router.to_json |> json.to_string),
            ]),
        ),
      ],
      "",
    )
  }

  let listener_name = listener.register()
  let assert Ok(_) =
    element.element(
      listener_name,
      [
        r
        |> router.to_json
        |> attribute.property("router", _),
      ],
      [],
    )
    |> app
    |> lustre.element
    |> lustre.start("html", Nil)
  Nil
}

fn app(content: element.Element(msg)) {
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
      content,
    ]),
  ])
}
