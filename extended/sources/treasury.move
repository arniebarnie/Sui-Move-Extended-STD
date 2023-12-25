// SPDX-License-Identifier: MIT

/// A `Treasury` allows for multi-coin management by dynamically storing multiple `sui::coin::TreasuryCap<T>`s.
module 0x0::treasury {
//======================================================== IMPORTS ============================================================//
    use 0x0::type_bag::{Self, TypeBag};
    use sui::object::{Self, UID};
    use 0x2::coin::{TreasuryCap};
    use 0x2::tx_context::{TxContext};
//========================================================= OBJECTS ===========================================================//
    /// Holds `sui::balance::TreasuryCap`s
    struct Treasury has key, store {
        id: UID,
        caps: TypeBag
    }
//========================================================= METHODS ===========================================================//
    /// Returns empty `Treasury`.
    public fun new(ctx: &mut TxContext): Treasury {
        Treasury {
            id: object::new(ctx),
            caps: type_bag::new(ctx)
        }
    }
    /// Adds the mint/burn capability, i.e. `sui::coin::TreasuryCap<T>`, for `sui::coin::Coin<T>` to `treasury`.
    public fun add<T>(treasury: &mut Treasury, cap: TreasuryCap<T>) {
        type_bag::add<T,TreasuryCap<T>>(&mut treasury.caps, cap);
    }
    /// Removes the mint/burn capability, i.e. `sui::coin::TreasuryCap<T>`, for `sui::coin::Coin<T>` from `treasury`.
    public fun remove<T>(treasury: &mut Treasury): TreasuryCap<T> {
        type_bag::remove<T,TreasuryCap<T>>(&mut treasury.caps)
    }
    /// Returns true if `treasury` has `sui::coin::TreasuryCap<T>`, and false otherwise.
    public fun contains<T>(treasury: & Treasury): bool {
        type_bag::contains<T>(& treasury.caps)
    }
    /// Immutably borrows `sui::coin::TreasuryCap<T>` from `treasury`.
    public fun borrow<T>(treasury: & Treasury): & TreasuryCap<T> {
        type_bag::borrow<T,TreasuryCap<T>>(& treasury.caps)
    }
    /// Mutably borrows `sui::coin::TreasuryCap<T>` from `treasury`.
    public fun borrow_mut<T>(treasury: &mut Treasury): &mut TreasuryCap<T> {
        type_bag::borrow_mut<T,TreasuryCap<T>>(&mut treasury.caps)
    }
}