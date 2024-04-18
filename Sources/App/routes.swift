import Vapor

func routes(_ app: Application) throws {
    let recoController = RecognitionController(modelsPath: "")
    try app.register(collection: recoController)
    try recoController.loadModel()
}
