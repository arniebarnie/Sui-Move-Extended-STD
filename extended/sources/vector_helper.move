// SPDX-License-Identifier: MIT

/// Additional utility methods for `vector`s.
module 0x0::vector_helper {
//======================================================== IMPORTS ============================================================//
    use 0x1::vector::{Self};
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
}