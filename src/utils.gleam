import ffi/ffi
import gleam/dict
import gleam/int
import gleam/javascript/promise
import gleam/list
import gleam/result
import gleam/string
import hash
import lustre
import plinth/browser/window

pub fn await_get_content(
  src: String,
  key: String,
  callback: fn(Result(String, Nil)) -> Nil,
) {
  {
    use res <- promise.await({
      use bits <- promise.try_await(ffi.decode_data_from_img(src))
      ffi.decrypt_data(bits, key)
    })
    callback(res)
    promise.resolve(Nil)
  }
  Nil
}

pub fn guess_title(content: String) -> String {
  let tags = ["h1", "h2", "h3", "h4", "h5", "h6"]
  {
    use tag <- list.find_map(tags)
    let open_tag = "<" <> tag <> ">"
    let close_tag = "</" <> tag <> ">"

    let trimd = string.trim_start(content)
    use trimd <- result.try(case trimd |> string.starts_with(open_tag) {
      True -> Ok(trimd)
      False -> Error(Nil)
    })
    use #(title, _) <- result.try({
      open_tag
      |> string.length
      |> string.drop_start(trimd, _)
      |> string.split_once(close_tag)
    })
    Ok(title)
  }
  |> result.unwrap("Awesome Page")
}

pub fn try_render_html(content: String) {
  case
    {
      use flag <- list.any(["<!DOCTYPE html", "<!doctype html", "<html"])
      content |> string.trim_start |> string.starts_with(flag)
    }
  {
    False -> Nil
    True -> {
      let next_href =
        hash.get_url_params()
        |> dict.insert("d", "html")
        |> hash.param_dict_to_hashed_href
      // window.set_location(window.self(), next_href)
      ffi.window_location_replace(window.self(), next_href)
    }
  }
}

pub fn wrap_src(src: String) -> String {
  case src |> string.ends_with(".x") {
    True -> src <> ".png"
    False -> src
  }
}

fn random_str(len: Int, from: String) {
  case len {
    0 -> ""
    _ ->
      random_str(len - 1, from)
      <> {
        from
        |> string.length
        |> int.random
        |> string.slice(from, _, 1)
      }
  }
}

const numbers_strings = "0123456789"

const lower_strings = "abcdefghijklmnopqrstuvwxyz"

const mix_strings = numbers_strings <> lower_strings

fn random_component_name() {
  random_str(1, lower_strings) <> "-" <> random_str(4, mix_strings)
}

pub fn register_with_random_name(component: lustre.App(Nil, model, msg)) {
  let name = random_component_name()
  case lustre.is_registered(name) {
    True -> register_with_random_name(component)
    False -> {
      let assert Ok(Nil) = lustre.register(component, name)
      name
    }
  }
}
