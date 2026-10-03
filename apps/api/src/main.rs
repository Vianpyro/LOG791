//! Sign-in, sessions, offerings, submissions and verdict notifications.

#[tokio::main]
async fn main() {
    let app = Router::new().route("/health", get(|| async { "ok" }));
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap();
    axum::server(listener, app).await.unwrap();
}
