// IMPORTS ---------------------------------------------------------------------
import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/result
import gleam/string
import lustre
import lustre/attribute
import lustre/component
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import plinth/browser/document
import styles/hljs_ant_design_css
import styles/modules/markdown_module_css as css
import types.{type PageProps}
import utils

const component_name = "markdown-body"

pub fn register() -> Result(Nil, lustre.Error) {
  let comp =
    lustre.component(init, update, view, [
      component.on_property_change("props", {
        let list_decoder = utils.json_decode_by_keys(["src", "key", "content"])
        use vals <- decode.map(list_decoder)
        case vals {
          [src, key, content] -> {
            // history shared link need this
            utils.try_render_html(content)
            ReceiveQuicContent(Props(src:, key:, content:))
          }
          _ -> ReceiveFailed
        }
      }),
    ])

  lustre.register(comp, component_name)
}

pub fn page(content: String, props: PageProps) -> Element(msg) {
  let extract = fn(key) {
    #(key, props |> dict.get(key) |> result.unwrap("") |> json.string)
  }
  let props_json =
    json.object([
      extract("src"),
      extract("key"),
      extract("pdf"),
      #("content", json.string(content)),
    ])
    |> attribute.property("props", _)

  element.element(component_name, [props_json], [])
}

// MODEL -----------------------------------------------------------------------

type Model {
  Model(content: String)
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Model(""), effect.none())
}

// UPDATE ----------------------------------------------------------------------

type Props {
  Props(src: String, key: String, content: String)
}

type Msg {
  ReceiveQuicContent(props: Props)
  ReceiveLazyContent(props: Props)
  ReceiveFailed
}

const lazy_continue_flag = "<!-- lazy start -->"

fn get_lazy_content_effect(props: Props) {
  use dispatch <- effect.from()
  case props.content |> string.ends_with(lazy_continue_flag) {
    False -> Nil
    True -> {
      let _ = {
        let next_src = props.src |> string.replace(".x.png", ".y.png")
        Ok({
          use data <- utils.await_get_content(next_src, props.key)
          case data {
            Ok(content) ->
              dispatch(ReceiveLazyContent(Props(..props, content:)))
            Error(_) -> Nil
          }
        })
      }
      Nil
    }
  }
}

fn set_title_effect(content: String) {
  use _dispatch <- effect.from()
  content |> utils.guess_title |> document.set_title
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ReceiveQuicContent(props) -> #(
      Model(props.content),
      effect.batch([
        get_lazy_content_effect(props),
        set_title_effect(props.content),
      ]),
    )
    ReceiveLazyContent(props) -> #(Model(props.content), effect.none())
    ReceiveFailed -> #(model, effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  let body =
    element.unsafe_raw_html(
      "",
      "div",
      [attribute.class(css.markdown)],
      model.content,
    )

  element.fragment([
    html.style([], css.css),
    html.style([], hljs_ant_design_css.css),
    html.div([attribute.class(css.container)], [
      body,
    ]),
  ])
}
