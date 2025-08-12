import gleam/list
import lustre/attribute
import lustre/element
import lustre/element/html
import styles/modules/loading_module_css

pub fn element() {
  let dots =
    list.map(list.repeat([0], 3), fn(_) {
      html.div([attribute.class(loading_module_css.dot)], [])
    })

  element.fragment([
    html.style([], loading_module_css.css),
    html.div(
      [
        attribute.styles([#("display", "flex"), #("justify-content", "center")]),
      ],
      [html.div([attribute.class(loading_module_css.loader)], dots)],
    ),
  ])
}
