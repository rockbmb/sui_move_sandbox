module tutorial::simple_warrior {
    use std::option::{Self, Option};

    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct SimpleWarrior has key {
        id: UID,
        sword: Option<Sword>,
        shield: Option<Shield>,
    }

    struct Sword has key, store {
        id: UID,
        strength: u8,
    }

    struct Shield has key, store {
        id: UID,
        armor: u8,
    }

    public entry fun create_warrior(ctx: &mut TxContext) {
        let warrior = SimpleWarrior {
            id: object::new(ctx),
            sword: option::none(),
            shield: option::none(),
        };
        transfer::transfer(warrior, tx_context::sender(ctx))
    }

    public entry fun equip_sword(warrior: &mut SimpleWarrior, sword: Sword, ctx: &mut TxContext) {
        if (option::is_some(&warrior.sword)) {
            // `option::extract` aborts if the option is empty!
            let old_sword = option::extract(&mut warrior.sword);
            transfer::transfer(old_sword, tx_context::sender(ctx));
        };
        // `option::fill` aborts if the `Option` already holds a value!
        option::fill(&mut warrior.sword, sword);
    }

    public entry fun equip_shield(
        warrior: &mut SimpleWarrior,
        shield: Shield,
        ctx: &mut TxContext
    ) {
        if (option::is_some(&warrior.shield)) {
            let old_shield = option::extract(&mut warrior.shield);
            transfer::transfer(old_shield, tx_context::sender(ctx));
        };
        option::fill(&mut warrior.shield, shield);
    }

}