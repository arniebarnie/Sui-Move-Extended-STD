// SPDX-License-Identifier: MIT

module 0x0::ibalance {
//======================================================== IMPORTS ============================================================//
    use 0x0::i64::{Self, I64};
	use 0x2::balance::Supply;
//======================================================= ERROR CODES =========================================================//
    const ENotEnough: u64 = 4;
    const ENotEmpty: u64 = 5;
//========================================================= OBJECTS ===========================================================//
    // Balance capable of holding a positive or negative value
    struct IBalance<phantom T> has store { 
            value: I64 
    }
//========================================================= METHODS ===========================================================//
    // Create a balance with a value
	public fun mint<T>(_: &mut Supply<T>, value: I64): IBalance<T> {
			IBalance { value }
	}
	// Create a zero balance
    public fun zero<T>(): IBalance<T> {
            IBalance { value: i64::zero() }
    }
    // Get value of balance
    public fun get<T>(balance: & IBalance<T>): I64 {
            balance.value
    }
    // Join value of balance to another balance
    public fun join<T>(self: &mut IBalance<T>, balance: IBalance<T>) {
        let IBalance { value } = balance;
        self.value = i64::add(self.value, value);
    }
    // Merge two balances
    public fun merge<T>(self: IBalance<T>, balance: IBalance<T>): IBalance<T> {
        let IBalance { value } = balance;
        self.value = i64::add(self.value, value);
        self
    }
    // Pull positive balances (previously held, newly created) from balance
    public fun pull<T>(self: &mut IBalance<T>, value: u64): (IBalance<T>, IBalance<T>) {
        let value = i64::i64(value);
        let value_1 = i64::min(value, self.value);
        let value_2 = i64::sub(value, value_1);
        self.value = i64::sub(self.value, value);
        (IBalance { value: value_1 }, IBalance { value: value_2 })
    }
    // Split balance from balance (Only pulls from positive value of balance)
    public fun split<T>(self: &mut IBalance<T>, value: u64): IBalance<T> {
        let value = i64::i64(value);
        assert!(i64::gte(self.value, value), ENotEnough);
        self.value = i64::sub(self.value, value);
        IBalance { value }
    }
    // Destroy balance
    public fun destroy<T>(balance: IBalance<T>) {
        let IBalance { value } = balance;
		assert!(value == i64::zero(), ENotEmpty);
    }
	// Burn balance
	public fun burn<T>(_: &mut Supply<T>, balance: IBalance<T>) {
		let IBalance { value: _ } = balance;
	}
//========================================================== TESTS ============================================================//
	#[test_only]
	struct X has drop { }
	#[test]
	fun zero_test() {
		let balance = zero<X>();
		assert!(balance.value == i64::zero(), 1);
		let IBalance { value: _ } = balance;
	}
	#[test]
	fun get_test() {
		let balance = zero<X>();
		assert!(get(& balance) == i64::zero(), 1);
		let IBalance { value: _ } = balance;
		let balance = IBalance<X> { value: i64::i64(5) };
		assert!(get(& balance) == i64::i64(5), 1);
		let IBalance { value: _ } = balance;
		let balance = IBalance<X> { value: i64::neg(i64::i64(5)) };
		assert!(get(& balance) == i64::neg(i64::i64(5)), 1);
		let IBalance { value: _ } = balance;
	}
	#[test]
	fun join_test() {
		let balance = zero<X>();
		let balance_1 = IBalance<X> { value: i64::i64(5) };
		join(&mut balance, balance_1);
		assert!(balance.value == i64::i64(5), 1);
		let balance_2 = IBalance<X> { value: i64::neg(i64::i64(5)) };
		join(&mut balance, balance_2);
		assert!(balance.value == i64::zero(), 1);
		let IBalance { value: _ } = balance;
	}
	#[test]
	fun merge_test() {
		let balance_1 = IBalance<X> { value: i64::i64(5) };
		let balance_2 = IBalance<X> { value: i64::neg(i64::i64(5)) };
		let balance = merge(balance_1, balance_2);
		assert!(balance.value == i64::zero(), 1);
		let IBalance { value: _ } = balance;
	}
	#[test]
	fun pull_test() {
		let balance = IBalance<X> { value: i64::i64(5) };
		let (balance_1, balance_2) = pull(&mut balance, 3);
		assert!(balance_1.value == i64::i64(3), 1);
		assert!(balance_2.value == i64::zero(), 1);
		let IBalance { value: _ } = balance_1;
		let IBalance { value: _ } = balance_2;
		let (balance_1, balance_2) = pull(&mut balance, 3);
		assert!(balance_1.value == i64::i64(2), 1);
		assert!(balance_2.value == i64::i64(1), 1);
		assert!(balance.value == i64::neg(i64::i64(1)), 1);
		let IBalance { value: _ } = balance_1;
		let IBalance { value: _ } = balance_2;
		let IBalance { value: _ } = balance;
	}
	#[test]
	fun split_test() {
		let balance = IBalance<X> { value: i64::i64(5) };
		let balance_1 = split(&mut balance, 3);
		assert!(balance_1.value == i64::i64(3), 1);
		assert!(balance.value == i64::i64(2), 1);
		let IBalance { value: _ } = balance_1;
		let IBalance { value: _ } = balance;
	}
	#[test]
	#[expected_failure]
	fun split_test_fail() {
		let balance = IBalance<X> { value: i64::i64(5) };
		let balance_1 = split(&mut balance, 6);
		let IBalance { value: _ } = balance_1;
		let IBalance { value: _ } = balance;
	}
	#[test]
	fun destroy_test() {
		let balance = IBalance<X> { value: i64::zero() };
		destroy(balance);
	}
	#[test]
	#[expected_failure]
	fun destroy_test_fail() {
		let balance = IBalance<X> { value: i64::i64(5) };
		destroy(balance);
	}
}