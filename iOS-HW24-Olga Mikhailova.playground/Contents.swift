import Foundation

class Generator: Thread {
    let storage: ChipStorage
    
    init(storage: ChipStorage) {
        self.storage = storage
        super.init()
    }
    
    override func main() {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < 20 {
            
            let chip = Chip.make()
            print("Генератор создал чип \(chip.chipType) ")
            storage.put(chip: chip)
            
            Thread.sleep(forTimeInterval: 2)
        }
    }
}

class ChipStorage {
    private var chipsReady: [Chip] = []
    private let locker = NSLock()
    
    func put(chip: Chip) {
        locker.lock()
        defer { locker.unlock() }
        chipsReady.append(chip)
        print("\(chip.chipType) готов к пайке. Всего \(chipsReady.count) в хранилище")
    }
    
    func take() -> Chip? {
        locker.lock()
        defer { locker.unlock() }
        guard !chipsReady.isEmpty else {
            "Хранилище пусто"
            return nil
        }
        
        return chipsReady.removeLast()
    }
    
    var isEmpty: Bool {
        locker.lock()
        defer { locker.unlock() }
        
        return chipsReady.isEmpty
    }
}

class Worker: Thread {
    let storage: ChipStorage
    let generator: Generator
    
    init(storage: ChipStorage, generator: Generator) {
        self.storage = storage
        self.generator = generator
        super.init()
    }
    
    override func main() {
        while generator.isExecuting || !storage.isEmpty {
            if let takeChip = storage.take() {
                print("Чип \(takeChip.chipType) взят из хранилища")
                takeChip.sodering()
            } else {
                if generator.isExecuting {
                    print("Ждем поставки чипов")
                    Thread.sleep(forTimeInterval: 1)
                }
            }
        }
    }
}

public struct Chip {
    public enum ChipType: UInt32 {
        case small = 1
        case medium
        case big
    }
    
    public let chipType: ChipType
    
    public static func make() -> Chip {
        guard let chipType = Chip.ChipType(rawValue: UInt32(arc4random_uniform(3) + 1)) else {
            fatalError("Incorrect random value")
        }
        
        return Chip(chipType: chipType)
    }
    
    public func sodering() {
        let soderingTime = chipType.rawValue
        print("🔧 Паяю чип \(chipType) (\(soderingTime) сек)...")
        sleep(UInt32(soderingTime))
        print("✅ Чип \(chipType) припаян!")
    }
}


let storage = ChipStorage()
let generator = Generator(storage: storage)
let worker = Worker(storage: storage, generator: generator)
// Запуск
generator.start()
worker.start()
