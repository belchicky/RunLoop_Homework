import UIKit
import PlaygroundSupport
import Foundation

public struct Bread {
    public enum BreadType: UInt32 {
        case small = 1
        case medium
        case big
    }
    
    public let breadType: BreadType
    
    public static func make() -> Bread {
        guard let breadType = Bread.BreadType(rawValue: UInt32(arc4random_uniform(3) + 1)) else {
            fatalError("Incorrect random value")
        }
        
        return Bread(breadType: breadType)
    }
    
    public func bake() {
        let bakeTime = breadType.rawValue
        sleep(UInt32(bakeTime))
    }
}

//MARK: Основной код
PlaygroundPage.current.needsIndefiniteExecution = true

/// Хранилище хлеба
struct StorageDevice {
    private(set) var array : [Bread] = []
    
    mutating func putNew(bread: Bread) {
        self.array.append(bread)
        print("Добавлена заготовка \(array.last!.breadType) на складе: \(array.count) шт.")
    }
    
    mutating func getNew() -> Bread? {
        return array.count > 0 ? array.removeLast() : nil
    }
}

var storageDevice = StorageDevice()
var isCreatedThreadWork = true
var isWorkerThreadWork = true
let condition = NSCondition()

class CreateThread : Thread {
    override func main() {
        for _ in 0...9 {
            let newBread = Bread.make()
            condition.lock()
            storageDevice.putNew(bread: newBread)
            condition.unlock()
            if !isWorkerThreadWork {
                print("Выпекаем хлеб, осталось заготовок: \(storageDevice.array.count)")
                condition.signal()
            }
            Darwin.sleep(2)
        }
        isCreatedThreadWork = false
    }
}

class WorkThread : Thread {
    override func main() {
        
        while isCreatedThreadWork {
            if storageDevice.array.count == 0 {
                isWorkerThreadWork = false
                condition.wait()
            }
            while storageDevice.array.count > 0 {
                isWorkerThreadWork = true
                storageDevice.getNew()?.bake()
            }
        }
        print("Процесс завершен в хранилище осталось: \(storageDevice.array.count) заготовок")
    }
}

//MARK: Проверка решения
let createThread = CreateThread()
let workThread = WorkThread()
createThread.qualityOfService = .userInitiated
workThread.qualityOfService = .background
createThread.start()
workThread.start()
