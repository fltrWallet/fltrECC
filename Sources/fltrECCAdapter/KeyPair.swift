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

public struct KeyPair: SecretBytes, SecretMutableBytes, Equatable {
    public let buffer: Buffer

    @usableFromInline
    internal init(_buffer: Buffer) {
        self.buffer = _buffer
    }

    @inlinable
    public init?(_ buffer: Buffer) {
        guard buffer.count == C.KEYPAIR_SIZE
        else { return nil }
        
        let keyPair = Self.init(_buffer: buffer)
        guard let _ = C.scalar(from: keyPair)
        else { return nil }
        
        self = keyPair
    }
}
