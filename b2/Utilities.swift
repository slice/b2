import Foundation

func measure<T>(_ name: String, task: () throws -> T) rethrows -> T {
    let start = DispatchTime.now()
    let returnValue = try task()
    let end = DispatchTime.now()
    let nanos = end.uptimeNanoseconds - start.uptimeNanoseconds
    let millis = Double(nanos) / 1_000_000
    NSLog("\(name) took \(millis)ms")
    return returnValue
}
