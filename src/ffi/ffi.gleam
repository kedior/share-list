import gleam/javascript/promise.{type Promise}

@external(javascript, "./export.mjs", "historyReplaceState")
pub fn history_replace_state(url: String) -> Nil

@external(javascript, "./export.mjs", "decodeDataFromImage")
pub fn decode_data_from_img(img_url: String) -> Promise(Result(BitArray, Nil))

@external(javascript, "./export.mjs", "decryptData")
pub fn decrypt_data(
  encrypted_data: BitArray,
  password: String,
) -> Promise(Result(String, Nil))

@external(javascript, "./export.mjs", "renderRawHTML")
pub fn render_raw_html(content: string) -> Nil
