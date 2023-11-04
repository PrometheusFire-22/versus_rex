#!/bin/bash

# This script initializes the PostgreSQL environment for your project.
# Replace 'versus_rex' with your desired database name,
# 'oedypus' with your desired username, and 'Zarathustra22!' with your desired password.

# Exit immediately if a command exits with a non-zero status.
set -e

# Replace 'versus_rex' with the name of the database you want to create.
DATABASE_NAME="versus_rex"

# Replace 'myusername' with the username you want to create.
USERNAME="oedypus"

# Replace 'mypassword' with the password for the new user.
PASSWORD="Zarathustra22!"

# Create a new PostgreSQL role.
echo "Creating role..."
sudo -u postgres psql -c "CREATE ROLE $USERNAME WITH LOGIN PASSWORD '$PASSWORD';"

# Alter role to set superuser or necessary privileges.
echo "Altering role..."
sudo -u postgres psql -c "ALTER ROLE $USERNAME SUPERUSER CREATEDB;"

# Create a new database with the new role as the owner.
echo "Creating database..."
sudo -u postgres psql -c "CREATE DATABASE $DATABASE_NAME WITH OWNER $USERNAME;"

# Grant all privileges of the new database to the new role.
echo "Granting privileges to user on database..."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DATABASE_NAME TO $USERNAME;"

# Optionally, set the default schema search path for the new role.
echo "Setting schema search path..."
sudo -u postgres psql -c "ALTER ROLE $USERNAME SET search_path TO my_schema, public;"

# Ensure the new role does not have more privileges than necessary.
# If the role should not be a superuser, comment out or remove the ALTER ROLE line above
# and uncomment and customize the line below according to your needs.
# sudo -u postgres psql -c "ALTER ROLE $USERNAME NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;"

echo "PostgreSQL environment initialization complete."
