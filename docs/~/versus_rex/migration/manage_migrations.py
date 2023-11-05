import psycopg2
import os

# Function to check if the migration has already been applied
def is_migration_applied(cursor, migration_name):
    cursor.execute("SELECT COUNT(1) FROM applied_migrations WHERE migration_name = %s", (migration_name,))
    return cursor.fetchone()[0] > 0

# Function to record a migration as applied
def record_migration(cursor, migration_name):
    cursor.execute("INSERT INTO applied_migrations (migration_name) VALUES (%s)", (migration_name,))

# Function to apply a migration script
def apply_migration(cursor, filename):
    # Extract the migration name from the filename
    migration_name = os.path.basename(filename)
    
    # Check if this migration has already been applied
    if is_migration_applied(cursor, migration_name):
        print(f"Migration {migration_name} has already been applied.")
        return
    
    print(f"Applying migration {filename}")
    with open(filename, 'r') as f:
        cursor.execute(f.read())
    
    # Record this migration as applied
    record_migration(cursor, migration_name)

# Function to get database connection and cursor
def get_db_cursor(commit=False):
    conn = psycopg2.connect(
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT")
    )
    return conn, conn.cursor()

# Main execution
if __name__ == "__main__":
    try:
        # Get the database connection and cursor
        conn, cur = get_db_cursor(commit=True)
        
        # Apply each migration script
        # TODO: Add logic to handle multiple scripts and track applied migrations.
        apply_migration(cur, 'path_to_your_migration_script.sql')
        
        # Commit changes if everything went well
        conn.commit()
    except Exception as e:
        # Roll back the changes on error
        conn.rollback()
        print(f"Error applying migrations: {e}")
    finally:
        # Always close the database connection
        cur.close()
        conn.close()
