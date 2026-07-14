# ER diagram for the workflow

![image](https://github.com/user-attachments/assets/7e3feb42-b7d3-4dce-899b-c56eec999387)



# data pipeline flow

![image](https://github.com/user-attachments/assets/17c776d1-8d13-47c0-b502-e61b412070a8)




# Setup procedure
1.Setup a linux machine(for the demo, below machine used)

    * Azure Virtual Machine
    * Operating System: Linux (ubuntu-24_04-lts)
    * Standard D2s v3 (2 vcpus, 8 GiB memory)

2.Install Python 

    sudo apt-get install python3.12.3
    python3 --version

3.Clone the Repository

    git clone https://github.com/ArulrajGopal/data_pipeline.git /project_directory/

4.set project directory and virtual environment directory in variable.json


5.Run setup file

    cd project_directory
    source setup.sh

6.start all components


    # initializes the database, creates a user and starts all components(webserver and scheduler)
    # Note: Once the initial setup has been completed on a machine/server, all future starts will begin from this step onwards only

    airflow standalone


7.deploy the dags(note: - deletion of dags is not implemented.)

    source deploy_dags.sh


8.login webui using "http://localhost:8080/"






# Additional information

    1.To activate virtual environment, in case of exited the environment

        - set current working as project directory and run below

            source activate_venv.sh

    2.default login credentials

        - username is "admin"

        - password will be saved in "<VENV_DIR>/airflow/simple_auth_manager_passwords.json.generated"
        
        - VENV_DIR is defined in setup.sh file


