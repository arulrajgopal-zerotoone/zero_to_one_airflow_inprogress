import psycopg2
import os

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
            # Call the stored procedure
            cur.execute("CALL load_monthly_summary()")
            print("Procedure executed successfully.")
            
finally:
    conn.close()
