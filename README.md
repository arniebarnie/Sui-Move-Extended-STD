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
* [`0x0::box`](/extended/sources/box.move "Box")
### Collections
* [`0x0::big_vector`](/extended/sources/big_vector.move "BigVector")
* [`0x0::critbit`](/extended/sources/critbit.move "CritBit")
* [`0x0::linked_bag`](/extended/sources/linked_bag.move "LinkedBag")
* [`0x0::type_bag`](/extended/sources/type_bag.move "TypeBag")
* [`0x0::typed_bag`](/extended/sources/typed_bag.move "TypedBag")
### Arithmetic
* [`0x0::fp64`](/extended/sources/fp64.move "FP64")
* [`0x0::i64`](/extended/sources/i64.move "I64")
* [`0x0::u64`](/extended/sources/u64.move "u64")
* [`0x0::u128`](/extended/sources/u128.move "u128")
* [`0x0::u256`](/extended/sources/u256.move "u256")
### Ideas/Examples
* [`0x0::ibalance`](/extended/sources/ibalance.move "IBalance")
* [`0x0::position`](/extended/sources/position.move "Position")
