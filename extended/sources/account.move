// SPDX-License-Identifier: MIT

/// Permissionless system to create and manage capability for an address.
module 0x0::account {
//======================================================== IMPORTS ============================================================//
    use sui::object::{Self, UID};
    use 0x2::tx_context::TxContext;
//========================================================= OBJECTS ===========================================================//
    /// Account capability for address
    struct Account has key, store {
        id: UID, // UID of the account
        account_id: address // Address of the account
    }
//========================================================= METHODS ===========================================================//
    /// Returns new capability for an account ID.
    public fun new(ctx: &mut TxContext): Account {
        let id = object::new(ctx);
        let account_id = object::uid_to_address(& id);
        Account {
            id,
            account_id
        }
    }
    /// Returns duplicate of capability for account ID.
    public fun duplicate(account: & Account, ctx: &mut TxContext): Account {
        Account {
            id: object::new(ctx),
            account_id: account.account_id
        }
    }
    /// Returns account ID of capability.
    public fun id(account: & Account): address {
        account.account_id
    }
    /// Destroy capability for account ID.
    public fun destroy(account: Account): address {
        let Account {
            id,
            account_id
        } = account;
        object::delete(id);
        account_id
    }
//========================================================== TESTS ============================================================//
    #[test_only]
    use 0x2::test_scenario;
    #[test]
    fun test() {
        let user = @0xBABE;
        let scenario = test_scenario::begin(user);
        {
            let account = new(test_scenario::ctx(&mut scenario));
            assert!(account.account_id == object::uid_to_address(& account.id), 1);
            let account_copy = duplicate(& account, test_scenario::ctx(&mut scenario));
            assert!(account_copy.account_id == account.account_id, 2);
            destroy(account);
            destroy(account_copy);
        };
        test_scenario::end(scenario);
    }
}