// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/*
IMPORTANT

When calling `entry fun`s that have generic type parameters, it is **necessary**
to instantiate those arguments in the CLI/RPC transaction call!

This is done via the `--type-args <TypeTag>` switch in `sui client call`.

A `TypeTag`, in the case of this module, would be something like

```
<package_id>::<module_name>::<type_identifier>
```

and there would be an instance of each of these for every generic type parameter.
*/

/// An escrow for atomic swap of objects without a trusted third party
module defi::shared_escrow {
    use std::option::{Self, Option};

    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    /// An object held in escrow
    struct EscrowedObj<T: key + store, phantom ExchangeForT: key + store> has key, store {
        id: UID,
        /// creator of the escrowed object - this object is shared, so it has
        /// no owner.
        creator: address,
        /// intended recipient of the escrowed object
        recipient: address,
        /// ID of the object `creator` wants in exchange
        exchange_for: ID,
        /// the escrowed object
        escrowed: Option<T>,
    }

    // Error codes
    /// An attempt to cancel escrow by a different user than the owner
    const EWrongOwner: u64 = 0;
    /// Exchange by a different user than the `recipient` of the escrowed object
    const EWrongRecipient: u64 = 1;
    /// Exchange with a different item than the `exchange_for` field
    const EWrongExchangeObject: u64 = 2;
    /// The escrow has already been exchanged or cancelled
    const EAlreadyExchangedOrCancelled: u64 = 3;

    /// Create an escrow for exchanging goods with a counterparty.
    public entry fun create<T: key + store, ExchangeForT: key + store>(
        recipient: address,
        // Note that the below is an ID, and not a UID.
        // This is because the requested item will not be locked under this escrow,
        // only referenced for cross-checking at the time `swap` is called.
        //
        // Whereas, the `escrowed_item` is passed by UID to relinquish ownership
        // from the transaction's sender, and award it to `EscrowedObj`.
        exchange_for: ID,
        escrowed_item: T,
        ctx: &mut TxContext
    ) {
        let creator = tx_context::sender(ctx);
        let id = object::new(ctx);
        let escrowed = option::some(escrowed_item);
        transfer::public_share_object(
            EscrowedObj<T, ExchangeForT> {
                id, creator, recipient, exchange_for, escrowed
            }
        );
    }

    /// The `recipient` of the escrow can exchange `obj` with the escrowed item
    public entry fun exchange<T: key + store, ExchangeForT: key + store>(
        obj: ExchangeForT,
        escrow: &mut EscrowedObj<T, ExchangeForT>,
        ctx: &TxContext
    ) {
        assert!(option::is_some(&escrow.escrowed), EAlreadyExchangedOrCancelled);
        let escrowed_item = option::extract<T>(&mut escrow.escrowed);
        assert!(&tx_context::sender(ctx) == &escrow.recipient, EWrongRecipient);
        assert!(object::borrow_id(&obj) == &escrow.exchange_for, EWrongExchangeObject);
        // everything matches. do the swap!
        transfer::public_transfer(escrowed_item, tx_context::sender(ctx));
        transfer::public_transfer(obj, escrow.creator);
    }

    /// The `creator` can cancel the escrow and get back the escrowed item.
    ///
    /// Note that this will not delete the escrowing object - it'll remain in
    /// existence, devoid of items, but available for future trades that respect the
    /// types it has already been instantiated with.
    public entry fun cancel<T: key + store, ExchangeForT: key + store>(
        escrow: &mut EscrowedObj<T, ExchangeForT>,
        ctx: &TxContext
    ) {
        assert!(&tx_context::sender(ctx) == &escrow.creator, EWrongOwner);
        assert!(option::is_some(&escrow.escrowed), EAlreadyExchangedOrCancelled);
        transfer::public_transfer(option::extract<T>(&mut escrow.escrowed), escrow.creator);
    }
}