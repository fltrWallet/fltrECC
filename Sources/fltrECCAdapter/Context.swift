//===----------------------------------------------------------------------===//
//
// This source file is part of the fltrECC open source project
//
// Copyright (c) 2022 fltrWallet AG and the fltrECC project authors
// Licensed under Apache License v2.0
//
// See LICENSE.md for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import Csecp256k1

public enum C {}

internal extension C {
    @usableFromInline
    final class Context {
        @usableFromInline
        var pointer: OpaquePointer
        
        init() {
            let context = C.createContext()
            C.randomize(context: context)
            self.pointer = context
        }
        
        deinit {
            C.destroy(context: self.pointer)
        }
    }
}

extension C {
    @usableFromInline
    static let context: Context = .init()
}
