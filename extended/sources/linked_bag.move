// SPDX-License-Identifier: MIT

/// A `LinkedBag` is similar to a `sui::bag::Bag` but the entries are linked together, allowing for ordered insertion and removal.
/// Note that all keys are of the same type.
module 0x0::linked_bag {
//======================================================== IMPORTS ============================================================//
    use 0x1::option::{Self, Option};
    use sui::object::{Self, UID};
    use 0x2::dynamic_field::{Self};
    use 0x2::tx_context::{TxContext};
//======================================================= ERROR CODES =========================================================//
    const EBagNotEmpty: u64 = 1; // Bag is not empty
//========================================================= OBJECTS ===========================================================//
    struct Entry<K: store + copy + drop, V: store> has store {
        prev: Option<K>, // Key for previous entry
        next: Option<K>, // Key for next entry
        value: V // Value of entry
    }
    struct LinkedBag<K: store + copy + drop> has key, store {
        id: UID,
        size: u64, // Number of entries held
        head: Option<K>, // Key for first entry
        tail: Option<K> // Key for last entry
    }
//========================================================= METHODS ===========================================================//
    /// Returns empty `LinkedBag`
    public fun empty<K:store+copy+drop>(ctx: &mut TxContext): LinkedBag<K> {
        LinkedBag {
            id: object::new(ctx),
            size: 0,
            head: option::none(),
            tail: option::none()
        }
    }
    /// Returns the key for the first element in `bag`, or None if `bag` is empty
    public fun front<K:store+copy+drop>(bag: & LinkedBag<K>): & Option<K> {
        & bag.head
    }
    /// Returns the key for the last element in `bag`, or None if `bag` is empty
    public fun back<K:store+copy+drop>(bag: & LinkedBag<K>): & Option<K> {
        & bag.tail
    }
    /// Inserts a key-value pair to the front of `bag`, i.e. the newly inserted pair will be the first element in `bag`. 
    /// Aborts with `sui::dynamic_field::EFieldAlreadyExists` if `bag` already has an entry with a key of `k`.
    public fun push_front<K:store+copy+drop,V:store>(bag: &mut LinkedBag<K>, k: K, value: V) {
        if (bag.size == 0) {
            dynamic_field::add(&mut bag.id, k, Entry<K,V> {
                prev: option::none(),
                next: option::none(),
                value
            });
            option::fill(&mut bag.head, k);
            option::fill(&mut bag.tail, k);
        } else {
            let head = option::swap(&mut bag.head, k);
            option::fill(&mut (dynamic_field::borrow_mut<K,Entry<K,V>>(&mut bag.id, head)).prev, k);
            dynamic_field::add(&mut bag.id, k, Entry<K,V> {
                prev: option::none(),
                next: option::some(head),
                value
            });
        };
        bag.size = bag.size + 1;
    }
    /// Inserts a key-value pair at the back of `bag`, i.e. the newly inserted pair will be the last element in the `bag`. 
    /// Aborts with sui::dynamic_field::EFieldAlreadyExists if `bag` already has an entry with a key of `k`.
    public fun push_back<K:store+copy+drop,V:store>(bag: &mut LinkedBag<K>, k: K, value: V) {
        if (bag.size == 0) {
            dynamic_field::add(&mut bag.id, k, Entry<K,V> {
                prev: option::none(),
                next: option::none(),
                value
            });
            option::fill(&mut bag.head, k);
            option::fill(&mut bag.tail, k);
        } else {
            let tail = option::swap(&mut bag.tail, k);
            option::fill(&mut (dynamic_field::borrow_mut<K,Entry<K,V>>(&mut bag.id, tail)).next, k);
            dynamic_field::add(&mut bag.id, k, Entry<K,V> {
                prev: option::some(tail),
                next: option::none(),
                value
            });
        };
        bag.size = bag.size + 1;
    }
    /// Returns immutable reference to the value associated with `k` in `bag`. 
    /// Aborts with `sui::dynamic_field::EFieldDoesNotExist` if `bag` does not have an entry with a key of `k`.
    /// Aborts with `sui::dynamic_field::EFieldTypeMismatch` if `bag` has an entry associated with `k`, but the value is not of type `V`.
    public fun borrow<K:store+copy+drop,V:store>(bag: & LinkedBag<K>, k: K): & V {
        & (dynamic_field::borrow<K,Entry<K,V>>(& bag.id, k)).value
    }
    /// Returns mutable reference to the value associated with `k` in `bag`. 
    /// Aborts with `sui::dynamic_field::EFieldDoesNotExist` if `bag` does not have an entry with a key of `k`.
    /// Aborts with `sui::dynamic_field::EFieldTypeMismatch` if `bag` has an entry associated with `k`, but the value is not of type `V`.
    public fun borrow_mut<K:store+copy+drop,V:store>(bag: &mut LinkedBag<K>, k: K): &mut V {
        &mut (dynamic_field::borrow_mut<K,Entry<K,V>>(&mut bag.id, k)).value
    }
    /// Returns a immutable reference to the key for the previous entry of `k` in `bag`. 
    /// Returns None if the entry does not have a predecessor. 
    /// Aborts with `sui::dynamic_field::EFieldDoesNotExist` if `bag` does not have an entry with a key of `k`.
    public fun prev<K:store+copy+drop,V:store>(bag: & LinkedBag<K>, k: K): & Option<K> {
        & (dynamic_field::borrow<K,Entry<K,V>>(& bag.id, k)).prev
    }
    /// Returns a immutable reference to the key for the next entry of `k` in `bag`. 
    /// Returns None if the entry does not have a successor. 
    /// Aborts with `sui::dynamic_field::EFieldDoesNotExist` if `bag` does not have an entry with a key of `k`.
    public fun next<K:store+copy+drop,V:store>(bag: & LinkedBag<K>, k: K): & Option<K> {
        & (dynamic_field::borrow<K,Entry<K,V>>(& bag.id, k)).next
    }
    /// Removes the entry associated with `k` in `bag` and returns the value. This splices the key-value pair out of the ordering.
    /// Aborts with `sui::dynamic_field::EFieldDoesNotExist` if `bag` does not have an entry with a key of `k`.
    /// Aborts with `sui::dynamic_field::EFieldTypeMismatch` if `bag` has an entry associated with `k`, but the value is not of type `V`.
    public fun remove<K:store+copy+drop,V:store>(bag: &mut LinkedBag<K>, k: K): V {
        let Entry {
            prev,
            next,
            value
        } = dynamic_field::remove(&mut bag.id, k);

        if (option::is_some(& prev)) {
            dynamic_field::borrow_mut<K,Entry<K,V>>(&mut bag.id, *option::borrow(& prev)).next = next;
        } else {
            bag.head = next;
        };
        if (option::is_some(& next)) {
            dynamic_field::borrow_mut<K,Entry<K,V>>(&mut bag.id, *option::borrow(& next)).prev = prev;
        } else {
            bag.tail = prev;
        };
        bag.size = bag.size - 1;

        value
    }
    /// Removes the front of the `bag` and returns the key and value.
    /// Aborts with `std::option::EOPTION_NOT_SET` if `bag` is empty.
    /// Aborts with `sui::dynamic_field::EFieldTypeMismatch` if `bag` is nonempty, but the front value is not of type `V`.
    public fun pop_front<K:store+copy+drop,V:store>(bag: &mut LinkedBag<K>): (K, V) {
        let old_head = option::extract(&mut bag.head);
        let Entry {
            prev: _,
            next,
            value
        } = dynamic_field::remove(&mut bag.id, old_head);
        
        if (option::is_some(& next)) {
            option::extract(&mut (dynamic_field::borrow_mut<K,Entry<K,V>>(&mut bag.id, *option::borrow(& next))).prev);
        };
        bag.head = next;
        bag.size = bag.size - 1;

        (old_head, value)
    }
    /// Removes the back of the `bag` and returns the key and value.
    /// Aborts with `std::option::EOPTION_NOT_SET` if `bag` is empty.
    /// Aborts with `sui::dynamic_field::EFieldTypeMismatch` if `bag` is nonempty, but the back value is not of type `V`.
    public fun pop_back<K:store+copy+drop,V:store>(bag: &mut LinkedBag<K>): (K, V) {
        let old_tail = option::extract(&mut bag.tail);
        let Entry {
            prev,
            next: _,
            value
        } = dynamic_field::remove(&mut bag.id, old_tail);
        
        if (option::is_some(& prev)) {
            option::extract(&mut (dynamic_field::borrow_mut<K,Entry<K,V>>(&mut bag.id, *option::borrow(& prev))).next);
        };
        bag.tail = prev;
        bag.size = bag.size - 1;

        (old_tail, value)
    }
    /// Returns true if `k` is associated with an entry in `bag`, and false otherwise.
    public fun contains<K:store+copy+drop>(bag: & LinkedBag<K>, k: K): bool {
        dynamic_field::exists_(& bag.id, k)
    }
    /// Returns true if `k` is associated with an entry in `bag` with a value of type `V`, and false otherwise.
    public fun contains_with_type<K:store+copy+drop,V:store>(bag: & LinkedBag<K>, k: K): bool {
        dynamic_field::exists_with_type<K,Entry<K,V>>(& bag.id, k)
    }
    /// Returns the size of `bag`, i.e. the number of key-value pairs.
    public fun length<K:store+copy+drop>(bag: & LinkedBag<K>): u64 {
        bag.size
    }
    /// Returns true if `bag` is empty, and false otherwise.
    public fun is_empty<K:store+copy+drop>(bag: & LinkedBag<K>): bool {
        bag.size == 0
    }
    /// Destroys `bag`. 
    /// Aborts with `EBagNotEmpty` if `bag` still contains entries.
    public fun destroy_empty<K:store+copy+drop>(bag: LinkedBag<K>) {
        let LinkedBag {
            id,
            size,
            head: _,
            tail: _
        } = bag;
        assert!(size == 0, EBagNotEmpty);
        object::delete(id);
    }
//========================================================== TESTS ============================================================//
    #[test_only]
    use 0x2::test_scenario;
    #[test_only]
    use 0x2::test_utils;
    #[test]
    fun test_empty() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let bag = empty<u64>(ctx);
            assert!(bag.size == 0, 1);
            assert!(option::is_none(& bag.head), 2);
            assert!(option::is_none(& bag.tail), 3);
            test_utils::destroy(bag);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_front() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let bag = empty<u64>(ctx);
            assert!(option::is_none(front(& bag)), 1);
            test_utils::destroy(bag);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_back() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let bag = empty<u64>(ctx);
            assert!(option::is_none(back(& bag)), 1);
            test_utils::destroy(bag);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_push_front() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let bag = empty<u64>(ctx);
            assert!(option::is_none(front(& bag)), 1);
            assert!(bag.size == 0, 2);
            push_front(&mut bag, 10, 10);
            assert!(*option::borrow(front(& bag)) == 10, 3);
            assert!(*borrow(& bag, 10) == 10, 4);
            assert!(*option::borrow(back(& bag)) == 10, 5);
            assert!(bag.size == 1, 6);
            push_front(&mut bag, 20, 20);
            assert!(*option::borrow(front(& bag)) == 20, 7);
            assert!(*borrow(& bag, 20) == 20, 8);
            assert!(*option::borrow(back(& bag)) == 10, 9);
            assert!(*borrow(& bag, 10) == 10, 10);
            assert!(bag.size == 2, 11);
            test_utils::destroy(bag);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_push_back() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let bag = empty<u64>(ctx);
            assert!(option::is_none(front(& bag)), 1);
            assert!(bag.size == 0, 2);
            push_back(&mut bag, 10, 10);
            assert!(*option::borrow(front(& bag)) == 10, 3);
            assert!(*borrow(& bag, 10) == 10, 4);
            assert!(*option::borrow(back(& bag)) == 10, 5);
            assert!(bag.size == 1, 6);
            push_back(&mut bag, 20, 20);
            assert!(*option::borrow(front(& bag)) == 10, 7);
            assert!(*borrow(& bag, 10) == 10, 8);
            assert!(*option::borrow(back(& bag)) == 20, 9);
            assert!(*borrow(& bag, 20) == 20, 10);
            assert!(bag.size == 2, 11);
            test_utils::destroy(bag);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_prev() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let bag = empty<u64>(ctx);
            push_back(&mut bag, 10, 10);
            push_back(&mut bag, 20, 20);
            push_back(&mut bag, 30, 30);
            push_back(&mut bag, 40, 40);
            push_back(&mut bag, 50, 50);
            let k = *option::borrow(back(& bag));
            assert!(k == 50, 1);
            k = *option::borrow(prev<u64,u64>(& bag, k));
            assert!(k == 40, 2);
            k = *option::borrow(prev<u64,u64>(& bag, k));
            assert!(k == 30, 3);
            k = *option::borrow(prev<u64,u64>(& bag, k));
            assert!(k == 20, 4);
            k = *option::borrow(prev<u64,u64>(& bag, k));
            assert!(k == 10, 5);
            let k = prev<u64,u64>(& bag, k);
            assert!(option::is_none(k), 6);
            test_utils::destroy(bag);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_next() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let bag = empty<u64>(ctx);
            push_back(&mut bag, 10, 10);
            push_back(&mut bag, 20, 20);
            push_back(&mut bag, 30, 30);
            push_back(&mut bag, 40, 40);
            push_back(&mut bag, 50, 50);
            let k = *option::borrow(front(& bag));
            assert!(k == 10, 1);
            k = *option::borrow(next<u64,u64>(& bag, k));
            assert!(k == 20, 2);
            k = *option::borrow(next<u64,u64>(& bag, k));
            assert!(k == 30, 3);
            k = *option::borrow(next<u64,u64>(& bag, k));
            assert!(k == 40, 4);
            k = *option::borrow(next<u64,u64>(& bag, k));
            assert!(k == 50, 5);
            let k = next<u64,u64>(& bag, k);
            assert!(option::is_none(k), 6);
            test_utils::destroy(bag);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_remove() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let bag = empty<u64>(ctx);
            push_back(&mut bag, 10, 10);
            push_back(&mut bag, 20, 20);
            push_back(&mut bag, 30, 30);
            push_back(&mut bag, 40, 40);
            push_back(&mut bag, 50, 50);
            assert!(remove(&mut bag, 10) == 10, 1);
            assert!(remove(&mut bag, 20) == 20, 2);
            assert!(remove(&mut bag, 30) == 30, 3);
            assert!(remove(&mut bag, 40) == 40, 4);
            assert!(remove(&mut bag, 50) == 50, 5);
            test_utils::destroy(bag);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_pop_front() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let bag = empty<u64>(ctx);
            push_back(&mut bag, 10, 10);
            push_back(&mut bag, 20, 20);
            push_back(&mut bag, 30, 30);
            push_back(&mut bag, 40, 40);
            push_back(&mut bag, 50, 50);
            assert!(bag.size == 5, 1);
            let (k, v) = pop_front<u64,u64>(&mut bag);
            assert!(k == 10, 2);
            assert!(v == 10, 3);
            assert!(bag.size == 4, 4);
            (k, v) = pop_front<u64,u64>(&mut bag);
            assert!(k == 20, 5);
            assert!(v == 20, 6);
            assert!(bag.size == 3, 7);
            (k, v) = pop_front<u64,u64>(&mut bag);
            assert!(k == 30, 8);
            assert!(v == 30, 9);
            assert!(bag.size == 2, 10);
            (k, v) = pop_front<u64,u64>(&mut bag);
            assert!(k == 40, 11);
            assert!(v == 40, 12);
            assert!(bag.size == 1, 13);
            (k, v) = pop_front<u64,u64>(&mut bag);
            assert!(k == 50, 14);
            assert!(v == 50, 15);
            assert!(bag.size == 0, 16);
            test_utils::destroy(bag);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_pop_back() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let bag = empty<u64>(ctx);
            push_back(&mut bag, 10, 10);
            push_back(&mut bag, 20, 20);
            push_back(&mut bag, 30, 30);
            push_back(&mut bag, 40, 40);
            push_back(&mut bag, 50, 50);
            assert!(bag.size == 5, 1);
            let (k, v) = pop_back<u64,u64>(&mut bag);
            assert!(k == 50, 2);
            assert!(v == 50, 3);
            assert!(bag.size == 4, 4);
            (k, v) = pop_back<u64,u64>(&mut bag);
            assert!(k == 40, 5);
            assert!(v == 40, 6);
            assert!(bag.size == 3, 7);
            (k, v) = pop_back<u64,u64>(&mut bag);
            assert!(k == 30, 8);
            assert!(v == 30, 9);
            assert!(bag.size == 2, 10);
            (k, v) = pop_back<u64,u64>(&mut bag);
            assert!(k == 20, 11);
            assert!(v == 20, 12);
            assert!(bag.size == 1, 13);
            (k, v) = pop_back<u64,u64>(&mut bag);
            assert!(k == 10, 14);
            assert!(v == 10, 15);
            assert!(bag.size == 0, 16);
            test_utils::destroy(bag);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_contains() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let bag = empty<u64>(ctx);
            push_back(&mut bag, 10, 10);
            push_back(&mut bag, 20, 20);
            push_back(&mut bag, 30, 30);
            push_back(&mut bag, 40, 40);
            push_back(&mut bag, 50, 50);
            assert!(contains(& bag, 10), 1);
            assert!(contains(& bag, 20), 2);
            assert!(contains(& bag, 30), 3);
            assert!(contains(& bag, 40), 4);
            assert!(contains(& bag, 50), 5);
            assert!(!contains(& bag, 25), 6);
            test_utils::destroy(bag);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_contains_with_type() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let bag = empty<u64>(ctx);
            push_back(&mut bag, 10, 10);
            push_back(&mut bag, 20, 20);
            push_back(&mut bag, 30, 30);
            push_back(&mut bag, 40, 40);
            push_back(&mut bag, 50, 50);
            assert!(contains_with_type<u64,u64>(& bag, 10), 1);
            assert!(contains_with_type<u64,u64>(& bag, 20), 2);
            assert!(contains_with_type<u64,u64>(& bag, 30), 3);
            assert!(contains_with_type<u64,u64>(& bag, 40), 4);
            assert!(contains_with_type<u64,u64>(& bag, 50), 5);
            assert!(!contains_with_type<u64,address>(& bag, 50), 6);
            assert!(!contains_with_type<u64,u64>(& bag, 25), 7);
            assert!(!contains_with_type<u64,bool>(& bag, 25), 8);
            test_utils::destroy(bag);
        };
        test_scenario::end(scenario);
    }
}