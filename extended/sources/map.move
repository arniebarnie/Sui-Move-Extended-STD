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
    const EKeysNotUnique: u64 = 4;
//========================================================= OBJECTS ===========================================================//
    /// Holds key and values in separate vectors
    struct Map<K, V> has store, copy, drop {
        keys: vector<K>,
        values: vector<V>,
    }
//========================================================= METHODS ===========================================================//
    /// Returns empty `Map`.
    public fun new<K,V>(): Map<K,V> {
        Map {
            keys: vector[],
            values: vector[]
        }
    }
    /// Returns a `Map` using elements of `keys` and `values` of the same index as key-value pairs.
    /// Aborts with `EVectorLengthNotEqual` if `keys` and `values` are not equal in length.
    /// Aborts with `EKeysNotUnique` if there are duplicate elements present in `keys`.
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
                assert!(i_val != vector::borrow(keys_ref, j), EKeysNotUnique);
                j = j + 1;
            };
            i = i + 1;
        };

        Map {
            keys,
            values
        }
    }
    /// Returns index of `k` in the keys vector of `map`.
    /// Aborts with `EKeyDoesNotExist` if `map` does not have an entry with a key of `k`.
    /// Aborts if `map` is empty.
    public fun idx_of<K,V>(map: & Map<K,V>, k: & K): u64 {
        let length = vector::length(& map.keys) - 1;
        let keys = & map.keys;
        loop {
            if (vector::borrow(keys, length) == k) (return length);
            if (length == 0) break;
            length = length - 1;
        };

        abort EKeyDoesNotExist
    }
    /// Returns index of `k` in the keys vector of `map`, and none if it is not found.
    public fun try_idx_of<K,V>(map: & Map<K,V>, k: & K): Option<u64> {
        let length = vector::length(& map.keys);
        if (length == 0) return option::none();
        length = length - 1;
        let keys = & map.keys;
        loop {
            if (vector::borrow(keys, length) == k) (return option::some(length));
            if (length == 0) break;
            length = length - 1;
        };

        option::none()
    }
    /// Returns true if `k` is associated with a value in `map`, and false otherwise.
    public fun contains<K,V>(map: & Map<K,V>, k: & K): bool {
        let length = vector::length(& map.keys) - 1;
        if (length == 0) (return false);
        let keys = & map.keys;
        loop {
            if (vector::borrow(keys, length) == k) (return true);
            if (length == 0) break;
            length = length - 1;
        };

        false
    }
    /// Adds a key-value pair of `k` and `v` to `map`.
    /// Aborts with `EKeyAlreadyExists` if `map` already has an entry with a key of `k`.
    public fun insert<K,V>(map: &mut Map<K,V>, k: K, v: V) {
        assert!(!contains(map, & k), EKeyAlreadyExists);
        vector::push_back(&mut map.keys, k);
        vector::push_back(&mut map.values, v);
    }
    /// Removes the entry associated with `k` in `map` and returns the value.
    /// Aborts with `EKeyDoesNotExist` if `map` does not have an entry with a key of `k`.
    public fun remove<K,V>(map: &mut Map<K,V>, k: & K): (K, V) {
        let idx = idx_of(map, k);
        (vector::swap_remove(&mut map.keys, idx), vector::swap_remove(&mut map.values, idx))
    }
    /// Removes the last entry in `map`.
    /// Aborts if `map` is empty.
    public fun pop<K,V>(map: &mut Map<K,V>): (K, V) {
        (vector::pop_back(&mut map.keys), vector::pop_back(&mut map.values))
    }
    /// Returns immutable reference to the value associated with `k` in `map`.
    /// Aborts with `EKeyDoesNotExist` if `map` does not have an entry with a key of `k`.
    public fun borrow<K,V>(map: & Map<K,V>, k: & K): & V {
        let idx = idx_of(map, k);
        vector::borrow(& map.values, idx)
    }
    /// Returns immutable reference to the `idx`th element of the values vector in `map`.
    /// Aborts with `std::vector::EINDEX_OUT_OF_BOUNDS` if `idx` is outside the bounds of the values vector.
    public fun borrow_idx<K,V>(map: & Map<K,V>, idx: u64): & V {
        vector::borrow(& map.values, idx)
    }
    /// Returns mutable reference to the value associated with `k` in `map`. 
    /// Aborts with `EKeyDoesNotExist` if `map` does not have an entry with a key of `k`.
    public fun borrow_mut<K,V>(map: &mut Map<K,V>, k: & K): &mut V {
        let idx = idx_of(map, k);
        vector::borrow_mut(&mut map.values, idx)
    }
    /// Returns mutable reference to the `idx`th element of the values vector in `map`.
    /// Aborts with `std::vector::EINDEX_OUT_OF_BOUNDS` if `idx` is outside the bounds of the values vector.
    public fun borrow_mut_idx<K,V>(map: &mut Map<K,V>, idx: u64): &mut V {
        vector::borrow_mut(&mut map.values, idx)
    }
    /// Returns copy of the value associated with `k` in `map`, and none if `k` is not a key in `map`.
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
    /// Returns copy of the `idx`th element of the values vector in `map`, and none if `idx` is out of bounds. 
    public fun get_idx<K,V:copy>(map: & Map<K,V>, idx: u64): Option<V> {
        if (idx < vector::length(& map.values)) option::some(*vector::borrow(& map.values, idx))
        else option::none()
    }
    /// Returns number of key-value pairs in `map`.
    public fun size<K,V>(map: & Map<K,V>): u64 {
        vector::length(& map.keys)
    }
    /// Returns true if `map` has no entries, and false otherwise.
    public fun is_empty<K,V>(map: & Map<K,V>): bool {
        vector::length(& map.keys) == 0
    }
    /// Destroys `map`.
    /// Aborts if `map` still contains entries.
    public fun destroy_empty<K,V>(map: Map<K,V>) {
        let Map {
            keys,
            values
        } = map;
        vector::destroy_empty(keys);
        vector::destroy_empty(values);
    }
    /// Returns immutable reference to the keys and values vectors of `map`.
    public fun into_keys_values<K,V>(map: & Map<K,V>): (& vector<K>, & vector<V>) {
        (& map.keys, & map.values)
    }
    /// Returns immutable reference to the keys vector of `map`.
    public fun keys<K,V>(map: & Map<K,V>): & vector<K> {
        & map.keys
    }
    /// Returns immutable reference to the values vector of `map`.
    public fun values<K,V>(map: & Map<K,V>): & vector<V> {
        & map.values
    }
    /// Destroys `map` and returns its keys and values vectors.
    public fun split<K,V>(map: Map<K,V>): (vector<K>, vector<V>) {
        let Map {
            keys,
            values
        } = map;
        (keys, values)
    }
}

spec 0x0::map {
    spec Map {
        invariant len(keys) == len(values);
        invariant forall i in range(keys), j in range(keys): (keys[i] == keys[j]) ==> (i == j);
    }

    spec from {
        aborts_if len(keys) == len(values) with EVectorLengthNotEqual;
        aborts_if exists i in range(keys), j in range(keys) where i != j: keys[i] == keys[j] with EKeysNotUnique;
        ensures forall idx in range(keys): result.keys[idx] == keys[idx] && result.values[idx] == values[idx];
    }

    spec idx_of {
        aborts_if index_of(map.keys, k) == len(map.keys);
        ensures map.keys[result] == k;
    }

    spec try_idx_of {
        ensures if (index_of(map.keys, k) == len(map.keys)) result == 0x1::option::spec_none()
                else result == 0x1::option::spec_some(index_of(map.keys, k));
    }

    spec contains {
        ensures result == (index_of(map.keys, k) != len(map.keys));
    }

    spec insert {
        aborts_if index_of(map.keys, k) != len(map.keys) with EKeyAlreadyExists;
        ensures (index_of(map.keys, k) != len(map.keys)) && (index_of(map.keys, k) == index_of(map.values, v));
        ensures len(map.keys) == len(old(map.keys)) + 1;
    }

    spec remove {
        aborts_if index_of(map.keys, k) == len(map.keys) with EKeyDoesNotExist;
        ensures (index_of(map.keys, k) == len(map.keys));
        ensures len(map.keys) + 1 == len(old(map).keys);
    }

    spec pop {
        aborts_if len(map.keys) == 0;
    }

    spec borrow {
        aborts_if index_of(map.keys, k) == len(map.keys) with EKeyDoesNotExist;
        ensures result == map.values[index_of(map.keys, k)];
    }

    spec borrow_idx {
        aborts_if idx >= len(map.values);
        ensures result == map.values[idx];
    }

    spec borrow_mut {
        aborts_if index_of(map.keys, k) == len(map.keys) with EKeyDoesNotExist;
        ensures result == map.values[index_of(map.keys, k)];
    }

    spec borrow_mut_idx {
        aborts_if idx >= len(map.values);
        ensures result == map.values[idx];
    }

    spec get {
        ensures if (index_of(map.keys, k) == len(map.keys)) result == 0x1::option::spec_none()
                else result == 0x1::option::spec_some(map.values[index_of(map.keys, k)]);
    }

    spec get_idx {
        ensures if (idx >= len(map.keys)) result == 0x1::option::spec_none()
                else result == 0x1::option::spec_some(map.values[idx]);
    }
}