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
* in the `objects_tutorial` package, the same as above:
  - code from the chapters contained in 3., from 1 through 6 with unit tests, and deployed on the devnet

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