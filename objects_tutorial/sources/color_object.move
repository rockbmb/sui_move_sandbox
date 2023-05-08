//! Devnet test notes:
//! Published by address 0x7b92450cdc8de8d032a4310934e34f64b4a16abc82f470514a57f0c25071c575
//! with original package ID
//! 0x74e8bb81b4f74ccb8421610f61a18fba08a5f0fd762679650e780647ab26c04b,
//! second package ID
//! 0x22bc110203426930b25e7d8e1439409c4bd4325295ef6b2d4f141f8f75e4f4da,
//! and `UpgradeCap` ID
//! 0x5f2d7f3014863e27da6fafa9992814d7e0fbeee963ec615c25f08dc95c30f6c7
//!
//! Called the `create` function with the same address used to publish, resulting
//! in the creation of object
//! 0xb393ca07d1b60bf2519f2c4dbe300b2608975feb0e3e56e1232f74abbe785a76
//! representing a `ColorObject`.
//! To test `transfer`, this `ColorObject` was transferred from
//! 0x7b92450cdc8de8d032a4310934e34f64b4a16abc82f470514a57f0c25071c575
//! to
//! 0xea7f77bb384d3bb1d3b1b1460a4f76dea6aeb8aae91efff717247200b075bfe9
//! , and then to test `delete`, the `ColorObject` was removed from
//! global storage.
//!
//! Second created `ColorObject`'s id, for further testing:
//! 0xa1756edd700d4fb82af92a0f58230b0753151627f0398aaa606d5cdc50455224

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

    /// IMPORTANT
    ///
    /// Since every Sui object struct type **must** include UID as its first field,
    /// and the UID struct does not have the drop ability, the Sui object struct
    /// type **cannot** have the drop ability either!
    ///
    /// Hence, any Sui object cannot be arbitrarily dropped and must be either
    /// consumed (for example, transferred to another owner) or deleted by
    /// unpacking, as described in the following sections.
    /// There are two ways to handle a pass-by-value Sui object in Move:
    ///
    /// 1. delete the object
    /// 2. transfer the object
    public fun delete(object: ColorObject) {
        let ColorObject { id, red: _, green: _, blue: _ } = object;
        object::delete(id);
    }

    /// The owner of the object might want to transfer it to another address, instead of
    /// having to delete it.
    /// To support this, the `ColorObject` module needs to define a transfer function:
    public entry fun transfer(object: ColorObject, recipient: address) {
        transfer::transfer(object, recipient)
    }

    /// The below
    /// ```move
    /// public native fun freeze_object<T: key>(obj: T);
    /// ```
    /// from the `sui::tranfer` module function irreversibly turns an object
    /// immutable.
    public entry fun freeze_object(object: ColorObject) {
        transfer::freeze_object(object)
    }

    /// Create an a priori immutable `ColorObject`
    public entry fun create_immutable(red: u8, green: u8, blue: u8, ctx: &mut TxContext) {
        let color_object = new(red, green, blue, ctx);
        transfer::freeze_object(color_object)
    }

    public entry fun update(
        object: &mut ColorObject,
        red: u8, green: u8, blue: u8,
    ) {
        object.red = red;
        object.green = green;
        object.blue = blue;
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

    #[test]
    fun test_delete() {
        let owner = @0x1;
        // Create a ColorObject and transfer it to @owner.
        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        let id = {
            let ctx = test_scenario::ctx(scenario);
            color_object::create(255, 0, 255, ctx);
            let id = object::id_from_address(tx_context::last_created_object_id(ctx));
            id
        };

        // Delete the ColorObject just created.
        test_scenario::next_tx(scenario, owner);
        {
            let object = test_scenario::take_from_sender_by_id<ColorObject>(scenario, id);
            let (red, green, blue) = color_object::get_color(&object);
            assert!(red == 255 && green == 0 && blue == 255, 0);

            color_object::delete(object);
        };

        // Verify that the object was indeed deleted.
        test_scenario::next_tx(scenario, owner);
        {
            assert!(!test_scenario::has_most_recent_for_sender<ColorObject>(scenario), 1);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_transfer() {
        let first_owner = @0x1;
        // Create a ColorObject and transfer it to @first_owner.
        let scenario_val = test_scenario::begin(first_owner);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            color_object::create(255, 0, 255, ctx);
        };


        let second_owner = @0x2;
        // Check that the future owner does not yet have ownership
        test_scenario::next_tx(scenario, second_owner);
        {
            assert!(!test_scenario::has_most_recent_for_sender<ColorObject>(scenario), 0);
        };

        // Transfer the object
        test_scenario::next_tx(scenario, first_owner);
        {
            let object = test_scenario::take_from_sender<ColorObject>(scenario);
            let (red, green, blue) = color_object::get_color(&object);
            assert!(red == 255 && green == 0 && blue == 255, 1);

            //
            color_object::transfer(object, second_owner);
        };

        // Check that the new owner is, in fact, in possession of the object
        test_scenario::next_tx(scenario, second_owner);
        {
            assert!(test_scenario::has_most_recent_for_sender<ColorObject>(scenario), 2);
            let object = test_scenario::take_from_sender<ColorObject>(scenario);
            let (red, green, blue) = color_object::get_color(&object);
            assert!(red == 255 && green == 0 && blue == 255, 3);
            test_scenario::return_to_sender(scenario, object);
        };

        // Check that the past owner no longer has ownership
        test_scenario::next_tx(scenario, first_owner);
        {
            assert!(!test_scenario::has_most_recent_for_sender<ColorObject>(scenario), 4);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_immutable() {
        let sender1 = @0x1;
        let scenario_val = test_scenario::begin(sender1);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            color_object::create_immutable(255, 0, 255, ctx);
        };

        test_scenario::next_tx(scenario, sender1);
        {
            // take_owned does not work for immutable objects.
            assert!(!test_scenario::has_most_recent_for_sender<ColorObject>(scenario), 0);
        };

        // Any sender works, since the object is immutable.
        let sender2 = @0x2;
        test_scenario::next_tx(scenario, sender2);
        {
            let object = test_scenario::take_immutable<ColorObject>(scenario);
            let (red, green, blue) = color_object::get_color(&object);
            assert!(red == 255 && green == 0 && blue == 255, 0);
            test_scenario::return_immutable(object);
        };

        test_scenario::next_tx(scenario, sender2);
        {
            let object = test_scenario::take_immutable<ColorObject>(scenario);
            let (red, green, blue) = color_object::get_color(&object);
            assert!(red == 255 && green == 0 && blue == 255, 0);
            // Uncommenting the below will result in a failed transaction,
            // because there would be an attempt to modify an immutable object
            //color_object::update(&mut object, 0, 0, 0);
            test_scenario::return_immutable(object);
        };

        test_scenario::end(scenario_val);
    }
}