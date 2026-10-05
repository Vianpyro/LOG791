//! Verdict of one test case (ADR-0011, ADR-0014)

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Verdict {
    Passed,
    WrongAnswer,
    Crashed,
    TimedOut,
}
