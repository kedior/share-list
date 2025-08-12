// IMPORTS ---------------------------------------------------------------------
import ffi/ffi.{set_body_class_name}
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
import styles/modules/global_module_css.{markdown_body_color}
import styles/modules/markdown_module_css
import types.{type PageProps, NewEncryptedPage}
import utils

const component_name = "markdown-body"

pub fn register() -> Result(Nil, lustre.Error) {
  let comp =
    lustre.component(init, update, view, [
      component.on_property_change("props", {
        let list_decoder =
          utils.json_decode_by_keys(["src", "key", "pdf", "content"])
        use vals <- decode.map(list_decoder)
        case vals {
          [src, key, pdf, content] -> {
            ReceiveQuicContent(Props(src:, key:, pdf:, content:))
          }
          _ -> ReceiveFailed
        }
      }),
    ])

  lustre.register(comp, component_name)
}

pub const page = NewEncryptedPage(start, clean)

fn start(content: String, props: PageProps) -> Element(msg) {
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

fn clean() {
  set_body_class_name("")
  document.set_title("")
}

// MODEL -----------------------------------------------------------------------

type Model {
  Model(content: String, pdf: String)
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Model("", ""), effect.none())
}

// UPDATE ----------------------------------------------------------------------

type Props {
  Props(src: String, key: String, pdf: String, content: String)
}

type Msg {
  ReceiveQuicContent(props: Props)
  ReceiveLazyContent(props: Props)
  ReceiveFailed
}

fn background_color_effect(pdf: String) {
  use _dispatch <- effect.from()
  case pdf {
    "" -> markdown_body_color
    _ -> ""
  }
  |> set_body_class_name
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
          use date <- utils.await_get_content(next_src, props.key)
          case date {
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
      Model(props.content, props.pdf),
      effect.batch([
        get_lazy_content_effect(props),
        background_color_effect(props.pdf),
        set_title_effect(props.content),
      ]),
    )
    ReceiveLazyContent(props) -> #(
      Model(props.content, props.pdf),
      effect.none(),
    )
    ReceiveFailed -> #(model, effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  let class_name =
    markdown_module_css.markdown
    <> " "
    <> case model.pdf {
      "" -> markdown_module_css.no_pdf
      _ -> ""
    }
  let container =
    element.unsafe_raw_html(
      "",
      "div",
      [attribute.class(class_name)],
      model.content,
    )

  element.fragment([
    html.style([], markdown_module_css.css),
    html.style([], hljs_ant_design_css.css),
    container,
  ])
}
