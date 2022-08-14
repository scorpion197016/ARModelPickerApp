//
//  Model.swift
//  ARModelPickerApp
//
//  Created by nikita9x on 14.08.2022.
//

import Foundation
import UIKit
import RealityKit
import Combine

class Model {
    var modelName: String
    var image: UIImage
    var modelEntity: ModelEntity?
    
    private var cancellable: AnyCancellable? = nil
    
    init(modelName: String) {
        self.modelName = modelName
        self.image = UIImage(named: modelName)!
        
        let filename = modelName + ".usdz"
        self.cancellable = ModelEntity.loadModelAsync(named: filename)
            .sink(receiveCompletion: { loadCompletion in
                print("DEBUG: Unable to load modelEntity for \(modelName)")
            }, receiveValue: { entity in
                self.modelEntity = entity
                print("DEBUG: modelEntity loaded for \(modelName)")
            })
    }
}
