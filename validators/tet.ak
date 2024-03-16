use aiken/dict
use aiken/list
use aiken/transaction.{
  Input, Mint, OutputReference, ScriptContext, Transaction, TransactionId,
}
use aiken/transaction/value.{Value}

type PolicyId =
  ByteArray

type Action {
  BurnAction
  MintAction
}

const tx_hash: ByteArray =
  #"fb02ffb3caec9d23b13229d50b810e1e71f01d80e5ddedab85ebbf39862b0386"

const output_index: Int = 0

const token_name: ByteArray = "TET"

const token_amount: Int = 1_000_000_000_000

validator {
  fn mint(action: Action, ctx: ScriptContext) {
    let ScriptContext { purpose, transaction } = ctx
    let Transaction { mint, inputs, .. } = transaction

    when purpose is {
      Mint(this_policy_id) ->
        when action is {
          BurnAction ->
            can_burn(
              minted_value: value.from_minted_value(mint),
              this_policy_id: this_policy_id,
            )

          MintAction ->
            can_mint(
              minted_value: value.from_minted_value(mint),
              inputs: inputs,
              this_policy_id: this_policy_id,
            )
        }
      _ -> False
    }
  }
}

fn can_burn(minted_value: Value, this_policy_id: PolicyId) -> Bool {
  expect [(name, amount)] =
    minted_value
      |> value.tokens(this_policy_id)
      |> dict.to_list()

  expect name == token_name && amount < 0

  True
}

fn can_mint(
  minted_value: Value,
  inputs: List<Input>,
  this_policy_id: PolicyId,
) -> Bool {
  expect Some(_input) =
    list.find(
      inputs,
      fn(input) {
        input.output_reference.transaction_id.hash == tx_hash && input.output_reference.output_index == output_index
      },
    )

  expect
    value.add(value.zero(), this_policy_id, token_name, token_amount) == minted_value
  True
}
