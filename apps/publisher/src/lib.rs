//! Validation, public projection and releases of a course's content (ADR-0005)

mod exercises;
mod import_report;
mod statement;

pub use exercises::exercises;
pub use import_report::no_import_report;
pub use statement::statement;

#[cfg(test)]
mod fixtures;
