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