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
/// Хранилище хлеба
public struct BreadStorage {
    private(set) var arrayStorage = [Bread]()
    
    let condition = NSCondition()
    let mutex = NSRecursiveLock()
    var isOpen = false
    
    var count: Int {
       storageBreadArray.arrayStorage.count
     }
    
    
    mutating func push(_ bread: Bread) {
        isOpen = true
        ///блокируем поток
        mutex.lock()
        arrayStorage.append(bread)
        print("Добавлена заготовка \(arrayStorage.last!.breadType) на складе \(arrayStorage.count) шт.")
        isOpen = false
        /// сигнилизируем что поток будет освобожден
        condition.signal()
        /// разблокируем поток
        mutex.unlock()
    }
    
    mutating func pop() -> Bread? {
        /// если поток закрыт или пустой, ждем
        if isOpen || arrayStorage.isEmpty {
            condition.wait()
        }
        
        mutex.lock()
        let bread = !arrayStorage.isEmpty ? arrayStorage.removeLast() : nil
        mutex.unlock()
        return bread
    }
}

var storageBreadArray = BreadStorage()

//MARK: Продолжающий поток
final class GeneratingThread: Thread {

    override func main() {
        let timer = Timer(timeInterval: 2,
                          repeats: true) { _ in
                            guard !self.isCancelled else { return }
                            /// для каждого цикла создаем рандомный экземпляр хлеба
                            let bread = Bread.make()
                            /// кладем заготовку в хранилище
                            storageBreadArray.push(bread)
        }
        RunLoop.current.add(timer, forMode: .default)
        RunLoop.current.run()
      }
    }

final class WorkThread: Thread {
  
  override func main() {
    /// пока поток закрыт или хранилище имеет заготовки, выпекаем хлеб
    while !isCancelled || !storageBreadArray.arrayStorage.isEmpty {
      storageBreadArray.pop()?.bake()
      print("Выпекаем хлеб, осталось заготовок: \(storageBreadArray.count)")
    }
    print("Процесс завершен в хранилище осталось: \(storageBreadArray.count) заготовок")
  }
}

//MARK: Проверка решения
let breadStorage = BreadStorage()
let generatingThread = GeneratingThread()
let workThread = WorkThread()
generatingThread.start()
workThread.start()
sleep(20)
generatingThread.cancel()
workThread.cancel()
