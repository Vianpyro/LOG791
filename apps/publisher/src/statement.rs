//! The statement of an exercise, in a single format (ADR-0016)

use std::{
    fs, io,
    path::{Path, PathBuf},
};

const FILES: [&str; 3] = ["statement.md", "statement.typ", "statement.tex"];

pub fn statement(exercise: &Path) -> io::Result<PathBuf> {
    let found: Vec<PathBuf> = FILES
        .iter()
        .map(|name| exercise.join(name))
        .filter(|path| fs::symlink_metadata(path).is_ok_and(|metadata| metadata.is_file()))
        .collect();
    let [statement] = found.as_slice() else {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            format!(
                "{}: expected one of {FILES:?}, found {}",
                exercise.display(),
                found.len()
            ),
        ));
    };
    Ok(statement.clone())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::assert_matches;

    fn exercise_with(name: &str, files: &[&str]) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("publisher-test-{name}"));
        fs::create_dir_all(&dir).unwrap();
        for file in files {
            fs::write(dir.join(file), "").unwrap();
        }
        dir
    }

    #[track_caller]
    fn assert_invalid(result: io::Result<PathBuf>) {
        assert_matches!(result, Err(error) if error.kind() == io::ErrorKind::InvalidData);
    }

    #[test]
    fn each_format_is_found_alone() {
        for file in FILES {
            let exercise = exercise_with(file, &[file]);
            assert_eq!(statement(&exercise).unwrap(), exercise.join(file));
        }
    }

    #[test]
    fn two_formats_are_ambiguous() {
        let exercise = exercise_with("statement-both", &["statement.md", "statement.tex"]);
        assert_invalid(statement(&exercise));
    }

    #[test]
    fn missing_statement_is_invalid() {
        assert_invalid(statement(&exercise_with("statement-none", &[])));
    }

    #[cfg(unix)]
    #[test]
    fn symbolic_link_is_not_a_statement() {
        let exercise = exercise_with("statement-link", &[]);
        let link = exercise.join("statement.md");
        let _ = fs::remove_file(&link); // left by a previous run
        std::os::unix::fs::symlink("/etc/passwd", &link).unwrap();
        assert_invalid(statement(&exercise));
    }
}
