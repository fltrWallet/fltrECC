# fltrECC
Swift wrapper for Bitcoin Core libsecp256k1

## Scalar and Point
The most primitive constructs for doing elliptic curve cryptography. Scalars can be used to instantiate secret keys while Points create public key.

The major difference here between secret keys and scalars (and public keys and points) are that many unsafe operations can be performed directly on Scalars and Points.

For example
```
let first = Scalar.random()
let second = Scalar.random()
let third = first * second + first
```
This requires significant understanding of elliptic curve arithmatic but is none the less essential in creating libraries for generating private keys, such as BIP32.

## Optional results
Addition resulting in infinity is statistically next to impossible in its frequency. Some libraries (rightly) treat such occurence as less likely than hardware error. Meaning they wont even check for their occurence. Since Swift is such a handy language at treating optionals, we have gone for the most conservative interpretation of such operations. Consider the following example: ```
let a = Scalar.random()
let b = Scalar.random()
guard let x = a + b else { throw Infinity() }``` There is this theoretical chance that the addition results in `x = 0`, which is not within the domain for elliptic curve operations.
