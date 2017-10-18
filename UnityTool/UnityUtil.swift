//
//  UnityUtil.swift
//  CityPlus
//
//  Created by frandfeng on 13/02/2017.
//  Copyright © 2017 JHQC. All rights reserved.
//

import Foundation

public class UnityUtil {
    
    /// 读取给定路径的文件到一个字串中
    ///
    /// - Parameter path: 文件的路径
    /// - Returns: 文件中的字串
    static func read(path:String) -> String {
        let file : FileHandle = FileHandle(forReadingAtPath:path)!;
        let data : Data = file.readDataToEndOfFile();
        let aStr : String = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String;
        file.closeFile();
        return aStr;
    }
    
    
    /// 将字符串写入到文件中
    ///
    /// - Parameters:
    ///   - aStr: 字符串
    ///   - path: 文件的路径
    /// - Returns: 是否写入成功
    static func writeString(aStr: String, toFile path : String) -> Bool {
        do {
            try aStr.write(toFile: path, atomically: true, encoding: String.Encoding.utf8);
            return true;
        } catch let err as NSError {
            print("写入文件"+path+"失败,原因是"+err.debugDescription);
            return false;
        }
    }
    
    /// 将文件从一个路径移动到另一个路径
    ///
    /// - Parameters:
    ///   - srcDir: 源文件路径
    ///   - desDir: 目标文件路径
    /// - Returns: 是否移动成功
    static func moveItem(fromPath srcDir : String, toPath desDir : String) -> Bool {
        let fileManager : FileManager = FileManager.default;
        do {
            if fileManager.fileExists(atPath: desDir) {
                try fileManager.removeItem(atPath: desDir);
            }
            try fileManager.moveItem(atPath: srcDir, toPath: desDir);
            return true;
        } catch let err as NSError {
            print("移动文件"+srcDir+"失败,原因是"+err.debugDescription);
            return false;
        }
    }
    
    /// 将文件从一个路径复制到另一个路径
    ///
    /// - Parameters:
    ///   - srcDir: 源文件路径
    ///   - desDir: 目标文件路径
    /// - Returns: 是否复制成功
    static func copyItem(fromPath srcDir : String, toPath desDir : String) -> Bool {
        let fileManager : FileManager = FileManager.default;
        do {
            if fileManager.fileExists(atPath: desDir) {
                try fileManager.removeItem(atPath: desDir);
            }
            try fileManager.copyItem(atPath: srcDir, toPath: desDir);
            return true;
        } catch let err as NSError {
            print("复制文件"+srcDir+"失败,原因是"+err.debugDescription);
            return false;
        }
    }
    
    /// 将工程文件内容转为字典对象
    ///
    /// - Parameter fileURL: 文件路径 URL
    /// - Returns: 字典对象，即转化后的内容
    static func parseProject(path: String) -> [String: Any]? {
        do {
            let file : FileHandle = FileHandle(forReadingAtPath:path)!;
            let fileData = file.readDataToEndOfFile();
            let plist = try PropertyListSerialization.propertyList(from: fileData, options: .mutableContainersAndLeaves, format: nil)
            return plist as? [String:Any]
        } catch let error {
            print("read project file failed. error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 返回指定文件对应的备份文件路径
    ///
    /// - parameter url: 文件 URL
    ///
    /// - returns: 备份文件路径
    static func backupURLOf(projectURL url: inout URL) -> URL {
        var backupURL : URL = url;
        backupURL.appendPathExtension("backup")
        return backupURL
    }

}
