BEGIN;

-- Step 1: Create the error_log table
CREATE TABLE IF NOT EXISTS email_schema.error_log (
  error_id SERIAL PRIMARY KEY,
  error_timestamp TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  error_message TEXT
);

-- Attempt to create the 'emails' table within the 'email_schema'.
DO $$
BEGIN
    CREATE TABLE IF NOT EXISTS email_schema.emails (
      email_id BIGSERIAL PRIMARY KEY,
      subject TEXT,
      sender VARCHAR(255) CHECK (sender ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'), -- More robust email validation regex
      recipient VARCHAR(255) CHECK (recipient ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
      sent_time TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(), -- Default to the current timestamp
      body_text TEXT,
      ip_address INET,
      x_originating_ip INET,
      received TEXT,
      user_agent VARCHAR(255),
      authentication_results TEXT,
      dkim_signature TEXT,
      sender_user_id INT,
      recipient_user_id INT
      -- phone_number VARCHAR(255) CHECK (phone_number ~* '^\(\d{3}\) \d{3}-\d{4}$') -- Example format: (123) 456-7890
    );

    -- Index for sender_user_id foreign key
    CREATE INDEX IF NOT EXISTS idx_emails_sender_user_id ON email_schema.emails(sender_user_id);

    -- Index for recipient_user_id foreign key
    CREATE INDEX IF NOT EXISTS idx_emails_recipient_user_id ON email_schema.emails(recipient_user_id);

    -- Index for sent_time to quickly find emails by date
    CREATE INDEX IF NOT EXISTS idx_emails_sent_time ON email_schema.emails(sent_time);

    -- Index for sender and recipient email address columns for quick searches
    CREATE INDEX IF NOT EXISTS idx_emails_sender ON email_schema.emails(sender);
    CREATE INDEX IF NOT EXISTS idx_emails_recipient ON email_schema.emails(recipient);

EXCEPTION
    WHEN undefined_table THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Attempted to create index on undefined table.');
    WHEN undefined_column THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Attempted to create index on undefined column.');
    WHEN duplicate_object THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Attempted to create a duplicate index.');
    WHEN others THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Unexpected error occurred while creating indexes: ' || SQLERRM);
        RAISE;
END;
$$;

DO $$
BEGIN
    -- Adding foreign key constraints to the 'emails' table.
    ALTER TABLE email_schema.emails
      ADD CONSTRAINT fk_emails_sender_user_id
      FOREIGN KEY (sender_user_id) REFERENCES email_schema.users(user_id)
      ON DELETE SET NULL,
      ADD CONSTRAINT fk_emails_recipient_user_id
      FOREIGN KEY (recipient_user_id) REFERENCES email_schema.users(user_id)
      ON DELETE SET NULL;

    -- Add indexes on foreign key columns after adding constraints
    CREATE INDEX IF NOT EXISTS idx_emails_sender_user_id ON email_schema.emails(sender_user_id);
    CREATE INDEX IF NOT EXISTS idx_emails_recipient_user_id ON email_schema.emails(recipient_user_id);

EXCEPTION
    WHEN undefined_table THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Undefined table referenced in foreign key constraint or index creation.');
        RAISE;
    WHEN undefined_column THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Undefined column referenced in foreign key constraint or index creation.');
        RAISE;
    WHEN duplicate_object THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Duplicate foreign key constraint or index name.');
        RAISE;
    WHEN others THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Unexpected error occurred while adding foreign key constraints or creating indexes: ' || SQLERRM);
        RAISE;
END;
$$;



DO $$
BEGIN
    -- Creating the 'attachments' table within the 'email_schema'.
    CREATE TABLE IF NOT EXISTS email_schema.attachments (
      attachment_id BIGSERIAL PRIMARY KEY,
      email_id BIGINT NOT NULL,
      file_name TEXT NOT NULL,
      file_type TEXT NOT NULL, -- assuming every attachment must have a file type
      file_size BIGINT NOT NULL CHECK (file_size >= 0), -- assuming file size must be non-negative
      content BYTEA -- consider storing only a reference to the file location if they're large
    );

    -- Adding foreign key constraint without CASCADE on delete
    ALTER TABLE email_schema.attachments
      ADD CONSTRAINT fk_attachments_email_id
      FOREIGN KEY (email_id) REFERENCES email_schema.emails(email_id) ON DELETE RESTRICT;

    -- Create an index on the email_id column to improve join performance
    CREATE INDEX IF NOT EXISTS idx_attachments_email_id ON email_schema.attachments(email_id);

    -- Optional: Create additional indexes on columns used in search queries
    CREATE INDEX IF NOT EXISTS idx_attachments_file_name ON email_schema.attachments(file_name);
    CREATE INDEX IF NOT EXISTS idx_attachments_file_type ON email_schema.attachments(file_type);

EXCEPTION
    WHEN undefined_table THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Undefined table referenced in foreign key constraint or index creation for attachments.');
        RAISE;
    WHEN undefined_column THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Undefined column referenced in foreign key constraint or index creation for attachments.');
        RAISE;
    WHEN duplicate_object THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Duplicate foreign key constraint or index name for attachments.');
        RAISE;
    WHEN others THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Unexpected error occurred while creating attachments table or creating indexes: ' || SQLERRM);
        RAISE;
END;
$$;

DO $$
BEGIN
    -- Adding foreign key constraint for attachments referencing emails without cascading deletes.
    ALTER TABLE email_schema.attachments
      ADD CONSTRAINT fk_attachments_email_id
      FOREIGN KEY (email_id) REFERENCES email_schema.emails(email_id)
      ON DELETE RESTRICT;

    -- Create an index on the email_id column to improve join performance
    CREATE INDEX IF NOT EXISTS idx_attachments_email_id ON email_schema.attachments(email_id);

EXCEPTION
    WHEN undefined_table THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Undefined table referenced in foreign key constraint or index creation.');
        RAISE;
    WHEN undefined_column THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Undefined column referenced in foreign key constraint or index creation.');
        RAISE;
    WHEN duplicate_object THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Duplicate foreign key constraint or index name.');
        RAISE;
    WHEN others THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Unexpected error occurred while adding foreign key constraints or creating indexes: ' || SQLERRM);
        RAISE;
END;
$$;



DO $$
BEGIN
    -- Creating the 'email_attachment_mapping' table for a many-to-many relationship.
    CREATE TABLE IF NOT EXISTS email_schema.email_attachment_mapping (
      email_id BIGINT NOT NULL,
      attachment_id BIGINT NOT NULL,
      PRIMARY KEY (email_id, attachment_id),
      CONSTRAINT fk_email_attachment_mapping_email_id FOREIGN KEY (email_id) REFERENCES email_schema.emails(email_id) ON DELETE RESTRICT,
      CONSTRAINT fk_email_attachment_mapping_attachment_id FOREIGN KEY (attachment_id) REFERENCES email_schema.attachments(attachment_id) ON DELETE RESTRICT
    );

    -- Since email_id and attachment_id are part of a composite primary key, they are indexed.
    -- Additional indexes can be created if there are frequent queries that filter or join on these columns independently.

    -- Create an index on the email_id column to improve performance for queries filtering by email_id
    CREATE INDEX IF NOT EXISTS idx_email_attachment_mapping_email_id ON email_schema.email_attachment_mapping(email_id);

    -- Create an index on the attachment_id column to improve performance for queries filtering by attachment_id
    CREATE INDEX IF NOT EXISTS idx_email_attachment_mapping_attachment_id ON email_schema.email_attachment_mapping(attachment_id);

EXCEPTION
    WHEN duplicate_table THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Duplicate table name: email_attachment_mapping.');
        RAISE;
    WHEN undefined_table THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Undefined table referenced in foreign key constraint or index creation.');
        RAISE;
    WHEN undefined_column THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Undefined column referenced in foreign key constraint or index creation.');
        RAISE;
    WHEN duplicate_object THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Duplicate foreign key constraint or index name.');
        RAISE;
    WHEN others THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Unexpected error occurred while creating email_attachment_mapping table or indexes: ' || SQLERRM);
        RAISE;
END;
$$;



DO $$
BEGIN
    -- Creating the 'email_status' table to track the state of emails.
    CREATE TABLE IF NOT EXISTS email_schema.email_status (
      status_id SERIAL PRIMARY KEY,
      email_id BIGINT NOT NULL,
      status TEXT NOT NULL CHECK (status IN ('sent', 'received', 'read', 'error', 'pending')), -- Add more statuses as needed
      updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );

    -- Index for email_id foreign key
    CREATE INDEX IF NOT EXISTS idx_email_status_email_id ON email_schema.email_status(email_id);

    -- Index for status column for quick searches
    CREATE INDEX IF NOT EXISTS idx_email_status_status ON email_schema.email_status(status);

    -- Index for updated_at to quickly find statuses by update date
    CREATE INDEX IF NOT EXISTS idx_email_status_updated_at ON email_schema.email_status(updated_at);

EXCEPTION
    WHEN duplicate_table THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Duplicate table name: email_status.');
        RAISE;
    WHEN check_violation THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Check constraint violation on table email_status.');
        RAISE;
    WHEN others THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Unexpected error occurred while creating email_status table or indexes: ' || SQLERRM);
        RAISE;
END;
$$;



DO $$
BEGIN
    -- Foreign key constraint for email_status referencing emails without cascading deletes.
    ALTER TABLE email_schema.email_status
      ADD CONSTRAINT fk_email_status_email_id
      FOREIGN KEY (email_id) REFERENCES email_schema.emails(email_id)
      ON DELETE RESTRICT;

    -- Explicitly create an index on the foreign key column, even though it's automatically indexed by PostgreSQL
    CREATE INDEX IF NOT EXISTS idx_fk_email_status_email_id ON email_schema.email_status(email_id);

EXCEPTION
    WHEN duplicate_object THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Duplicate constraint or index name: fk_email_status_email_id or idx_fk_email_status_email_id.');
        RAISE;
    WHEN undefined_table THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Undefined table: email_status or emails.');
        RAISE;
    WHEN undefined_column THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Undefined column: email_id in table email_status or emails.');
        RAISE;
    WHEN others THEN
        INSERT INTO email_schema.error_log (error_message) VALUES ('Unexpected error occurred while adding foreign key constraint or creating index for email_status table: ' || SQLERRM);
        RAISE;
END;
$$;

-- Commit the changes if all operations are successful.
COMMIT;


