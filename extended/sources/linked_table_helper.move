// SPDX-License-Identifier: MIT

/// Additional utility methods for `sui::linked_table`.
module 0x0::linked_table_helper {
//======================================================== IMPORTS ============================================================//
    use 0x1::vector::{Self};
    use 0x1::option::{Self, Option};
    use 0x2::linked_table::{Self, LinkedTable};
//========================================================= METHODS ===========================================================//
    /// Returns the keys of `map` as a `vector`.
    public fun keys<K:store+copy+drop,V:store>(table: & LinkedTable<K,V>): vector<K> {
        let key_opt = linked_table::front(table);
        let keys = vector[];
        let keys_mut = &mut keys;
        while (option::is_some(key_opt)) {
            vector::push_back(keys_mut, *option::borrow(key_opt));
            key_opt = linked_table::next(table, *option::borrow(key_opt));
        };

        keys
    }
    /// Returns the values of `map` as a `vector`.
    public fun values<K:store+copy+drop,V:store+copy>(table: & LinkedTable<K,V>): vector<V> {
        let key_opt = linked_table::front(table);
        let values = vector[];
        let values_mut = &mut values;
        while (option::is_some(key_opt)) {
            vector::push_back(values_mut, *linked_table::borrow(table, *option::borrow(key_opt)));
            key_opt = linked_table::next(table, *option::borrow(key_opt));
        };

        values
    }
    /// Returns a copy of the keys and values of `map` in `vector`s.
    public fun as_vector<K:store+copy+drop,V:store+copy>(table: & LinkedTable<K,V>): (vector<K>, vector<V>) {
        let key_opt = linked_table::front(table);
        let (keys, values) = (vector[], vector[]);
        let (keys_mut, values_mut) = (&mut keys, &mut values);
        while (option::is_some(key_opt)) {
            let key = *option::borrow(key_opt);
            vector::push_back(keys_mut, key);
            vector::push_back(values_mut, *linked_table::borrow(table, key));
            key_opt = linked_table::next(table, key);
        };

        (keys, values)
    }
    /// Destroys `map` and returns its keys and values in `vector`s.
    public fun to_vector<K:store+copy+drop,V:store>(table: LinkedTable<K,V>): (vector<K>, vector<V>) {
        let table_mut = &mut table;
        let key_opt = *linked_table::front(table_mut);
        let (keys, values) = (vector[], vector[]);
        let (keys_mut, values_mut) = (&mut keys, &mut values);
        while (option::is_some(& key_opt)) {
            let key = *option::borrow(& key_opt);
            key_opt = *linked_table::next(table_mut, key);
            vector::push_back(keys_mut, key);
            vector::push_back(values_mut, linked_table::remove(table_mut, key));
        };

        linked_table::destroy_empty(table);
        (keys, values)
    }
    /// Returns an `std::Option<V>` of the value in `table` associated with `k`, and none otherwise.
    public fun try_get<K:store+copy+drop,V:store+copy>(table: & LinkedTable<K,V>, k: K): Option<V> {
        if (linked_table::contains(table, k)) option::some(*linked_table::borrow(table, k))
        else option::none()
    }
    /// Returns a copy of the value in `table` associated with each key in `keys`.
    public fun get_all<K:store+copy+drop,V:store+copy>(table: & LinkedTable<K,V>, keys: vector<K>): vector<V> {
        let keys_ref = & keys;
        let len = vector::length(keys_ref);
        let i = 0;
        let values = vector[];
        let values_mut = &mut values;
        while (i < len) {
            let k = *vector::borrow(keys_ref, i);
            vector::push_back(values_mut, *linked_table::borrow(table, k));
            i = i + 1;
        };

        values
    }
    /// Returns an `std::Option<V>` of the value in `table` associated with each key in `keys` and none if it is not found.
    public fun try_get_all<K:store+copy+drop,V:store+copy>(table: & LinkedTable<K,V>, keys: vector<K>): vector<Option<V>> {
        let keys_ref = & keys;
        let len = vector::length(keys_ref);
        let i = 0;
        let values = vector[];
        let values_mut = &mut values;
        while (i < len) {
            let k = *vector::borrow(keys_ref, i);
            vector::push_back(values_mut, if (linked_table::contains(table, k)) option::some(*linked_table::borrow(table, k))
                                             else option::none());
            i = i + 1;
        };

        values
    }
}