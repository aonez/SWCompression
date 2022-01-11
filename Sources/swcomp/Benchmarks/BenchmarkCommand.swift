// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

#if os(Linux)
    import CoreFoundation
#endif

import Foundation
import SWCompression
import SwiftCLI

protocol BenchmarkCommand: Command {

    associatedtype InputType
    associatedtype OutputType

    var inputs: [String] { get }

    var benchmarkName: String { get }

    var benchmarkInput: InputType? { get set }

    var benchmarkInputSize: Double? { get set }

    func benchmarkSetUp(_ input: String)

    func iterationSetUp()

    func benchmark() -> OutputType

    func iterationTearDown()

    func benchmarkTearDown()

    // Compression ratio is calculated only if the InputType and the type of output is Data, and the size of the input
    // is greater than zero.
    var calculateCompressionRatio: Bool { get }

}

extension BenchmarkCommand {

    func benchmarkSetUp() { }

    func benchmarkTearDown() {
        benchmarkInput = nil
        benchmarkInputSize = nil
     }

    func iterationSetUp() { }

    func iterationTearDown() { }

}

extension BenchmarkCommand where InputType == Data {

    func benchmarkSetUp(_ input: String) {
        do {
            let inputURL = URL(fileURLWithPath: input)
            benchmarkInput = try Data(contentsOf: inputURL, options: .mappedIfSafe)
            benchmarkInputSize = Double(benchmarkInput!.count)
        } catch let error {
            print("\nERROR: Unable to set up benchmark: input=\(input), error=\(error).")
            exit(1)
        }
    }

}

extension BenchmarkCommand {

    var calculateCompressionRatio: Bool {
        return false
    }

    func execute() {
        let title = "\(benchmarkName) Benchmark\n"
        print(String(repeating: "=", count: title.count))
        print(title)

        for input in self.inputs {
            self.benchmarkSetUp(input)
            print("Input: \(input)")

            var totalSpeed = 0.0

            var maxSpeed = Double(Int.min)
            var minSpeed = Double(Int.max)

            print("Iterations: ", terminator: "")
            #if !os(Linux)
                fflush(__stdoutp)
            #endif
            // Zeroth (excluded) iteration.
            self.iterationSetUp()
            let startTime = CFAbsoluteTimeGetCurrent()
            let warmupOutput = self.benchmark()
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            let speed = benchmarkInputSize! / timeElapsed
            print("(\(SpeedFormat(speed).format())), ", terminator: "")
            #if !os(Linux)
                fflush(__stdoutp)
            #endif
            self.iterationTearDown()

            for _ in 1...10 {
                self.iterationSetUp()
                let startTime = CFAbsoluteTimeGetCurrent()
                _ = self.benchmark()
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                let speed = benchmarkInputSize! / timeElapsed
                print(SpeedFormat(speed).format() + ", ", terminator: "")
                #if !os(Linux)
                    fflush(__stdoutp)
                #endif
                totalSpeed += speed
                if speed > maxSpeed {
                    maxSpeed = speed
                }
                if speed < minSpeed {
                    minSpeed = speed
                }
                self.iterationTearDown()
            }
            let avgSpeed = totalSpeed / 10
            let avgSpeedFormat = SpeedFormat(avgSpeed)
            let speedUncertainty = (maxSpeed - minSpeed) / 2
            print("\nAverage: \(avgSpeedFormat.format().prefix { $0 != " " }) \u{B1} \(avgSpeedFormat.format(speedUncertainty))")

            if let inputData = benchmarkInput! as? Data, let outputData = warmupOutput as? Data, calculateCompressionRatio,
                inputData.count > 0 {
                let compressionRatio = Double(inputData.count) / Double(outputData.count)
                print(String(format: "Compression ratio: %.3f", compressionRatio))
            }
            print()
            self.benchmarkTearDown()
        }
    }

}
