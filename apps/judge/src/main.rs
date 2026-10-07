//! Pulls jobs, runs the sandbox and writes the verdict.

use std::{
    env, fs, io,
    path::Path,
    process::{self, ExitCode},
    time::Duration,
};

use judge::{Verdict, judge_cases, read_cases};

// Python pack until packs are data (ADR-0013)
const IMAGE: &str = "python:3.14-alpine";
const TIMEOUT: Duration = Duration::from_secs(10);

#[tokio::main(flavor = "current_thread")]
async fn main() -> ExitCode {
    let mut args = env::args_os().skip(1);
    let (Some(exercise), Some(solution), None) = (args.next(), args.next(), args.next()) else {
        eprintln!("usage: judge <exercise> <solution.py>");
        return ExitCode::FAILURE;
    };
    match judge(Path::new(&exercise), Path::new(&solution)).await {
        Ok(true) => ExitCode::SUCCESS,
        Ok(false) => ExitCode::FAILURE,
        Err(error) => {
            eprintln!("judge: {error}");
            ExitCode::FAILURE
        }
    }
}

async fn judge(exercise: &Path, solution: &Path) -> io::Result<bool> {
    let cases = read_cases(&exercise.join("assessment"))?;
    let source = fs::read_to_string(solution)?;
    let name = format!("judge-{}", process::id());
    let command = ["python3", "-c", &source];
    let verdicts = judge_cases(&name, IMAGE, &command, &cases, TIMEOUT).await?;
    for (index, verdict) in verdicts.iter().enumerate() {
        println!("{} {verdict:?}", index + 1);
    }
    Ok(verdicts.iter().all(|&verdict| verdict == Verdict::Passed))
}
