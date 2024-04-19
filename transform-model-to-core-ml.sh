#!/bin/zsh

# needs a mac

# install miniconda
echo "setting up conda in ${MODEL_EXPORT_DIR}"
brew install miniconda
eval "$(conda "shell.$(basename "${SHELL}")" hook)"

# cleanup previous attempt gracefully
conda init
conda deactivate || echo "nothing to conda deactivate" 
conda remove -y -n coreml-service-yolov8 --all || echo "no env to remove"	

# create env from file
conda env create -f environment.yml
conda init
# activate env
conda activate coreml-service-yolov8

# coreml export and conversion
cd ${MODEL_EXPORT_DIR}
yolo export model=yolov8m-oiv7.pt format=coreml nms=True
xcrun coremlcompiler compile yolov8m-oiv7.mlpackage ${MODEL_EXPORT_DIR}
