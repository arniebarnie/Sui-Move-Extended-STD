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
    spec Map {
        invariant len(keys) == len(values);
        invariant forall i in range(keys), j in range(keys): (keys[i] == keys[j]) ==> (i == j);
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
    spec from {
        ensures forall idx in range(keys): result.keys[idx] == keys[idx] && result.values[idx] == values[idx];
    }
    /// Returns index of `k` in the keys vector of `map`.
    /// Aborts with `EKeyDoesNotExist` if `map` does not have an entry with a key of `k`.
    public fun idx_of<K,V>(map: & Map<K,V>, k: & K): u64 {
        let i = 0;
        let length = vector::length(& map.keys);
        let keys = & map.keys;
        while (i < length) {
            if (vector::borrow(keys, i) == k) (return i);
            i = i + 1;
        };

        abort EKeyDoesNotExist
    }
    spec idx_of {
        aborts_if index_of(map.keys, k) == len(map.keys);
        ensures map.keys[result] == k;
    }
    /// Returns index of `k` in the keys vector of `map`, and none if it is not found.
    public fun try_idx_of<K,V>(map: & Map<K,V>, k: & K): Option<u64> {
        let i = 0;
        let length = vector::length(& map.keys);
        let keys = & map.keys;
        while (i < length) {
            if (vector::borrow(keys, i) == k) (return option::some(i));
            i = i + 1;
        };

        option::none()
    }
    spec try_idx_of {
        ensures if (index_of(map.keys, k) != len(map.keys)) result == 0x1::option::some(index_of(map.keys, k))
                else result == 0x1::option::none();
    }
    /// Returns true if `k` is associated with a value in `map`, and false otherwise.
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
    spec contains {
        ensures result == (index_of(map.keys, k) != len(map.keys));
    }
    /// Adds a key-value pair of `k` and `v` to `map`.
    /// Aborts with `EKeyAlreadyExists` if `map` already has an entry with a key of `k`.
    public fun insert<K,V>(map: &mut Map<K,V>, k: K, v: V) {
        assert!(!contains(map, & k), EKeyAlreadyExists);
        vector::push_back(&mut map.keys, k);
        vector::push_back(&mut map.values, v);
    }
    spec insert {
        ensures (index_of(map.keys, k) != len(map.keys)) && (index_of(map.keys, k) == index_of(map.values, v));
        ensures len(map.keys) == len(old(map.keys)) + 1;
    }
    /// Removes the entry associated with `k` in `map` and returns the value.
    /// Aborts with `EKeyDoesNotExist` if `map` does not have an entry with a key of `k`.
    public fun remove<K,V>(map: &mut Map<K,V>, k: & K): (K, V) {
        let idx = idx_of(map, k);
        (vector::swap_remove(&mut map.keys, idx), vector::swap_remove(&mut map.values, idx))
    }
    spec remove {
        let old_map = old(map);
        ensures (index_of(old_map.keys, k) != len(old_map.keys)) && (index_of(old_map.keys, k) == index_of(old_map.values, v));
        ensures len(map.keys) + 1 == len(old_map.keys);
    }
    /// Removes the last entry in `map`.
    /// Aborts if `map` is empty.
    public fun pop<K,V>(map: &mut Map<K,V>): (K, V) {
        (vector::pop_back(&mut map.keys), vector::pop_back(&mut map.values))
    }
    spec pop {
        aborts_if len(map.keys) == 0;
    }
    /// Returns immutable reference to the value associated with `k` in `map`.
    /// Aborts with `EKeyDoesNotExist` if `map` does not have an entry with a key of `k`.
    public fun borrow<K,V>(map: & Map<K,V>, k: & K): & V {
        let idx = idx_of(map, k);
        vector::borrow(& map.values, idx)
    }
    spec borrow {
        ensures len(map.keys) == len(old(map).keys);
        ensures len(map.values) == len(old(map).values);
        aborts_if index_of(map.keys, k) == len(map.keys) with EKeyDoesNotExist;
        invariant result == map.values[index_of(map.keys, k)];
    }
    /// Returns immutable reference to the `idx`th element of the values vector in `map`.
    /// Aborts with `std::vector::EINDEX_OUT_OF_BOUNDS` if `idx` is outside the bounds of the values vector.
    public fun borrow_idx<K,V>(map: & Map<K,V>, idx: u64): & V {
        vector::borrow(& map.values, idx)
    }
    spec borrow_idx {
        ensures len(map.keys) == len(old(map).keys);
        ensures len(map.values) == len(old(map).values);
        aborts_if idx >= len(map.values);
        invariant result == map.values[idx];
    }
    /// Returns mutable reference to the value associated with `k` in `map`. 
    /// Aborts with `EKeyDoesNotExist` if `map` does not have an entry with a key of `k`.
    public fun borrow_mut<K,V>(map: &mut Map<K,V>, k: & K): &mut V {
        let idx = idx_of(map, k);
        vector::borrow_mut(&mut map.values, idx)
    }
    spec borrow_mut {
        ensures len(map.keys) == len(old(map).keys);
        ensures len(map.values) == len(old(map).values);
        aborts_if index_of(map.keys, k) == len(map.keys) with EKeyDoesNotExist;
        invariant result == map.values[index_of(map.keys, k)];
    }
    /// Returns mutable reference to the `idx`th element of the values vector in `map`.
    /// Aborts with `std::vector::EINDEX_OUT_OF_BOUNDS` if `idx` is outside the bounds of the values vector.
    public fun borrow_mut_idx<K,V>(map: &mut Map<K,V>, idx: u64): &mut V {
        vector::borrow_mut(&mut map.values, idx)
    }
    spec borrow_mut_idx {
        ensures len(map.keys) == len(old(map).keys);
        ensures len(map.values) == len(old(map).values);
        aborts_if idx >= len(map.values);
        invariant result == map.values[idx];
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
    spec get {
        ensures len(map.keys) == len(old(map).keys);
        ensures len(map.values) == len(old(map).values);
        ensures if (index_of(map.keys, k) == len(map.keys)) result == 0x1::option::none()
                else result == 0x1::option::some(map.values[index_of(map.keys, k)]);
    }
    /// Returns copy of the `idx`th element of the values vector in `map`, and none if `idx` is out of bounds. 
    public fun get_idx<K,V:copy>(map: & Map<K,V>, idx: u64): Option<V> {
        if (idx < vector::length(& map.values)) option::some(*vector::borrow(& map.values, idx))
        else option::none()
    }
    spec get_idx {
        ensures len(map.keys) == len(old(map).keys);
        ensures len(map.values) == len(old(map).values);
        ensures if (idx >= len(map.keys)) result == option::none()
                else result == option::some(map.values[idx]);
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