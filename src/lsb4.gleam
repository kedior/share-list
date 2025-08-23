import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}
import gleam/result

fn lsb4(bits: BitArray, idx: Int, acc: BytesTree) {
  case bit_array.slice(bits, idx, 2) {
    Ok(<<_:4, a:4, _:4, b:4>>) -> {
      let next = bytes_tree.append(acc, <<{ b * 16 + a }:8>>)
      lsb4(bits, idx + 2, next)
    }
    _ -> bytes_tree.to_bit_array(acc)
  }
}

fn rgba_to_rgb(bits: BitArray, idx: Int, acc: BytesTree) {
  case bit_array.slice(bits, idx, 4) {
    Ok(<<r, g, b, _a>>) -> {
      let next = bytes_tree.append(acc, <<r, g, b>>)
      rgba_to_rgb(bits, idx + 4, next)
    }
    _ -> bytes_tree.to_bit_array(acc)
  }
}

pub fn parse_rgba_lsb4(bits: BitArray) {
  let rgbs = rgba_to_rgb(bits, 0, bytes_tree.new())
  use len_part <- result.try(bit_array.slice(rgbs, 0, 8))
  use length <- result.try(case lsb4(len_part, 0, bytes_tree.new()) {
    <<len:little-32>> -> Ok(len)
    _ -> Error(Nil)
  })
  use datas <- result.try(bit_array.slice(rgbs, 8, length * 2))
  Ok(lsb4(datas, 0, bytes_tree.new()))
}
