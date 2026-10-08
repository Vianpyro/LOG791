//! Sign-in, sessions, offerings, submissions and verdict notifications.

use std::{env, error::Error};

use axum::{
    Json, Router,
    extract::State,
    http::StatusCode,
    routing::{get, post},
};
use contracts::Id;
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

const CONTRACT: i32 = 1;
const MAX_SOURCE: usize = 1024 * 1024;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let database = env::var("DATABASE_URL")?;
    let pool = PgPool::connect(&database).await?;
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await?;
    axum::serve(listener, app(pool)).await?;
    Ok(())
}

fn app(pool: PgPool) -> Router {
    Router::new()
        .route("/health", get(|| async { StatusCode::OK }))
        .route("/submissions", post(submit))
        .with_state(pool)
}

#[derive(Deserialize)]
struct Submission {
    course: Id,
    exercise: Id,
    language_pack: Id,
    source: String,
}

#[derive(Serialize)]
struct Submitted {
    id: Uuid,
}

const ENQUEUE: &str = "
    INSERT INTO jobs (contract, course, exercise, language_pack, source)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING id
";

async fn submit(
    State(pool): State<PgPool>,
    Json(submission): Json<Submission>,
) -> Result<(StatusCode, Json<Submitted>), StatusCode> {
    if submission.source.is_empty() || submission.source.len() > MAX_SOURCE {
        return Err(StatusCode::UNPROCESSABLE_ENTITY);
    }
    let id = sqlx::query_scalar(ENQUEUE)
        .bind(CONTRACT)
        .bind(submission.course.as_str())
        .bind(submission.exercise.as_str())
        .bind(submission.language_pack.as_str())
        .bind(submission.source)
        .fetch_one(&pool)
        .await
        .map_err(|error| {
            eprintln!("api: enqueue: {error}");
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
    Ok((StatusCode::ACCEPTED, Json(Submitted { id })))
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{
        body::Body,
        http::{Request, header},
    };
    use tower::ServiceExt;

    async fn post_submission(pool: &PgPool, body: &'static str) -> StatusCode {
        let request = Request::post("/submissions")
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::from(body))
            .unwrap();
        app(pool.clone()).oneshot(request).await.unwrap().status()
    }

    async fn waiting_jobs(pool: &PgPool) -> i64 {
        sqlx::query_scalar("SELECT count(*) FROM jobs WHERE state = 'waiting'")
            .fetch_one(pool)
            .await
            .unwrap()
    }

    #[tokio::test]
    async fn health_is_ok() {
        let pool = PgPool::connect_lazy("postgres://unused").unwrap();
        let request = Request::get("/health").body(Body::empty()).unwrap();
        let response = app(pool).oneshot(request).await.unwrap();
        assert_eq!(response.status(), StatusCode::OK);
    }

    #[sqlx::test(migrations = "../../db/migrations")]
    #[ignore = "needs PostgreSQL"]
    async fn submission_is_queued(pool: PgPool) {
        let body = r#"{"course": "log200", "exercise": "sum", "language_pack": "python", "source": "print(0)"}"#;
        assert_eq!(post_submission(&pool, body).await, StatusCode::ACCEPTED);
        assert_eq!(waiting_jobs(&pool).await, 1);
    }

    #[sqlx::test(migrations = "../../db/migrations")]
    #[ignore = "needs PostgreSQL"]
    async fn invalid_identifier_is_rejected(pool: PgPool) {
        let body = r#"{"course": "log200", "exercise": "../sum", "language_pack": "python", "source": "print(0)"}"#;
        assert_eq!(
            post_submission(&pool, body).await,
            StatusCode::UNPROCESSABLE_ENTITY
        );
        assert_eq!(waiting_jobs(&pool).await, 0);
    }

    #[sqlx::test(migrations = "../../db/migrations")]
    #[ignore = "needs PostgreSQL"]
    async fn empty_source_is_rejected(pool: PgPool) {
        let body =
            r#"{"course": "log200", "exercise": "sum", "language_pack": "python", "source": ""}"#;
        assert_eq!(
            post_submission(&pool, body).await,
            StatusCode::UNPROCESSABLE_ENTITY
        );
        assert_eq!(waiting_jobs(&pool).await, 0);
    }
}
