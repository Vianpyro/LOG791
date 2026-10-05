//! Validation, public projection and releases of a course's content (ADR-0005)

mod exercises;
mod statement;

pub use exercises::exercises;
pub use statement::statement;

#[cfg(test)]
mod fixtures;
