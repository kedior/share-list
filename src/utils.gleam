import ffi/ffi
import gleam/dict
import gleam/int
import gleam/javascript/promise
import gleam/list
import gleam/result
import gleam/string
import gleam/uri
import lustre
import plinth/browser/window

pub fn get_url_params() -> dict.Dict(String, String) {
  let parser = fn(res) {
    let str = res |> result.unwrap("")
    case str |> string.contains("=") {
      True -> str
      False -> ""
    }
    |> uri.parse_query
    |> result.unwrap([])
  }

  let hash_params = window.get_hash() |> parser |> dict.from_list
  let params_list = window.get_search() |> parser

  // filter out kv that not in hash_params
  {
    use #(k, v) <- list.filter_map(params_list)
    case hash_params |> dict.has_key(k) {
      True -> Error(Nil)
      False -> Ok(#(k, v))
    }
  }
  // merge to hash_params
  |> dict.from_list
  |> dict.merge(hash_params)
}

pub fn param_dict_to_hashed_url(params: dict.Dict(String, String)) {
  window.pathname()
  <> "#"
  <> {
    params
    |> dict.to_list
    |> uri.query_to_string
  }
}

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
      use flag <- list.any(["<!DOCTYPE html", "<!doctype html"])
      content |> string.trim_start |> string.starts_with(flag)
    }
  {
    False -> Nil
    True -> {
      let next_href =
        get_url_params()
        |> dict.insert("d", "html")
        |> param_dict_to_hashed_url
      window.set_location(window.self(), next_href)
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
  let from_len = string.length(from)
  list.range(1, len)
  |> list.map(fn(_) {
    int.random(from_len)
    |> string.drop_start(from, _)
    |> string.first()
    |> result.unwrap("")
  })
  |> string.join("")
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
