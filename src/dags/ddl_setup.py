import textwrap
from datetime import datetime, timedelta
from airflow.providers.standard.operators.bash import BashOperator
import os 

BASE_DIR = os.path.dirname(os.path.dirname(__file__)) 



from airflow.sdk import DAG
with DAG(
    "ddl_setup",
    default_args={
        "depends_on_past": False,
        "retries": 1,
        "retry_delay": timedelta(minutes=5),
    },
    description="One-off/manual setup: creates the demo schema's tables and stored procedures",
    schedule=None,
    start_date=datetime(2021, 1, 1),
    catchup=False,
    tags=["arul_added_dag"],
) as dag:


    t1 = BashOperator(
        task_id="create_tables_and_procs",
        depends_on_past=False,
        bash_command=f"python3 {BASE_DIR}/tasks/create_ddl.py"

    )

