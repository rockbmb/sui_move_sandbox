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

    /// IMPORTANT
    ///
    /// Although `from_object` is a read-only reference in this transaction, it is
    /// still a mutable object in Sui storage--another transaction could be sent
    /// to mutate the object at the same time.
    /// 
    /// To prevent this, Sui must lock any mutable object used as a
    /// transaction input, even when it's passed as a read-only reference.
    /// 
    /// In addition, only an object's owner can send a transaction that
    /// locks the object.
    public entry fun copy_into(from_object: &ColorObject, into_object: &mut ColorObject) {
        into_object.red = from_object.red;
        into_object.green = from_object.green;
        into_object.blue = from_object.blue;
    }
}

#[test_only]
module tutorial::color_object_tests {
    use sui::test_scenario;
    use tutorial::color_object::{Self, ColorObject};
    use sui::object;
    use sui::tx_context;

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

    #[test]
    fun test_copy_into() {
        let owner = @0x1;
        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        let (id1, id2) = {
            let ctx = test_scenario::ctx(scenario);
            color_object::create(255, 255, 255, ctx);
            let id1 = object::id_from_address(tx_context::last_created_object_id(ctx));
            color_object::create(0, 0, 0, ctx);
            let id2 = object::id_from_address(tx_context::last_created_object_id(ctx));
            (id1, id2)
        };

        test_scenario::next_tx(scenario, owner);
        {
            let obj1 = test_scenario::take_from_sender_by_id<ColorObject>(scenario, id1);
            let obj2 = test_scenario::take_from_sender_by_id<ColorObject>(scenario, id2);
            let (red, green, blue) = color_object::get_color(&obj1);
            assert!(red == 255 && green == 255 && blue == 255, 0);

            color_object::copy_into(&obj2, &mut obj1);
            test_scenario::return_to_sender(scenario, obj1);
            test_scenario::return_to_sender(scenario, obj2);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let obj1 = test_scenario::take_from_sender_by_id<ColorObject>(scenario, id1);
            let (red, green, blue) = color_object::get_color(&obj1);
            assert!(red == 0 && green == 0 && blue == 0, 1);
            // Don't forget to have the below line on objects that don't implement `drop`,
            // or else the following error occurs:
            // >
            // > The local variable 'obj1' still contains a value. The value does
            // > not have the 'drop' ability and must be consumed before the function
            // > returns
            // >
            test_scenario::return_to_sender(scenario, obj1);
        };

        test_scenario::end(scenario_val);
    }
}