import psycopg2
from psycopg2 import sql
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Connection parameters - adjust these according to your setup
db_params = {
    "dbname": "your_dbname",
    "user": "your_username",
    "password": "your_password",
    "host": "localhost",
    "port": 5432
}

def get_db_connection():
    try:
        conn = psycopg2.connect(**db_params)
        return conn
    except Exception as e:
        logging.error(f"Error connecting to the database: {e}")
        raise

def setup():
    logging.info("Setting up test environment.")
    # Setup can include creating a test database or other preparatory tasks.
    # For this example, we are simply ensuring we can connect to the database.
    conn = get_db_connection()
    conn.close()

def teardown():
    logging.info("Tearing down test environment.")
    # Teardown would involve cleaning up the database or any other necessary cleanup.
    # In this simple example, there is no persistent change to clean up.

def test_schema_creation():
    conn = get_db_connection()
    conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)  # Allow to create schema outside of a transaction
    cursor = conn.cursor()

    try:
        # Define the schema and role
        schema_name = 'email_schema'
        role_name = 'oedypus'

        # Check if the role exists
        cursor.execute(sql.SQL("SELECT 1 FROM pg_roles WHERE rolname = %s;"), (role_name,))
        role_exists = cursor.fetchone()
        assert role_exists, f"Role '{role_name}' does not exist."

        # Check if the schema already exists
        cursor.execute(sql.SQL("SELECT schema_name FROM information_schema.schemata WHERE schema_name = %s;"), (schema_name,))
        schema_exists = cursor.fetchone()

        # Create schema if it does not exist
        if not schema_exists:
            cursor.execute(sql.SQL("CREATE SCHEMA IF NOT EXISTS {} AUTHORIZATION {};").format(
                sql.Identifier(schema_name),
                sql.Identifier(role_name)
            ))

        # Check if the role has the correct default search path
        cursor.execute(sql.SQL("SHOW search_path;"))
        search_path = cursor.fetchone()
        assert schema_name in search_path[0], f"Search path for role '{role_name}' is incorrect."

        logging.info(f"Schema '{schema_name}' exists and role '{role_name}' has the correct search path.")
    
    except Exception as e:
        logging.error(f"An error occurred: {e}")
        raise
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    setup()
    try:
        test_schema_creation()
    finally:
        teardown()
