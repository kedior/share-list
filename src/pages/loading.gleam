import gleam/list
import lustre
import lustre/attribute as attr
import lustre/element
import lustre/element/html
import lustre/element/svg
import plinth/browser/document
import styles/modules/loading_module_css as css
import utils

pub fn element() {
  document.set_title("loading")
  let single_svg =
    svg.svg(
      [
        attr.attribute("fill", "currentColor"),
        attr.attribute("viewBox", "0 0 90 120"),
      ],
      [
        svg.path([
          attr.attribute(
            "d",
            "M90,0 L90,120 L11,120 C4.92486775,120 0,115.075132 0,109 L0,11 C0,4.92486775 4.92486775,0 11,0 L90,0 Z M71.5,81 L18.5,81 C17.1192881,81 16,82.1192881 16,83.5 C16,84.8254834 17.0315359,85.9100387 18.3356243,85.9946823 L18.5,86 L71.5,86 C72.8807119,86 74,84.8807119 74,83.5 C74,82.1745166 72.9684641,81.0899613 71.6643757,81.0053177 L71.5,81 Z M71.5,57 L18.5,57 C17.1192881,57 16,58.1192881 16,59.5 C16,60.8254834 17.0315359,61.9100387 18.3356243,61.9946823 L18.5,62 L71.5,62 C72.8807119,62 74,60.8807119 74,59.5 C74,58.1192881 72.8807119,57 71.5,57 Z M71.5,33 L18.5,33 C17.1192881,33 16,34.1192881 16,35.5 C16,36.8254834 17.0315359,37.9100387 18.3356243,37.9946823 L18.5,38 L71.5,38 C72.8807119,38 74,36.8807119 74,35.5 C74,34.1192881 72.8807119,33 71.5,33 Z",
          ),
        ]),
      ],
    )

  let pages =
    html.li([], [single_svg])
    |> list.repeat(6)

  let body =
    html.div([attr.class(css.loader)], [
      html.div([], [html.ul([], pages)]),
      html.span([], [html.text("Loading")]),
    ])

  element.fragment([
    html.style([], css.css),
    html.div(
      [
        attr.styles([
          #("display", "flex"),
          #("justify-content", "center"),
          #("margin-top", "30px"),
        ]),
      ],
      [body],
    ),
  ])
}

pub fn register() {
  lustre.element(element())
  |> utils.register_with_random_name
}
