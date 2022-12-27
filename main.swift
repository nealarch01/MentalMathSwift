import Foundation 
import Dispatch

struct Queue<T> {
    private var array = [T]()
    private let lock = DispatchSemaphore(value: 1)
    
    mutating public func enqueue(_ element: T) {
        lock.wait()
        array.append(element)
        lock.signal()
    }
    
    mutating public func dequeue() -> T? {
        var element: T
        lock.wait()
        element = array.removeFirst()
        lock.signal()
        return element
    }

    mutating public func peek() -> T? {
        var element: T?
        lock.wait()
        element = array.first
        lock.signal()
        return element
    }

    public var count: Int {
        var count: Int
        lock.wait()
        count = array.count
        lock.signal()
        return count
    }
}

struct Stats {
    var correct: Int
    var incorrect: Int


    init() {
        correct = 0
        incorrect = 0
    }
}

class LoggerFileStream {
    private var fileHandle: FileHandle

    init?(url: URL) {
        do {
            try "".write(to: url, atomically: true, encoding: .utf8)
            fileHandle = try FileHandle(forWritingTo: url)
            // print("Opened file")
        } catch {
            print("Error: \(error)")
            return nil
        }
    } 

    func write(_ message: String) {
        fileHandle.seekToEndOfFile()
        fileHandle.write(message.data(using: .utf8)!)
    }
}

enum ExpressionOperator: String {
    case plus = "+"
    case minus = "-"
    case multiply = "*"
    case divide = "/"
}

enum Difficulty: Int {
    case easy = 1
    case medium = 2
    case hard = 3 
}

struct Expression {
    static var difficulty: Difficulty = .easy // Static variable initialization
    private(set) var leftOperand: Int
    private(set) var oprt: ExpressionOperator
    private(set) var rightOperand: Int

    init() {
        // Generate a random number between 1 and 100 inclusive
        leftOperand = 0
        rightOperand = 0
        oprt = ExpressionOperator(rawValue: ["+", "-", "/", "*"].randomElement()!)!
        if oprt == .minus || oprt == .plus {
            initAddSubtract()
        } else if oprt == .multiply {
            initMultiply()
        } else {
            initDivide()
        }
    }

    mutating private func initAddSubtract() -> Void {
        var max = 100
        switch Expression.difficulty {
            case .easy:
                max += 0
                break
            case .medium:
                max += 400
                break
            default:
                max += 900
                break
        }
        leftOperand = Int.random(in: 1...max)
        rightOperand = Int.random(in: 1...max)
        if oprt == .minus && leftOperand < rightOperand {
            let temp = leftOperand
            leftOperand = rightOperand
            rightOperand = temp
        }
    }

    mutating private func initMultiply() -> Void {
        var leftMax = 12
        var rightMax = 10
        switch Expression.difficulty {
            case .easy:
                leftMax += 0
                rightMax += 0
                break
            case .medium:
                leftMax += 8
                rightMax += 0
                break
            default:
                leftMax += 20
                rightMax += 2
                break
        }
        leftOperand = Int.random(in: 1...leftMax)
        rightOperand = Int.random(in: 1...rightMax)
    }

    mutating private func initDivide() -> Void {
        var leftMax = 100
        var rightMax = 10
        switch Expression.difficulty {
            case .easy:
                leftMax += 0
                rightMax += 0
                break
            case .medium:
                leftMax += 200
                rightMax += 4
                break
            default:
                leftMax += 400
                rightMax += 10
                break
        } 
        leftOperand = Int.random(in: 1...leftMax)
        rightOperand = Int.random(in: 1...rightMax)
        if leftOperand < rightOperand {
            let temp = leftOperand
            leftOperand = rightOperand
            rightOperand = temp
        }
    }

    public func display() -> String {
        return "\(leftOperand) \(oprt.rawValue) \(rightOperand)"
    }

    public func evaluate() -> Int {
        switch oprt {
        case .plus:
            return leftOperand + rightOperand
        case .minus:
            return leftOperand - rightOperand
        case .multiply:
            return leftOperand * rightOperand
        default:
            return leftOperand / rightOperand
        }
    }
}

func enqueueThread(expressionQueue: inout Queue<Expression>, duration: Double, active: inout Bool, logger: LoggerFileStream) {
    let startTime = Date()
    while active && Date().timeIntervalSince(startTime) < duration {
        // Check if 3 seconds have passed
        let timeElapsed = Date().timeIntervalSince(startTime)
        // Use modulo to check if 3 seconds have passed
        if timeElapsed.truncatingRemainder(dividingBy: 3) == 0 {
            logger.write("Enqueueing expression at \(timeElapsed) seconds\n")
            expressionQueue.enqueue(Expression())
        }
    }
}

func answerThread(expressionQueue: inout Queue<Expression>, duration: Double, active: inout Bool) -> Stats {
    // Run a timer for 10 seconds
    var stats = Stats()
    let startTime = Date()
    while active && Date().timeIntervalSince(startTime) < duration {
        let topExpression = expressionQueue.peek()
        if expressionQueue.count == 0 {
            active = false
            break
        }
        print("\(topExpression!.display()): ", terminator: "") // Set terminator to empty string to avoid print to add a newline
        let userInput = readLine()
        guard let number = Int(userInput!) else {
            print("Invalid input. Enter a number")
            continue
        }
        if number != topExpression!.evaluate() {
            // Print with the color red
            print("\u{001B}[0;31mIncorrect\u{001B}[0;0m")
            stats.incorrect += 1
            continue
        }
        // Print with the color green
        print("\u{001B}[0;32mCorrect answer\u{001B}[0;0m")
        stats.correct += 1
        let _ = expressionQueue.dequeue()
    }
    return stats
}


func main() {
    var expressionQueue = Queue<Expression>()
    // Initialize the queue 
    for _ in 0..<1 {
        expressionQueue.enqueue(Expression())
    }
    let argc = CommandLine.argc
    let args = CommandLine.arguments
    if argc == 1 || argc > 3 {
        print("Usage: \(args[0]) <duration> <difficulty>")
        print("For more help, run \(args[0]) --help")
        exit(1)
    }
    if args[1] == "--help" {
        print("Usage: \(args[0]) <duration> <difficulty>")
        print("duration: The duration of the game in seconds")
        print("difficulty: The difficulty of the game. Must be 1 (easy)/ 2 (medium)/ 3 (hard)")
        print("Example: \(args[0]) 60 2")
        print("This will start a game with a duration of 60 seconds and a difficulty of medium")
        print("The greater the difficulty, the greater the range of numbers")
        return
    }
    guard let duration = Double(args[1]) ?? nil else {
        print("Invalid input. Duration must be a number")
        exit(2)
    }
    let difficultyValue = Int(args[2]) ?? 0
    if difficultyValue < 1 || difficultyValue > 3 {
        print("Invalid input. Difficulty must be 1 (easy)/ 2 (medium)/ 3 (hard)")
        exit(2)
    }
    Expression.difficulty = Difficulty(rawValue: difficultyValue)! // if raw value is invalid, difficulty will be nil
    if duration <= 9 {
        print("Duration must be greater than 9 seconds")
        exit(2)
    }
    guard let logger = LoggerFileStream(url: URL(fileURLWithPath: "./log.txt")) else {
        print("Error: Unable to create log file")
        exit(3)
    }
    var active = true
    // Create a waitgroup
    let waitGroup = DispatchGroup()

    // Run the enqueue thread and answer thread concurrently
    waitGroup.enter()
    DispatchQueue.global().async {
        enqueueThread(expressionQueue: &expressionQueue, duration: duration, active: &active, logger: logger)
        waitGroup.leave()
    }
    waitGroup.enter()
    var stats: Stats?
    DispatchQueue.global().async {
        stats = answerThread(expressionQueue: &expressionQueue, duration: duration, active: &active)
        waitGroup.leave()
    }
    waitGroup.wait() // Blocks the main thread until the waitgroup is done
    print("======================================")
    if expressionQueue.count == 0 {
        print("Good job!\nYou answered all the questions faster\nthan the game could generate them!")
    } else {
        print("Time is up!")
    }
    print("======================================")
    print("Correct answers: \(stats!.correct)")
    print("Incorrect answers: \(stats!.incorrect)")
    print("Score: \(stats!.correct)/\(stats!.correct + stats!.incorrect)")
    print("======================================")
    exit(0)
}


main()

