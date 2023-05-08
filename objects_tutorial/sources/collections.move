//! Notes from "Programming with Objects", chapter 6 on collections
//!
//! IMPORTANT:
//!
//! The types and function discussed in this section are built into the Sui
//! framework in modules table and bag.
//! 
//! As with dynamic fields, there is also an object_ variant of both:
// ! `ObjectTable` in `object_table` and `ObjectBag` in `object_bag`.
//! 
//! The relationship between `Table` and `ObjectTable`, and `Bag` and
//! `ObjectBag` are the same as between a field and an object field:
//! * The former can hold any store type as a value, but
//!   - objects stored as values are hidden when viewed from external
//!     storage.
//! * The latter can only store objects as values, but
//!   - keeps those objects visible at their ID in external storage.
//!
//! Additionally, the following functionality is planned, but not currently supported:
//!
//! * sui::bag::contains<K: copy + drop + store>(bag: &Bag, k: K): bool`, which checks
//!   whether a key-value pair exists in `bag` with key `k: K` and a value of any type
//!  (in addition to `contain_with_type` which performs a similar check, but requires
//!  passing a specific value type).
//!
//! Regarding the API:
//!
//! * Like with dynamic fields, it is an error to attempt to overwrite an existing
//!   key, or access or remove a non-existent key.
//! * The extra flexibility of Bag's heterogeneity means the type system doesn't
//!   statically prevent attempts to add a value with one type, and then borrow or
//!   remove it at another type.
//!     - This pattern fails at runtime, similar to the
//!       behavior for dynamic fields.
//!
//! About `drop`ping collections:
//!
//! * You can call the convenience function only for tables where the value type also
//!   has the `drop` ability, which allows it to delete tables whether they are empty or
//!   not.
//! * Note that `drop` is **not** called implicitly on eligible tables before they go out of
//!   scope.
//!   - It must be called explicitly, but it is guaranteed to succeed at runtime.
//! * `Bag` and `ObjectBag` cannot support `drop` because they could be holding a variety of
//!   types, some of which may have `drop` and some which may not.
//! * `ObjectTable` does not support drop because
//!   - its values must be objects, which cannot be `drop`
//!   - this is because:
//!     1. they must contain an `id: UID` field, and
//!     2. `UID` does not have `drop`.
//!
//! About equality
//!
//! The default `==` operator works on identity, careful!

/*

## Tables

module sui::table {
    struct Table<K: copy + drop + store, V: store> has key, store { ... }

    public fun new<K: copy + drop + store, V: store>(
        ctx: &mut TxContext,
    ): Table<K, V>;
    }

* `Table<K, V>` is a homogeneous map, meaning that all its keys have the same type
  as each other (`K`), and all its values have the same type as each other as well
  (`V`).

* It is created with `sui::table::new`, which requires access to a &mut
  `TxContext` because Tables are objects themselves, which can be
  - transferred,
  - shared,
  - wrapped, or
  - unwrapped,
  just like any other object.

`sui::object_table::ObjectTable` is the object-preserving version of `Table`.
*/

/*

## Bags

* `Bag` is a heterogeneous map, so it can hold key-value pairs of arbitrary types
  (they don't need to match each other).

* Note that the `Bag` type does not have any type parameters for this reason. Like
  `Table`, `Bag` is also an object, so creating one with `sui::bag::new` requires
  supplying a `&mut TxContext` to generate an ID.

`sui::bag::ObjectBag` for the object-preserving version of `Bag`.

*/