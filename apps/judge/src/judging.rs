//! Submissions run on every standard I/O case of an exercise (ADR-0013, ADR-0018)

use std::{io, time::Duration};

use crate::{Case, Verdict, case_verdict, run_in_sandbox};

// One case at a time; concurrent sandboxes once V-0013 measures how many a judge holds
pub async fn judge_cases(
    name: &str,
    image: &str,
    command: &[&str],
    cases: &[Case],
    timeout: Duration,
) -> io::Result<Vec<Verdict>> {
    let mut verdicts = Vec::with_capacity(cases.len());
    for (index, case) in cases.iter().enumerate() {
        let container = format!("{name}-{index}");
        let outcome = run_in_sandbox(&container, image, command, &case.input, timeout).await?;
        verdicts.push(case_verdict(&outcome, &case.expected));
    }
    Ok(verdicts)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::read_cases;
    use std::path::Path;

    const IMAGE: &str = "python:3.14-alpine";
    const TIMEOUT: Duration = Duration::from_mins(1);

    async fn python_on_sum(name: &str, code: &str) -> Vec<Verdict> {
        let assessment = Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("../../examples/content/exercises/sum/assessment");
        let cases = read_cases(&assessment).unwrap();
        let command = ["python3", "-c", code];
        judge_cases(
            &format!("judge-test-{name}"),
            IMAGE,
            &command,
            &cases,
            TIMEOUT,
        )
        .await
        .unwrap()
    }

    #[tokio::test]
    #[ignore = "needs Docker with runsc"]
    async fn reference_solution_passes_every_case() {
        let sum = "import sys; print(sum(map(int, sys.stdin.read().split())))";
        assert_eq!(python_on_sum("reference", sum).await, [Verdict::Passed; 3]);
    }

    #[tokio::test]
    #[ignore = "needs Docker with runsc"]
    async fn wrong_solution_fails_every_case() {
        assert_eq!(
            python_on_sum("wrong", "print(0)").await,
            [Verdict::WrongAnswer; 3]
        );
    }
}
