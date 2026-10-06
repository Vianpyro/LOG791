-- Judge claims only through this function: no direct access to jobs (ADR-0001)

CREATE FUNCTION claim_job()
RETURNS TABLE (
    id uuid,
    contract integer,
    course identifier,
    exercise identifier,
    language_pack identifier,
    source text
)
LANGUAGE sql SECURITY DEFINER SET search_path = pg_catalog, pg_temp
BEGIN ATOMIC
    UPDATE public.jobs SET state = 'running', claimed_at = now()
    WHERE jobs.id = (
        SELECT j.id FROM public.jobs j
        WHERE j.state = 'waiting'
        ORDER BY j.enqueued_at, j.id LIMIT 1 FOR UPDATE SKIP LOCKED
    )
    RETURNING jobs.id, jobs.contract, jobs.course, jobs.exercise, jobs.language_pack, jobs.source;
END;

REVOKE EXECUTE ON FUNCTION claim_job() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION claim_job() TO judge;
