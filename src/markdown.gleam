// IMPORTS ---------------------------------------------------------------------
import gleam/dict
import gleam/dynamic/decode
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
import styles/mdparser_css
import styles/modules/markdown_module_css as css
import utils

pub fn register() {
  lustre.component(init, update, view, [
    component.on_property_change("props", {
      use props <- decode.map(decode.dict(decode.string, decode.string))
      let try_parse_props = {
        use src <- result.try(props |> dict.get("src"))
        use key <- result.try(props |> dict.get("key"))
        use content <- result.try(props |> dict.get("content"))

        Ok(Props(src, key, content))
      }
      case try_parse_props {
        Ok(props) -> {
          // history shared link need this
          utils.try_render_html(props.content)
          ReceiveQuicContent(props)
        }
        _ -> ReceiveFailed
      }
    }),
  ])
  |> utils.register_with_random_name
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
  {
    use _ <- result.try(
      case props.content |> string.ends_with(lazy_continue_flag) {
        True -> Ok(Nil)
        False -> Error(Nil)
      },
    )
    let next_src = props.src |> string.replace(".x.png", ".y.png")
    utils.await_get_content(next_src, props.key, fn(res) {
      case res {
        Ok(content) -> dispatch(ReceiveLazyContent(Props(..props, content:)))
        Error(_) -> Nil
      }
    })
    Ok(Nil)
  }
  |> result.unwrap(Nil)
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
    html.style([], mdparser_css.css),
    html.div([attribute.class(css.container)], [
      body,
    ]),
  ])
}
