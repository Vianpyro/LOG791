-- Judge finishes only through this function: no direct access to jobs (ADR-0001)

CREATE TYPE case_verdict AS ENUM (
    'passed',
    'wrong-answer',
    'crashed',
    'timed-out'
);

CREATE FUNCTION finish_job(job uuid, verdicts case_verdict[])
RETURNS boolean
LANGUAGE sql SECURITY DEFINER SET search_path = pg_catalog, pg_temp
BEGIN ATOMIC
    WITH finished AS (
        UPDATE public.jobs
        SET state = 'done', finished_at = now(), result = jsonb_build_object('cases', to_jsonb(verdicts))
        WHERE jobs.id = job AND jobs.state = 'running' AND cardinality(verdicts) > 0
        RETURNING 1
    )
    SELECT count(*) = 1 FROM finished;
END;

REVOKE EXECUTE ON FUNCTION finish_job(uuid, case_verdict[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION finish_job(uuid, case_verdict[]) TO judge;
