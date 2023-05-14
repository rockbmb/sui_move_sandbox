// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module defi::paid_shared_escrow_tests {
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::sui::SUI;
    use sui::test_scenario::{Self, Scenario};
    use sui::transfer;

    use defi::paid_shared_escrow::{Self, EscrowedObj};

    const ALICE_ADDRESS: address = @0xACE;
    const BOB_ADDRESS: address = @0xACEB;
    const THIRD_PARTY_ADDRESS: address = @0xFACE;
    const RANDOM_ADDRESS: address = @123;

    const EXCHANGE_FEE: u64 = 100_000;
    const CANCEL_FEE: u64 = 10_000;

    // Error codes.
    const ESwapTransferFailed: u64 = 0;
    const EReturnTransferFailed: u64 = 0;

    // Example of an object type used for exchange
    struct ItemA has key, store {
        id: UID
    }

    // Example of the other object type used for exchange
    struct ItemB has key, store {
        id: UID
    }

    #[test]
    fun test_escrow_flow() {
        // Alice creates the escrow
        let (scenario_val, item_b) = create_escrow(ALICE_ADDRESS, BOB_ADDRESS);

        // Bob exchanges item B for the escrowed item A
        let scenario = &mut scenario_val;
        fund_account(scenario, BOB_ADDRESS, EXCHANGE_FEE);
        exchange(&mut scenario_val, BOB_ADDRESS, item_b);

        // Alice now owns item B, and Bob now owns item A
        assert!(owns_object<ItemB>(ALICE_ADDRESS), ESwapTransferFailed);
        assert!(owns_object<ItemA>(BOB_ADDRESS), ESwapTransferFailed);

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_cancel() {
        // Alice creates the escrow
        let (scenario_val, ItemB { id }) = create_escrow(ALICE_ADDRESS, BOB_ADDRESS);
        object::delete(id);
        let scenario = &mut scenario_val;
        // Alice does not own item A
        assert!(!owns_object<ItemA>(ALICE_ADDRESS), EReturnTransferFailed);

        // Alice cancels the escrow
        cancel(scenario, ALICE_ADDRESS);

        // Alice now owns item A
        assert!(owns_object<ItemA>(ALICE_ADDRESS), EReturnTransferFailed);

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = paid_shared_escrow::EWrongOwner)]
    fun test_cancel_with_wrong_owner() {
        // Alice creates the escrow
        let (scenario_val, ItemB { id }) = create_escrow(ALICE_ADDRESS, BOB_ADDRESS);
        object::delete(id);
        let scenario = &mut scenario_val;

        // Bob tries to cancel the escrow that Alice owns and expects failure
        cancel(scenario, BOB_ADDRESS);

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = paid_shared_escrow::EWrongExchangeObject)]
    fun test_swap_wrong_objects() {
        // Alice creates the escrow in exchange for item b
        let (scenario_val, ItemB { id }) = create_escrow(ALICE_ADDRESS, BOB_ADDRESS);
        object::delete(id);
        let scenario = &mut scenario_val;

        // Bob tries to exchange item C for the escrowed item A and expects failure
        fund_account(scenario, BOB_ADDRESS, EXCHANGE_FEE);
        test_scenario::next_tx(scenario, BOB_ADDRESS);
        let ctx = test_scenario::ctx(scenario);
        let item_c = ItemB { id: object::new(ctx) };
        exchange(scenario, BOB_ADDRESS, item_c);

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = paid_shared_escrow::EWrongRecipient)]
    fun test_swap_wrong_recipient() {
         // Alice creates the escrow in exchange for item b
        let (scenario_val, item_b) = create_escrow(ALICE_ADDRESS, BOB_ADDRESS);
        let scenario = &mut scenario_val;

        fund_account(scenario, RANDOM_ADDRESS, EXCHANGE_FEE);
        // Random address tries to exchange item B for the escrowed item A and expects failure
        exchange(scenario, RANDOM_ADDRESS, item_b);

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = paid_shared_escrow::EExchangeFeeTooLow)]
    fun test_swap_low_fee() {
         // Alice creates the escrow in exchange for item b
        let (scenario_val, item_b) = create_escrow(ALICE_ADDRESS, BOB_ADDRESS);
        let scenario = &mut scenario_val;

        fund_account(scenario, BOB_ADDRESS, EXCHANGE_FEE - 1);
        // Bob attempts to use the escrow without paying the full usage fee
        // set by its creator.
        exchange(scenario, BOB_ADDRESS, item_b);

        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = paid_shared_escrow::EAlreadyExchangedOrCancelled)]
    fun test_cancel_twice() {
        // Alice creates the escrow
        let (scenario_val, ItemB { id }) = create_escrow(ALICE_ADDRESS, BOB_ADDRESS);
        object::delete(id);
        let scenario = &mut scenario_val;
        // Alice does not own item A
        assert!(!owns_object<ItemA>(ALICE_ADDRESS), EReturnTransferFailed);

        // Alice cancels the escrow
        cancel(scenario, ALICE_ADDRESS);

        // Alice now owns item A
        assert!(owns_object<ItemA>(ALICE_ADDRESS), EReturnTransferFailed);

        // Alice tries to cancel the escrow again
        cancel(scenario, ALICE_ADDRESS);

        test_scenario::end(scenario_val);
    }

    fun cancel(scenario: &mut Scenario, initiator: address) {
        test_scenario::next_tx(scenario, initiator);
        {
            let escrow_val = test_scenario::take_shared<EscrowedObj<ItemA, ItemB>>(scenario);
            let escrow = &mut escrow_val;
            let ctx = test_scenario::ctx(scenario);
            paid_shared_escrow::cancel(escrow, ctx);
            test_scenario::return_shared(escrow_val);
        };
        test_scenario::next_tx(scenario, initiator);
    }


    fun exchange(scenario: &mut Scenario, bob: address, item_b: ItemB) {
        test_scenario::next_tx(scenario, bob);
        {
            let escrow_val = test_scenario::take_shared<EscrowedObj<ItemA, ItemB>>(scenario);
            let escrow = &mut escrow_val;
            let coin = test_scenario::take_from_sender<Coin<SUI>>(scenario);
            let ctx = test_scenario::ctx(scenario);
            paid_shared_escrow::exchange(item_b, escrow, coin, ctx);
            test_scenario::return_shared(escrow_val);
        };
        test_scenario::next_tx(scenario, bob);
    }

    fun create_escrow(
        alice: address,
        bob: address,
    ): (Scenario, ItemB) {
        let new_scenario = test_scenario::begin(alice);
        let scenario = &mut new_scenario;
        let ctx = test_scenario::ctx(scenario);
        let item_a_versioned_id = object::new(ctx);

        test_scenario::next_tx(scenario, bob);
        let ctx = test_scenario::ctx(scenario);
        let item_b = ItemB { id: object::new(ctx) };
        let item_b_id = object::id(&item_b);

        // Alice creates the escrow
        test_scenario::next_tx(scenario, alice);
        {
            let ctx = test_scenario::ctx(scenario);
            let escrowed = ItemA {
                id: item_a_versioned_id
            };
            paid_shared_escrow::create<ItemA, ItemB>(
                bob,
                item_b_id,
                escrowed,
                ctx
            );
        };
        test_scenario::next_tx(scenario, alice);
        (new_scenario, item_b)
    }

    fun fund_account(scenario: &mut Scenario, acc: address, amount: u64) {
        let ctx = test_scenario::ctx(scenario);
        let coin = coin::mint_for_testing<SUI>(amount, ctx);
        transfer::public_transfer(coin, acc)
    }

    fun owns_object<T: key + store>(owner: address): bool {
        test_scenario::has_most_recent_for_address<T>(owner)
    }
}