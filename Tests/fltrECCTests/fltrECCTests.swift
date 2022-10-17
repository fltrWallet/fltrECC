//===----------------------------------------------------------------------===//
//
// This source file is part of the fltrECC open source project
//
// Copyright (c) 2022 fltrWallet AG and the fltrECC project authors
// Licensed under Apache License v2.0
//
// See LICENSE.md for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import fltrECC
import fltrECCTesting
import XCTest

final class fltrECCTests: XCTestCase {
    func testPointNegate() {
        let s = Scalar(5)
        let p = Point(s)
        let negatedS = -s
        let negatedP = -p
        XCTAssertEqual(Point(negatedS), negatedP)
        XCTAssertEqual(p, -negatedP)
    }
    
    func testPointCombine() {
        let ss = (1...10).map(Scalar.init)
        let ps = ss.map(Point.init)
        let combine = ps[0].combine(ps[1], ps[2], ps[3], ps[4], ps[5], ps[6], ps[7], ps[8], ps[9]) // 55
        XCTAssertEqual(combine, 55)
    }
    
    func testPointAdd() {
        let p1 = Point(1)
        let p2 = Point(2)
        let p3 = p1 + p2
        XCTAssertNotNil(p3)
        guard let p3 else { return }
        XCTAssertEqual(p3, Point(3))
        XCTAssertEqual(p1 + p2, p2 + p1)
        XCTAssertEqual(-p1 - p2, -p2 - p1)
        
        XCTAssertNil(p1 + -p1)
        XCTAssertNil(p1 - 1)
        XCTAssertNil(p2 + -p2)
        XCTAssertNil(p2 - 2)
        XCTAssertNotNil(p1 + -p2)
        XCTAssertNotNil(p2 + -p1)
    }
    
    func testPointMul() {
        let p = Point(200_000)
        let s = Scalar(1_000)
        XCTAssertEqual(p * s, s * p)
        XCTAssertEqual(p * s, Point(200_000_000))
    }
    
    func testPointComparable() {
        let p1 = Point(8)
        let p2 = Point(11)
        XCTAssertLessThan(p1, p2)
        XCTAssertNotEqual(p1, p2)
        let p3 = Point(8)
        XCTAssertNotEqual(p2, p3)
        XCTAssertLessThanOrEqual(p1, p3)
    }

    func testPrivkeyPubkey() {
        let privkey = DSA.SecretKey(5)
        let pubkey = privkey.pubkey()
        XCTAssertEqual(pubkey.serialize(), DSA.PublicKey(5).serialize())
        XCTAssertNotEqual(pubkey.serialize(), DSA.PublicKey(6).serialize())
    }
    
    func testPrivkeySign() {
        let privkey = DSA.SecretKey(200)
        let pubkey = privkey.pubkey()
        let message = (0..<32).map(UInt8.init)
        let signature = privkey.sign(message: message)
        XCTAssert(pubkey.verify(signature: signature, message: message))
    }
    
    func testPrivkeyRecoverable() {
        let privkey = DSA.SecretKey(201)
        let pubkey = privkey.pubkey()
        let message = (0..<32).map(UInt8.init)
        let recoverable = privkey.sign(recoverable: message)
        let signature = recoverable.dsaSignature()
        let pubkeyRecover = recoverable.recover(from: message)
        XCTAssertNotNil(pubkeyRecover)
        guard let pubkeyRecover else { return }
        XCTAssertEqual(pubkey.serialize(), pubkeyRecover.serialize())
        XCTAssert(pubkey.verify(signature: signature, message: message))
    }
    
    func testPrivkeyEcdh() {
        let s10 = DSA.SecretKey(10_000_000_000_000)
        let s20 = DSA.SecretKey(20_000_000_000_000)
        let p10 = s10.pubkey()
        let p20 = s20.pubkey()
        let ecdhAlice = s10.ecdh(p20)
        let ecdhBob = s20.ecdh(p10)
        XCTAssertEqual(ecdhAlice, ecdhBob)
    }
    
    func testDsaSignatureSerialize() {
        let privkey = DSA.SecretKey(200)
        let message = (0..<32).map(UInt8.init)
        let signature = privkey.sign(message: message)
        let serialDer = signature.serializeDer()
        let serialCompact = signature.serializeCompact()
        XCTAssertEqual(DSA.Signature(from: serialDer), signature)
        XCTAssertEqual(DSA.Signature(from: serialCompact), signature)
    }
    
    func testRecoverableSignatureSerialize() {
        let privkey = DSA.SecretKey(202)
        let message = (1..<33).map(UInt8.init)
        let recoverable = privkey.sign(recoverable: message)
        let (serial, id) = recoverable.serialize()
        XCTAssertEqual(DSA.RecoverableSignature(from: serial, id: id), recoverable)
        let signature = DSA.Signature(from: serial)
        XCTAssertNotNil(signature)
        guard let signature else { return }
        
        let pubkey = DSA.PublicKey(202)
        XCTAssert(pubkey.verify(signature: signature, message: message))
    }
    
    func testPubkeySerialize() {
        let pubkey = DSA.PublicKey(1_203_456_689_123_123)
        let compressed = pubkey.serialize(format: .compressed)
        let uncompressed = pubkey.serialize(format: .uncompressed)
        XCTAssertEqual(pubkey, DSA.PublicKey(from: compressed))
        XCTAssertEqual(pubkey, DSA.PublicKey(from: uncompressed))
    }
    
    func testXOnlyFromPubkey() {
        let eight = DSA.PublicKey(8)
        XCTAssertFalse(eight.xOnly().negated)
        XCTAssertEqual(eight.xOnly().xPubkey, .init(8))
        
        let nine = DSA.PublicKey(9)
        XCTAssert(nine.xOnly().negated)
        XCTAssertEqual(nine.xOnly().xPubkey, .init(-9))
    }
    
    func testXPrivkeyPubkey() {
        let privkey = X.SecretKey(5)
        let pubkey = privkey.pubkey().xPoint
        XCTAssertEqual(pubkey.serialize(), X.PublicKey(5).serialize())
        XCTAssertNotEqual(pubkey.serialize(), X.PublicKey(6).serialize())
    }
    
    func testXSecretKeyTweak() {
        let sk2 = X.SecretKey(2)
        let sk3 = X.SecretKey(3)
        
        XCTAssertEqual(sk2.tweak(add: 3), X.SecretKey(5))
        XCTAssertEqual(sk3.tweak(add: 2), sk2.tweak(add: 3))
        XCTAssertNil(sk2.tweak(add: -2))
        XCTAssertEqual(sk2.tweak(add: -2), sk3.tweak(add: -3))
    }
    
    func testXPublicKeyTweak() {
        let pk2 = X.PublicKey(20_000)
        let pk3 = X.PublicKey(30_000)
        XCTAssertEqual(pk2.tweak(add: 30_000), DSA.PublicKey(50_000))
        XCTAssertEqual(pk3.tweak(add: 20_000), pk2.tweak(add: 30_000))
        XCTAssertNil(pk2.tweak(add: -20_000))
        XCTAssertEqual(pk2.tweak(add: -20_000), pk3.tweak(add: -30_000))
    }
    
    func testXPublicKeyCheck() {
        let base = X.PublicKey(3)
        let tweak: [UInt8] = Scalar(2).withUnsafeBytes { Array($0) }
        let check = X.PublicKey(5)
        XCTAssert(check.check(base: base, tweak: tweak, negated: false))
    }
    
    func testXPublicKeyCheckNegated() {
        let base = X.PublicKey(8)
        let tweak: [UInt8] = Scalar(9).withUnsafeBytes { Array($0) }
        let check = X.PublicKey(17)
        XCTAssert(check.check(base: base, tweak: tweak, negated: true))
    }
    
    func testXPublicKeySerialize() {
        let pk = X.PublicKey(123_456_789)
        let serialized = pk.serialize()
        XCTAssertEqual(X.PublicKey(from: serialized), X.PublicKey(123_456_789))
    }
    
    func testXSignVerify() {
        let sk = X.SecretKey(777_999_888_111)
        let pk = X.PublicKey(777_999_888_111)
        XCTAssertEqual(pk, sk.pubkey().xPoint)
        let message = (2..<34).map(UInt8.init)
        let signature = sk.sign(message: message)
        XCTAssert(pk.verify(signature: signature, message: message))
        XCTAssertEqual(signature.serialize(), X.Signature(from: signature.serialize())?.serialize())
    }
    
    func testXPublicKeyDsa() {
        let pk = DSA.PublicKey(-8)
        let x = pk.xOnly()
        XCTAssert(x.negated)
        XCTAssertEqual(x.xPubkey.dsa(), .init(8))
    }
    
    func testRandom() {
        let t1 = DSA.SecretKey.random()
        let t2 = X.SecretKey.random()
        XCTAssert(t1.scalar >= 1)
        XCTAssert(t2.scalar >= 1)
        
        var t3: X.SecretKey!
        for _ in 0..<100 {
            t3 = .random()
            guard t3.scalar < Scalar(Int.max)
            else { return }
        }
        XCTAssertGreaterThanOrEqual(t3.scalar, Scalar(Int.max))
    }
}
