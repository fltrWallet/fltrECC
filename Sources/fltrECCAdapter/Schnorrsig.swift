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
import Csecp256k1

public extension C {
    @inlinable
    static func schnorrSign(keypair: KeyPair,
                            message: [UInt8],
                            nonce: [UInt8]?) throws -> [UInt8] {
        assert(keypair.count == C.KEYPAIR_SIZE)
        precondition(message.count == C.MESSAGE_SIZE)
        precondition(nonce == nil || nonce!.count == C.SCHNORR_SIGNATURE_NONCE_SIZE)
        var nonce = nonce

        return try Array(unsafeUninitializedCapacity: C.SCHNORR_SIGNATURE_SIZE) { signature, setSizeTo in
            let cRet = message.withUnsafeBufferPointer { data in
                keypair.withUnsafeBytes { keyPair in
                    secp256k1_schnorrsig_sign32(self.context.pointer,
                                                signature.baseAddress!,
                                                data.baseAddress!,
                                                keyPair.bindMemory(to: secp256k1_keypair.self).baseAddress!,
                                                &nonce)
                }
            }
            guard cRet == 1 else {
                throw C.Error.illegalKeyPairValue
            }
            
            setSizeTo = C.SCHNORR_SIGNATURE_SIZE
        }
    }
    
    @inlinable
    static func verify(schnorr signature: [UInt8], xPoint point: [UInt8], message data: [UInt8]) -> Bool {
        assert(signature.count == C.SCHNORR_SIGNATURE_SIZE && point.count == C.XPOINT_SIZE)
        precondition(data.count == C.MESSAGE_SIZE)
        
        let cRet = signature.withUnsafeBytes { signature in
            point.withUnsafeBytes { point in
                data.withUnsafeBufferPointer { data in
                    secp256k1_schnorrsig_verify(self.context.pointer,
                                                signature.baseAddress!,
                                                data.baseAddress!,
                                                C.MESSAGE_SIZE,
                                                point
                        .bindMemory(to: secp256k1_xonly_pubkey.self)
                        .baseAddress!)
                }
            }
        }
        
        return cRet == 1
    }
}
