//
//  Copyright 2026 Jamf. All rights reserved.
//

import Foundation

struct Log {
    static var path: String? = (NSHomeDirectory() + "/Library/Logs/")
    static var file  = "masb.log"
    static var maxFiles = 42
}

class WriteToLog {
    
    static let shared = WriteToLog()
    private init() { }
    
    var logFileW: FileHandle? = FileHandle(forUpdatingAtPath: (Log.path! + Log.file))
    let fm                    = FileManager()
    
    func logCleanup() {
        if didRun {
            var logArray: [String] = []
            var logCount: Int = 0
            do {
                let logFiles = try fm.contentsOfDirectory(atPath: Log.path!)
                
                for logFile in logFiles {
                    let filePath: String = Log.path! + logFile
                    logArray.append(filePath)
                }
                logArray.sort()
                logCount = logArray.count
                // remove old log files
                if logCount-1 >= Log.maxFiles {
                    for i in (0..<logCount-Log.maxFiles) {
                        let fileName = URL(fileURLWithPath: logArray[i]).lastPathComponent
                        WriteToLog.shared.message("Deleting log file: " + fileName)
                        do {
                            try fm.removeItem(atPath: logArray[i])
                        }
                        catch let error as NSError {
                            WriteToLog.shared.message("Error deleting log file:\n                " + fileName + "\n                \(error)\n")
                        }
                    }
                }
            } catch {
                print("no history")
            }
        } else {
            // delete empty log file
            do {
                try fm.removeItem(atPath: Log.path! + Log.file)
            }
            catch let error as NSError {
                WriteToLog.shared.message("Error deleting log file:\n                " + Log.path! + Log.file + "\n                \(error)\n")
            }
        }
    }

    func message(_ stringOfText: String) {
        let logString = "\(getCurrentTime(theFormat: "log")) \(stringOfText)\n"

        self.logFileW?.seekToEndOfFile()
            
        let logText = (logString as NSString).data(using: String.Encoding.utf8.rawValue)
        self.logFileW?.write(logText!)
    }

}

func getCurrentTime(theFormat: String = "log") -> String {
    var stringDate = ""
    let current = Date()
    let localCalendar = Calendar.current
    let dateObjects: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
    let dateTime = localCalendar.dateComponents(dateObjects, from: current)
    let currentMonth  = leadingZero(value: dateTime.month!)
    let currentDay    = leadingZero(value: dateTime.day!)
    let currentHour   = leadingZero(value: dateTime.hour!)
    let currentMinute = leadingZero(value: dateTime.minute!)
    let currentSecond = leadingZero(value: dateTime.second!)
    switch theFormat {
    case "info":
        stringDate = "\(dateTime.year!)-\(currentMonth)-\(currentDay) \(currentHour)\(currentMinute)"
    default:
        stringDate = "\(dateTime.year!)\(currentMonth)\(currentDay)_\(currentHour)\(currentMinute)\(currentSecond)"
    }
    return stringDate
}
// add leading zero to single digit integers
func leadingZero(value: Int) -> String {
    var formattedValue = ""
    if value < 10 {
        formattedValue = "0\(value)"
    } else {
        formattedValue = "\(value)"
    }
    return formattedValue
}
