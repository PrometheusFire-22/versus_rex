
import psycopg2
import os
import logging
from contextlib import contextmanager

# Configure logging
logging.basicConfig(
    filename='migration.log',
    filemode='a',
    format='%(asctime)s - %(levelname)s - %(message)s',
    level=logging.INFO
)

# Database connection parameters
db_params = {
    "dbname": os.getenv("DB_NAME"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "host": os.getenv("DB_HOST"),
    "port": os.getenv("DB_PORT")
}

# Context manager for database connection
@contextmanager
def get_db_connection():
    conn = psycopg2.connect(**db_params)
    try:
        yield conn
    finally:
        conn.close()

# Context manager for database cursor
@contextmanager
def get_db_cursor(commit=False):
    with get_db_connection() as conn:
        cursor = conn.cursor()
        try:
            yield cursor
            if commit:
                conn.commit()
        except Exception as e:
            conn.rollback()
            logging.error(f"Transaction failed: {e}")
            raise
        finally:
            cursor.close()

# Function to check if a migration was applied
def is_migration_applied(cursor, migration_name):
    cursor.execute("SELECT COUNT(*) FROM applied_migrations WHERE migration_name = %s", (migration_name,))
    return cursor.fetchone()[0] > 0

# Function to record a migration as applied
def record_migration(cursor, migration_name):
    cursor.execute("INSERT INTO applied_migrations (migration_name) VALUES (%s)", (migration_name,))

# Function to apply a migration script
def apply_migration(cursor, filepath):
    filename = os.path.basename(filepath)
    if is_migration_applied(cursor, filename):
        logging.info(f"Migration {filename} already applied.")
        return
    
    logging.info(f"Applying migration {filename}")
    with open(filepath, 'r') as file:
        cursor.execute(file.read())
    record_migration(cursor, filename)
    logging.info(f"Migration {filename} applied successfully.")

# Main migration function
def migrate():
    # List of migration scripts
    migration_scripts = ['path_to_your_first_migration_script.sql', 'path_to_your_next_migration_script.sql']  # etc.

    with get_db_cursor(commit=True) as cursor:
        # Ensure the migrations tracking table exists
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS applied_migrations (
                migration_name TEXT PRIMARY KEY,
                applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        """)

        # Apply each migration script
        for script_path in migration_scripts:
            apply_migration(cursor, script_path)

def main():
    try:
        migrate()
    except Exception as e:
        logging.error(f"Migration failed: {e}")

if __name__ == '__main__':
    main()
