import logging
import os
import psycopg2
from psycopg2 import sql
import pytest

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Connection parameters - obtain from environment variables
db_params = {
    "dbname": os.environ.get("DB_NAME"),
    "user": os.environ.get("DB_USER"),
    "password": os.environ.get("DB_PASSWORD"),
    "host": os.environ.get("DB_HOST", "localhost"),
    "port": os.environ.get("DB_PORT", 5432)
}

@pytest.fixture(scope="module")
def db_connection():
    try:
        conn = psycopg2.connect(**db_params)
        logging.info("Database connection established.")
        yield conn
    except psycopg2.DatabaseError as e:
        logging.error(f"Database connection failed: {e}")
        pytest.fail(f"Database connection failed: {e}")
    finally:
        conn.close()
        logging.info("Database connection closed.")

@pytest.fixture(scope="module")
def cursor(db_connection):
    cur = db_connection.cursor()
    yield cur
    cur.close()

@pytest.fixture(scope="function", autouse=True)
def rollback_transaction(request, db_connection):
    # Start a transaction before each test
    db_connection.begin()
    logging.info("Transaction started for test.")

    def rollback():
        # Rollback the transaction after each test
        db_connection.rollback()
        logging.info("Transaction rolled back.")

    request.addfinalizer(rollback)

def check_role_exists(cursor, role_name):
    try:
        cursor.execute(sql.SQL("SELECT 1 FROM pg_roles WHERE rolname = %s;"), (role_name,))
        return cursor.fetchone() is not None
    except psycopg2.DatabaseError as e:
        logging.error(f"Check role exists failed: {e}")
        return False

def test_role_exists(cursor):
    role_name = 'oedypus'
    assert check_role_exists(cursor, role_name), f"Role '{role_name}' does not exist."
    logging.info(f"Role '{role_name}' confirmed to exist.")

def test_schema_creation(cursor):
    schema_name = 'email_schema'
    role_name = 'oedypus'

    try:
        cursor.execute(sql.SQL("SELECT schema_name FROM information_schema.schemata WHERE schema_name = %s;"), (schema_name,))
        if cursor.fetchone() is None:
            cursor.execute(sql.SQL("CREATE SCHEMA IF NOT EXISTS {} AUTHORIZATION {};").format(
                sql.Identifier(schema_name),
                sql.Identifier(role_name)
            ))
            logging.info(f"Schema '{schema_name}' created.")

        cursor.execute(sql.SQL("SELECT schema_name FROM information_schema.schemata WHERE schema_name = %s;"), (schema_name,))
        assert cursor.fetchone() is not None, f"Schema '{schema_name}' was not created."
        logging.info(f"Schema '{schema_name}' existence confirmed.")
    except psycopg2.DatabaseError as e:
        logging.error(f"Schema creation test failed: {e}")
        pytest.fail(f"Schema creation test failed: {e}")
