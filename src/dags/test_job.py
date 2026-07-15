import textwrap
from datetime import datetime, timedelta
from airflow.providers.standard.operators.bash import BashOperator
import os 

BASE_DIR = os.path.dirname(os.path.dirname(__file__)) 

from airflow.sdk import DAG
with DAG(
    "test_job",
    default_args={
        "depends_on_past": False
    },
    description="A simple tutorial DAG",
    schedule=timedelta(days=1),
    start_date=datetime(2021, 1, 1),
    catchup=False,
    tags=["arul_added_dag"],
) as dag:

    t1 = BashOperator(
        task_id="print_start_time",
        bash_command="date",
    )

    t2 = BashOperator(
        task_id="say_hello",
        depends_on_past=False,
        bash_command=f"python3 {BASE_DIR}/tasks/test.py"

    )

    t3 = BashOperator(
        task_id="print_end_time",
        depends_on_past=False,
        bash_command="date",
    )


    t1 >> t2 >> t3
