// SPDX-License-Identifier: MIT

/// Additional utility methods for `sui::table`.
module 0x0::table_helper {
//======================================================== IMPORTS ============================================================//
    use 0x1::vector::{Self};
    use 0x1::option::{Self, Option};
    use 0x2::table::{Self, Table};
//========================================================= METHODS ===========================================================//
    /// Returns an `std::Option<V>` of the value in `table` associated with `k`, and none if it is not found.
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
            let k = *vector::borrow(keys, i);
            vector::push_back(values_mut, *table::borrow(table, k));
            i = i + 1;
        };

        values
    }
    /// Returns an `std::Option<V>` of the value in `table` associated with each key in `keys` and none if it is not found.
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
}