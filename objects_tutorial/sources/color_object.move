//! Published by address 0x7b92450cdc8de8d032a4310934e34f64b4a16abc82f470514a57f0c25071c575
//! on the devnet, with original package ID
//! 0x74e8bb81b4f74ccb8421610f61a18fba08a5f0fd762679650e780647ab26c04b
//! and `UpgradeCap` ID
//! 0x5f2d7f3014863e27da6fafa9992814d7e0fbeee963ec615c25f08dc95c30f6c7
//!
//! Called the `create` function with the same address used to publish, resulting
//! in the creation of object
//! 0xb393ca07d1b60bf2519f2c4dbe300b2608975feb0e3e56e1232f74abbe785a76
//! representing a `ColorObject`.

module tutorial::color_object {
    // object creates an alias to the object module, which allows you to call
    // functions in the module, such as the `new` function, without fully
    // qualifying, for example `sui::object::new`.
    use sui::object;
    use sui::transfer;
    // tx_context::TxContext creates an alias to the TxContext struct in the tx_context module.
    use sui::tx_context::{Self, TxContext};

    struct ColorObject has key {
        id: object::UID,
        red: u8,
        green: u8,
        blue: u8,
    }

    // This is an entry function that you can call directly by a Transaction.
    public entry fun create(red: u8, green: u8, blue: u8, ctx: &mut TxContext) {
        let color_object = new(red, green, blue, ctx);
        transfer::transfer(color_object, tx_context::sender(ctx))
    }

    public fun get_color(self: &ColorObject): (u8, u8, u8) {
        (self.red, self.green, self.blue)
    }

    fun new(red: u8, green: u8, blue: u8, ctx: &mut TxContext): ColorObject {
        ColorObject {
            id: object::new(ctx),
            red,
            green,
            blue,
        }
    }
}

#[test_only]
module tutorial::color_object_tests {
    use sui::test_scenario;
    use tutorial::color_object::{Self, ColorObject};

    #[test]
    fun test_create() {
        let owner = @0x1;
        // Create a ColorObject and transfer it to @owner.
        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            color_object::create(255, 0, 255, ctx);
        };

        // After the first transaction completes (and only after the first
        //transaction completes), address @0x1 owns the object.
        // First, make sure it's not owned by anyone else:

        let different_address = @0x2;
        test_scenario::next_tx(scenario, different_address);
        {
            assert!(!test_scenario::has_most_recent_for_sender<ColorObject>(scenario), 0);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let object = test_scenario::take_from_sender<ColorObject>(scenario);
            let (red, green, blue) = color_object::get_color(&object);
            assert!(red == 255 && green == 0 && blue == 255, 1);
            test_scenario::return_to_sender(scenario, object);
        };
        test_scenario::end(scenario_val);
    }
}