# Sui Move Extended Standard Library

Extended standard library for the Sui Move language
## Installation
Add the following snippet in your `Move.toml`

```toml
[dependencies.extended]
git = "https://github.com/arniebarnie/Sui-Move-Extended-STD.git"
subdir = "extended"
rev = "testnet"
```
## Modules
### General
* [`0x0::account`](/extended/sources/account.move "Account")
  Permissionless system to create and manage capability for an address.
* [`0x0::box`](/extended/sources/box.move "Box")
  A `Box` is used to place objects without the key ability in global storage.
### Coin Management
* [`0x0::treasury`](/extended/sources/treasury.move "Treasury")
  A `Treasury` allows for multi-coin management by dynamically storing multiple `sui::coin::TreasuryCap<T>`s.
### Collections
* [`0x0::big_vector`](/extended/sources/big_vector.move "BigVector")
  A `BigVector` is a vector-like collection that stores multiple vectors using Sui's dynamic fields. This allows a `BigVector`'s capacity
  to be theoretically unlimited. However, the quantity of operations on `BigVector`'s in a single transaction is bounded by its dynamic field
  accesses as these are capped per transaction. Note that this also means that `BigVector` values with the exact same index-value mapping
  will not be equal, with `==`, at runtime.
* [`0x0::critbit`](/extended/sources/critbit.move "CritBit")
  Copied from [Econia Labs](https://github.com/econia-labs/econia/blob/main/src/move/econia/sources/CritBit.move "CritBit").
  A critical bit (crit-bit) tree is a compact binary prefix tree that supports quick:
    * Membership testing
    * Insertion
    * Deletion
    * Predecessor
    * Successor
    * Iteration
* [`0x0::dyn_set`](/extended/sources/dyn_set.move "DynSet")
  A `DynSet` is a set-like collection that holds keys using Sui's dynamic fields. Note that this also means that 
  `DynSet` values containing the exact same keys will not be equal, with `==`, at runtime.
* [`0x0::linked_bag`](/extended/sources/linked_bag.move "LinkedBag")
  A `LinkedBag` is similar to a `sui::bag::Bag` but the entries are linked together, allowing for ordered insertion and removal.
  Note that all keys are of the same type.
* [`0x0::linked_table_helper`](/extended/sources/linked_table_helper.move "LinkedTable")
  Additional utility methods for `sui::linked_table`.
* [`0x0::map`](/extended/sources/map.move "Map")
  This module is a different implementation of a vector-based map from `sui::vec_map` that allows for easier iteration and
  copying of keys and values.
* [`0x0::table_helper`](/extended/sources/table_helper.move "Table")
* [`0x0::type_bag`](/extended/sources/type_bag.move "TypeBag")
  A `TypeBag` is a `sui::bag::Bag` but where values are keyed by types.
* [`0x0::typed_bag`](/extended/sources/typed_bag.move "TypedBag")
  A `TypedBag` is similar to a `sui::bag::Bag` but except that all keys are of the same type.
### Arithmetic
* [`0x0::fp64`](/extended/sources/fp64.move "FP64")
  An `FP64` is a 64.64 bit fixed point number stored in a `u128`.
* [`0x0::i64`](/extended/sources/i64.move "I64")
  An `I64` is a signed 64-bit integer.
* [`0x0::u64`](/extended/sources/u64.move "u64")
  Mathematical functions for `u64`s.
* [`0x0::u128`](/extended/sources/u128.move "u128")
  Mathematical functions for `u128`s.
* [`0x0::u256`](/extended/sources/u256.move "u256")
  Mathematical functions for `u256`s.
### Ideas/Examples
* [`0x0::ibalance`](/extended/sources/ibalance.move "IBalance")
  An `IBalance` is a balance capable of holding a positive or negative value.
* [`0x0::position`](/extended/sources/position.move "Position")
