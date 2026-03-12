import textwrap
from datetime import datetime, timedelta
from airflow.providers.standard.operators.bash import BashOperator
import os 

BASE_DIR = os.path.dirname(os.path.dirname(__file__)) 


from airflow.sdk import DAG
with DAG(
    "demo_job",
    default_args={
        "depends_on_past": False,
        "retries": 1,
        "retry_delay": timedelta(minutes=5),
    },
    description="This job is demo the solution for parent and child tables load without orphan even though the data arrival have inconsistency",
    schedule="*/5 * * * *",
    start_date=datetime(2021, 1, 1),
    catchup=False,
    tags=["arul_added_dag"],
) as dag:

    t1 = BashOperator(
        task_id="print_start_time",
        bash_command="date",
    )

    t2 = BashOperator(
        task_id="create_tables_and_procs",
        depends_on_past=False,
        bash_command=f"python3 {BASE_DIR}/tasks/create_ddl.py"

    )

    t3 = BashOperator(
        task_id="insert_data",
        depends_on_past=False,
        bash_command=f"python3 {BASE_DIR}/tasks/insert_data.py"

    )

    t4 = BashOperator(
        task_id="load_order_details",
        depends_on_past=False,
        bash_command=f"python3 {BASE_DIR}/tasks/load_order_details.py"

    )

    t5 = BashOperator(
        task_id="load_monthly_summary",
        depends_on_past=False,
        bash_command=f"python3 {BASE_DIR}/tasks/load_monthly_summary.py"

    )

    t6 = BashOperator(
        task_id="print_end_time",
        depends_on_past=False,
        bash_command="date",
    )


    t1 >>  t2 >> t3 >> t4 >> t5 >> t6 