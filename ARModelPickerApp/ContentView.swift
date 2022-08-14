//
//  ContentView.swift
//  ARModelPickerApp
//
//  Created by nikita9x on 13.08.2022.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity

struct ContentView : View {
    @State private var isPlacementEnabled = false
    @State private var selectedModel: Model?
    @State private var modelConfirmedForPlacement: Model?
    
    var models: [Model] = {
        let fileManager = FileManager.default
        
        guard let path = Bundle.main.resourcePath,
              let files = try? fileManager.contentsOfDirectory(atPath: path) else {
            return []
        }
        
        var availableModels: [Model] = []
        for filename in files where
        filename.hasSuffix("usdz") {
            let modelName = filename.replacingOccurrences(of: ".usdz", with: "")
            let model = Model(modelName: modelName)
            availableModels.append(model)
        }
        
        return availableModels
    }()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(modelConfirmedForPlacement: $modelConfirmedForPlacement)
            if isPlacementEnabled {
                PlacementButtonsView(isPlacementEnabled: $isPlacementEnabled, selelectedModel: $selectedModel, modelConfirmedForPlacement: $modelConfirmedForPlacement)
            } else {
                ModelPickerView(models: models, isPlacementEnabled: $isPlacementEnabled, selectedModel: $selectedModel)
            }
        }
    }
}

class CustomARView: ARView {
    let focusSquare = FESquare()
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        
        focusSquare.viewDelegate = self
        focusSquare.delegate = self
        focusSquare.setAutoUpdate(to: true)
        
        self.setupARView()
    }
    
    @MainActor required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupARView() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
            print("DEBUG: Device supports scene reconstruction")
        } else {
            print("DEBUG: Device does not support scene reconstruction")
        }
        
        self.session.run(config)
    }
}

extension CustomARView: FEDelegate {
    func toTrackingState() {
        print("tracking")
    }
    
    func toInitializingState() {
        print("initializing")
    }
}

struct ModelPickerView: View {
    var models: [Model]
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 30) {
                ForEach(0 ..< models.count) { index in
                    Button {
                        self.selectedModel = models[index]
                        isPlacementEnabled = true
                    } label: {
                        Image(uiImage: models[index].image)
                            .resizable()
                            .frame(height: 80)
                            .aspectRatio(1/1,contentMode: .fit)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.5))
    }
}

struct PlacementButtonsView: View {
    @Binding var isPlacementEnabled: Bool
    @Binding var selelectedModel: Model?
    @Binding var modelConfirmedForPlacement: Model?
    
    var body: some View {
        HStack {
            Button {
                print("Cancel model placement")
                resetPlacementParameters()
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 60, height: 60)
                    .font(.title)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(30)
                    .padding(20)
            }
            
            Button {
                print("Confirm model placement")
                modelConfirmedForPlacement = selelectedModel
                resetPlacementParameters()
            } label: {
                Image(systemName: "checkmark")
                    .frame(width: 60, height: 60)
                    .font(.title)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(30)
                    .padding(20)
            }
            
        }
    }
    
    func resetPlacementParameters() {
        isPlacementEnabled = false
        selelectedModel = nil
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var modelConfirmedForPlacement: Model?
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = CustomARView(frame: .zero)
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if let model = modelConfirmedForPlacement {
            
            if let modelEntity = model.modelEntity {
                print("DEBUG: Adding model to scene - \(model.modelName)")
                
                let anchorEntity = AnchorEntity(plane: .any)
                anchorEntity.addChild(modelEntity.clone(recursive: true))
                
                uiView.scene.addAnchor(anchorEntity)
            } else {
                print("DEBUG: Unable to load model entity for: \(model.modelName)")
            }
            
            DispatchQueue.main.async {
                modelConfirmedForPlacement = nil
            }
        } else {
            print("DEBUG: EMPTY SUKA")
        }
    }
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDevice("iPhone 13 Pro Max")
            ContentView()
                .previewDevice("iPad Pro (12.9-inch) (5th generation)")
        }
    }
}
#endif
