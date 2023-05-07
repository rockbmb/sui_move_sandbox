# Custom Upgrade Policy test for Sui Move packages

This section of the repository is a sandbox for the Sui Move documentation
page found [here](https://docs.sui.io/build/custom-upgrade-policy) regarding
custom upgrade policies in Sui Move.

## Components

There's a 4 different parts to it:
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