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
    use sqlx::PgPool;

    async fn enqueue(pool: &PgPool) -> Uuid {
        todo!()
    }

    async fn claim_as_judge(pool: &PgPool) -> Option<Job> {
        todo!()
    }

    #[sqlx::test(migrations = "../../db/migrations")]
    #[ignore = "needs PostgreSQLs"]
    async fn empty_queue_has_nothing_to_claim(pool: PgPool) {
        todo!()
    }
}
