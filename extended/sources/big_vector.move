// SPDX-License-Identifier: MIT

/// A `BigVector` is a vector-like collection that stores multiple vectors using Sui's dynamic fields. This allows a `BigVector`'s capacity 
/// to be theoretically unlimited. However, the quantity of operations on `BigVector`'s in a single transaction is bounded by its dynamic field 
/// accesses as these are capped per transaction. Note that this also means that `BigVector` values with the exact same index-value mapping 
/// will not be equal, with `==`, at runtime.
module 0x0::big_vector {
//======================================================== IMPORTS ============================================================//
    use 0x1::vector::{Self};
    use sui::object::{Self, UID};
    use sui::dynamic_field::{Self};
    use sui::tx_context::{TxContext};
//======================================================= ERROR CODES =========================================================//
    /// Element index out of bounds
    const EInvalidElementIndex: u64 = 1;
    /// Bucket index out of bounds
    const EInvalidBucketIndex: u64 = 2;
    /// `BigVector` is empty
    const EBigVectorEmpty: u64 = 3;
    /// `BigVector` is not empty
    const EBigVectorNotEmpty: u64 = 4;
    /// Vector is too large to append
    const EInvalidVectorSize: u64 = 5;
//======================================================== CONSTANTS ==========================================================//
    /// Maximum bytes able to be held in a single vector
    const VECTOR_MAX_BYTES: u64 = 256_000;
    /// Buffer in each bucket to store elements temporarily during methods
    const BUCKET_SIZE_BUFFER: u64 = 1;
//========================================================= OBJECTS ===========================================================//
    struct BigVector<phantom E> has key, store {
        id: UID,
        bucket_size: u64,
        bucket_count: u64,
        length: u64,
    }
//========================================================= METHODS ===========================================================//
    /// Returns empty `BigVector`.
    public fun empty<E:store>(element_size_in_bytes: u16, ctx: &mut TxContext): BigVector<E> {
        let id = object::new(ctx);
        BigVector {
            id,
            // Calculate maximum elements capable of being held in one bucket then remove the buffer
            bucket_size: VECTOR_MAX_BYTES / (element_size_in_bytes as u64) - BUCKET_SIZE_BUFFER,
            bucket_count: 0,
            length: 0
        }
    }
    /// Returns a `BigVector` of size one containing `e`. Uses 1 dynamic field access.
    public fun singleton<E:store>(e: E, element_size_in_bytes: u16, ctx: &mut TxContext): BigVector<E> {
        let id = object::new(ctx);
        // Initialize bucket 0 by attaching singleton vector of e to bv at 0
        dynamic_field::add(&mut id, 0, vector::singleton(e));
        BigVector {
            id,
            // Calculate maximum elements capable of being held in one bucket then remove the buffer
            bucket_size: VECTOR_MAX_BYTES / (element_size_in_bytes as u64) - BUCKET_SIZE_BUFFER,
            bucket_count: 1,
            length: 1
        }
    }
    /// Returns true if `bv` is empty and false otherwise.
    public fun is_empty<E:store>(bv: & BigVector<E>): bool {
        bv.length == 0
    }
    /// Returns length of `bv`.
    public fun length<E:store>(bv: & BigVector<E>): u64 {
        bv.length
    }
    /// Returns number of buckets in `bv`.
    public fun bucket_count<E:store>(bv: & BigVector<E>): u64 {
        bv.bucket_count
    }
    /// Returns immutable reference to the `i`th element of `bv`. Uses 1 dynamic field access.
    public fun borrow<E:store>(bv: & BigVector<E>, i: u64): & E {
        // i / bucket_size finds the bucket index
        // i % bucket_size finds the element index inside the bucket
        vector::borrow(dynamic_field::borrow(& bv.id, i / bv.bucket_size), i % bv.bucket_size)
    }
    /// Returns mutable reference to the `i`th element of `bv`. Uses 1 dynamic field access.
    public fun borrow_mut<E:store>(bv: &mut BigVector<E>, i: u64): &mut E {
        // i / bucket_size finds the bucket index
        // i % bucket_size finds the element index inside the bucket
        vector::borrow_mut(dynamic_field::borrow_mut(&mut bv.id, i / bv.bucket_size), i % bv.bucket_size)
    }
    /// Returns immutable reference to `i`th bucket of `bv`. Uses 1 dynamic field access.
    public fun borrow_bucket<E:store>(bv: & BigVector<E>, i: u64): & vector<E> {
        assert!(i < bv.bucket_count, EInvalidBucketIndex);
        dynamic_field::borrow(& bv.id, i)
    }
    /// Adds `e` to the end of `bv`. Uses 1 dynamic field access.
    public fun push_back<E:store>(bv: &mut BigVector<E>, e: E) {
        let bv_bucket_count = bv.bucket_count;
        let bv_length = bv.length;
        // If the last bucket is full then a new one must be added
        if (bv_length / bv.bucket_size == bv_bucket_count) {
            dynamic_field::add(&mut bv.id, bv_bucket_count, vector::singleton(e));
            bv.bucket_count = bv_bucket_count + 1;
        } else vector::push_back(dynamic_field::borrow_mut(&mut bv.id, bv_bucket_count - 1), e);
        bv.length = bv_length + 1;
    }
    /// Pops an element from the end of `bv`. Uses 1 dynamic field access.
    public fun pop_back<E:store>(bv: &mut BigVector<E>): E {
        let bv_length = bv.length;
        assert!(bv_length != 0, EBigVectorEmpty);
        bv.length = bv_length - 1;
        // If bv has only one element in its last bucket, then this bucket has to removed and destroyed
        if (bv_length % bv.bucket_size == 1) {
            let bv_bucket_count = bv.bucket_count - 1;
            let removed_bucket = dynamic_field::remove(&mut bv.id, bv_bucket_count);
            let popped_element = vector::pop_back(&mut removed_bucket);
            vector::destroy_empty(removed_bucket);
            bv.bucket_count = bv_bucket_count;
            popped_element
        } else vector::pop_back(dynamic_field::borrow_mut(&mut bv.id, bv.bucket_count - 1))
    }
    /// Swaps `i`th and `j`th element of `bv`. Borrow checker makes this use <= 3 instead of <= 2 dynamic field accesses.
    public fun swap<E:store>(bv: &mut BigVector<E>, i: u64, j: u64) {
        let bv_length = bv.length;
        assert!(i < bv_length && j < bv_length, EInvalidElementIndex);
        let bv_bucket_size = bv.bucket_size;
        // i / bucket_size finds the bucket index
        let i_bucket = i / bv_bucket_size;
        let j_bucket = j / bv_bucket_size;
        // Check if ith and jth elements are in the same bucket
        if (i_bucket != j_bucket) {
            // i % bucket_size finds the element index inside the bucket
            let i_slot = i % bv_bucket_size;
            let j_slot = j % bv_bucket_size;
            let bv_id = &mut bv.id;

            // Swap element at index i_slot with last element then remove from bucket i_bucket
            let popped_element = vector::swap_remove<E>(dynamic_field::borrow_mut(bv_id, i_bucket), i_slot);
            let bucket = dynamic_field::borrow_mut(bv_id, j_bucket);
            // Add popped element to end of bucket
            vector::push_back(bucket, popped_element);
            // Swap element at index j_slot with last element then remove from bucket j_bucket
            popped_element = vector::swap_remove(bucket, j_slot);
            bucket = dynamic_field::borrow_mut(bv_id, i_bucket);
            // Add popped element to end of bucket i_bucket
            vector::push_back(bucket, popped_element);
            // Swap element at index i_slot with last element from bucket i_bucket
            let bucket_length = vector::length(bucket) - 1;
            vector::swap(bucket, i_slot, bucket_length);
        } else vector::swap<E>(dynamic_field::borrow_mut(&mut bv.id, i_bucket), i % bv_bucket_size, j % bv_bucket_size);
    }
    /// Appends `v` to the end of `bv`. Uses <= 2 dynamic field accesses.
    public fun append<E:store>(bv: &mut BigVector<E>, v: vector<E>) {
        let v_length = vector::length(& v);
        let bv_bucket_size = bv.bucket_size;
        assert!(v_length <= bv_bucket_size, EInvalidVectorSize);
        let bv_length = bv.length;
        let bv_bucket_count = bv.bucket_count;
        // Check if the last bucket of bv is already full
        if (bv_length / bv_bucket_size == bv_bucket_count) {
            dynamic_field::add(&mut bv.id, bv_bucket_count, v);
            bv.bucket_count = bv_bucket_count + 1;
        // Check if appending to v to bv will require another bucket
        } else if ((bv_length + v_length) / bv_bucket_size  == bv_bucket_count && (bv_length % bv_bucket_size) + v_length != bv_bucket_size) {
            // Reverse v to pop elements in reverse order
            vector::reverse(&mut v);
            let bv_id = &mut bv.id;
            let bucket = dynamic_field::borrow_mut(bv_id, bv_bucket_count - 1);
            let added_to_bucket = bv_bucket_size - vector::length(bucket);
            let v_mut = &mut v;
            // Push elements of v onto last bucket
            while (added_to_bucket != 0) {
                vector::push_back(bucket, vector::pop_back(v_mut));
                added_to_bucket = added_to_bucket - 1;
            };
            // Re-reverse v to get original ordering
            vector::reverse(&mut v);
            // Push remaining to new bucket
            dynamic_field::add(bv_id, bv_bucket_count, v);
            bv.bucket_count = bv_bucket_count + 1;

        } else vector::append(dynamic_field::borrow_mut(&mut bv.id, bv_bucket_count - 1), v);
        bv.length = bv_length + v_length;
    }
    /// Swaps `i`th and last element in `bv` then pops it. Uses <= 2 dynamic field accesses.
    public fun swap_remove<E:store>(bv: &mut BigVector<E>, i: u64): E {
        let bv_length = bv.length;
        assert!(i < bv_length, EInvalidElementIndex);
        let bv_id = &mut bv.id;
        let bv_bucket_count = bv.bucket_count - 1;
        let bv_bucket_size = bv.bucket_size;
        let i_bucket = i / bv_bucket_size;
        // Check if ith element is in the last bucket
        if (i_bucket != bv_bucket_count) {
            // i % bucket_size finds the element index inside the bucket
            let i_slot = i % bv_bucket_size;
            // Pop last element of last bucket
            // Check if last bucket has only one element, and if so delete it
            let popped_element = if (bv_length % bv_bucket_size == 1) {
                let bucket = dynamic_field::remove(bv_id, bv_bucket_count);
                let popped_element = vector::pop_back(&mut bucket);
                vector::destroy_empty(bucket);
                bv.bucket_count = bv_bucket_count;
                popped_element
            } else vector::pop_back(dynamic_field::borrow_mut(bv_id, bv_bucket_count));
            let bucket = dynamic_field::borrow_mut(bv_id, i_bucket);
            bv.length = bv_length - 1;
            // Push popped element to end of bucket i_bucket
            vector::push_back(bucket, popped_element);
            // Swap element at index i_slot with last element then remove from bucket i_bucket
            vector::swap_remove(bucket, i_slot)
        } else {
            // Check if last bucket has only one element, and if so delete it
            if (bv_length % bv_bucket_size == 1) {
                let bucket = dynamic_field::remove(bv_id, bv_bucket_count);
                let popped_element = vector::pop_back(&mut bucket);
                vector::destroy_empty(bucket);
                bv.length = bv_length - 1;
                bv.bucket_count = bv_bucket_count;
                popped_element
            } else {
                bv.length = bv_length - 1;
                vector::swap_remove(dynamic_field::borrow_mut(bv_id, bv_bucket_count), i % bv_bucket_size)
            }
        }
    }
    /// Destroys `bv`. Aborts if `bv` is not empty.
    public fun destroy_empty<E:store>(bv: BigVector<E>) {
        let BigVector {
            id,
            bucket_count: _,
            bucket_size: _,
            length
        } = bv;
        assert!(length == 0, EBigVectorNotEmpty);
        object::delete(id);
    }
    #[allow(unused_type_parameter)]
    /// Drops a possibly non-empty `bv`. Usable only if the `E` has the `drop` ability.
    public fun drop<E:store+drop>(bv: BigVector<E>) {
        let BigVector {
            id,
            bucket_count: _,
            bucket_size: _,
            length: _,
        } = bv;
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
            let element_size_in_bytes = 64_000;
            
            let bv = empty<u64>(element_size_in_bytes, ctx);
            assert!(bv.bucket_size == 3, 1);
            assert!(bv.bucket_count == 0, 2);
            assert!(bv.length == 0, 3);
            test_utils::destroy(bv);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_singleton() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let element_size_in_bytes = 64_000;
            
            let bv = singleton(1010101, element_size_in_bytes, ctx);
            assert!(bv.bucket_size == 3, 1);
            assert!(bv.bucket_count == 1, 2);
            assert!(bv.length == 1, 3);
            test_utils::destroy(bv);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_is_empty() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let element_size_in_bytes = 64_000;
            
            let bv = empty<u64>(element_size_in_bytes, ctx);
            assert!(is_empty(& bv), 1);
            test_utils::destroy(bv);
        };
        test_scenario::next_tx(&mut scenario, user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let element_size_in_bytes = 64_000;
            
            let bv = singleton(1010101, element_size_in_bytes, ctx);
            assert!(!is_empty(& bv), 2);
            test_utils::destroy(bv);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_length() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let element_size_in_bytes = 64_000;
            
            let bv = empty<u64>(element_size_in_bytes, ctx);
            assert!(length(& bv) == 0, 1);
            test_utils::destroy(bv);
        };
        test_scenario::next_tx(&mut scenario, user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let element_size_in_bytes = 64_000;
            
            let bv = singleton(1010101, element_size_in_bytes, ctx);
            assert!(length(& bv) == 1, 2);
            test_utils::destroy(bv);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_bucket_count() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let element_size_in_bytes = 64_000;
            
            let bv = empty<u64>(element_size_in_bytes, ctx);
            assert!(bucket_count(& bv) == 0, 1);
            test_utils::destroy(bv);
        };
        test_scenario::next_tx(&mut scenario, user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let element_size_in_bytes = 64_000;
            
            let bv = singleton(1010101, element_size_in_bytes, ctx);
            assert!(bucket_count(& bv) == 1, 2);
            test_utils::destroy(bv);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_push_back() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let element_size_in_bytes = 64_000;
            
            let bv = empty<u64>(element_size_in_bytes, ctx);
            assert!(bv.bucket_size == 3, 1);
            assert!(bv.bucket_count == 0, 2);
            assert!(bv.length == 0, 3);

            let i = 0;
            while (i < 100) {
                push_back(&mut bv, i);
                assert!(bv.bucket_count == (i / bv.bucket_size) + 1, 1);
                assert!(bv.length == i + 1, 2);
                i = i + 1;
            };
            i = 0;
            while (i < 100) {
                assert!(*borrow(& bv, i) == i, 3);
                assert!(*borrow_mut(&mut bv, i) == i, 4);
                i = i + 1;
            };

            test_utils::destroy(bv);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_pop_back() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let element_size_in_bytes = 64_000;
            
            let bv = empty<u64>(element_size_in_bytes, ctx);
            assert!(bv.bucket_size == 3, 1);
            assert!(bv.bucket_count == 0, 2);
            assert!(bv.length == 0, 3);

            let i = 0;
            while (i < 100) {
                push_back(&mut bv, i);
                assert!(bv.bucket_count == (i / bv.bucket_size) + 1, 1);
                assert!(bv.length == i + 1, 2);
                i = i + 1;
            };
            while (i > 0) {
                assert!(pop_back(&mut bv) == i - 1, 3);
                i = i - 1;
            };

            test_utils::destroy(bv);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_swap() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let element_size_in_bytes = 64_000;
            
            let bv = empty<u64>(element_size_in_bytes, ctx);
            let i = 0;
            while (i < 100) {
                push_back(&mut bv, i);
                i = i + 1;
            };
            
            swap(&mut bv, 5, 10);
            assert!(*borrow(& bv, 5) == 10, 1);
            assert!(*borrow(& bv, 10) == 5, 2);
            
            swap(&mut bv, 22, 22);
            assert!(*borrow(& bv, 22) == 22, 3);

            test_utils::destroy(bv);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_append() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let element_size_in_bytes = 64_000;
            
            let bv = empty<u64>(element_size_in_bytes, ctx);
            assert!(bv.bucket_size == 3, 1);
            assert!(bv.bucket_count == 0, 2);
            assert!(bv.length == 0, 3);

            let i = 0;
            while (i < 100) {
                push_back(&mut bv, i);
                assert!(bv.bucket_count == (i / bv.bucket_size) + 1, 1);
                assert!(bv.length == i + 1, 2);
                i = i + 1;
            };
            append(&mut bv, vector[100, 101, 102]);
            append(&mut bv, vector[103, 104]);
            assert!(bv.bucket_size == 3, 1);
            assert!(bv.bucket_count == 104 / 3 + 1, 2);
            assert!(bv.length == 105, 3);
            i = 105;
            while (i > 0) {
                assert!(pop_back(&mut bv) == i - 1, 3);
                i = i - 1;
            };

            test_utils::destroy(bv);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_swap_remove() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let element_size_in_bytes = 64_000;
            
            let bv = empty<u64>(element_size_in_bytes, ctx);
            let i = 0;
            while (i < 100) {
                push_back(&mut bv, i);
                i = i + 1;
            };
            
            assert!(swap_remove(&mut bv, 10) == 10, 1);
            assert!(*borrow(& bv, 10) == 99, 2);
            assert!(swap_remove(&mut bv, 10) == 99, 3);
            assert!(*borrow(& bv, 10) == 98, 4);
            assert!(swap_remove(&mut bv, 97) == 97, 5);
            *borrow_mut(&mut bv, 10) = 10;
            i = 96;
            while (i > 0) {
                assert!(pop_back(&mut bv) == i, 6);
                i = i - 1;
            };
            assert!(pop_back(&mut bv) == 0, 7);

            test_utils::destroy(bv);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_destroy_empty() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let element_size_in_bytes = 64_000;
            
            let bv = empty<u64>(element_size_in_bytes, ctx);
            assert!(bv.bucket_size == 3, 1);
            assert!(bv.bucket_count == 0, 2);
            assert!(bv.length == 0, 3);

            let i = 0;
            while (i < 100) {
                push_back(&mut bv, i);
                assert!(bv.bucket_count == (i / bv.bucket_size) + 1, 1);
                assert!(bv.length == i + 1, 2);
                i = i + 1;
            };
            while (i > 0) {
                assert!(pop_back(&mut bv) == i - 1, 3);
                i = i - 1;
            };

            destroy_empty(bv);
        };
        test_scenario::end(scenario);
    }
    #[test]
    fun test_drop() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let element_size_in_bytes = 64_000;
            
            let bv = empty<u64>(element_size_in_bytes, ctx);
            assert!(bv.bucket_size == 3, 1);
            assert!(bv.bucket_count == 0, 2);
            assert!(bv.length == 0, 3);

            let i = 0;
            while (i < 100) {
                push_back(&mut bv, i);
                assert!(bv.bucket_count == (i / bv.bucket_size) + 1, 1);
                assert!(bv.length == i + 1, 2);
                i = i + 1;
            };

            drop(bv);
        };
        test_scenario::end(scenario);
    }
}