# Project Structure

This document describes the directory structure for the project, including the purpose of each directory and subdirectory.

## Root Directory

At the highest level, the project root should contain:

- `README.md`: The main documentation file that includes project information and setup instructions.
- `requirements.txt` or `Pipfile`: Lists all Python dependencies for the project.
- `.env`: Stores configuration variables and sensitive information, which should not be tracked by version control.
- `.gitignore`: Specifies intentionally untracked files to ignore.
- `app/`: Contains the application source code.
- `postgresql/`: Contains all PostgreSQL related scripts and files.
- `tests/`: Contains test cases and testing scripts.

### `/app`

The application source code directory, which includes:

- `main.py`: The entry point to the application.
- `modules/`: Modular code separated into concerns or functionality.
- `static/`: Static files like CSS, JavaScript, and images.
- `templates/`: HTML templates for the web interface.

### `/postgresql`

This directory includes everything related to the PostgreSQL database:

- `/schemas`: SQL scripts to initialize the database schema.
- `/migrations`: Incremental changes to the database schema.
- `/seeds`: Data import files to populate the database with initial data.

#### `/postgresql/schemas`

Contains the initial database setup scripts:

- `init_db.sh`: A shell script to initialize the PostgreSQL database.
- `01_create_database.sql`: SQL script to create the database.
- `02_create_schema.sql`: SQL script to set up the database schema.
- `03_create_tables.sql`: SQL script to create tables.
- `04_create_views.sql`: SQL script to create views.
- `05_create_indexes.sql`: SQL script to create indexes.
- `06_create_triggers.sql`: SQL script to create triggers.

#### `/postgresql/migrations`

Stores migration scripts:

- Each script should have a timestamp or version number as part of the file name for ordering.

#### `/postgresql/seeds`

Includes data seeding scripts or files:

- These could be SQL files or scripts that load data from CSV or JSON files.

### `/tests`

The directory for test code:

- Organize tests to reflect the module or feature they are testing.
- Include a `README.md` with instructions on how to run the tests.

## Additional Directories

Depending on the project complexity, you may include additional directories such as:

- `/docs`: For more extensive documentation.
- `/scripts`: For utility scripts that aid in development or deployment.
- `/config`: For additional configuration files.

Remember to update this file as the project structure evolves.
