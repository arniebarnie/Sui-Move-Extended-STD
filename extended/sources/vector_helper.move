// SPDX-License-Identifier: MIT

/// Additional utility methods for `vector`s.
module 0x0::vector_helper {
//======================================================== IMPORTS ============================================================//
    use 0x1::vector::{Self};
//======================================================= ERROR CODES =========================================================//
    const EElementNotFound: u64 = 1;
//========================================================= METHODS ===========================================================//
    /// Returns true if `v` only contains `e`, and false otherwise.
    public fun all<E>(v: & vector<E>, e: & E): bool {
        let i = 0;
        let len = vector::length(v);
        while (i < len) {
            if (vector::borrow(v, i) != e) (return false);
            i = i + 1;
        };

        true
    }
    /// Removes `e` from `v` at the first index that it is found.
    public fun find_and_remove<E>(v: &mut vector<E>, e: & E): E {
        let (contains, i) = vector::index_of(v, e);
        assert!(contains, EElementNotFound);
        vector::remove(v, i)
    }
    /// Swap removes `e` from `v` at the first index that it is found.
    public fun find_and_swap_remove<E>(v: &mut vector<E>, e: & E): E {
        let (contains, i) = vector::index_of(v, e);
        assert!(contains, EElementNotFound);
        vector::swap_remove(v, i)
    }
    /// Removes `e` from `v` at the first index that it is found, and `default` if it is not found.
    public fun find_and_remove_with_default<E:copy>(v: &mut vector<E>, e: & E, default: & E): E {
        let (contains, i) = vector::index_of(v, e);
        if (contains) vector::remove(v, i)
        else *default
    }
    /// Swap removes `e` from `v` at the first index that it is found, and `default` if it is not found.
    public fun find_and_swap_remove_with_default<E:copy>(v: &mut vector<E>, e: & E, default: & E): E {
        let (contains, i) = vector::index_of(v, e);
        if (contains) vector::swap_remove(v, i)
        else *default
    }
}