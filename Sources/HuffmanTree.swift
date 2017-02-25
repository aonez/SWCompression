//
//  HuffmanTree.swift
//  SWCompression
//
//  Created by Timofey Solomko on 24.10.16.
//  Copyright © 2017 Timofey Solomko. All rights reserved.
//

import Foundation

class HuffmanTree {

    private enum HTNode {
        case leaf(Int)
        case branch([Int])
    }

    private var pointerData: DataWithPointer

    /// Array of [code, bitsCount] arrays.
    private var tree: [[Int]]
    private let leafCount: Int

    private var newTree: [HTNode]

    private let coding: Bool

    init(bootstrap: [[Int]], _ pointerData: inout DataWithPointer, _ coding: Bool = false) {
        self.coding = coding
        self.pointerData = pointerData

        // Fills the 'lengths' array with numerous HuffmanLengths from a 'bootstrap'.
        var lengths: [[Int]] = []
        var start = bootstrap[0][0]
        var bits = bootstrap[0][1]
        for pair in bootstrap[1..<bootstrap.count] {
            let finish = pair[0]
            let endbits = pair[1]
            if bits > 0 {
                for i in start..<finish {
                    lengths.append([i, bits])
                }
            }
            start = finish
            bits = endbits
        }
        // Sort the lengths' array to calculate symbols correctly.
        lengths.sort { (left: [Int], right: [Int]) -> Bool in
            if left[1] == right[1] {
                return left[0] < right[0]
            } else {
                return left[1] < right[1]
            }
        }

        func reverse(bits: Int, in symbol: Int) -> Int {
            // Auxiliarly function, which generates reversed order of bits in a number.
            var a = 1 << 0
            var b = 1 << (bits - 1)
            var z = 0
            for i in stride(from: bits - 1, to: -1, by: -2) {
                z |= (symbol >> i) & a
                z |= (symbol << i) & b
                a <<= 1
                b >>= 1
            }
            return z
        }

        // Calculate maximum amount of leaves possible in a tree.
        self.leafCount = 1 << (lengths.last![1] + 1)
        // Create a tree (array, actually) with all leaves equal nil.
        self.tree = Array(repeating: [-1, -1], count: leafCount)

        self.newTree = Array(repeating: .leaf(-1), count: leafCount)

        // Calculates symbols for each length in 'lengths' array and put them in the tree.
        var loopBits = -1
        var symbol = -1
        for length in lengths {
            symbol += 1
            // We sometimes need to make symbol to have length.bits bit length.
            let bits = length[1]
            if bits != loopBits {
                symbol <<= (bits - loopBits)
                loopBits = bits
            }
            // Then we need to reverse bit order of the symbol.
            var treeCode = reverse(bits: loopBits, in: symbol)
            // Finally, we put it at its place in the tree.
            var index = 0
            for _ in 0..<bits {
                let bit = treeCode & 1
                index = bit == 0 ? 2 * index + 1 : 2 * index + 2
                treeCode >>= 1
            }
            self.tree[index] = length
            self.newTree[index] = .leaf(length[0])
        }

        if coding {
            for treeIndex in stride(from: self.leafCount - 1, through: 0, by: -1) {
                switch self.newTree[treeIndex] {
                case .leaf(let symbol):
                    if symbol == -1 {
                        var replacementArray = [Int]()

                        let leftChildIndex = 2 * treeIndex + 1
                        if leftChildIndex < self.leafCount {
                            switch self.newTree[leftChildIndex] {
                            case .leaf(let leftSymbol):
                                replacementArray.append(leftSymbol)
                            case .branch(let leftArray):
                                for leftChild in leftArray {
                                    replacementArray.append(leftChild)
                                }
                            }
                        }

                        let rightChildIndex = 2 * treeIndex + 2
                        if rightChildIndex < self.leafCount {
                            switch self.newTree[rightChildIndex] {
                            case .leaf(let rightSymbol):
                                replacementArray.append(rightSymbol)
                            case .branch(let rightArray):
                                for rightChild in rightArray {
                                    replacementArray.append(rightChild)
                                }
                            }
                        }

                        self.newTree[treeIndex] = .branch(replacementArray)
                    }
                default:
                    continue
                }
            }
        }
    }

    convenience init(lengthsToOrder: [Int], _ pointerData: inout DataWithPointer) {
        var addedLengths = lengthsToOrder
        addedLengths.append(-1)
        let lengthsCount = addedLengths.count
        let range = Array(0...lengthsCount)
        self.init(bootstrap: (zip(range, addedLengths)).map { [$0, $1] }, &pointerData)
    }

    func findNextSymbol() -> Int {
        var index = 0
        while true {
            let bit = pointerData.bit()
            index = bit == 0 ? 2 * index + 1 : 2 * index + 2
            guard index < self.leafCount else { return -1 }
            switch self.newTree[index] {
            case .leaf(let symbol):
                if symbol > -1 {
                    return symbol
                }
            default:
                continue
            }
        }
    }

    func code(symbol: Int) -> [UInt8] {
        guard self.coding else { return [] }

        var index = 0
        var bits = [UInt8]()
        while true {
            switch self.newTree[index] {
            case .leaf(let foundSymbol):
                if foundSymbol == symbol {
                    return bits
                } else {
                    return []
                }
            case .branch(_):
                let leftChildIndex = 2 * index + 1
                if leftChildIndex < self.leafCount {
                    switch self.newTree[leftChildIndex] {
                    case .leaf(let foundLeftSymbol):
                        if foundLeftSymbol == symbol {
                            index = leftChildIndex
                            bits.append(0)
                            continue
                        } else {
                            break
                        }
                    case .branch(let leftArray):
                        if leftArray.contains(symbol) {
                            index = leftChildIndex
                            bits.append(0)
                            continue
                        } else {
                            break
                        }
                    }
                }

                let rightChildIndex = 2 * index + 2
                if rightChildIndex < self.leafCount {
                    switch self.newTree[rightChildIndex] {
                    case .leaf(let foundRightSymbol):
                        if foundRightSymbol == symbol {
                            index = rightChildIndex
                            bits.append(1)
                            continue
                        } else {
                            return []
                        }
                    case .branch(let rightArray):
                        if rightArray.contains(symbol) {
                            index = rightChildIndex
                            bits.append(1)
                            continue
                        } else {
                            return []
                        }
                    }
                }
            }
        }
    }

}
