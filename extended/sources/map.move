// SPDX-License-Identifier: MIT

/// This module is a different implementation of a vector-based map from `sui::vec_map` that allows for easier iteration and
/// copying of keys and values.
module 0x0::map {
//======================================================== IMPORTS ============================================================//
    use 0x1::vector::{Self};
    use 0x1::option::{Self, Option};
//======================================================= ERROR CODES =========================================================//
    const EKeyAlreadyExists: u64 = 1;
    const EKeyDoesNotExist: u64 = 2;
    const EVectorLengthNotEqual: u64 = 3;
    const EKeyIsNotUnique: u64 = 4;
//========================================================= OBJECTS ===========================================================//
    struct Map<K, V> has store, copy, drop {
        keys: vector<K>,
        values: vector<V>,
    }
//========================================================= METHODS ===========================================================//

    public fun new<K,V>(): Map<K,V> {
        Map {
            keys: vector[],
            values: vector[]
        }
    }

    public fun from<K,V>(keys: vector<K>, values: vector<V>): Map<K,V> {
        let keys_ref = & keys;
        let length = vector::length(keys_ref);
        assert!(length == vector::length(& values), EVectorLengthNotEqual);

        let i = 0;
        let j: u64;
        while (i < length) {
            let i_val = vector::borrow(keys_ref, i);
            j = i + 1;
            while (j < length) {
                assert!(i_val != vector::borrow(keys_ref, j), EKeyIsNotUnique);
                j = j + 1;
            };
            i = i + 1;
        };

        Map {
            keys,
            values
        }
    }

    public fun index_of<K,V>(map: & Map<K,V>, k: & K): u64 {
        let i = 0;
        let length = vector::length(& map.keys);
        let keys = & map.keys;
        while (i < length) {
            if (vector::borrow(keys, i) == k) (return i);
            i = i + 1;
        };

        abort EKeyDoesNotExist
    }

    public fun try_index_of<K,V>(map: & Map<K,V>, k: & K): Option<u64> {
        let i = 0;
        let length = vector::length(& map.keys);
        let keys = & map.keys;
        while (i < length) {
            if (vector::borrow(keys, i) == k) (return option::some(i));
            i = i + 1;
        };

        option::none()
    }

    public fun contains<K,V>(map: & Map<K,V>, k: & K): bool {
        let i = 0;
        let length = vector::length(& map.keys);
        let keys = & map.keys;
        while (i < length) {
            if (vector::borrow(keys, i) == k) (return true);
            i = i + 1;
        };

        false
    }

    public fun insert<K,V>(map: &mut Map<K,V>, k: K, v: V) {
        assert!(!contains(map, & k), EKeyAlreadyExists);
        vector::push_back(&mut map.keys, k);
        vector::push_back(&mut map.values, v);
    }

    public fun remove<K,V>(map: &mut Map<K,V>, k: & K): (K, V) {
        let idx = index_of(map, k);
        (vector::swap_remove(&mut map.keys, idx), vector::swap_remove(&mut map.values, idx))
    }

    public fun pop<K,V>(map: &mut Map<K,V>): (K, V) {
        (vector::pop_back(&mut map.keys), vector::pop_back(&mut map.values))
    }

    public fun borrow<K,V>(map: & Map<K,V>, k: & K): & V {
        let idx = index_of(map, k);
        vector::borrow(& map.values, idx)
    }

    public fun borrow_idx<K,V>(map: & Map<K,V>, idx: u64): & V {
        vector::borrow(& map.values, idx)
    }

    public fun borrow_mut<K,V>(map: &mut Map<K,V>, k: & K): &mut V {
        let idx = index_of(map, k);
        vector::borrow_mut(&mut map.values, idx)
    }

    public fun borrow_mut_idx<K,V>(map: &mut Map<K,V>, idx: u64): &mut V {
        vector::borrow_mut(&mut map.values, idx)
    }

    public fun get<K,V:copy>(map: & Map<K,V>, k: & K): Option<V> {
        let i = 0;
        let length = vector::length(& map.keys);
        let keys = & map.keys;
        while (i < length) {
            if (vector::borrow(keys, i) == k) (return option::some(*vector::borrow(& map.values, i)));
            i = i + 1;
        };

        option::none()
    }

    public fun get_idx<K,V:copy>(map: & Map<K,V>, idx: u64): Option<V> {
        if (idx < vector::length(& map.keys)) option::some(*vector::borrow(& map.values, idx))
        else option::none()
    }

    public fun size<K,V>(map: & Map<K,V>): u64 {
        vector::length(& map.keys)
    }

    public fun is_empty<K,V>(map: & Map<K,V>): bool {
        vector::length(& map.keys) == 0
    }

    public fun destroy_empty<K,V>(map: Map<K,V>) {
        let Map {
            keys,
            values
        } = map;
        vector::destroy_empty(keys);
        vector::destroy_empty(values);
    }

    public fun into_keys_values<K,V>(map: & Map<K,V>): (& vector<K>, & vector<V>) {
        (& map.keys, & map.values)
    }

    public fun keys<K,V>(map: & Map<K,V>): & vector<K> {
        & map.keys
    }

    public fun values<K,V>(map: & Map<K,V>): & vector<V> {
        & map.values
    }

    public fun split<K,V>(map: Map<K,V>): (vector<K>, vector<V>) {
        let Map {
            keys,
            values
        } = map;
        (keys, values)
    }
}