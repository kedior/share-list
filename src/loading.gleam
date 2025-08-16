import lustre/attribute
import lustre/element
import lustre/element/html
import plinth/browser/document
import styles/modules/loading_module_css as css
import types.{type PageProps}

pub fn element() {
  document.set_title("loading")

  element.fragment([
    html.title([], "loading..."),
    html.style([], css.css),
    html.div(
      [
        attribute.styles([
          #("display", "flex"),
          #("justify-content", "center"),
          #("margin-top", "30px"),
        ]),
      ],
      [
        html.div([attribute.class(css.loadingspinner)], [
          html.div([attribute.id(css.square1)], []),
          html.div([attribute.id(css.square2)], []),
          html.div([attribute.id(css.square3)], []),
          html.div([attribute.id(css.square4)], []),
          html.div([attribute.id(css.square5)], []),
        ]),
      ],
    ),
  ])
}

pub fn page(_: PageProps) {
  element()
}
