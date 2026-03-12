#!/bin/bash

# Create destination directory if it doesn't exist
mkdir -p "$VENV_DIR/airflow/dags"
mkdir -p "$VENV_DIR/airflow/tasks"

# Copy all dag files from source to destination
cp -a "$PROJECT_DIR/dags/"/* "$VENV_DIR/airflow/dags"/

echo "dag files copied successfully from $PROJECT_DIR/dags to $VENV_DIR/airflow/dags"


# Copy all task files from source to destination
cp -a "$PROJECT_DIR/tasks/"/* "$VENV_DIR/airflow/tasks"/

echo "task files copied successfully from $PROJECT_DIR/tasks to $VENV_DIR/airflow/tasks"



#registering the dags
DAGS_DIR="$VENV_DIR/airflow/dags"

for file in "$DAGS_DIR"/*.py; do
    echo "Registering: $file"
    python "$file"
done

echo "Registered all the dags successfully, it will take few mins to reflect in UI"


