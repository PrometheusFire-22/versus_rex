import pytest
import psycopg2

# Fixture to set up the database connection
@pytest.fixture
def db_conn():
    connection = psycopg2.connect(user="user", password="password", host="localhost", port="5432", database="testdb")
    yield connection
    connection.close()

# A simple test function that uses the database connection
def test_db_connection(db_conn):
    cursor = db_conn.cursor()
    cursor.execute("SELECT 1;")
    result = cursor.fetchone()
    assert result == (1,)
