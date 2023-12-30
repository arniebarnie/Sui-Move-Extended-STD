// SPDX-License-Identifier: MIT

/// A `DynSet` is a set-like collection that holds keys using Sui's dynamic fields. Note that this also means that 
/// `DynSet` values containing the exact same keys will not be equal, with `==`, at runtime.
module 0x0::dyn_set {
//======================================================== IMPORTS ============================================================//
    use sui::object::{Self, UID};
    use 0x2::dynamic_field::{Self};
    use 0x2::tx_context::{TxContext};
//======================================================= ERROR CODES =========================================================//
    const ESetNotEmpty: u64 = 1;
//========================================================= OBJECTS ===========================================================//
    struct V has store, copy, drop { }
    struct DynSet<phantom K: store + copy + drop> has key, store {
        id: UID,
        size: u64
    }
//========================================================= METHODS ===========================================================//
    /// Returns empty `DynSet`.
    public fun new<K:store+copy+drop>(ctx: &mut TxContext): DynSet<K> {
        DynSet {
            id: object::new(ctx),
            size: 0
        }
    }
    /// Returns a `DynSet` containing only `k`.
    public fun singleton<K:store+copy+drop>(k: K, ctx: &mut TxContext): DynSet<K> {
        let id = object::new(ctx);
        dynamic_field::add(&mut id, k, V { });
        DynSet {
            id,
            size: 1
        }
    }
    /// Inserts `k` into `set`.
    public fun insert<K:store+copy+drop>(set: &mut DynSet<K>, k: K) {
        dynamic_field::add(&mut set.id, k, V { });
        set.size = set.size + 1;
    }
    /// Removes `k` into `set`.
    public fun remove<K:store+copy+drop>(set: &mut DynSet<K>, k: K) {
        dynamic_field::remove<K,V>(&mut set.id, k);
        set.size = set.size - 1;
    }
    /// Returns true if `k` is contained in `set`, and false otherwise.
    public fun contains<K:store+copy+drop>(set: &mut DynSet<K>, k: K): bool {
        dynamic_field::exists_(& set.id, k)
    }
    /// Returns number of keys in `set`.
    public fun size<K:store+copy+drop>(set: & DynSet<K>): u64 {
        set.size
    }
    /// Returns true if `set` has no keys, and false otherwise.
    public fun is_empty<K:store+copy+drop>(set: & DynSet<K>): bool {
        set.size == 0
    }
    /// Destroys `set`.
    /// Aborts with `ESetNotEmpty` if `set` still contains keys.
    public fun destroy_empty<K:store+copy+drop>(set: DynSet<K>) {
        let DynSet {
            id,
            size
        } = set;
        assert!(size == 0, ESetNotEmpty);
        object::delete(id);
    }
    /// Destroys `set` which may still contain keys.
    public fun drop<K:store+copy+drop>(set: DynSet<K>) {
        let DynSet {
            id,
            size: _
        } = set;
        object::delete(id);
    }
}