Steps to deploy and run the dag
1.Infrastructure prepare - go through terraform.md 

2.

3.dags and tasks in vm
cd /opt/airflow/dags
cd /opt/airflow/tasks



docker ps --format "table {{.Names}}\t{{.Status}}"

NAMES                     STATUS
airflow-dag-processor-1   Up About an hour
airflow-webserver-1       Up 3 hours
airflow-scheduler-1       Up 3 hours