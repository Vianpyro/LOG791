//! Judging of a submission in a gVisor sandbox (ADR-0002, ADR-0018)

mod sandbox;
mod stdio;
mod verdict;

pub use sandbox::{Outcome, run_in_sandbox};
pub use stdio::case_verdict;
pub use verdict::Verdict;
