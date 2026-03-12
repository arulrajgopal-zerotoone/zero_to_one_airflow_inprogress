import psycopg2

# Connect to the database
conn = psycopg2.connect(
    host="localhost",
    database="postgres",
    user="postgres",
    password="Arulraj@1234"
)


try:
    with conn:
        with conn.cursor() as cur:
            # Call the stored procedure
            cur.execute("CALL load_order_details()")
            print("Procedure executed successfully.")
            
finally:
    conn.close()
