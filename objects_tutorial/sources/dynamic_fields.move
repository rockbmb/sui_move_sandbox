//! About dynamic fields and object fields (they're different things!):
//!
//! * It is an error to overwrite a field (attempt to add a field with the same Name
//!   type and value as one that is already defined), and a transaction that does this
//!   will fail.
//!
//! * Fields can be modified in-place by borrowing them mutably and can be overwritten
//!   safely (such as to change its value type) by removing the old value first.
//!
//! IMPORTANT
//! * A transaction that attempts to borrow a field that does not exist will fail.
//! * The `Value` type passed to `borrow` and `borrow_mut` from sui::dynamic_object and
//!   sui::dynamic_object_field must match the type of the stored field, or the
//!   transaction will abort.
//! * Dynamic object field values must be accessed through the provided APIs.
//!   - A transaction that attempts to use those objects as inputs (by value or by
//!     reference), will be rejected for having invalid inputs.
//! * Similar to borrowing a field, a transaction that attempts to remove a
//!   non-existent field, or a field with a different `Value` type, fails.
//! * It is **possible** to delete an object that has dynamic fields still defined on it.
//!   - Because field values can be accessed only via the dynamic field's associated
//!     object and field name, deleting an object that has dynamic fields still defined
//!     on it renders them all inaccessible to future transactions.
//!   - This is true **regardless** of whether the field's value has the drop ability.
//! * Deleting an object that has dynamic fields still defined on it is permitted, but
//!   it will render all its fields **inaccessible**.

module tutorial::dynamic_fields {
    use sui::object::{Self, UID};
    use sui::dynamic_object_field as ofield;
    use sui::transfer;
    use sui::tx_context;
    use sui::tx_context::TxContext;

    struct Parent has key {
        id: UID,
    }

    struct Child has key, store {
        id: UID,
        count: u64,
    }

    /// Add a `Child` as a dynamic field of a `Parent`.
    /// This call results in the following ownership relationship:
    ///
    /// 1. Sender address (still) owns the Parent object.
    /// 2. The Parent object owns the Child object, and can refer to it by the name b"child".
    ///
    /// Note how the `Child` was passed by value.
    public entry fun add_child(parent: &mut Parent, child: Child) {
        ofield::add(&mut parent.id, b"child", child);
    }

    /// This function accepts a mutable reference to the Child object directly, and
    /// can be called with Child objects that haven't been added as fields to Parent
    /// objects.
    public entry fun mutate_child(child: &mut Child) {
        child.count = child.count + 1;
    }

    /// This function accepts a mutable reference to the Parent object and accesses
    /// its dynamic field using borrow_mut, to pass to mutate_child.
    ///
    /// This can only be called on Parent objects that have a b"child" field
    /// defined.
    ///
    /// IMPORTANT
    ///
    /// A Child object that has been added to a Parent must be accessed via its
    /// dynamic field, so it can only by mutated using mutate_child_via_parent, not
    /// mutate_child, even if its ID is known.
    public entry fun mutate_child_via_parent(parent: &mut Parent) {
        // Note how `mutate_child` takes a `&mut Child`, which is the result of
        // `ofield::borrow_mut<vector<u8>, Child>`.
        mutate_child(ofield::borrow_mut<vector<u8>, Child>(
            &mut parent.id,
            b"child",
        ));
    }

    public entry fun delete_child(parent: &mut Parent) {
        let Child { id, count: _ } = ofield::remove<vector<u8>, Child>(
            &mut parent.id,
            b"child",
        );

        object::delete(id);
    }

    /// Same as above, but instead of deleting the `Child`, it is remanded
    /// to the custody of the emitter of the `delete_child` transaction.
    public entry fun reclaim_child(parent: &mut Parent, ctx: &mut TxContext) {
        let child = ofield::remove<vector<u8>, Child>(
            &mut parent.id,
            b"child",
        );

        transfer::transfer(child, tx_context::sender(ctx));
    }
}