# list commands
default:
    @just --list

project-fish:
    ./misc/run_fish.sh

#NOTE: Dataset is from https://www.kaggle.com/datasets/samybaladram/palmers-penguin-dataset-extended?select=palmerpenguins_extended.csv
download-data:
    #!/bin/bash
    set -e

    DATA_URL="https://www.kaggle.com/api/v1/datasets/download/samybaladram/palmers-penguin-dataset-extended"
    OUT_DIR="data/01_raw"
    ZIP_FILE="$OUT_DIR/palmers-penguin-dataset-extended.zip"

    mkdir -p "$OUT_DIR"
    wget -O "$ZIP_FILE" "$DATA_URL"
    unzip -o "$ZIP_FILE" -d "$OUT_DIR"
