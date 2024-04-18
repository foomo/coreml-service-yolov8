import Vapor
import AVFoundation
import CoreImage
import Vision

class RecognitionController: RouteCollection {
    
    private var modelsPath: String
    
    init(modelsPath: String) {
        self.modelsPath = modelsPath
    }
    
    var classes:[String] = []
    
    var yoloRequest:VNCoreMLRequest?
    
    func loadModel() throws {
        let modelURL = URL(fileURLWithPath: modelsPath).appendingPathComponent("yolov8m-oiv7.mlmodelc")
        let model = try MLModel(contentsOf: modelURL, configuration: MLModelConfiguration())
        guard let classes = model.modelDescription.classLabels as? [String] else {
            fatalError()
        }
        self.classes = classes
        let vnModel = try VNCoreMLModel(for: model)
        yoloRequest = VNCoreMLRequest(model: vnModel)
    }
    
    func boot(routes: RoutesBuilder) throws {
       routes.on(.POST,
                 "recognize",
                 body: .collect(maxSize: ByteCount(value: 2000*1024)),
                 use: recognize
       )
   }
   
   func recognize(req: Request) async throws -> BboxResponse {
       guard yoloRequest != nil else {
           throw ModelError.notLoaded
       }
       let request = try req.content.decode(String.self)
       
       guard let dataDecoded : Data = Data(base64Encoded: request, options: .ignoreUnknownCharacters) else {
           return BboxResponse(detections: [])
       }
       let ciImage = CIImage(data: dataDecoded)!
       var pixelBuffer: CVPixelBuffer?
       let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                    kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
       let width:Int = Int(ciImage.extent.width)
       let height:Int = Int(ciImage.extent.height)
       CVPixelBufferCreate(kCFAllocatorDefault,
                           width,
                           height,
                           kCVPixelFormatType_32BGRA,
                           attrs,
                           &pixelBuffer)
               let context = CIContext()
       context.render(ciImage, to: pixelBuffer!)
       
       
       let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer!)
       try handler.perform([yoloRequest!])
       guard let results = yoloRequest!.results as? [VNRecognizedObjectObservation] else {
           return BboxResponse(detections: [])
       }
       var detections:[Detection] = []
       for result in results {
           guard let label = result.labels.first?.identifier as? String else {
               return BboxResponse(detections: [])
           }
           let detection = Detection(prob: result.confidence, category: label, x: Float(result.boundingBox.minX * ciImage.extent.width), y: Float((1 - result.boundingBox.maxY) * ciImage.extent.height), w: Float(result.boundingBox.width * ciImage.extent.width), h: Float(result.boundingBox.height * ciImage.extent.height))
           detections.append(detection)
       }
       
       return BboxResponse(detections: detections)
   }
}

struct BboxResponse: Content {
    let detections: [Detection]
}

struct Detection: Codable {
    let prob:Float
    let category:String?
    let x: Float
    let y : Float
    let w: Float
    let h: Float
}

public enum ModelError: Error {
    case notLoaded
}
