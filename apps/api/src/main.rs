//! Sign-in, sessions, offerings, submissions and verdict notifications.

use axum::{Router, http::StatusCode, routing::get};

#[tokio::main]
async fn main() -> std::io::Result<()> {
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await?;
    axum::serve(listener, app()).await
}

fn app() -> Router {
    Router::new().route("/health", get(|| async { StatusCode::OK }))
}

#[cfg(test)]
mod tests {
    use axum::{
        body::Body,
        http::{Request, StatusCode},
    };
    use tower::ServiceExt;

    #[tokio::test]
    async fn health_is_ok() {
        let request = Request::get("/health").body(Body::empty()).unwrap();
        let response = super::app().oneshot(request).await.unwrap();
        assert_eq!(response.status(), StatusCode::OK);
    }
}
