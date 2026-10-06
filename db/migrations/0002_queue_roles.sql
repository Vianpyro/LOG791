-- Least privilege on the queue (ADR-0001, ADR-0004)
-- Login users and their passwords come from Ansible: GRANT judge TO <user>.

DO $$
BEGIN
    CREATE ROLE api NOLOGIN;
EXCEPTION WHEN duplicate_object OR unique_violation THEN
    RAISE NOTICE 'Role api already exists, skipping creation.';
END $$;

DO $$
BEGIN
    CREATE ROLE judge NOLOGIN;
EXCEPTION WHEN duplicate_object OR unique_violation THEN
    RAISE NOTICE 'Role judge already exists, skipping creation.';
END $$;

-- API: Enqueues, reads resuls, replaces a waiting run (ADR-0030)
GRANT SELECT, INSERT, UPDATE (state, finished_at) ON jobs TO api;
