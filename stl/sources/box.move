// SPDX-License-Identifier: MIT

/// A `Box` is used to place objects without the key ability in global storage
module sui::box {
//======================================================== IMPORTS ============================================================//
    use sui::object::{Self, UID};
    use 0x2::tx_context::TxContext;
//========================================================= OBJECTS ===========================================================//
    /// Generic struct to hold items with store
    struct Box<T:store> has key, store {
        id: UID,
        item: T
    }
//========================================================= METHODS ===========================================================//
    /// Returns item inside of a `Box`.
    public fun box<T:store>(item: T, ctx: &mut TxContext): Box<T> {
        Box {
            id: object::new(ctx),
            item
        }
    }
    /// Destroys `box` and returns the item inside.
    public fun unbox<T:store>(box: Box<T>): T {
        let Box {
            id,
            item
        } = box;
        object::delete(id);
        item
    }
    /// Borrows item from `box`
    public fun borrow<T:store>(box: & Box<T>): & T {
        & box.item
    }
    /// Mutably borrows item from `box`
    public fun borrow_mut<T:store>(box: &mut Box<T>): &mut T {
        &mut box.item
    }
}