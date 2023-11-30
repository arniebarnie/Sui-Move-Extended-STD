// SPDX-License-Identifier: MIT

module 0x0::positions {
//======================================================== IMPORTS ============================================================//
    use 0x0::u64;
    use 0x0::fp64::{Self, FP64};
    use sui::object::{Self, UID};
    use 0x2::balance::{Self, Balance};
    use 0x2::tx_context::TxContext;
//======================================================= ERROR CODES =========================================================//
    const EPoolIDMismatch: u64 = 4;
    const EInsufficientPositionValue: u64 = 5;
    const EPositionValueMismatch: u64 = 6;
    const EPoolNotSettled: u64 = 7;
    const EPoolSettled: u64 = 8;
    const ENotEmpty: u64 = 9;
//========================================================= OBJECTS ===========================================================//
    // Holds negative position value
    struct Negative has store { 
        pool_id: address, // Pool ID
        cost: FP64, // Collateralization rate
        value: u64, // Position value
    }
    // Holds positive position value
    struct Positive has store { 
        pool_id: address, // Pool ID
        value: u64, // Position value
    }
    // Holds pool of collateralized positions
    struct Pool<phantom Q> has key, store {
        id: UID, // Pool ID
        rate: FP64, // Collateralization then settlement rate
        collateral: Balance<Q>, // Total collateral
        settled: bool // Whether the pool is settled
    }
//========================================================= METHODS ===========================================================//
    // Create new pool
    public fun new<Q>(rate: FP64, ctx: &mut TxContext): Pool<Q> {
        Pool {
            id: object::new(ctx),
            rate,
            collateral: balance::zero(),
            settled: false
        }
    }
    // Get position pool ID
    public fun id<Q>(pool: & Pool<Q>): address {
        object::uid_to_address(& pool.id)
    }
    // Get position pool collateralization or eventually settlement rate
    public fun rate<Q>(pool: & Pool<Q>): FP64 {
        pool.rate
    }
    // Get position pool collateral total
    public fun total<Q>(pool: & Pool<Q>): u64 {
        balance::value(& pool.collateral)
    }
    // Check if position pool is settled
    public fun settled<Q>(pool: & Pool<Q>): bool {
        pool.settled
    }
    // Create new zero negative position
    public fun negative_zero<Q>(pool: & Pool<Q>): Negative {
        assert!(!pool.settled, EPoolSettled);
        Negative { 
            pool_id: object::uid_to_address(& pool.id),
            cost: pool.rate,
            value: 0
        }
    }
    // Create new zero positive position
    public fun positive_zero<Q>(pool: & Pool<Q>): Positive {
        assert!(!pool.settled, EPoolSettled);
        Positive { 
            pool_id: object::uid_to_address(& pool.id),
            value: 0
        }
    }
    // Pool ID of positive position
    public fun positive_id(self: & Positive): address {
        self.pool_id
    }
    // Pool ID of negative position
    public fun negative_id(self: & Negative): address {
        self.pool_id
    }
    // Value of positive position
    public fun positive_value(position: & Positive): u64 {
        position.value
    }
    // Value of negative position
    public fun negative_value(position: & Negative): u64 {
        position.value
    }
    // Collateralization rate of negative position
    public fun cost(position: & Negative): FP64 {
        position.cost
    }
    // Get quantity of collateral locked in position
    public fun collateral(position: & Negative): u64 {
        // Collateral locked always at least 1
        if (position.value == 0) 0
        else u64::norm(fp64::prod(position.value, position.cost))
    }
    // Join positive position to another
    public fun join(self: &mut Positive, position: Positive) {
        let Positive {
            pool_id,
            value
        } = position;
        assert!(self.pool_id == pool_id, EPoolIDMismatch);
        self.value = self.value + value;
    }
    // Join negative position to another
    public fun fill(self: &mut Negative, position: Negative) {
        let Negative {
            pool_id,
            cost: _,
            value
        } = position;
        assert!(self.pool_id == pool_id, EPoolIDMismatch);
        self.value = self.value + value;
    }
    // Merge two positive positions
    public fun add(self: Positive, position: Positive): Positive {
        let Positive {
            pool_id,
            value
        } = position;
        assert!(self.pool_id == pool_id, EPoolIDMismatch);
        self.value = self.value + value;
        self
    }
    // Merge two negative positions
    public fun merge(self: Negative, position: Negative): Negative {
        let Negative {
            pool_id,
            cost: _,
            value
        } = position;
        assert!(self.pool_id == pool_id, EPoolIDMismatch);
        self.value = self.value + value;
        self
    }
    // Split positive position from another
    public fun split(self: &mut Positive, quantity: u64): Positive {
        assert!(self.value >= quantity, EInsufficientPositionValue);
        self.value = self.value - quantity;
        Positive {
            pool_id: self.pool_id,
            value: quantity
        }
    }
    // Split negative position from another
    public fun pull(self: &mut Negative, quantity: u64): Negative {
        assert!(self.value >= quantity, EInsufficientPositionValue);
        self.value = self.value - quantity;
        Negative {
            pool_id: self.pool_id,
            cost: self.cost,
            value: quantity
        }
    }
    // Collateral needed for position creation
    public fun needed(position: & Negative, quantity: u64): u64 {
        // Collateral locked always at least 1
        if (quantity == 0) 0
        else u64::norm(fp64::prod(quantity, position.cost))
    }
    // Create new negative and positive position with collateral
    public fun create<Q>(pool: &mut Pool<Q>, quantity: u64, balance: &mut Balance<Q>): (Negative, Positive) {
        assert!(!pool.settled, EPoolSettled);
        let pool_id = object::uid_to_address(& pool.id);
        if (quantity > 0) {
            balance::join(&mut pool.collateral, balance::split(balance, u64::norm(fp64::prod(quantity, pool.rate))));
        };
        (Negative {
            pool_id,
            cost: pool.rate,
            value: quantity
        },
        Positive {
            pool_id,
            value: quantity
        })
    }
    // Close negative and positive position and return collateral
    public fun close<Q>(pool: &mut Pool<Q>, negative: Negative, positive: Positive, balance: &mut Balance<Q>) {
        assert!(!pool.settled, EPoolSettled);
        let Negative {
            pool_id,
            cost,
            value
        } = negative;
        let Positive {
            pool_id: positive_id,
            value: pos_val
        } = positive;
        assert!(pool_id == positive_id, EPoolIDMismatch);
        assert!(value == pos_val, EPositionValueMismatch);
        if (value > 0) {
            balance::join(balance, balance::split(&mut pool.collateral, u64::norm(fp64::prod(value, cost))));
        };
    }
    // Settle position pool
    public fun settle<Q>(pool: &mut Pool<Q>, rate: FP64) {
        assert!(!pool.settled, EPoolSettled);
        pool.rate = rate;
        pool.settled = true;
    }
    // Claim winnings for positive position from settled pool
    public fun claim<Q>(pool: &mut Pool<Q>, positive: Positive): Balance<Q> {
        assert!(pool.settled, EPoolNotSettled);
        let Positive {
            pool_id,
            value
        } = positive;
        assert!(pool_id == object::uid_to_address(& pool.id), EPoolIDMismatch);
        if (value == 0) balance::zero()
        else balance::split(&mut pool.collateral, fp64::prod(value, fp64::sub(fp64::int(1), pool.rate)))
    }
    // Unlock remaining collateral for negative position from settled pool
    public fun unlock<Q>(pool: &mut Pool<Q>, negative: Negative): Balance<Q> {
        assert!(pool.settled, EPoolNotSettled);
        let Negative {
            pool_id,
            cost: _,
            value
        } = negative;
        assert!(pool_id == object::uid_to_address(& pool.id), EPoolIDMismatch);
        if (value == 0) balance::zero()
        else balance::split(&mut pool.collateral, u64::norm(fp64::prod(value, pool.rate)))
    }
    // Destroy zero positive position
    public fun destroy_positive(position: Positive) {
        let Positive {
            pool_id: _,
            value
        } = position;
        assert!(value == 0, ENotEmpty);
    }
    // Destroy zero negative position
    public fun destroy_negative(position: Negative) {
        let Negative {
            pool_id: _,
            cost: _,
            value
        } = position;
        assert!(value == 0, ENotEmpty);
    }
    // Drain all collateral from position pool
    public(friend) fun collect<Q>(pool: &mut Pool<Q>): Balance<Q> {
        balance::withdraw_all(&mut pool.collateral)
    }
//========================================================== TESTS ============================================================//
    #[test_only]
    struct X has drop { }
    #[test_only]
    use 0x2::test_scenario;
    use 0x2::test_utils;
    #[test]
    fun position_test() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let supply = balance::create_supply(X { });

            let pool = new<X>(fp64::int(1), ctx);
            assert!(id(& pool) == object::uid_to_address(& pool.id), 1);
            assert!(rate(& pool) == fp64::int(1), 2);
            assert!(total(& pool) == 0, 3);
            assert!(!settled(& pool), 4);

            let neg = negative_zero(& pool);
            let pos = positive_zero(& pool);
            assert!(negative_id(& neg) == id(& pool), 5);
            assert!(positive_id(& pos) == id(& pool), 6);
            assert!(negative_value(& neg) == 0, 7);
            assert!(positive_value(& pos) == 0, 8);
            assert!(cost(& neg) == fp64::int(1), 9);
            assert!(collateral(& neg) == 0, 10);

            fill(&mut neg, Negative { pool_id: id(& pool), cost: pool.rate, value: 5 });
            join(&mut pos, Positive { pool_id: id(& pool), value: 5 });
            assert!(negative_id(& neg) == id(& pool), 11);
            assert!(positive_id(& pos) == id(& pool), 12);
            assert!(negative_value(& neg) == 5, 13);
            assert!(positive_value(& pos) == 5, 14);
            assert!(cost(& neg) == fp64::int(1), 15);
            assert!(collateral(& neg) == 5, 16);

            let neg = merge(neg, Negative { pool_id: id(& pool), cost: pool.rate, value: 5 });
            let pos = add(pos, Positive { pool_id: id(& pool), value: 5 });
            assert!(negative_id(& neg) == id(& pool), 17);
            assert!(positive_id(& pos) == id(& pool), 18);
            assert!(negative_value(& neg) == 10, 19);
            assert!(positive_value(& pos) == 10, 20);
            assert!(cost(& neg) == fp64::int(1), 21);
            assert!(collateral(& neg) == 10, 22);
            test_utils::destroy(pull(&mut neg, 10));
            test_utils::destroy(split(&mut pos, 10));
            assert!(needed(& neg, 25) == 25, 23);

            destroy_negative(neg);
            destroy_positive(pos);

            let col_bal = balance::increase_supply(&mut supply, 20);
            let (neg, pos) = create(&mut pool, 20, &mut col_bal);
            assert!(balance::value(& col_bal) == 0, 24);
            assert!(negative_id(& neg) == id(& pool), 25);
            assert!(positive_id(& pos) == id(& pool), 26);
            assert!(negative_value(& neg) == 20, 27);
            assert!(positive_value(& pos) == 20, 28);
            assert!(cost(& neg) == fp64::int(1), 29);
            assert!(collateral(& neg) == 20, 30);
            close(&mut pool, neg, pos, &mut col_bal);
            assert!(balance::value(& col_bal) == 20, 31);
            test_utils::destroy(col_bal);

            test_utils::destroy(pool);
            test_utils::destroy(supply);
        };
        test_scenario::end(scenario);
    }
}