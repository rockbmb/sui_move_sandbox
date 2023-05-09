# Experiments with [Sui](https://sui.io/) Move

These are notes I've taken while working through the, in my opinion, excellent
documentation for Sui, starting [here](https://docs.sui.io/build/move).

Where needed, there will be notes explaining how to run a particular example
using the [`sui` CLI](https://docs.sui.io/build/cli-client)

## Structure

The notes and example packages were written while using the following sources:

1. The previously linked [series of pages](https://docs.sui.io/build/move) on smart contracts in Sui Move
2. A [series of articles](https://docs.sui.io/build/programming-with-objects) on the Sui documentation on working with Sui Move object
3. The [set of working examples](https://github.com/MystenLabs/sui/tree/main/sui_programmability/examples) showcasing Sui Move packages

In particular:

* the `first_package` package is a walkthrough of the resources in 1., containing
  - some experiments from [working with time in Sui Move](https://docs.sui.io/build/move/time)
  - a walkthrough of ["Write a Sui Move Package"](https://docs.sui.io/build/move/write-package)
  - the material on how to [build and test](https://docs.sui.io/build/move/build-test) Sui Move code
* in the `policy_upgrade_example` folder, live Sui Move packages and NodeJS modules built over the course
  of the Sui Move chapter on [custom package upgrage policies](https://docs.sui.io/build/custom-upgrade-policy)
  - [here](#custom-package-upgrade-policy-for-sui-move-packages) is a detailed description of what it is and does
* in the `objects_tutorial` package, the same as above:
  - code from the chapters contained in 3., from 1 through 6 with unit tests, and deployed on the devnet
* the `defi` package contains a simple example of an escrow, taken from 3.
  - [here](#defi-in-sui-move) are details on how it was tested

## Example of reader's note

Throughout the repository, I left notes that I believe are important highlights of the content
that particular package/module refers to.
They're marked with the word

>
> IMPORTANT
>

to allow easy search via e.g. an editor's `CTRL + SHIFT + F`.

An example note regarding the nature of Sui Move packages as indistinct from objects:

>
> IMPORTANT
>
> 1. Sui smart contracts are represented by immutable package objects consisting of a
>    collection of Move modules.
>
> 2. Because the packages are immutable, transactions can safely access smart contracts
>    without full consensus (fast-path transactions).
>    - If someone could change these packages, they would become **shared** objects, which
>      would require full consensus before completing a transaction.
>
> 3. When you create packages that involve shared objects, you need to think about
>    upgrades and versioning from the start given that all prior versions of a
>    package still exist on-chain.
>    - A useful pattern is to introduce **versioning** to the shared object and using
>      a version check to guard access to functions in the package.
>    - This enables you to limit access to the shared object to only the latest version of
>      a package.
>

# Custom Package Upgrade Policy for Sui Move packages

In `policy_upgrade_example` is a sandbox for the Sui Move documentation
page found [here](https://docs.sui.io/build/custom-upgrade-policy) regarding
custom upgrade policies in Sui Move.

## Components

There are 4 different parts to it:
* the actual upgrade policy, in the `policy` folder; in it is a `sui` package detailing
  a hypothetical package upgrade policy that only permits upgrades when submitted
  on the chosen day of the week
  - said day of the week is gotten via the network's current epoch timestamp
* an example Sui Move package, meant to be upgrade with the above policy. It lives in
  the `example` folder.
* a NodeJS module, `publish.js` to publish a package with a specific upgrade policy and output the
  relevant output data
  - e.g. the ID of the published example's package `UpgradeCap`, and its own package ID
* another NodeJS module, `upgrade.js`, to upgrade the `example` Sui Move package with
  the upgrade policy created through `publish.js`

## Workflow

The details are in [this section](https://docs.sui.io/build/custom-upgrade-policy#example-day-of-the-week-upgrade-policy) of the chapter:

1. First, the Sui Move `policy` package must be built and published via
    ```bash
    sui client publish --gas-budget 100000000
    ```
   - if successful, the command's output with contain the published package's ID, referred to
     with the placeholder `'<POLICY-PACKAGE>'`
2. Optionally, publishing of the package may be tested via
   ```bash
   sui client call --gas-budget 10000000 \
    --package 0x2 \
    --module 'package' \
    --function 'make_immutable' \
    --args '<POLICY-UPGRADE-CAP>'
   ```
  where `<POLICY-UPGRADE-CAP>` is the ID of the package, emitted in step 1.
3. Modify the `publish.js` module with the policy's desired permitted day of the week,
   and then run
   ```
   node publish.js
   ```
   The output of this command, if successful, will contain
   - the `example` package's ID, referred to as `'<EXAMPLE-PACKAGE-ID>'`
   - the `example` package's `UpgradeCap`, referred to in the tutorial with the placeholder `'<EXAMPLE-UPGRADE-CAP>'`
4. Optionally, test the `example::example::nudge` function via
   ```bash
   sui client call --gas-budget 10000000 \
    --package '<EXAMPLE-PACKAGE-ID>' \
    --module 'example' \
    --function 'nudge' \
   ```
5. Use the `upgrade.js` module, with the placeholders correctly filled in with the outputs
   of relevant previous commands, to upgrade the published `example` package, obeying the
   upgrade policy specified through `publish.js`
   ```bash
   node upgrade.js
   ```
   - this command, if successful, will output the ID of the upgraded package, in the tutorial
   known as `'<UPGRADED-EXAMPLE-PACKAGE>'`
6. Optionally, `example::example::nudge`, from the upgraded package, may be tested via
   ```bash
   sui client call --gas-budget 10000000 \
    --package '<UPGRADED-EXAMPLE-PACKAGE>' \
    --module 'example' \
    --function 'nudge'
   ```

# DeFi in Sui Move

Sui Move examples of DeFi concepts.

The examples here were taken from the [`sui`](https://github.com/MystenLabs/sui/tree/main/sui_programmability/examples/defi) repository.

For now, there's an owned escrow in the `escrow.move` module, and test items to be
exchanged in `simple_warrior.move`

## Devnet testing

Assuming
* a devnet environment setup
* two fictional parties, Alice and Bob, wish to trade an item, and mediate that trade via a third party
* the package has already been published
* the `simple_warrior` module, in the `defi` package for this purpose, will be used to create items
  - a `Sword` for Alice, and
  - a `Shield` for Bob
* The shell variables
  - `ALICE`
  - `BOB`
  - `THIRDPARTY`
  - `PACKAGE`
  containing Sui object IDs have been/will be `export`, and are/will be available

run the following instructions

```bash
sui client switch --address "$ALICE"
sui client call \
  --function create_sword \
  --module simple_warrior \
  --package "$PACKAGE" \
  --args 100 \
  --gas-budget 10000000
# place the created sword's address in $SWORD

sui client switch --address "$BOB"
sui client call \
  --function create_shield \
  --module simple_warrior \
  --package "$PACKAGE" \
  --args 100 \
  --gas-budget 10000000
# same for the shield, in $SHIELD

sui client switch --address "$ALICE"
sui client call \
  --function create \
  --module escrow \
  --package "$PACKAGE" \
  --args "$BOB" "$THIRDPARTY" "$SWORD" "$SHIELD" \
  --type-args "$PACKAGE::simple_warrior::Sword" "$PACKAGE::simple_warrior::Shield" \
  --gas-budget 10000000
# let the escrow object above be exported as `SWORD_ESCROW`

sui client switch --address "$BOB"
sui client call \
  --function create \
  --module escrow \
  --package "$PACKAGE" \
  --args "$ALICE" "$THIRDPARTY" "$SHIELD" "$SWORD" \
  --type-args "$PACKAGE::simple_warrior::Shield" "$PACKAGE::simple_warrior::Sword" \
  --gas-budget 10000000
# let the escrow object above be exported as `SHIELD_ESCROW`

sui client switch --address "$THIRDPARTY"
sui client call --package $PACKAGE --module escrow --function swap --args $SWORD_ESCROW $SHIELD_ESCROW --gas-budget 10000000 --type-args "$PACKAGE::simple_warrior::Sword" "$PACKAGE::simple_warrior::Shield"
```