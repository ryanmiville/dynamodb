import decode.{type Decoder}
import gleam/bit_array
import gleam/float
import gleam/int
import gleam/json.{type Json}
import gleam/list

// ENCODERS -----------------------------------------------------------------------

pub type AttributeValue =
  Json

pub fn blob(value: BitArray) -> AttributeValue {
  let value = bit_array.base64_encode(value, False)
  json.object([#("B", json.string(value))])
}

pub fn blobs(value: List(BitArray)) -> AttributeValue {
  let value = list.map(value, bit_array.base64_encode(_, False))
  json.object([#("BS", json.array(value, json.string))])
}

pub fn bool(value: Bool) -> AttributeValue {
  json.object([#("BOOL", json.bool(value))])
}

pub fn int(value: Int) -> AttributeValue {
  json.object([#("N", json.string(int.to_string(value)))])
}

pub fn ints(value: List(Int)) -> AttributeValue {
  let value = list.map(value, int.to_string)
  json.object([#("NS", json.array(value, json.string))])
}

pub fn float(value: Float) -> AttributeValue {
  json.object([#("N", json.string(float.to_string(value)))])
}

pub fn floats(value: List(Float)) -> AttributeValue {
  let value = list.map(value, float.to_string)
  json.object([#("NS", json.array(value, json.string))])
}

pub fn null(value: Bool) -> AttributeValue {
  json.object([#("NULL", json.bool(value))])
}

pub fn string(value: String) -> AttributeValue {
  json.object([#("S", json.string(value))])
}

pub fn strings(value: List(String)) -> AttributeValue {
  json.object([#("SS", json.array(value, json.string))])
}

pub fn list(
  from entries: List(a),
  of inner_type: fn(a) -> AttributeValue,
) -> AttributeValue {
  json.object([#("L", json.array(entries, inner_type))])
}

pub fn map(av: AttributeValue) -> AttributeValue {
  json.object([#("M", av)])
}

pub fn object(entries: List(#(String, AttributeValue))) -> AttributeValue {
  json.object(entries)
}

// DECODERS -----------------------------------------------------------------------

pub fn decode_blob() -> Decoder(BitArray) {
  let dec = decode.at(["B"], decode.string)
  use string <- decode.then(dec)
  case bit_array.base64_decode(string) {
    Ok(bits) -> decode.into(bits)
    Error(_) -> decode.fail("BitArray")
  }
}

pub fn decode_blobs() -> Decoder(List(BitArray)) {
  let dec = decode.at(["BS"], decode.list(of: decode.string))
  use strings <- decode.then(dec)
  let bits = list.try_map(strings, bit_array.base64_decode)
  case bits {
    Ok(bits) -> decode.into(bits)
    Error(_) -> decode.fail("BitArray")
  }
}

pub fn decode_bool() -> Decoder(Bool) {
  decode.at(["BOOL"], decode.bool)
}

pub fn decode_int() -> Decoder(Int) {
  let dec = decode.at(["N"], decode.string)
  use string <- decode.then(dec)
  let num = int.parse(string)
  case num {
    Ok(num) -> decode.into(num)
    Error(_) -> decode.fail("Int")
  }
}

pub fn decode_ints() -> Decoder(List(Int)) {
  let dec = decode.at(["NS"], decode.list(of: decode.string))
  use strings <- decode.then(dec)
  let nums = list.try_map(strings, int.parse)
  case nums {
    Ok(nums) -> decode.into(nums)
    Error(_) -> decode.fail("Int")
  }
}

pub fn decode_float() -> Decoder(Float) {
  let dec = decode.at(["N"], decode.string)
  use string <- decode.then(dec)
  let num = float.parse(string)
  case num {
    Ok(num) -> decode.into(num)
    Error(_) -> decode.fail("Float")
  }
}

pub fn decode_floats() -> Decoder(List(Float)) {
  let dec = decode.at(["NS"], decode.list(of: decode.string))
  use strings <- decode.then(dec)
  let nums = list.try_map(strings, float.parse)
  case nums {
    Ok(nums) -> decode.into(nums)
    Error(_) -> decode.fail("Float")
  }
}

pub fn decode_null() -> Decoder(Bool) {
  decode.at(["NULL"], decode.bool)
}

pub fn decode_string() -> Decoder(String) {
  decode.at(["S"], decode.string)
}

pub fn decode_strings() -> Decoder(List(String)) {
  decode.at(["SS"], decode.list(of: decode.string))
}

pub fn decode(
  from json: String,
  using decoder: decode.Decoder(t),
) -> Result(t, json.DecodeError) {
  json.decode(json, decode.from(decoder, _))
}

pub fn decode_bits(
  from json: BitArray,
  using decoder: decode.Decoder(t),
) -> Result(t, json.DecodeError) {
  json.decode_bits(json, decode.from(decoder, _))
}
