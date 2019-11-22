
//
//  Progress+extensions.swift
//  Pods
//
//  Created by Aleksandr Vdovichenko on 9/5/17.
//
//

import RealmSwift

extension ProgressModel {
    public static func find(withConfiguration readerConfig: FolioReaderConfig, bookId: String, fontSize: String, fontName: String, spaceLine: Int, pading: Int) -> ProgressModel? {
        
        var spaceType = "lineHeightOne"
        
        if spaceLine == 1 { spaceType = "lineHeightTwo" }
        else if spaceLine == 2 { spaceType = "lineHeightThree" }
        
        var predicate = NSPredicate(format: "bookId = %@ AND fontName = %@ AND fontSize = %@ AND spaceLine = %@ AND pading = %d", bookId, fontName, fontSize, spaceType, pading)
        do {
            let realm = try Realm(configuration: readerConfig.realmConfiguration)
            guard let progressModel = realm.objects(ProgressModel.self).filter(predicate).toArray(ProgressModel.self).first else {
                return nil
            }
            return progressModel
        } catch let error as NSError {
            print("Error on fetch all by book Id: \(error)")
            return nil
        }
    }
}
