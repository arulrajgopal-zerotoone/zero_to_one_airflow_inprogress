Steps to deploy and run the dag
1.Infrastructure prepare - go through terraform.md and all infra through azure resources.
All the needed infra kept here. --IAC\terraform
capture the output from the terraform apply will be used later.

2.Setup github secrtes
    AZURE_CREDENTIALS in below format
    {
        "clientId": "xxxx",
        "clientSecret": "xxxx",
        "subscriptionId": "xxxx",
        "tenantId": "xxxx"
    }

    POSTGRES_HOST 
    POSTGRES_DB
    POSTGRES_USER
    POSTGRES_PASSWORD

Note: POSTGRES_HOST is from terraform output.




3.dags and tasks in vm
cd /opt/airflow/dags
cd /opt/airflow/tasks




http://20.219.110.239:8080/

http://<ip_address>:8080/

docker ps --format "table {{.Names}}\t{{.Status}}"

NAMES                     STATUS
airflow-dag-processor-1   Up About an hour
airflow-webserver-1       Up 3 hours
airflow-scheduler-1       Up 3 hours

# to get airflow password
cat /opt/airflow/simple_auth_manager_passwords.json.generated


CHANGES TO BE DONE:
1.document all steps by combining new.md and readme.md
2.set allowed_source_ip dynamic  -- in vm and postgres sql server