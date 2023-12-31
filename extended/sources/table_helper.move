// SPDX-License-Identifier: MIT

/// Additional utility methods for `sui::table`.
module 0x0::table_helper {
//======================================================== IMPORTS ============================================================//
    use 0x1::vector::{Self};
    use 0x1::option::{Self, Option};
    use 0x2::table::{Self, Table};
//========================================================= METHODS ===========================================================//
    /// Returns an `std::Option<V>` of the value in `table` associated with `k` or none if it is not found.
    public fun try_get<K:store+copy+drop,V:store+copy>(table: & Table<K,V>, k: K): Option<V> {
        if (table::contains(table, k)) option::some(*table::borrow(table, k))
        else option::none()
    }
    /// Returns a copy of the value in `table` associated with each key in `keys`.
    public fun get_all<K:store+copy+drop,V:store+copy>(table: & Table<K,V>, keys: & vector<K>): vector<V> {
        let len = vector::length(keys);
        let i = 0;
        let values = vector[];
        let values_mut = &mut values;
        while (i < len) {
            vector::push_back(values_mut, *table::borrow(table, *vector::borrow(keys, i)));
            i = i + 1;
        };

        values
    }
    /// Returns an `std::Option<V>` of the value in `table` associated with each key in `keys` or none if it is not found.
    public fun try_get_all<K:store+copy+drop,V:store+copy>(table: & Table<K,V>, keys: & vector<K>): vector<Option<V>> {
        let len = vector::length(keys);
        let i = 0;
        let values = vector[];
        let values_mut = &mut values;
        while (i < len) {
            let k = *vector::borrow(keys, i);
            vector::push_back(values_mut, if (table::contains(table, k)) option::some(*table::borrow(table, k)) else option::none());
            i = i + 1;
        };

        values
    }
    /// Returns a copy of the value in `table` associated with `k` or a copy of `default` if it is not found.
    public fun get_with_default<K:store+copy+drop,V:store+copy>(table: & Table<K,V>, k: K, default: & V): V {
        if (table::contains(table, k)) *table::borrow(table, k)
        else *default
    }
    /// Returns a copy of the value in `table` associated with each key in `keys` or a copy of `default` if it is not found.
    public fun get_all_with_default<K:store+copy+drop,V:store+copy>(table: & Table<K,V>, keys: & vector<K>, default: & V): vector<V> {
        let len = vector::length(keys);
        let i = 0;
        let values = vector[];
        let values_mut = &mut values;
        while (i < len) {
            let k = *vector::borrow(keys, i);
            vector::push_back(values_mut, if (table::contains(table, k)) *table::borrow(table, k) else *default);
            i = i + 1;
        };

        values
    }
    /// Inserts pairs of elements of the same index in `keys` and `values` as key-value pairs into `table`.
    public fun add_all<K:store+copy+drop,V:store>(table: &mut Table<K,V>, keys: vector<K>, values: vector<V>) {
        let (keys_mut, values_mut) = (&mut keys, &mut values);
        let len = vector::length(keys_mut);
        while (len > 0) {
            table::add(table, vector::pop_back(keys_mut), vector::pop_back(values_mut));
            len = len - 1;
        };
        vector::destroy_empty(keys);
        vector::destroy_empty(values);
    }
    // Removes the entry associated with each key in `keys` from `table` and returns the values.
    public fun remove_all<K:store+copy+drop,V:store>(table: &mut Table<K,V>, keys: & vector<K>): vector<V> {
        let len = vector::length(keys);
        let i = 0;
        let values = vector[];
        let values_mut = &mut values;
        while (i < len) {
            vector::push_back(values_mut, table::remove(table, *vector::borrow(keys, i)));
            i = i + 1;
        };

        values
    }
}