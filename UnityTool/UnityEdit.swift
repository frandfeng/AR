//
//  UnityEdit.swift
//  CityPlus
//
//  Created by frandfeng on 07/02/2017.
//  Copyright © 2017 JHQC. All rights reserved.
//

import Foundation

public class UnityEdit : NSObject {
    
    static let ProjectPath = "/Users/frand/Develop/Project/iOS/";
    
    /// 当工程中第一次导入Unity时需要调用的
    public static func startUnityImport() -> Void {
        if editAppDelegate() {
            print("修改APPDelegate成功");
        } else {
            print("修改APPDelegate失败");
        }
        
        if replaceUniTool() {
            print("替换CPUniViewTool.mm文件成功");
        } else {
            print("替换CPUniViewTool.mm文件失败");
        }
        
        if replaceMainmm() {
            print("替换main.mm文件文件成功");
        } else {
            print("替换main.mm文件文件失败");
        }
        
        if insertHeaderInPch() {
            print("在pch文件中添加unity头成功");
        } else {
            print("在pch文件中添加unity头失败");
        }
        
        if insertHeadAndLibSearchPath() {
            print("在工程文件中插入unity header和lib的搜索路径成功");
        } else {
            print("在工程文件中插入unity header和lib的搜索路径失败");
        }
    }
    
    /// 当Unity重新导出需要刷新工程时需要调用的
    public static func startUnityRefresh() -> Void {
        let res : Bool = removeMainmm();
        if res {
            print("移除main.mm成功");
        } else {
            print("移除main.mm失败");
        }
        
//        let res1 : Bool = replaceDec2Attr();
//        if res1 {
//            print("替换attribute成功");
//        } else {
//            print("替换attribute失败");
//        }
        
        let res2 : Bool = editGetAppController();
        if res2 {
            print("替换GetAppController成功");
        } else {
            print("替换GetAppController失败");
        }
    }
    
    /// 将Native中的.h文件移动到一个暂时的文件夹中
    public static func removeHFile() -> Void {
        let desNativeDir : String = ProjectPath + "Temp/Native/";
        let srcNativeDir : String = ProjectPath + "AR3DCity/Unity3DPlugin/Classes/Native/";
        let fileManager : FileManager = FileManager.default;
        do {
            if fileManager.fileExists(atPath: desNativeDir) {
                try fileManager.removeItem(atPath: desNativeDir);
            }
            try fileManager.createDirectory(at: URL(string:"file://"+desNativeDir)!, withIntermediateDirectories: true, attributes: nil);
            print(Date());
            let hfiles : [String] = try fileManager.contentsOfDirectory(atPath: srcNativeDir);
            for file : String in hfiles {
                if (file.contains(".h")) {
                    try fileManager.moveItem(atPath: srcNativeDir+file, toPath: desNativeDir+file);
                }
            }
            print(Date());
        } catch let error {
            print(error.localizedDescription);
        }
    }
    
    /// 将原来备份的.h文件移动回来
    public static func moveHFileBack() -> Void {
        let srcNativeDir : String = ProjectPath + "Temp/Native/";
        let desNativeDir : String = ProjectPath + "AR3DCity/Unity3DPlugin/Classes/Native/";
        let fileManager : FileManager = FileManager.default;
        do {
            print(Date());
            let hfiles : [String] = try fileManager.contentsOfDirectory(atPath: srcNativeDir);
            for file : String in hfiles {
                if (file.contains(".h")) {
                    try fileManager.moveItem(atPath: srcNativeDir+file, toPath: desNativeDir+file);
                }
            }
            print(Date());
            if fileManager.fileExists(atPath: srcNativeDir) {
                try fileManager.removeItem(atPath: srcNativeDir);
            }
        } catch let error {
            print(error.localizedDescription);
        }
    }
    
    /// 修改AppDelegate
    static func editAppDelegate() -> Bool {
        let file : String = ProjectPath + "CityPlus/CityPlus/Class/AppDelegate/CPAppDelegate.m";
        let mFileContent : String = UnityUtil.read(path: file);
        let myStrings : [String] = mFileContent.components(separatedBy: NSCharacterSet.newlines);
        var resultString : String = String();
        for string : String in myStrings {
            if (string.hasPrefix("//") && string.contains("#import \"UnityAppController.h\"")) {
                resultString = resultString.appending(string.substring(from: string.index(string.startIndex, offsetBy: 2)));
            } else if (string.contains("return nil")) {
                resultString = resultString.appending(string.replacingOccurrences(of: "return nil", with: "return UnityGetMainWindow()"));
            } else if (string.contains("self.unityWindow") || string.contains("self.unityController")) {
                resultString = resultString.appending(string.substring(from: string.index(string.startIndex, offsetBy: 2)));
            } else {
                resultString = resultString.appending(string);
            }
            resultString = resultString.appending("\n");
        }
        return UnityUtil.writeString(aStr: resultString, toFile: file);
    }
    
    /// 替换CPUniViewTool.mm文件
    static func replaceUniTool() -> Bool {
        let srcDir : String = ProjectPath + "Temp/CPUniViewTool.mm";
        let desDir : String = ProjectPath + "CityPlus/CityPlus/Class/Managers/CPUniViewTool.mm";
        return UnityUtil.copyItem(fromPath: srcDir, toPath: desDir);
    }
    
    /// 替换main.mm文件
    static func replaceMainmm() -> Bool {
        let srcDir : String = ProjectPath + "Temp/main.mm";
        let desDir : String = ProjectPath + "CityPlus/CityPlus/Supporting Files/main.mm";
        return UnityUtil.copyItem(fromPath: srcDir, toPath: desDir);
    }
    
    /// 在pch文件中添加unity头
    static func insertHeaderInPch() -> Bool {
        let path : String = ProjectPath + "CityPlus/CityPlus/Supporting Files/CPPrefix.pch";
        var content : String = UnityUtil.read(path: path);
        content = content.replacingOccurrences(of: "#import <UIKit/UIKit.h>", with: "#import <UIKit/UIKit.h>\n\n#include \"Preprocessor.h\"\n#include \"UnityTrampolineConfigure.h\"\n#include \"UnityInterface.h\"\n\n");
        let res = UnityUtil.writeString(aStr: content, toFile: path);
        return res;
    }
    
    /// 在工程文件中插入unity header和lib的搜索路径
    static func insertHeadAndLibSearchPath() -> Bool {
        let path : String = ProjectPath + "CityPlus/CityPlus.xcodeproj/project.pbxproj";
        var content : String = UnityUtil.read(path: path);
        let headerPath : String = "HEADER_SEARCH_PATHS = (\n\t\t\t\t\t\"$(inherited)\",";
        let headerPathEnd : String = headerPath+"\n\t\t\t\t\t\"$(SRCROOT)/../UnityBuildiOSProj\","+"\n\t\t\t\t\t\"$(SRCROOT)/../UnityBuildiOSProj/Classes\","+"\n\t\t\t\t\t\"$(SRCROOT)/../UnityBuildiOSProj/Classes/Native\","+"\n\t\t\t\t\t\"$(SRCROOT)/../UnityBuildiOSProj/Classes/UI\","+"\n\t\t\t\t\t\"$(SRCROOT)/../UnityBuildiOSProj/Libraries\","+"\n\t\t\t\t\t\"$(SRCROOT)/../UnityBuildiOSProj/Libraries/libil2cpp/include\",";
        content = content.replacingOccurrences(of: headerPath, with: headerPathEnd);
        let libPath : String = "LIBRARY_SEARCH_PATHS = (\n\t\t\t\t\t\"$(inherited)\",";
        let libPathEnd : String = libPath+"\n\t\t\t\t\t\"$(SRCROOT)/../UnityBuildiOSProj\","+"\n\t\t\t\t\t\"$(SRCROOT)/../UnityBuildiOSProj/Libraries\","+"\n\t\t\t\t\t\"$(SRCROOT)/../UnityBuildiOSProj/Libraries/Plugins/iOS\",";
        content = content.replacingOccurrences(of: libPath, with: libPathEnd);
        return UnityUtil.writeString(aStr: content, toFile: path);
    }
    
    /// 删除main.mm引用
    ///
    /// - Returns: 是否删除main.mm引用成功
    static func removeMainmm() -> Bool {
        let path : String = ProjectPath+"CityPlus/CityPlus.xcodeproj/project.pbxproj";
        var keys : Set<String> = [];
        let propertyList : [String: Any] = UnityUtil.parseProject(path: path)!;
        //寻找所有的main.mm的id
        for key1 : String in propertyList.keys {
            if key1 == "objects" {
                let propertyList1 : [String: Any] = propertyList[key1] as! [String : Any];
                for key2 : String in propertyList1.keys {
                    let propertyList2 : [String: Any] = propertyList1[key2] as! [String : Any];
                    for key3 : String in propertyList2.keys {
                        if (propertyList2[key3] is String) {
                            let value3 : String = propertyList2[key3] as! String;
                            if (key3 == "path" && value3 == "main.mm") {
                                print("find key "+key2+" and path "+value3);
                                keys.insert(key2);
                            }
                        }
                    }
                }
            }
        }
        
        //只保留在UnityBuildiOSProj文件夹下的main.mm的id
        for key1 : String in propertyList.keys {
            if key1 == "objects" {
                let propertyList1 : [String: Any] = propertyList[key1] as! [String : Any];
                for key2 : String in propertyList1.keys {
                    let propertyList2 : [String: Any] = propertyList1[key2] as! [String : Any];
                    if (propertyList2.keys.contains("path") && propertyList2["path"] is String) {
                        let path : String = propertyList2["path"] as! String;
                        for key3 : String in propertyList2.keys {
                            if (propertyList2[key3] is [String]) {
                                let value3 : [String] = propertyList2[key3] as! [String];
                                for value4 : String in value3 {
                                    if (keys.contains(value4)) {
                                        if (!path.contains("UnityBuildiOSProj")) {
                                            print("remove key "+value4);
                                            keys.remove(value4);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        print("all id is "+keys.description);
        if keys.count == 0 {
            print("find no key");
            return false;
        }
        
        //备份project文件，读取备份内容，将内容中关于main.mm的id部分删除，再重写写入project文件
        var url : URL = URL(string:"file://"+path)!;
        let backupURL = UnityUtil.backupURLOf(projectURL: &url);
        do {
            if FileManager().fileExists(atPath: backupURL.path) {
                try FileManager().removeItem(at: backupURL)
            }
            try FileManager().moveItem(at: url, to: backupURL)
            print("已备份project工程文件，地址backupURL: \(backupURL)")
            let content : String = UnityUtil.read(path: path+".backup");
            let myStrings : [String] = content.components(separatedBy: NSCharacterSet.newlines);
            print(myStrings.count);
            var resultString : String = String();
            for key : String in keys {
                for string : String in myStrings {
                    if (string.contains(key)) {
                        print(string);
                    } else {
                        resultString = resultString.appending(string).appending("\n");
                    }
                }
            }
            return UnityUtil.writeString(aStr: resultString, toFile: path);
        } catch let error {
            do {
                print("generate new project file failed: \(error.localizedDescription), try to roll back project file!")
                try FileManager().moveItem(at: backupURL, to: url)
            } catch _ {
                print("roll back project file failed! backup file url: \(backupURL), error: \(error.localizedDescription)")
            }
            return false;
        }
    }
    
    /// 修改il2cpp-config.h中的attribute
    static func replaceDec2Attr() -> Bool {
        let path : String = ProjectPath + "UnityBuildiOSProj/Libraries/libil2cpp/include/il2cpp-config.h";
        var content : String = UnityUtil.read(path: path);
        if content.contains("__declspec(noreturn)") {
            content = content.replacingOccurrences(of: "__declspec(noreturn)", with: "__attribute__((noreturn))");
            let res = UnityUtil.writeString(aStr: content, toFile: path);
            return res;
        } else {
            return false;
        }
    }
    
    /// 修改GetAppController中的代码
    static func editGetAppController() -> Bool {
        let path : String = ProjectPath + "UnityBuildiOSProj/Classes/UnityAppController.h";
        var content : String = UnityUtil.read(path: path);
        if !content.contains("#import \"CPAppDelegate.h\"") {
            //添加#import "CPAppDelegate.h"
            content = content.replacingOccurrences(of: "#import <QuartzCore/CADisplayLink.h>", with: "#import <QuartzCore/CADisplayLink.h>\n#import \"CPAppDelegate.h\"");
            //替换GetAppController函数
            content = content.replacingOccurrences(of: "(UnityAppController*)[UIApplication sharedApplication].delegate", with: "[(CPAppDelegate*)[UIApplication sharedApplication].delegate unityController]")
            let res = UnityUtil.writeString(aStr: content, toFile: path);
            return res;
        } else {
            return false;
        }
    }
    
}
