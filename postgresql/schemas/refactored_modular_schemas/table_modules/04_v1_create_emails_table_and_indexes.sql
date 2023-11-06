-- Module: Create Emails Table and Indexes
DO $$
BEGIN
    -- Attempt to create the 'emails' table with appropriate data types and constraints
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'email_schema' AND tablename = 'emails') THEN
        CREATE TABLE email_schema.emails (
            email_id BIGSERIAL PRIMARY KEY,
            subject TEXT,
            sender VARCHAR(255) CHECK (sender ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
            recipient VARCHAR(255) CHECK (recipient ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
            sent_time TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
            body_text TEXT,
            ip_address INET,
            x_originating_ip INET,
            received TEXT,
            user_agent VARCHAR(255),
            authentication_results TEXT,
            dkim_signature TEXT,
            sender_user_id INT,
            recipient_user_id INT
        );
    END IF;

    -- After ensuring the 'emails' table exists, create indexes to optimize search and lookups
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_emails_sender_user_id ON email_schema.emails(sender_user_id);
        CREATE INDEX IF NOT EXISTS idx_emails_recipient_user_id ON email_schema.emails(recipient_user_id);
        CREATE INDEX IF NOT EXISTS idx_emails_sent_time ON email_schema.emails(sent_time);
        CREATE INDEX IF NOT EXISTS idx_emails_sender ON email_schema.emails(sender);
        CREATE INDEX IF NOT EXISTS idx_emails_recipient ON email_schema.emails(recipient);
    EXCEPTION
        WHEN undefined_table THEN
            INSERT INTO email_schema.error_log (error_message) VALUES ('Attempted to create index on undefined table.');
            RAISE;
        WHEN undefined_column THEN
            INSERT INTO email_schema.error_log (error_message) VALUES ('Attempted to create index on undefined column.');
        WHEN duplicate_object THEN
            INSERT INTO email_schema.error_log (error_message) VALUES ('Attempted to create a duplicate index.');
        WHEN OTHERS THEN
            INSERT INTO email_schema.error_log (error_message) VALUES ('Unexpected error occurred while creating indexes: ' || SQLERRM);
            RAISE;
    END;
END;
$$ LANGUAGE plpgsql;
