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

pub fn register() -> Result(Nil, lustre.Error) {
  let assert Ok(_) = markdown.register()
  let comp =
    lustre.component(init, update, view, [
      component.on_property_change("props", {
        use props <- decode.map(decode.dict(decode.string, decode.string))
        PropsChange(props)
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

type Model {
  Loading
  Failed
  Model(page_type: String, content: String, other_props: PageProps)
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Loading, effect.none())
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  PropsChange(PageProps)
  FetchContentSuccess(Model)
  FetchContentFailed
}

fn wrap_src(src: String) -> String {
  case src |> string.ends_with(".x") {
    True -> src <> ".png"
    False -> src
  }
}

fn props_change_effect(old_model: Model, props: PageProps) {
  use dispatch <- effect.from()
  case
    {
      let d = props |> dict.get("d") |> result.unwrap("")
      use src <- result.try(props |> dict.get("src"))
      use key <- result.try(props |> dict.get("key"))
      // history reasons
      let next_src = wrap_src(src)
      let next_props = dict.insert(props, "src", next_src)

      let _clean = case old_model {
        Model(old_type, _, _) -> {
          case router(old_type) == router(d) {
            True -> Nil
            False -> router(d).clean()
          }
        }
        _ -> Nil
      }

      Ok({
        use res <- utils.await_get_content(next_src, key)
        case res {
          Ok(content) -> {
            let next_model = Model(d, content, next_props)
            dispatch(FetchContentSuccess(next_model))
          }
          Error(_) -> dispatch(FetchContentFailed)
        }
      })
    }
  {
    Ok(Nil) -> Nil
    Error(_) -> dispatch(FetchContentFailed)
  }
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    PropsChange(props) -> {
      #(Loading, props_change_effect(model, props))
    }
    FetchContentFailed -> #(Failed, effect.none())
    FetchContentSuccess(model) -> #(model, effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  case model {
    Loading -> loading.element()
    Failed -> fallback.element()
    Model(page_type, content, other_props) -> {
      router(page_type).start(content, other_props)
    }
  }
}
