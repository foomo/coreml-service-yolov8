# coreml-service-yolov8

vapor server with a generic REST API for a Core ML version of YOLOv8 from https://github.com/ultralytics/ultralytics 

# Releasing

- set a git tag

```shell
CODE_SIGNING_IDENTITY="<you code signing id>" make release
```