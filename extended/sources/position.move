// SPDX-License-Identifier: MIT

module 0x0::position {
//======================================================== IMPORTS ============================================================//
    use 0x0::u64::{Self};
    use 0x0::fp64::{Self, FP64};
    use 0x1::type_name::{Self, TypeName};
    use sui::object::{Self, UID};
    use 0x2::balance::{Self, Balance, Supply};
    use 0x2::table::{Self, Table};
    use 0x2::clock::{Self, Clock};
    use 0x2::transfer::{Self};
    use sui::tx_context::{Self, TxContext};
    use 0x2::event::{Self};
//======================================================= ERROR CODES =========================================================//
    const ETypeRegistered: u64 = 4;
    const ETypeNotRegistered: u64 = 5;
    const EPoolSettled: u64 = 6;
    const EPoolNotSettled: u64 = 7;
    const EBalanceValueMismatch: u64 = 8;
    const ENotEmpty: u64 = 9;
//========================================================== EVENTS ===========================================================//
    struct RegisterCreated has copy, drop {
        registry: address
    }
    struct PoolCreated<phantom T> has copy, drop {
        pool: address,
        creator: address,
        collateral: TypeName,
        rate: FP64,
        metadata: vector<u8>
    }
//========================================================= OBJECTS ===========================================================//
    // Type for position on type T
    struct Position<phantom T> has drop { }
    // Type for note for collateral locked in position pool
    struct Note<phantom T> has drop { }
    // Pool for collateral locked for positions
    struct Pool<phantom T, phantom Q> has key {
        id: UID,
        rate: FP64,
        winning: FP64,
        collateral: Balance<Q>,
        closure: u64,
        position_supply: Supply<Position<T>>,
        note_supply: Supply<Note<T>>
    }
    struct PoolData has store, copy, drop {
        pool_id: address,
        metadata: vector<u8>
    }
    // Singleton registry for position pools
    struct PoolRegistry has key {
        id: UID,
        registered: Table<TypeName, PoolData>
    }
//========================================================= METHODS ===========================================================//
    // Module initializer
    // Create pool registry singleton
    fun init(ctx: &mut TxContext) {
        let id = object::new(ctx);
        event::emit(RegisterCreated {
            registry: object::uid_to_address(& id)
        });
        transfer::share_object(
            PoolRegistry {
                id,
                registered: table::new(ctx),
            }
        );
    }
    // Get (address, metadata) for pool of given type
    public fun get<T>(registry: & PoolRegistry): (address, vector<u8>) {
        let t_name = type_name::get<T>();
        assert!(table::contains(& registry.registered, t_name), ETypeNotRegistered);
        let data = table::borrow(& registry.registered, t_name);
        (data.pool_id, data.metadata)
    }
    // Create new position pool
    // Must own type of positions
    public fun new<T:drop,Q>(registry: &mut PoolRegistry, _: T, rate: FP64, closure: u64, metadata: vector<u8>, ctx: &mut TxContext): address {
        let t_name = type_name::get<T>();
        assert!(!table::contains(& registry.registered, t_name), ETypeRegistered);
        let id = object::new(ctx);
        let pool_id = object::uid_to_address(& id);
        table::add(&mut registry.registered, t_name, PoolData {
            pool_id,
            metadata
        });
        event::emit(PoolCreated<T> {
            pool: pool_id,
            creator: tx_context::sender(ctx),
            collateral: type_name::get<Q>(),
            rate,
            metadata
        });
        transfer::share_object(
            Pool<T,Q> {
                id,
                rate,
                winning: fp64::zero(),
                collateral: balance::zero(),
                closure,
                position_supply: balance::create_supply(Position { }),
                note_supply: balance::create_supply(Note { })
            }
        );
        pool_id
    }
    // Get pool ID
    public fun id<T,Q>(pool: & Pool<T,Q>): address {
        object::uid_to_address(& pool.id)
    }
    // Get pool collateralization rate
    public fun rate<T,Q>(pool: & Pool<T,Q>): FP64 {
        pool.rate
    }
    // Get pool collateral total
    public fun collateral<T,Q>(pool: & Pool<T,Q>): u64 {
        balance::value(& pool.collateral)
    }
    // Check if pool is settled
    public fun settled<T,Q>(pool: & Pool<T,Q>, clock: & Clock): bool {
        clock::timestamp_ms(clock) >= pool.closure
    }
    // Get winning position winning rate
    public fun winning<T,Q>(pool: & Pool<T,Q>): FP64 {
        pool.winning
    }
    // Calculate collateral needed for position creation
    public fun needed<T,Q>(pool: & Pool<T,Q>, quantity: u64): u64 {
        if (quantity == 0) 0
        else u64::norm(fp64::prod(quantity, pool.rate))
    }
    // Underwrite position with collateral
    public fun underwrite<T,Q>(pool: &mut Pool<T,Q>, quantity: u64, collateral: &mut Balance<Q>, clock: & Clock)
                              : (Balance<Position<T>>, Balance<Note<T>>) {
        assert!(clock::timestamp_ms(clock) < pool.closure, EPoolSettled);
        if (quantity > 0) { 
            balance::join(&mut pool.collateral, balance::split(collateral, u64::norm(fp64::prod(quantity, pool.rate))));
        };
        (balance::increase_supply(&mut pool.position_supply, quantity), balance::increase_supply(&mut pool.note_supply, quantity))
    }
    // Close position with note to release collateral
    public fun close<T,Q>(pool: &mut Pool<T,Q>, position: Balance<Position<T>>, note: Balance<Note<T>>, collateral: &mut Balance<Q>,
                          clock: & Clock) {
        assert!(clock::timestamp_ms(clock) < pool.closure, EPoolSettled);
        let quantity = balance::value(& position);
        assert!(quantity == balance::value(& note), EBalanceValueMismatch);
        balance::join(collateral, balance::split(&mut pool.collateral, fp64::prod(quantity, pool.rate)));
        balance::decrease_supply(&mut pool.position_supply, position);
        balance::decrease_supply(&mut pool.note_supply, note);
    }
    // Collateral locked under note
    public fun locked<T,Q>(pool: & Pool<T,Q>, note: & Balance<Note<T>>): u64 {
        if (balance::value(note) == 0) 0
        else u64::norm(fp64::prod(balance::value(note), pool.rate))
    }
    // Update position pool winnings rate
    public fun update<T:drop,Q>(pool: &mut Pool<T,Q>, _: T, winning: FP64, clock: & Clock) {
        assert!(clock::timestamp_ms(clock) < pool.closure, EPoolSettled);
        pool.winning = winning;
    }
    // Claim winnings for position from settled pool
    public fun claim<T,Q>(pool: &mut Pool<T,Q>, position: Balance<Position<T>>, clock: & Clock): Balance<Q> {
        assert!(clock::timestamp_ms(clock) >= pool.closure, EPoolNotSettled);
        balance::split(&mut pool.collateral, fp64::prod(balance::decrease_supply(&mut pool.position_supply, position), 
                                                        pool.winning))
    }
    // Unlock remaining collateral for note from settled pool
    public fun unlock<T,Q>(pool: &mut Pool<T,Q>, note: Balance<Note<T>>, clock: & Clock): Balance<Q> {
        assert!(clock::timestamp_ms(clock) >= pool.closure, EPoolNotSettled);
        balance::split(&mut pool.collateral, fp64::prod(balance::decrease_supply(&mut pool.note_supply, note), 
                                                        fp64::sub(pool.rate, pool.winning)))
    }
    // Empty collateral pool after all positions and notes settled
    public fun drain<T:drop,Q>(pool: &mut Pool<T,Q>, _: T, clock: & Clock): Balance<Q> {
        assert!(clock::timestamp_ms(clock) >= pool.closure, EPoolNotSettled);
        assert!(balance::supply_value(& pool.position_supply) == 0 && balance::supply_value(& pool.note_supply) == 0, ENotEmpty);
        balance::withdraw_all(&mut pool.collateral)
    }
//========================================================== TESTS ============================================================//
    #[test_only]
    struct X has drop { }
    struct Y has drop { }
    #[test_only]
    use 0x2::test_scenario;
    #[test_only]
    use 0x2::test_utils;
    #[test]
    fun position_test() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let clock = clock::create_for_testing(ctx);
            let supply = balance::create_supply(Y { });
            let pool = Pool<X,Y> {
                id: object::new(ctx),
                rate: fp64::int(1),
                winning: fp64::zero(),
                collateral: balance::zero(),
                closure: clock::timestamp_ms(& clock) + 100,
                position_supply: balance::create_supply(Position { }),
                note_supply: balance::create_supply(Note { })
            };
            assert!(id(& pool) == object::uid_to_address(& pool.id), 1);
            assert!(rate(& pool) == pool.rate, 2);
            assert!(collateral(& pool) == 0, 3);
            assert!(!settled(& pool, & clock), 4);
            assert!(needed(& pool, 10) == 10, 5);
            let collateral = balance::increase_supply(&mut supply, 20);
            let (position, note) = underwrite(&mut pool, 10, &mut collateral, & clock);
            assert!(balance::value(& collateral) == 10, 6);
            assert!(balance::value(& position) == 10, 7);
            assert!(balance::value(& note) == 10, 8);
            assert!(locked(& pool, & note) == 10, 9);
            close(&mut pool, balance::split(&mut position, 5), balance::split(&mut note, 5), &mut collateral, & clock);
            assert!(balance::value(& collateral) == 15, 10);
            assert!(balance::value(& position) == 5, 11);
            assert!(balance::value(& note) == 5, 12);
            assert!(locked(& pool, & note) == 5, 13);
            update(&mut pool, X { }, fp64::frac(1,2), & clock);
            clock::increment_for_testing(&mut clock, 200);
            assert!(settled(& pool, & clock), 14);
            let winnings = claim(&mut pool, position, & clock);
            let remaining = unlock(&mut pool, note, & clock);
            let left = drain(&mut pool, X { }, & clock);
            assert!(balance::value(& winnings) == 2, 15);
            assert!(balance::value(& remaining) == 2, 16);
            assert!(balance::value(& left) == 1, 17);
            assert!(balance::value(& pool.collateral) == 0, 18);
            test_utils::destroy(left);
            test_utils::destroy(remaining);
            test_utils::destroy(winnings);
            test_utils::destroy(collateral);
            test_utils::destroy(pool);
            test_utils::destroy(supply);
            test_utils::destroy(clock);
        };
        test_scenario::end(scenario);
    }
}