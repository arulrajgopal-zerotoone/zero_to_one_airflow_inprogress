import psycopg2
import os

BASE_DIR = os.path.dirname(__file__)

# Connect to the database
conn = psycopg2.connect(
    host=os.environ["POSTGRES_HOST"],
    database=os.environ["POSTGRES_DB"],
    user=os.environ["POSTGRES_USER"],
    password=os.environ["POSTGRES_PASSWORD"]
)

try:
    with conn:
        with conn.cursor() as cur:
            # Read the SQL file content
            with open(f"{BASE_DIR}/createStatement.sql", "r") as sql_file:
                sql_script = sql_file.read()

            # Execute the SQL file content
            cur.execute(sql_script)
            print("SQL file executed successfully.")

finally:
    conn.close()
    
