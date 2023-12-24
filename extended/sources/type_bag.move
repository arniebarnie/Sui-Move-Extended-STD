// SPDX-License-Identifier: MIT

/// A `TypeBag` is a `sui::bag::Bag` but where values are keyed by types.
module 0x0::type_bag {
//======================================================== IMPORTS ============================================================//
    use sui::object::{Self, UID};
    use 0x2::dynamic_field::{Self};
    use 0x2::tx_context::{TxContext};
//======================================================= ERROR CODES =========================================================//
    const EBagNotEmpty: u64 = 1; // Bag is not empty
//========================================================= OBJECTS ===========================================================//
    /// Dummy struct to hold type
    struct Key<phantom K> has store, copy, drop { }
    /// Holds key-values in `id`
    struct TypeBag has key, store {
        id: UID,
        size: u64 // Number of entries held
    }
//========================================================= METHODS ===========================================================//
    /// Returns empty `TypeBag`.
    public fun new(ctx: &mut TxContext): TypeBag {
        TypeBag {
            id: object::new(ctx),
            size: 0
        }
    }
    /// Adds a key-value pair of `K` and `value` to `bag`. 
    /// Aborts with `sui::dynamic_field::EFieldAlreadyExists` if `bag` already has an entry with a key of `K`.
    public fun add<K,V:store>(bag: &mut TypeBag, value: V) {
        dynamic_field::add(&mut bag.id, Key<K> { }, value);
        bag.size = bag.size + 1;
    }
    /// Returns immutable reference to the value associated with `K` in `bag`. 
    /// Aborts with `sui::dynamic_field::EFieldDoesNotExist` if `bag` does not have a value with a key of `K`.
    /// Aborts with `sui::dynamic_field::EFieldTypeMismatch` if `bag` has a value associated with `K`, but the value is not of type `V`.
    public fun borrow<K,V:store>(bag: & TypeBag): & V {
        dynamic_field::borrow(& bag.id, Key<K> { })
    }
    /// Returns mutable reference to the value associated with `K` in `bag`. 
    /// Aborts with `sui::dynamic_field::EFieldDoesNotExist` if `bag` does not have a value with a key of `K`.
    /// Aborts with `sui::dynamic_field::EFieldTypeMismatch` if `bag` has a value associated with `K`, but the value is not of type `V`.
    public fun borrow_mut<K,V:store>(bag: &mut TypeBag): &mut V {
        dynamic_field::borrow_mut(&mut bag.id, Key<K> { })
    }
    /// Removes the entry associated with `K` in `bag` and returns the value.
    /// Aborts with `sui::dynamic_field::EFieldDoesNotExist` if `bag` does not have a value with a key of `K`.
    /// Aborts with `sui::dynamic_field::EFieldTypeMismatch` if `bag` has a value associated with `K`, but the value is not of type `V`.
    public fun remove<K,V:store>(bag: &mut TypeBag): V {
        bag.size = bag.size - 1;
        dynamic_field::remove(&mut bag.id, Key<K> { })
    }
    /// Returns true if `K` is associated with a value in `bag`, and false otherwise.
    public fun contains<K>(bag: & TypeBag): bool {
        dynamic_field::exists_(& bag.id, Key<K> { })
    }
    /// Returns true if `K` is associated with an entry in `bag` with a value of type `V`, and false otherwise.
    public fun contains_with_type<K,V:store>(bag: & TypeBag): bool {
        dynamic_field::exists_with_type<Key<K>,V>(& bag.id, Key<K> { })
    }
    /// Returns the size of `bag`, i.e. the number of key-value pairs.
    public fun length(bag: & TypeBag): u64 {
        bag.size
    }
    /// Returns true if `bag` is empty, and false otherwise.
    public fun is_empty(bag: & TypeBag): bool {
        bag.size == 0
    }
    /// Destroys `bag`. 
    /// Aborts with `EBagNotEmpty` if `bag` still contains entries.
    public fun destroy_empty(bag: TypeBag) {
        let TypeBag {
            id,
            size
        } = bag;
        assert!(size == 0, EBagNotEmpty);
        object::delete(id);
    }
}