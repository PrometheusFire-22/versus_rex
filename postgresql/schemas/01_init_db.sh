#!/bin/bash

# Replace 'versus_rex' with your desired database name,
# 'oedypus' with your desired username, and 'Zarathustra22!' with your desired password.

# Exit immediately if a command exits with a non-zero status.
set -e

# Database name and user credentials
DATABASE_NAME="versus_rex"
USERNAME="oedypus"
PASSWORD="Zarathustra22!"

# Create a new PostgreSQL role.
echo "Creating role..."
sudo -u postgres createuser --login --password "$PASSWORD" "$USERNAME"

# Alter role to set superuser or necessary privileges.
echo "Altering role to superuser and allowing database creation..."
sudo -u postgres psql -c "ALTER ROLE $USERNAME SUPERUSER CREATEDB;"

# Create a new database with the new role as the owner.
echo "Creating database..."
sudo -u postgres createdb --owner="$USERNAME" "$DATABASE_NAME"

# Grant all privileges of the new database to the new role.
echo "Granting privileges to user on database..."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DATABASE_NAME TO $USERNAME;"

# Optionally, set the default schema search path for the new role.
# Replace 'my_schema' with the schema you will use.
echo "Setting schema search path..."
sudo -u postgres psql -d "$DATABASE_NAME" -c "ALTER ROLE $USERNAME SET search_path TO my_schema, public;"

# Create the applied_migrations table to track migration history
echo "Creating applied_migrations table to track migrations..."
sudo -u postgres psql -d "$DATABASE_NAME" -c "
BEGIN;
CREATE TABLE IF NOT EXISTS applied_migrations (
    migration_name TEXT PRIMARY KEY,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMIT;
"

echo "PostgreSQL environment initialization complete."
