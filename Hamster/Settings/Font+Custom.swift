//
//  Font+Custom.swift
//  Hamster
//
//  Created by Vitta on 2023/5/3.
//

import UIKit

public var appSettings = HamsterAppSettings()
// 在应用程序启动时运行以下代码，对系统的 UIFont 类进行方法交换
extension UIFont {
    
    @objc class func mySystemFont(ofSize size: CGFloat) -> UIFont {
        guard let font = UIFont(name: appSettings.customFontName, size: size) else {
            return UIFont.mySystemFont(ofSize: size)
        }
        return font
    }
    
    @objc class func myBoldSystemFont(ofSize size: CGFloat) -> UIFont {
        guard let font = UIFont(name: appSettings.customFontName, size: size) else {
            return UIFont.myBoldSystemFont(ofSize: size)
        }
        return font
    }
    
    static func swizzleMethods() {
        if let systemFontMethod = class_getClassMethod(self, #selector(systemFont(ofSize:))),
           let mySystemFontMethod = class_getClassMethod(self, #selector(mySystemFont(ofSize:))) {
            method_exchangeImplementations(systemFontMethod, mySystemFontMethod)
        }
        
        if let boldSystemFontMethod = class_getClassMethod(self, #selector(boldSystemFont(ofSize:))),
           let myBoldSystemFontMethod = class_getClassMethod(self, #selector(myBoldSystemFont(ofSize:))) {
            method_exchangeImplementations(boldSystemFontMethod, myBoldSystemFontMethod)
        }
    }
}
