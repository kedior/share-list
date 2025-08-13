// IMPORTS ---------------------------------------------------------------------
import fallback
import gleam/dict
import gleam/dynamic/decode
import gleam/function
import gleam/json
import gleam/result
import gleam/string
import loading
import lustre
import lustre/attribute
import lustre/component
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import markdown
import rawhtml
import types.{type EncryptedPage, type PageProps, NewPage}
import utils

const component_name = "encrypted-page"

fn wrap_src(src: String) -> String {
  case src |> string.ends_with(".x") {
    True -> src <> ".png"
    False -> src
  }
}

pub fn register() -> Result(Nil, lustre.Error) {
  let assert Ok(_) = markdown.register()
  let comp =
    lustre.component(init, update, view, [
      component.on_property_change("props", {
        use props <- decode.map(decode.dict(decode.string, decode.string))
        let try_parse_props = {
          use src <- result.try(props |> dict.get("src"))
          use key <- result.try(props |> dict.get("key"))
          let d = props |> dict.get("d") |> result.unwrap("")

          // history reasons
          let next_src = wrap_src(src)
          let next_props = dict.insert(props, "src", next_src)

          Ok(Props(d, next_src, key, next_props))
        }
        case try_parse_props {
          Ok(props) -> MsgPropsChange(props)
          Error(Nil) -> MsgFailed
        }
      }),
    ])

  lustre.register(comp, component_name)
}

fn router(page_type: String) -> EncryptedPage(Msg) {
  case page_type {
    "html" -> rawhtml.page
    _ -> markdown.page
  }
}

pub const page = NewPage(start, clean)

fn start(props: PageProps) -> Element(msg) {
  let props_json =
    props
    |> json.dict(function.identity, json.string)
    |> attribute.property("props", _)

  element.element(component_name, [props_json], [])
}

fn clean() {
  Nil
}

// MODEL -----------------------------------------------------------------------
type Status {
  Loading
  Failed
  Success(String)
}

type Props {
  Props(page_type: String, src: String, key: String, other: PageProps)
}

fn empty_prop() {
  Props("", "", "", dict.new())
}

type Model {
  Model(status: Status, props: Props)
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Model(Loading, empty_prop()), effect.none())
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  MsgPropsChange(Props)
  MsgSuccess(Model)
  MsgFailed
}

fn is_source_changed(old_props: Props, new_props: Props) {
  old_props.src != new_props.src || old_props.key != new_props.key
}

fn do_fetch_content(props: Props, dispatch) {
  use res <- utils.await_get_content(props.src, props.key)
  case res {
    Ok(content) -> {
      let next_model = Model(Success(content), props)
      dispatch(MsgSuccess(next_model))
    }
    Error(_) -> dispatch(MsgFailed)
  }
}

fn props_change_effect(old_model: Model, props: Props) {
  use dispatch <- effect.from()
  let old_props = old_model.props
  let page_changed = router(old_props.page_type) != router(props.page_type)
  let source_changed = is_source_changed(old_model.props, props)

  case page_changed, source_changed {
    True, _ | _, True -> do_fetch_content(props, dispatch)
    False, False -> dispatch(MsgSuccess(Model(..old_model, props:)))
  }
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    MsgPropsChange(props) -> {
      #(Model(Loading, props), props_change_effect(model, props))
    }
    MsgFailed -> #(Model(Failed, empty_prop()), effect.none())
    MsgSuccess(model) -> #(model, effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  case model.status {
    Loading -> loading.element()
    Failed -> fallback.element()
    Success(content) -> {
      router(model.props.page_type).start(content, model.props.other)
    }
  }
}
