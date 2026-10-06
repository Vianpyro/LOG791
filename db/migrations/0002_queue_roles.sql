-- Least privilege on the queue (ADR-0001, ADR-0004)
-- Login users and their passwords come from Ansible: GRANT log791_judge TO <user>.

DO $$
BEGIN
    CREATE ROLE log791_api NOLOGIN;
EXCEPTION WHEN duplicate_object OR unique_violation THEN
    RAISE NOTICE 'Role log791_api already exists, skipping creation.';
END $$;

DO $$
BEGIN
    CREATE ROLE log791_judge NOLOGIN;
EXCEPTION WHEN duplicate_object OR unique_violation THEN
    RAISE NOTICE 'Role log791_judge already exists, skipping creation.';
END $$;

-- API: Enqueues, reads resuls, replaces a waiting run (ADR-0030)
GRANT SELECT, INSERT, UPDATE (state, finished_at) ON jobs TO log791_api;

-- Judge: Claims and writes the verdict; never the submitted code or its target
GRANT SELECT, UPDATE (state, claimed_at, finished_at, result) ON jobs TO log791_judge;
