#!/bin/bash

# Read from the JSON file
PROJECT_DIR=$(jq -r '.project_directory' variables.json)
VENV_DIR=$(jq -r '.virtual_env_directory' variables.json)


echo "Project directory: $PROJECT_DIR"
echo "Virtual environment directory: $VENV_DIR"


# Check Python version
python3 --version

# Install pip if missing
if ! command -v pip3 &> /dev/null
then
    echo "pip3 not found, installing..."
    sudo apt install -y python3-pip
else
    echo "pip3 is already installed."
fi

# Install venv if missing
sudo apt install -y python3-venv

# Create virtual environment if it doesn't exist
python3 -m venv "$VENV_DIR"

# Activate virtual environment and move to project directory
echo "Activating virtual environment and changing to project directory..."
source "$VENV_DIR/bin/activate"
cd "$PROJECT_DIR"

# Setting up variables
export PROJECT_DIR
export VENV_DIR
POSTGRES_PASSWORD="Arulraj@1234"


# Check if PostgreSQL is already installed
if command -v psql >/dev/null 2>&1; then
    echo "PostgreSQL is already installed. Version: $(psql --version)"
else
    echo "PostgreSQL not found. Installing..."

    # Update package list
    sudo apt update

    # Install PostgreSQL
    sudo apt install -y postgresql postgresql-contrib

    # Enable and start PostgreSQL service
    sudo systemctl enable postgresql
    sudo systemctl start postgresql

    echo "PostgreSQL installation complete."
    echo "Installed version: $(psql --version)"
fi


# Set password for the 'postgres' user
echo "Setting password for the 'postgres' PostgreSQL user..."

# Run the password command in the postgres user's psql shell
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_PASSWORD}';"

echo "Password for 'postgres' user has been set."


# Install dependencies
echo "Installing dependencies from requirements.txt..."
pip install --upgrade pip
pip install -r requirements.txt

echo "Dependencies installed successfully."


# Set Airflow and Python versions
AIRFLOW_VERSION=3.0.2
PYTHON_VERSION="$(python --version | cut -d ' ' -f 2 | cut -d '.' -f 1-2)"
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"


export AIRFLOW_HOME=~/airflow

# Check if airflow is installed
if ! command -v airflow &> /dev/null; then
    echo "Airflow not found. Installing Apache Airflow ${AIRFLOW_VERSION}..."
    pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"

    echo "Initializing Airflow database..."
    airflow db init

    echo "Airflow installed and database initiated successfully."
else
    echo "Airflow is already installed."
fi


