import Vapor

func routes(_ app: Application) throws {
    var modelsPath = ""
    if Environment.get("MODELS_PATH") != nil {
        modelsPath = Environment.get("MODELS_PATH")!
    }
    let recoController = RecognitionController(modelsPath: modelsPath)
    try app.register(collection: recoController)
    try recoController.loadModel()
}
