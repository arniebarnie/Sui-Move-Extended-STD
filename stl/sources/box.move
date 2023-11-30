// SPDX-License-Identifier: MIT

module 0x0::box {
//======================================================== IMPORTS ============================================================//
    use 0x2::object::{Self, UID};
    use 0x2::tx_context::TxContext;
//========================================================= OBJECTS ===========================================================//
    // Generic struct to hold items with store
    struct Box<T:store> has key, store {
        id: UID,
        item: T
    }
//========================================================= METHODS ===========================================================//
    // Box item
    public fun box<T:store>(item: T, ctx: &mut TxContext): Box<T> {
        Box {
            id: object::new(ctx),
            item
        }
    }
    // Unbox item
    public fun unbox<T:store>(box: Box<T>): T {
        let Box {
            id,
            item
        } = box;
        object::delete(id);
        item
    }
}