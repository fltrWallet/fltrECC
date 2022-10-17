@testable import fltrECCAdapter
import fltrECCTesting
import XCTest

class CoreTests: XCTestCase {
    override func setUp() {
        self.scalarZero = Scalar(unsafeUninitializedCapacity: 32) { a, s in
            (0..<32).forEach { a[$0] = UInt8(1) }
            s = 32
        }
        self.scalarZero.withUnsafeMutableBytes { scalar in
            (0..<32).forEach { scalar[$0] = UInt8(0) }
        }
        
        self.scalarOutOfOrder = Scalar(unsafeUninitializedCapacity: 32) { a, s in
            (0..<32).forEach { a[$0] = UInt8(1) }
            s = 32
        }
        self.scalarOutOfOrder.withUnsafeMutableBytes { scalar in
            (0..<32).forEach { scalar[$0] = UInt8(255) }
        }
    }
    
    override func tearDown() {
        self.scalarZero = nil
        self.scalarOutOfOrder = nil
    }
    
    private var scalarZero: Scalar!
    private var scalarOutOfOrder: Scalar!
    
    // MARK: Scalar
    func testScalarOneValid() {
        XCTAssertTrue(C.scalarIsValid(scalar: 1))
    }
    
    func testScalarInvalid() {
        XCTAssertFalse(C.scalarIsValid(scalar: self.scalarZero))
        XCTAssertFalse(C.scalarIsValid(scalar: self.scalarOutOfOrder))
    }
    
    func testNegate() {
        let one = Scalar(1)
        let alsoOne = Scalar(1)
        C.negate(into: one)
        XCTAssertNotEqual(one, alsoOne)
        C.negate(into: one)
        XCTAssertEqual(one, alsoOne)
    }
    
    func testAddOne() {
        let one = Scalar(1)
        let alsoOne = Scalar(1)
        XCTAssertNoThrow(try C.add(into: one, scalar: alsoOne))
        XCTAssertEqual(one, 2)
    }
    
    func testAddFail() {
        let one = Scalar(1)
        let negate = Scalar(1)
        C.negate(into: negate)
        XCTAssertThrowsError(try C.add(into: one, scalar: negate))
    }
    
    func testMul() {
        let result = Scalar(2)
        let alsoTwo = Scalar(2)
        XCTAssertNoThrow(try C.mul(into: result, scalar: alsoTwo))
        let four = Scalar(4)
        XCTAssertEqual(result, four)
    }
    
    func testMulFail() {
        let one = Scalar(1)
        let zero = self.scalarZero!
        XCTAssertThrowsError(try C.mul(into: one, scalar: zero))
    }
    
    // MARK: Point
    func testCreatePoint() {
        var result: [UInt8]!
        XCTAssertNoThrow(result = try C.point(from: Scalar(1)))
        XCTAssertNotNil(result)
    }
    
    func testComparePointsEquals() {
        let a = Point(4)
        let b = Point(4)
        XCTAssert(C.comparePoints(a._data, b._data).equals)
    }
    
    func testComparePointsLessThan() {
        let a = Point(2)
        let b = Point(4)
        XCTAssertEqual(C.comparePoints(a._data, b._data), .lessThan)
    }
    
    func testComparePointsGreaterThan() {
        let a = Point(4)
        let b = Point(2)
        XCTAssertEqual(C.comparePoints(a._data, b._data), .greaterThan)
    }
    
    func testNegatePoint() {
        let point = Point(5)._data
        var negated = point
        C.negate(into: &negated)
        XCTAssertNotEqual(point, negated)
        let scalar = Scalar(5)
        C.negate(into: scalar)
        var point2: [UInt8]!
        XCTAssertNoThrow(point2 = try C.point(from: scalar))
        XCTAssertNotNil(point2)
        guard let point2 else { return }
        XCTAssertEqual(negated, point2)
    }
    
    func testAddPoint() {
        var one = Point(1)._data
        let scalarOne = Scalar(1)
        XCTAssertNoThrow(try C.add(into: &one, scalar: scalarOne))
        XCTAssertEqual(one, Point(2)._data)
    }
    
    func testMulPoint() {
        var result = Point(2)._data
        let scalarTwo = Scalar(2)
        XCTAssertNoThrow(try C.mul(into: &result, scalar: scalarTwo))
        XCTAssertEqual(result, Point(4)._data)
    }
    
    func testCombinePoint() {
        var result: [UInt8]!
        let ones = (0..<10).map { _ in
            try! C.point(from: Scalar(1))
        }
        XCTAssertNoThrow(result = try C.combine(points: ones))
        XCTAssertNotNil(result)
        
        let ten = try! C.point(from: Scalar(10))
        let comp = C.comparePoints(result, ten)
        XCTAssert(comp.equals)
    }
    
    func testSerializeDeserialize() {
        let h = Point(100)._data
        let compressed = C.compressed(point: h)
        let uncompressed = C.uncompressed(point: h)
        XCTAssertEqual(compressed.count, 33)
        XCTAssertEqual(uncompressed.count, 65)
        
        var result: [UInt8]!
        XCTAssertNoThrow(result = try C.deSerialize(point: compressed))
        XCTAssertEqual(result, h)
        XCTAssertNoThrow(result = try C.deSerialize(point: uncompressed))
        XCTAssertEqual(result, h)
    }
    
    // MARK: DSA Signature
    func testDSASign() {
        let secret = Scalar(20)
        let pubkey = try! C.point(from: secret)
        let message = (1...32).map(UInt8.init)
        let nonce = (1...32).map { _ in UInt8(1) }
        var signature: [UInt8]!
        var signatureNonce: [UInt8]!
        XCTAssertNoThrow(signature = try C.dsaSign(scalar: secret, message: message, nonce: nil))
        XCTAssertNoThrow(signatureNonce = try C.dsaSign(scalar: secret, message: message, nonce: nonce))
        XCTAssertNotEqual(signature, signatureNonce)
        
        XCTAssert(
            C.verify(dsa: signature, point: pubkey, message: message)
        )
        XCTAssert(
            C.verify(dsa: signatureNonce, point: pubkey, message: message)
        )
    }
    
    // MARK: Extrakeys
    func testSerializeDeserializeXPoint() {
        let point = Point(100)._data
        let (_, xPoint) = C.xPoint(from: point)
        let serialized = C.serialize(xPoint: xPoint)
        XCTAssertEqual(serialized.count, 32)
        
        var result: [UInt8]!
        XCTAssertNoThrow(result = try C.deSerialize(xPoint: serialized))
        XCTAssertNotNil(result)
        XCTAssert(C.compareXPoints(xPoint, result).equals)
    }
    
    func testCompareXPointEquals() {
        let (_, a) = C.xPoint(from: Point(200)._data)
        let (_, b) = C.xPoint(from: Point(200)._data)
        XCTAssert(C.compareXPoints(a, b).equals)
    }
    
    func testCompareXPointLessThan() {
        let (_, a) = C.xPoint(from: Point(2)._data)
        let (_, b) = C.xPoint(from: Point(4)._data)
        XCTAssertEqual(C.compareXPoints(a, b), .lessThan)
    }
    
    func testCompareXPointGreaterThan() {
        let (_, a) = C.xPoint(from: Point(4)._data)
        let (_, b) = C.xPoint(from: Point(2)._data)
        XCTAssertEqual(C.compareXPoints(a, b), .greaterThan)
    }
    
    func testXPointFromPoint() {
        let scalar = Scalar(10)
        let point = try! C.point(from: scalar)
        let (parity, xPoint) = C.xPoint(from: point)
        let negate = scalar
        C.negate(into: negate)
        let (parityNegated, xPointNegated) = try! C.xPoint(from: C.point(from: negate))
        XCTAssertNotEqual(parity, parityNegated)
        XCTAssertEqual(xPoint, xPointNegated)
    }
    
    func testCreateKeypair() {
        let scalar = Scalar(30)
        var keypair: KeyPair!
        XCTAssertNoThrow(keypair = try C.keypair(from: scalar))
        XCTAssertNotNil(keypair)
        guard let keypair
        else { return }
        
        let backToScalar = C.scalar(from: keypair)
        XCTAssertEqual(scalar, backToScalar)
    }
    
    func testPointFromKeypair() {
        let scalar = Scalar(40)
        var keypair: KeyPair!
        XCTAssertNoThrow(keypair = try C.keypair(from: scalar))
        XCTAssertNotNil(keypair)
        guard let keypair
        else { return }
        
        let point = C.point(from: keypair)
        XCTAssert(C.comparePoints(point, Point(40)._data).equals)
    }
    
    func testAddXTweakCheckXTweak() {
        guard let keypair = try? C.keypair(from: Scalar(6)) // odd
        else { XCTFail(); return }
        XCTAssertNoThrow(try C.addXTweak(into: keypair, scalar: Scalar(1)))
        let point = C.point(from: keypair)
        XCTAssertNotEqual(point, Point(7)._data)
        
        guard let keypair2 = try? C.keypair(from: Scalar(2)) // even
        else { XCTFail(); return }
        XCTAssertNoThrow(try C.addXTweak(into: keypair2, scalar: Scalar(1)))
        let point2 = C.point(from: keypair2)
        XCTAssertEqual(point2, Point(3)._data)
    }
    
    func testCheckXTweak() {
        guard let keypair = try? C.keypair(from: Scalar(4))
        else { XCTFail(); return }
        let keypairXPoint = C.xPoint(from: keypair)
        let scalar = Scalar(2)
        let copy = keypair
        XCTAssertNoThrow(try C.addXTweak(into: copy, scalar: scalar))
        let xPoint = C.xPoint(from: copy)
        let ser = C.serialize(xPoint: xPoint.xPoint)
        XCTAssert(xPoint.negated)
        
        scalar.withUnsafeBytes {
            XCTAssert(C.checkAddXTweak(tweaked: ser,
                                       negated: xPoint.negated,
                                       xPoint: keypairXPoint.xPoint,
                                       tweak: Array($0)))
        }
    }
    
    // MARK: Schnorr Signature
    func testSchnorrSign() {
        let secret = Scalar(20)
        let keypair = try! C.keypair(from: secret)
        let (_, xPoint) = C.xPoint(from: keypair)
        let message = (1...32).map(UInt8.init)
        let nonce = (1...32).map { _ in UInt8(1) }
        var signature: [UInt8]!
        var signatureNonce: [UInt8]!
        XCTAssertNoThrow(signature = try C.schnorrSign(keypair: keypair,
                                                       message: message,
                                                       nonce: nil))
        XCTAssertNoThrow(signatureNonce = try C.schnorrSign(keypair: keypair,
                                                            message: message,
                                                            nonce: nonce))
        XCTAssertNotEqual(signature, signatureNonce)
        
        XCTAssert(
            C.verify(schnorr: signature, xPoint: xPoint, message: message)
        )
        XCTAssert(
            C.verify(schnorr: signatureNonce, xPoint: xPoint, message: message)
        )
    }
    
    // MARK: ECDH
    func testEcdh() {
        let scalarAlice = Scalar(100)
        let scalarBob = Scalar(200)
        let pointAlice = Point(100)._data
        let pointBob = Point(200)._data
        
        var secretAlice: EcdhSecret!
        XCTAssertNoThrow(secretAlice = try C.ecdh(my: scalarAlice, their: pointBob))
        XCTAssertNotNil(secretAlice)
        var secretBob: EcdhSecret!
        XCTAssertNoThrow(secretBob = try C.ecdh(my: scalarBob, their: pointAlice))
        XCTAssertNotNil(secretBob)
        guard let secretAlice, let secretBob
        else { return }
        
        XCTAssertEqual(secretAlice, secretBob)
    }
    
    func testEcdhFail() {
        let scalarAlice = Scalar(101)
        let scalarBob = Scalar(200)
        let pointAlice = Point(100)._data
        let pointBob = Point(200)._data
        
        var secretAlice: EcdhSecret!
        XCTAssertNoThrow(secretAlice = try C.ecdh(my: scalarAlice, their: pointBob))
        XCTAssertNotNil(secretAlice)
        var secretBob: EcdhSecret!
        XCTAssertNoThrow(secretBob = try C.ecdh(my: scalarBob, their: pointAlice))
        XCTAssertNotNil(secretBob)
        guard let secretAlice, let secretBob
        else { return }
        
        XCTAssertNotEqual(secretAlice, secretBob)
    }
    
    func testEcdhFailIllegalScalar() {
        let scalarAlice: Scalar = self.scalarZero
        let scalarBob = Scalar(11)
        let pointBob = try! C.point(from: scalarBob)
        XCTAssertThrowsError(try C.ecdh(my: scalarAlice, their: pointBob))
    }
    
    // MARK: Recoverable
    func testRecoverableSignRecoverPoint() {
        let secret = Scalar(120)
        let pubkey = try! C.point(from: secret)
        let message = (1...32).map(UInt8.init)
        let nonce = (1...32).map { _ in UInt8(1) }
        var signature: [UInt8]!
        XCTAssertNoThrow(signature = try C.recoverableSign(scalar: secret, message: message, nonce: nonce))
        XCTAssertNotNil(signature)
        guard let signature else { return }
        var recoverPoint: [UInt8]!
        XCTAssertNoThrow(recoverPoint = try C.recoverPoint(from: signature, message: message))
        XCTAssertEqual(pubkey, recoverPoint)
    }
    
    func testRecoverableSignVerify() {
        let secret = Scalar(120)
        let pubkey = try! C.point(from: secret)
        let message = (1...32).map(UInt8.init)
        var signature: [UInt8]!
        XCTAssertNoThrow(signature = try C.recoverableSign(scalar: secret, message: message, nonce: nil))
        XCTAssertNotNil(signature)
        guard let signature else { return }
        let dsa: [UInt8] = C.convert(recoverable: signature)
        XCTAssert(
            C.verify(dsa: dsa, point: pubkey, message: message)
        )
    }
    
    func testRecoverableSerializeDeserialize() {
        let secret = Scalar(120)
        let message = (1...32).map(UInt8.init)
        let nonce = (1...32).map { _ in UInt8(1) }
        var signature: [UInt8]!
        XCTAssertNoThrow(signature = try C.recoverableSign(scalar: secret, message: message, nonce: nonce))
        XCTAssertNotNil(signature)
        guard let signature else { return }
        let serialized = C.serialize(recoverable: signature)
        var deser: [UInt8]!
        XCTAssertNoThrow(deser = try C.deSerialize(recoverable: serialized.data, id: serialized.id))
        XCTAssertNotNil(deser)
        guard let deser else { return }
        XCTAssertEqual(signature, deser)
    }
    
    func testCustomScalarType() {
        struct TestScalar: SecretBytes {
            let buffer: Buffer
            init(_ buffer: Buffer) {
                self.buffer = buffer
            }
        }
        
        let validScalar = TestScalar(unsafeUninitializedCapacity: 32) { b, s in
            (UInt8(0)..<32).forEach { b[Int($0)] = $0 }
            s = 32
        }
        XCTAssertNotNil(Scalar(validScalar))
        
        let invalidScalar = TestScalar(unsafeUninitializedCapacity: 32) { b, s in
            (UInt8(0)..<32).forEach { b[Int($0)] = 0 }
            s = 32
        }
        XCTAssertNil(Scalar(invalidScalar))
        
        let shortScalar = TestScalar(unsafeUninitializedCapacity: 32) { b, s in
            (UInt8(0)..<32).forEach { b[Int($0)] = $0 }
            s = 31
        }
        XCTAssertNil(Scalar(shortScalar))
    }
    
    func testCustomKeyPairType() {
        struct TestKeyPair: SecretBytes {
            let buffer: Buffer
            init(_ buffer: Buffer) {
                self.buffer = buffer
            }
        }
        
        let validScalar = Scalar(1000)
        let validKeyPair = try! C.keypair(from: validScalar)
        let kpBytes: [UInt8] = validKeyPair.withUnsafeBytes { Array($0) }
        let testKeyPair = TestKeyPair(unsafeUninitializedCapacity: C.KEYPAIR_SIZE) { b, s in
            (0..<C.KEYPAIR_SIZE).forEach { i in
                b[i] = kpBytes[i]
            }
            s = C.KEYPAIR_SIZE
        }
        XCTAssertNotNil(KeyPair(testKeyPair))
        
        let invalidKeyPair = TestKeyPair(unsafeUninitializedCapacity: C.KEYPAIR_SIZE) { b, s in
            (0..<C.KEYPAIR_SIZE).forEach { i in
                b[i] = 0
            }
            s = C.KEYPAIR_SIZE
        }
        XCTAssertNil(KeyPair(invalidKeyPair))
        
        let shortKeyPair = TestKeyPair(unsafeUninitializedCapacity: C.KEYPAIR_SIZE) { b, s in
            (0..<C.KEYPAIR_SIZE).forEach { i in
                b[i] = kpBytes[i]
            }
            s = C.KEYPAIR_SIZE - 1
        }
        XCTAssertNil(KeyPair(shortKeyPair))
    }
    
    func testCustomEcdhSecret() {
        struct TestEcdhSecret: SecretBytes {
            let buffer: Buffer
            init(_ buffer: Buffer) {
                self.buffer = buffer
            }
        }
        let validSecret = TestEcdhSecret(unsafeUninitializedCapacity: C.ECDH_SECRET_SIZE) { b, s in
            (0..<C.ECDH_SECRET_SIZE).forEach {
                b[$0] = 0
            }
            s = C.ECDH_SECRET_SIZE
        }
        XCTAssertNotNil(EcdhSecret(validSecret))
        
        let shortSecret = TestEcdhSecret(unsafeUninitializedCapacity: C.ECDH_SECRET_SIZE) { b, s in
            (0..<C.ECDH_SECRET_SIZE).forEach {
                b[$0] = 0
            }
            s = C.ECDH_SECRET_SIZE - 1
        }
        XCTAssertNil(EcdhSecret(shortSecret))
    }
}
