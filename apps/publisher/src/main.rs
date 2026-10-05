//! Validates course content and publishes immutable releases.

use std::{env, io, path::Path, process::ExitCode};

fn main() -> ExitCode {
    let Some(content) = env::args_os().nth(1) else {
        eprintln!("usage: publisher <content>");
        return ExitCode::FAILURE;
    };
    match validate(Path::new(&content)) {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("publisher: {error}");
            ExitCode::FAILURE
        }
    }
}

fn validate(content: &Path) -> io::Result<()> {
    for exercise in publisher::exercises(content)?.values() {
        publisher::no_import_report(exercise)?;
        publisher::statement(exercise)?;
    }
    Ok(())
}
