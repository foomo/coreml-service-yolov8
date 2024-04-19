RELEASE_TAG=`git describe --tags || echo "dev"`
ABS_MAKEFILE=$(realpath $(MAKEFILE_LIST))
BUILD_DIR=`dirname ${ABS_MAKEFILE}`/.build
DOWNLOAD_PACKAGE_DIR=${BUILD_DIR}/downloadpackage
MODEL_EXPORT_DIR=${BUILD_DIR}/model-export
ZIP_NAME=coreml-service-yolov8m-${RELEASE_TAG}.zip
DOWNLOAD_PACKAGE_ZIP=${DOWNLOAD_PACKAGE_DIR}/${ZIP_NAME}
SERVER_FILE_IN_PACKAGE=${DOWNLOAD_PACKAGE_DIR}/coreml-service-yolov8m


test-identity:
	@echo "checking code signing identity"
	@if [ -z "${CODE_SIGNING_IDENTITY}" ]; then echo "please set CODE_SIGNING_IDENTITY" && exit 1 ; fi
	@echo "signing .... with ${CODE_SIGNING_IDENTITY} for ${RELEASE_TAG}"

clean: test-identity
	@echo "------- CLEANING -------"
	mkdir -p ${BUILD_DIR} 
	mkdir -p ${DOWNLOAD_PACKAGE_DIR} 
	mkdir -p ${MODEL_EXPORT_DIR}
	rm -Rvf ${DOWNLOAD_PACKAGE_DIR}/* 
	rm -Rvf ${MODEL_EXPORT_DIR}/*

build-server:
	@echo "------- swift server build -------"
	swift build -c release

transform-model-to-core-ml:
	@echo "------- transforming model for core ml use -------"
	MODEL_EXPORT_DIR=${MODEL_EXPORT_DIR} ./transform-model-to-core-ml.sh

move-to-download-package:
	@echo "--------- moving things into place ---------"
	mv ${MODEL_EXPORT_DIR}/yolov8m-oiv7.mlmodelc ${DOWNLOAD_PACKAGE_DIR}/.
	mv ${BUILD_DIR}/release/app ${SERVER_FILE_IN_PACKAGE}

codesign:
	@echo "--------- todo sign app ---------"
	echo "TODO: code sign ${SERVER_FILE_IN_PACKAGE}"

release: clean build-server transform-model-to-core-ml move-to-download-package codesign
	@echo "--------- building download pkg ---------"
	cd ${DOWNLOAD_PACKAGE_DIR} && zip -r ${ZIP_NAME} . && shasum -a 256 ${ZIP_NAME}

	

