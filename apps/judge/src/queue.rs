//! Jobs claimed from the PostgreSQL queue (ADR-0001)

use sqlx::{FromRow, PgConnection, types::Uuid};

#[derive(Debug, FromRow)]
pub struct Job {
    pub id: Uuid,
    pub contract: i32,
    pub course: String,
    pub exercise: String,
    pub language_pack: String,
    pub source: String,
}

const CLAIM: &str = r#"
    SELECT id, contract, course, exercise, language_pack, source FROM claim_job()
"#;

pub async fn claim(connection: &mut PgConnection) -> sqlx::Result<Option<Job>> {
    sqlx::query_as(CLAIM).fetch_optional(connection).await
}

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::{PgPool, Postgres, Transaction};
    use std::time::Duration;
    use tokio::time;

    const AS_JUDGE: &str = "SET LOCAL ROLE judge";
    const AS_API: &str = "SET LOCAL ROLE api";

    const ENQUEUE: &str = r#"
        INSERT INTO jobs (contract, course, exercise, language_pack, source)
        VALUES (1, 'log200', 'sum', 'python', 'print(0)')
        RETURNING id
    "#;

    const DENIED: &str = "42501"; // SQLSTATE insufficient_privilege

    async fn enqueue(pool: &PgPool) -> Uuid {
        sqlx::query_scalar(ENQUEUE).fetch_one(pool).await.unwrap()
    }

    // Tests connect as a superuser: each check runs with the role's privileges instead
    async fn begin_as(pool: &PgPool, role: &'static str) -> Transaction<'static, Postgres> {
        let mut transaction = pool.begin().await.unwrap();
        sqlx::query(role).execute(&mut *transaction).await.unwrap();
        transaction
    }

    async fn claim_as_judge(pool: &PgPool) -> Option<Uuid> {
        let mut transaction = begin_as(pool, AS_JUDGE).await;
        let job = claim(&mut transaction).await.unwrap();
        transaction.commit().await.unwrap();
        job.map(|job| job.id)
    }

    #[track_caller]
    fn assert_denied(error: &sqlx::Error) {
        let code = error.as_database_error().and_then(|error| error.code());
        assert_eq!(code.as_deref(), Some(DENIED), "{error}");
    }

    #[sqlx::test(migrations = "../../db/migrations")]
    #[ignore = "needs PostgreSQL"]
    async fn empty_queue_has_nothing_to_claim(pool: PgPool) {
        assert_eq!(claim_as_judge(&pool).await, None);
    }

    #[sqlx::test(migrations = "../../db/migrations")]
    #[ignore = "needs PostgreSQL"]
    async fn jobs_are_claimed_oldest_first_and_once(pool: PgPool) {
        let first = enqueue(&pool).await;
        let second = enqueue(&pool).await;
        assert_eq!(claim_as_judge(&pool).await, Some(first));
        assert_eq!(claim_as_judge(&pool).await, Some(second));
        assert_eq!(claim_as_judge(&pool).await, None);
    }

    #[sqlx::test(migrations = "../../db/migrations")]
    #[ignore = "needs PostgreSQL"]
    async fn concurrent_judges_skip_a_locked_job(pool: PgPool) {
        let first = enqueue(&pool).await;
        let second = enqueue(&pool).await;
        let mut holding = begin_as(&pool, AS_JUDGE).await;
        let held = claim(&mut holding).await.unwrap().map(|job| job.id);
        // Without SKIP LOCKED, this waits for `holding` to end
        let other = time::timeout(Duration::from_secs(5), claim_as_judge(&pool))
            .await
            .expect("blocked behind a locked job");
        assert_eq!(held, Some(first));
        assert_eq!(other, Some(second));
    }

    #[sqlx::test(migrations = "../../db/migrations")]
    #[ignore = "needs PostgreSQL"]
    async fn judge_has_no_direct_access_to_jobs(pool: PgPool) {
        enqueue(&pool).await;
        for statement in [
            "SELECT source FROM jobs",
            "UPDATE jobs SET state = 'failed', finished_at = now()",
        ] {
            let mut transaction = begin_as(&pool, AS_JUDGE).await;
            let error = sqlx::query(statement)
                .execute(&mut *transaction)
                .await
                .unwrap_err();
            assert_denied(&error);
        }
    }

    #[sqlx::test(migrations = "../../db/migrations")]
    #[ignore = "needs PostgreSQL"]
    async fn only_the_judge_can_claim(pool: PgPool) {
        enqueue(&pool).await;
        let mut transaction = begin_as(&pool, AS_API).await;
        assert_denied(&claim(&mut transaction).await.unwrap_err());
    }
}
