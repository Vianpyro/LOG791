//! Judging of a submission in a gVisor sandbox (ADR-0002, ADR-0018)

mod sandbox;

pub use sandbox::{Outcome, run_in_sandbox};
