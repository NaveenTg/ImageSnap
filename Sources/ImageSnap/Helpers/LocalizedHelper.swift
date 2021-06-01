//
//  LocalizedHelper.swift
//  
//
//  Created by Navi on 01/06/21.
//

import Foundation

struct LocalizedHelper {
    static func getString(_ key: String, value: String? = nil, comment: String = "") -> String {
        let value = value ?? key
        
        var text = value
        if let bundle = ImageSnap.bundle {
            text = NSLocalizedString(key, tableName: "ImageSnapLocalizable", bundle: bundle, value: value, comment: comment)
        }
        return text
    }
}
