import aws_request/config
import aws_request/service/dynamodb
import decode.{type Decoder}
import dynamodb/attribute_value.{type AttributeValue}
import gleam/bit_array
import gleam/dynamic.{type Dynamic}
import gleam/http/response.{Response}
import gleam/httpc
import gleam/json.{type DecodeError}
import gleam/option.{None, Some}
import gleam/result

pub opaque type Client {
  Client(inner: dynamodb.Client)
}

pub type Error {
  ServiceError(code: Int, body: BitArray)
  UnexpectedResultType(DecodeError)
  UnknownError(Dynamic)
}

pub fn new(cfg: config.Config) -> Client {
  Client(dynamodb.new(cfg))
}

pub fn execute_statement(
  using client: Client,
  query partiql_statement: String,
  with parameters: List(AttributeValue),
  expecting decoder: Decoder(t),
) -> Result(List(t), Error) {
  let input =
    json.object([
      #("Statement", json.string(partiql_statement)),
      #("Parameters", encode_parameters(parameters)),
    ])
    |> json.to_string
    |> bit_array.from_string

  let res =
    dynamodb.execute_statement(client.inner, input)
    |> httpc.send_bits
    |> result.map_error(UnknownError)

  use response <- result.try(res)
  case response {
    Response(200, _, body) -> {
      let items = decode.at(["Items"], decode.list(decoder))
      attribute_value.decode_bits(body, items)
      |> result.map_error(UnexpectedResultType)
    }
    Response(code, _, body) -> Error(ServiceError(code, body))
  }
}

fn encode_parameters(parameters: List(AttributeValue)) -> AttributeValue {
  let wrapped = case parameters {
    [] -> None
    _ -> Some(parameters)
  }
  json.nullable(wrapped, json.array(_, identity))
}

fn identity(a: t) -> t {
  a
}
