# fltrECC
Swift wrapper for Bitcoin Core libsecp256k1

## Using
Add a reference to your `Package.swift` file under
```swift
dependencies: [
    ...
    .package(url: "https://github.com/fltrWallet/fltrECC", .branch("main")),
    ...
],
```


## Scalar and Point
The most primitive constructs for doing ECC (elliptic curve cryptography). Scalars can be used to instantiate secret keys while Points create public key.

The major difference here between secret keys and scalars (and public keys and points) are that many unsafe operations can be performed directly on Scalars and Points.

For example
```swift
let first = Scalar.random()
let second = Scalar.random()
let third = first * second + first
```
This requires significant understanding of elliptic curve arithmatic but is none the less essential in creating libraries for generating private keys, such as BIP32.

## Optional results
Addition resulting in infinity is statistically next to impossible in its frequency. Some libraries (rightly) treat such occurence as less likely than hardware error. Meaning they wont even check for their occurence. Since Swift is such a handy language at treating optionals, we have gone for the most conservative interpretation of such operations. Consider the following example: 
```swift
let a = Scalar.random()
let b = Scalar.random()
guard let x = a + b else { throw Infinity() }
```
There is this theoretical chance that the addition results in `x = 0`, which is not within the domain for elliptic curve operations.

## SecretKey and PublicKey
There are two sets of secret and public keys. One set starting with DSA for the old way of encoding, decoding and encrypting. Schnorr signatures and their updated encoding are implemented under the X prefix. Operations for recoverable signatures and diffie hellman secret sharing are only available in the DSA types.

## fltrECCTesting
There is a testing library to simplify writing unit tests or integration tests where ECC types are needed. It provides for numerical types instead of its formal counterparts. Let us have a look at an example explaining its use:
```swift
import fltrECC
import fltrECCTesting

let scalar: Scalar = 12
let publicKey = X.PublicKey(15)```
