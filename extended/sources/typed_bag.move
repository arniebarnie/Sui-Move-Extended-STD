// SPDX-License-Identifier: MIT

/// A `TypedBag` is similar to a `sui::bag::Bag` but except that all keys are of the same type.
module 0x0::typed_bag {
//======================================================== IMPORTS ============================================================//
    use sui::object::{Self, UID};
    use 0x2::dynamic_field::{Self};
    use 0x2::tx_context::{TxContext};
//======================================================= ERROR CODES =========================================================//
    const EBagNotEmpty: u64 = 1; // Bag is not empty
//========================================================= OBJECTS ===========================================================//
    struct TypedBag<phantom K: store + copy + drop> has key, store {
        id: UID,
        size: u64 // Number of entries held
    }
//========================================================= METHODS ===========================================================//
    /// Returns empty `TypedBag`
    public fun empty<K:store+copy+drop>(ctx: &mut TxContext): TypedBag<K> {
        TypedBag {
            id: object::new(ctx),
            size: 0
        }
    }
    /// Adds a key-value pair of `k` and `value` to `bag`. 
    /// Aborts with `sui::dynamic_field::EFieldAlreadyExists` if `bag` already has an entry with a key of `k`.
    public fun add<K:store+copy+drop,V:store>(bag: &mut TypedBag<K>, k: K, value: V) {
        bag.size = bag.size + 1;
        dynamic_field::add(&mut bag.id, k, value);
    }
    /// Returns immutable reference to the value associated with `k` in `bag`. 
    /// Aborts with `sui::dynamic_field::EFieldDoesNotExist` if `bag` does not have a value with a key of `k`.
    /// Aborts with `sui::dynamic_field::EFieldTypeMismatch` if `bag` has a value associated with `k`, but the value is not of type `V`.
    public fun borrow<K:store+copy+drop,V:store>(bag: & TypedBag<K>, k: K): & V {
        dynamic_field::borrow(& bag.id, k)
    }
    /// Returns mutable reference to the value associated with `k` in `bag`. 
    /// Aborts with `sui::dynamic_field::EFieldDoesNotExist` if `bag` does not have a value with a key of `k`.
    /// Aborts with `sui::dynamic_field::EFieldTypeMismatch` if `bag` has a value associated with `k`, but the value is not of type `V`.
    public fun borrow_mut<K:store+copy+drop,V:store>(bag: &mut TypedBag<K>, k: K): &mut V {
        dynamic_field::borrow_mut(&mut bag.id, k)
    }
    /// Removes the entry associated with `k` in `bag` and returns the value.
    /// Aborts with `sui::dynamic_field::EFieldDoesNotExist` if `bag` does not have a value with a key of `k`.
    /// Aborts with `sui::dynamic_field::EFieldTypeMismatch` if `bag` has a value associated with `k`, but the value is not of type `V`.
    public fun remove<K:store+copy+drop,V:store>(bag: &mut TypedBag<K>, k: K): V {
        bag.size = bag.size - 1;
        dynamic_field::remove(&mut bag.id, k)
    }
    /// Returns true if `k` is associated with a value in `bag`, and false otherwise.
    public fun contains<K:store+copy+drop>(bag: & TypedBag<K>, k: K): bool {
        dynamic_field::exists_(& bag.id, k)
    }
    /// Returns true if `k` is associated with an entry in `bag` with a value of type `V`, and false otherwise.
    public fun contains_with_type<K:store+copy+drop,V:store>(bag: & TypedBag<K>, k: K): bool {
        dynamic_field::exists_with_type<K,V>(& bag.id, k)
    }
    /// Returns the size of `bag`, i.e. the number of key-value pairs.
    public fun length<K:store+copy+drop>(bag: & TypedBag<K>): u64 {
        bag.size
    }
    /// Returns true if `bag` is empty, and false otherwise.
    public fun is_empty<K:store+copy+drop>(bag: & TypedBag<K>): bool {
        bag.size == 0
    }
    /// Destroys `bag`. 
    /// Aborts with `EBagNotEmpty` if `bag` still contains entries.
    public fun destroy_empty<K:store+copy+drop>(bag: TypedBag<K>) {
        let TypedBag {
            id,
            size,
        } = bag;
        assert!(size == 0, EBagNotEmpty);
        object::delete(id);
    }
//========================================================== TESTS ============================================================//
    #[test_only]
    use 0x2::test_scenario;
    #[test_only]
    use 0x2::test_utils;
    #[test]
    fun test_empty() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let bag = empty<u64>(ctx);
            assert!(bag.size == 0, 1);
            test_utils::destroy(bag);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_add() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let bag = empty<u64>(ctx);
            assert!(bag.size == 0, 1);
            add(&mut bag, 10, 10);
            assert!(bag.size == 1, 2);
            assert!(*borrow(& bag, 10) == 10, 3);
            add(&mut bag, 20, 20);
            assert!(bag.size == 2, 4);
            assert!(*borrow(& bag, 20) == 20, 5);
            add(&mut bag, 30, 30);
            assert!(bag.size == 3, 6);
            assert!(*borrow(& bag, 30) == 30, 7);
            test_utils::destroy(bag);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_remove() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let bag = empty<u64>(ctx);
            add(&mut bag, 10, 10);
            add(&mut bag, 20, 20);
            add(&mut bag, 30, 30);
            assert!(length(& bag) == 3, 1);
            assert!(*borrow(& bag, 30) == 30, 2);
            
            assert!(remove(&mut bag, 10) == 10, 3);
            assert!(length(& bag) == 2, 4);
            assert!(!contains(& bag, 10), 5);
            
            assert!(remove(&mut bag, 20) == 20, 6);
            assert!(length(& bag) == 1, 7);
            assert!(!contains(& bag, 20), 8);
            
            assert!(remove(&mut bag, 30) == 30, 9);
            assert!(is_empty(& bag), 10);
            assert!(!contains(& bag, 30), 11);
            
            destroy_empty(bag);
        };
        test_scenario::end(scenario);
    }
}