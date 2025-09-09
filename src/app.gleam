// IMPORTS ---------------------------------------------------------------------

import download
import encrypted
import fallback
import gleam/dict
import gleam/json
import listener
import loading
import lustre
import lustre/attribute
import lustre/element
import lustre/element/html
import markdown
import rawhtml
import router.{Page, new_router, router_to_json_str}
import styles/katex_css
import styles/modules/global_module_css

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let enc_r = {
    let markdown_name = markdown.register()
    let raw_html_name = rawhtml.register()
    new_router(
      [
        #(["md", "markdown"], Page(markdown_name, dict.new())),
        #(["html"], Page(raw_html_name, dict.new())),
      ],
      "md",
    )
  }

  let r = {
    let download_name = download.register()
    let fallback_name = fallback.register()
    let loading_name = loading.register()
    let enc_name = encrypted.register()

    new_router(
      [
        #(["fallback", "404"], Page(fallback_name, dict.new())),
        #(["loading", "load"], Page(loading_name, dict.new())),
        #(["download"], Page(download_name, dict.new())),
        #(
          [""],
          Page(
            enc_name,
            dict.from_list([
              #("router", router_to_json_str(enc_r)),
            ]),
          ),
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
        |> router_to_json_str
        |> json.string
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
