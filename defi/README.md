# DeFi in Sui Move

Sui Move examples of DeFi tools.
Taken from the [`sui`](https://github.com/MystenLabs/sui/tree/main/sui_programmability/examples/defi) repository.

## How the escrow was tested

Assuming
* a devnet environment setup
* a trade between Alice, Bob, and a third party
* the package has already been published
* the `simple_warrior` module has been used to create items, a `Sword` for Alice and a `Shield` for Bob
* The shell variables
  - `ALICE`
  - `BOB`
  - `THIRDPARTY`
  - `PACKAGE`
  - `SWORD`
  - `SHIELD`
  have been `export`ed, and are available

run the following instructions (WIP)

```bash
sui client switch --address "$ALICE"
sui client call --function create_sword --module simple_warrior --package "$PACKAGE" --args 100 --gas-budget 10000000

sui client switch --address "$BOB"
sui client call --function create_shield --module simple_warrior --package "$PACKAGE" --args 100 --gas-budget 10000000

sui client switch --address "$ALICE"
sui client call --function create --module escrow --package "$PACKAGE" --args "$BOB" "$THIRDPARTY" "$SHIELD" "$SWORD" --gas-budget 10000000

sui client switch --address "$BOB"
sui client call --function create --module escrow --package "$PACKAGE" --args "$BOB" "$THIRDPARTY" "$SWORD" "$SHIELD" --gas-budget 10000000

sui client switch --address "$THIRDPARTY"
...

```