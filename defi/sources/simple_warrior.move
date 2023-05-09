module defi::simple_warrior {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct Sword has key, store {
        id: UID,
        strength: u8,
    }

    struct Shield has key, store {
        id: UID,
        armor: u8,
    }

    public entry fun create_sword(strength: u8, ctx: &mut TxContext) {
        let sword = Sword {
            id: object::new(ctx),
            strength
        };
        transfer::transfer(sword, tx_context::sender(ctx))
    }

    public fun sword_id(sw: &Sword): &UID {
        &sw.id
    }

    public entry fun create_shield(armor: u8, ctx: &mut TxContext) {
        let shield = Shield {
            id: object::new(ctx),
            armor
        };
        transfer::transfer(shield, tx_context::sender(ctx))
    }

}