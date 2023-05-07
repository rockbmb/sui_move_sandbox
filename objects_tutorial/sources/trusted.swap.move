//! IMPORTANT
//!
//! From Chapter 4:
//! Transactions using only owned objects are faster and less expensive (in
//! terms of gas) than using shared objects, since they do not require consensus in
//! Sui.
//! To swap objects, the same address must own both objects.
//!
//! Anyone who wants to swap their object can send their objects to the **third
//! party**, such as a site that offers swapping services, and the third party helps
//! perform the swap and send the objects to the appropriate owner.
//! 
//! To ensure that you retain custody of your objects (such as coins and NFTs) and
//! not give full custody to the third party, use direct wrapping.

module tutorial::trusted_swap {
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    const MIN_FEE: u64 = 1000;

    struct Object has key, store {
        id: UID,
        scarcity: u8,
        style: u8,
    }

    public entry fun create_object(scarcity: u8, style: u8, ctx: &mut TxContext) {
        let object = Object {
            id: object::new(ctx),
            scarcity,
            style,
        };
        transfer::transfer(object, tx_context::sender(ctx))
    }

    public entry fun transfer_object(object: Object, recipient: address) {
        transfer::transfer(object, recipient)
    }

    struct ObjectWrapper has key {
        id: UID,
        original_owner: address,
        to_swap: Object,
        fee: Balance<SUI>,
    }

    /// From chapter 4:
    /// For coin balances that need to be embedded in another Sui object struct,
    /// use Balance instead because it's not a Sui object type and is much less
    /// expensive to use.
    public entry fun request_swap(
        object: Object,
        fee: Coin<SUI>,
        service_address: address,
        ctx: &mut TxContext
    ) {
        assert!(coin::value(&fee) >= MIN_FEE, 0);
        let wrapper = ObjectWrapper {
            id: object::new(ctx),
            original_owner: tx_context::sender(ctx),
            to_swap: object,
            fee: coin::into_balance(fee),
        };
        transfer::transfer(wrapper, service_address);
    }

    /// Since the contract defined only one way to deal with ObjectWrapper -
    /// `execute_swap` - there is no other way the service operator can interact with
    /// ObjectWrapper despite its ownership.
    public entry fun execute_swap(
        wrapper1: ObjectWrapper,
        wrapper2: ObjectWrapper,
        ctx: &mut TxContext
    ) {
        assert!(wrapper1.to_swap.scarcity == wrapper2.to_swap.scarcity, 1);
        assert!(wrapper1.to_swap.style != wrapper2.to_swap.style, 2);

        let ObjectWrapper {
            id: id1,
            original_owner: original_owner1,
            to_swap: object1,
            fee: fee1,
        } = wrapper1;

        let ObjectWrapper {
            id: id2,
            original_owner: original_owner2,
            to_swap: object2,
            fee: fee2,
        } = wrapper2;

        // Perform the actual swap
        transfer::transfer(object1, original_owner2);
        transfer::transfer(object2, original_owner1);

        // Fee for the service provider
        let service_address = tx_context::sender(ctx);
        balance::join(&mut fee1, fee2);
        transfer::transfer(coin::from_balance(fee1, ctx), service_address);

        // Delete both wrapped objects:
        object::delete(id1);
        object::delete(id2);
    }

}