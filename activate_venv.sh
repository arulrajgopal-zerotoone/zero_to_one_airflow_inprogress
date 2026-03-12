#!/bin/bash

# Read from the JSON file
PROJECT_DIR=$(jq -r '.project_directory' variables.json)
VENV_DIR=$(jq -r '.virtual_env_directory' variables.json)

echo "Project directory: $PROJECT_DIR"
echo "Virtual environment directory: $VENV_DIR"


source "$VENV_DIR/bin/activate"


