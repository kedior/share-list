import gleam/list
import lustre/attribute
import lustre/element
import lustre/element/html
import plinth/browser/document
import styles/modules/loading_module_css
import types.{type PageProps}

pub fn element() {
  document.set_title("loading")
  let dots =
    list.map(list.repeat([0], 3), fn(_) {
      html.div([attribute.class(loading_module_css.dot)], [])
    })

  element.fragment([
    html.title([], "loading..."),
    html.style([], loading_module_css.css),
    html.div(
      [
        attribute.styles([#("display", "flex"), #("justify-content", "center")]),
      ],
      [html.div([attribute.class(loading_module_css.loader)], dots)],
    ),
  ])
}

pub fn page(_: PageProps) {
  element()
}
