//! Verdict of one test case (ADR-0011, ADR-0014)

#[derive(sqlx::Type, Debug, Clone, Copy, PartialEq, Eq)]
#[sqlx(type_name = "case_verdict", rename_all = "kebab-case")]
pub enum Verdict {
    Passed,
    WrongAnswer,
    Crashed,
    TimedOut,
}
