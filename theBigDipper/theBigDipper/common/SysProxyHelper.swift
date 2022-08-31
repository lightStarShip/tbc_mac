import Foundation

open class SysProxyHelper {
        
        static let kProxyConfigPath = "/Library/Application Support/theBigDipper/SystemConfig"
        static public let kSysProxyConfigVersion = "0.1.0";
        
        public static func checkVersion() -> Bool {
                let task = Process()
                task.launchPath = kProxyConfigPath
                task.arguments = ["version"]

                let pipe = Pipe()
                task.standardOutput = pipe
                let fd = pipe.fileHandleForReading
                task.launch()

                task.waitUntilExit()

                if task.terminationStatus != 0 {
                        return false
                }

                let res = String(data: fd.readDataToEndOfFile(), encoding: String.Encoding.utf8) ?? ""
                if res.contains(kSysProxyConfigVersion) {
                        return true
                }
                return false
        }

        public static func install() -> Bool {
                
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: kProxyConfigPath) || !checkVersion() {
                        let scriptPath = "\(Bundle.main.resourcePath!)/install_proxy_helper.sh"
                        let appleScriptStr = "do shell script \"bash \(scriptPath)\" with administrator privileges"
                        let appleScript = NSAppleScript(source: appleScriptStr)
                        
                        var err: NSDictionary?
                        appleScript?.executeAndReturnError(&err)
                        if let e = err{
                                print(e)
                                return false
                        }
                        return true
                }
                return true
        }
        
        static func SetupProxy(isGlocal:Bool) -> Bool{
                if isGlocal{
                        return executeSetting(args: ["global"])
                }else{
                        return executeSetting(args: ["pac"])
                }
        }
        
        static func RemoveSetting() -> Bool{
                return executeSetting(args: ["disable"])
        }
        
        static private func executeSetting(args:[String]?) -> Bool{
                let task = Process()
                task.launchPath = kProxyConfigPath
                task.arguments = args
                task.launch()
                task.waitUntilExit()
                return task.terminationStatus == 0
        }
        
        static func ensureLaunchAgentsDirOwner () throws{
                let dirPath = NSHomeDirectory() + "/Library/LaunchAgents"
                let fileMgr = FileManager.default
                if !fileMgr.fileExists(atPath: dirPath) {
                    exit(-1)
                }
                
                let attrs = try fileMgr.attributesOfItem(atPath: dirPath)
                if attrs[FileAttributeKey.ownerAccountName] as! String != NSUserName() {
                        let bashFilePath = Bundle.main.path(forResource: "fix_dir_owner.sh", ofType: nil)!
                        let script = "do shell script \"bash \\\"\(bashFilePath)\\\" \(NSUserName()) \" with administrator privileges"
                        if let appleScript = NSAppleScript(source: script) {
                                var err: NSDictionary? = nil
                                appleScript.executeAndReturnError(&err)
                        }
                }
        }
}
