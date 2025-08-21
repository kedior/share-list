// IMPORTS ---------------------------------------------------------------------
import fallback
import ffi/ffi
import gleam/bit_array
import gleam/dict
import gleam/dynamic/decode
import gleam/function
import gleam/int
import gleam/javascript/promise
import gleam/json
import gleam/result
import lustre
import lustre/attribute as attr
import lustre/component
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg
import lustre/event
import plinth/browser/document
import plinth/browser/element as dom_element
import plinth/browser/file
import plinth/javascript/console
import styles/modules/download_module_css as css
import types.{type PageProps}
import utils

const component_name = "download-page"

pub fn register() -> Result(Nil, lustre.Error) {
  let comp =
    lustre.component(init, update, view, [
      component.on_property_change("props", {
        use props <- decode.map(decode.dict(decode.string, decode.string))
        let try_parse_props = {
          use src <- result.try(props |> dict.get("src"))
          use key <- result.try(props |> dict.get("key"))
          let filename =
            props |> dict.get("filename") |> result.unwrap("unknown file")

          // history reasons
          let next_src = utils.wrap_src(src)
          Ok(Props(next_src, key, filename))
        }
        case try_parse_props {
          Ok(props) -> PropsChange(props)
          Error(Nil) -> InvalidProps
        }
      }),
    ])

  lustre.register(comp, component_name)
}

pub fn page(props: PageProps) -> Element(msg) {
  let props_json =
    props
    |> json.dict(function.identity, json.string)
    |> attr.property("props", _)

  element.element(component_name, [props_json], [])
}

// MODEL -----------------------------------------------------------------------
type Status {
  Idle
  Downloading(percent: Int)
  Complete
  Failed
  FallBack
}

type Props {
  Props(src: String, key: String, filename: String)
}

type Model {
  Model(status: Status, props: Props)
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Model(Idle, Props("", "", "")), effect.none())
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  PropsChange(Props)
  StartDownload
  UpdateProgress(Int)
  DownloadSuccess
  DownloadFailed
  InvalidProps
}

type BoxedFile {
  BoxedFile(filename: String, mime: String, base64_data: String)
}

fn triggle_download(boxed_file: BoxedFile) {
  let decode_res = bit_array.base64_decode(boxed_file.base64_data)
  use data <- result.try(decode_res)
  let data_url =
    file.new(data, boxed_file.filename)
    |> file.create_object_url()
  let a = document.create_element("a")
  dom_element.set_attribute(a, "href", data_url)
  dom_element.set_attribute(a, "download", boxed_file.filename)
  dom_element.set_attribute(a, "style", "display: none")
  Ok(ffi.dom_click(a))
}

fn parse_and_download(props: Props, data: BitArray, dispatch: fn(Msg) -> Nil) {
  let url =
    file.new(data, "data.png")
    |> file.create_object_url()

  use res <- utils.await_get_content(url, props.key)
  case
    {
      use data <- result.try(res)
      let decoder = {
        use filename <- decode.field("filename", decode.string)
        use mime <- decode.field("mimetype", decode.string)
        use base64_data <- decode.field("data", decode.string)
        decode.success(BoxedFile(filename, mime, base64_data))
      }
      case json.parse(data, decoder) {
        Error(err) -> Error(console.log(err))
        Ok(boxed_file) -> triggle_download(boxed_file)
      }
    }
  {
    Ok(_) -> dispatch(DownloadSuccess)
    Error(_) -> dispatch(DownloadFailed)
  }
  Nil
}

fn start_download_effect(props: Props) {
  use dispatch <- effect.from()
  let download_promise =
    ffi.download_file(props.src, fn(percent) {
      dispatch(UpdateProgress(percent))
    })

  let _async = {
    use res <- promise.await(download_promise)
    case res {
      Ok(data) -> parse_and_download(props, data, dispatch)
      Error(Nil) -> dispatch(DownloadFailed)
    }
    promise.resolve(Nil)
  }
  Nil
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    PropsChange(props) -> #(Model(Idle, props), effect.none())
    StartDownload -> #(
      Model(..model, status: Downloading(0)),
      start_download_effect(model.props),
    )
    UpdateProgress(percent) -> #(
      Model(..model, status: Downloading(percent)),
      effect.none(),
    )
    DownloadFailed -> #(Model(Failed, props: model.props), effect.none())
    DownloadSuccess -> #(Model(..model, status: Complete), effect.none())
    InvalidProps -> #(Model(..model, status: FallBack), effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

fn btn_text(str: String) {
  html.span([attr.class(css.btn_text)], [html.text(str)])
}

fn download_svg() {
  svg.svg(
    [
      attr.attribute("xmlns", "http://www.w3.org/2000/svg"),
      attr.attribute("viewBox", "0 -960 960 960"),
    ],
    [
      svg.path([
        attr.attribute(
          "d",
          "M480-320 280-520l56-58 104 104v-326h80v326l104-104 56 58-200 200ZM240-160q-33 0-56.5-23.5T160-240v-120h80v120h480v-120h80v120q0 33-23.5 56.5T720-160H240Z",
        ),
      ]),
    ],
  )
}

fn complete_svg() {
  svg.svg(
    [
      attr.attribute("viewBox", "0 -960 960 960"),
      attr.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attr.attribute(
          "d",
          "M382-320 155-547l57-57 170 170 366-366 57 57-423 423ZM200-160v-80h560v80H200Z",
        ),
      ]),
    ],
  )
}

fn failed_svg() {
  svg.svg(
    [
      attr.attribute("viewBox", "0 -960 960 960"),
      attr.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attr.attribute(
          "d",
          "M480-280q17 0 28.5-11.5T520-320q0-17-11.5-28.5T480-360q-17 0-28.5 11.5T440-320q0 17 11.5 28.5T480-280Zm-40-160h80v-240h-80v240Zm40 360q-83 0-156-31.5T197-197q-54-54-85.5-127T80-480q0-83 31.5-156T197-763q54-54 127-85.5T480-880q83 0 156 31.5T763-763q54 54 85.5 127T880-480q0 83-31.5 156T763-197q-54 54-127 85.5T480-80Zm0-80q134 0 227-93t93-227q0-134-93-227t-227-93q-134 0-227 93t-93 227q0 134 93 227t227 93Zm0-320Z",
        ),
      ]),
    ],
  )
}

fn button_view(model: Model) {
  html.button(
    [
      attr.class(css.download_btn),
      attr.disabled(case model.status {
        Failed | Downloading(_) | Complete -> True
        _ -> False
      }),
      event.on_click(StartDownload),
    ],
    [
      html.div(
        [
          attr.class(
            css.progress_layer
            <> {
              case model.status {
                Failed -> " " <> css.failed
                Complete -> " " <> css.complete
                _ -> ""
              }
            },
          ),
          attr.style("width", {
            case model.status {
              Downloading(percent) -> int.to_string(percent) <> "%"
              _ -> "100%"
            }
          }),
        ],
        [],
      ),
      {
        case model.status {
          Idle -> element.fragment([download_svg(), btn_text("Download")])
          Downloading(percent) -> btn_text(int.to_string(percent) <> "%")
          Complete -> element.fragment([complete_svg(), btn_text("Complete!")])
          _ -> element.fragment([failed_svg(), btn_text("Failed")])
        }
      },
    ],
  )
}

fn real_view(model: Model) {
  html.div([attr.class(css.file_card)], [
    html.div([attr.class(css.file_name)], [html.text(model.props.filename)]),
    button_view(model),
  ])
}

fn view(model: Model) -> Element(Msg) {
  document.set_title("File Download")
  case model.status {
    FallBack -> fallback.element()
    _ ->
      element.fragment([
        html.style([], css.css),
        html.div([attr.class(css.container)], [real_view(model)]),
      ])
  }
}
