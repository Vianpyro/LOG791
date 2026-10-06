//! The standard I/O cases of an exercise: each `<name>.in` with its `<name>.out` (ADR-0013, ADR-0023)

use std::{
    ffi::OsStr,
    fs, io,
    path::{Path, PathBuf},
};

use crate::sandbox::MAX_OUTPUT;

// An expected output beyond what the sandbox keeps could never match
const MAX_CASE_FILE: u64 = MAX_OUTPUT;

#[derive(Debug, PartialEq, Eq)]
pub struct Case {
    pub input: Vec<u8>,
    pub expected: Vec<u8>,
}

// Untrusted content
fn read_case_file(path: &Path) -> io::Result<Vec<u8>> {
    let metadata = fs::symlink_metadata(path)
        .map_err(|error| io::Error::new(error.kind(), format!("{}: {error}", path.display())))?;
    (metadata.is_file() && metadata.len() <= MAX_CASE_FILE).ok_or_else(|| {
        io::Error::new(
            io::ErrorKind::InvalidData,
            format!(
                "{}: not a regular file of at most {MAX_CASE_FILE} bytes",
                path.display()
            ),
        )
    })?;
    fs::read(path)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::assert_matches;

    fn assessment(name: &str, files: &[(&str, &str)]) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("judge-test-cases-{name}"));
        let _ = fs::remove_dir_all(&dir).unwrap();
        for (file, contents) in files {
            fs::write(dir.join(file), contents).unwrap();
        }
        dir
    }

    fn case(input: &str, expected: &str) -> Case {
        Case {
            input: input.into(),
            expected: expected.into(),
        }
    }

    #[track_caller]
    fn assert_invalid(result: io::Result<Vec<Case>>) {
        assert_matches!(result, Err(error) if error.kind() == io::ErrorKind::InvalidData);
    }

    #[test]
    fn cases_are_paired_in_name_order() {}

    #[test]
    fn example_exercise_has_its_three_cases() {
        let dir = Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("../../examples/content/exercises/sum/assessment");
        assert_eq!(read_cases(&dir).unwrap().len(), 3);
    }

    #[test]
    fn missing_expected_output_is_named() {}

    #[test]
    fn exercise_without_case_is_invalid() {}

    #[test]
    fn oversized_file_is_invalid() {}

    #[cfg(unix)]
    #[test]
    fn symbolic_link_is_invalid() {
        let dir = assessment("link", &[("1.out", "A")]);
        std::os::unix::fs::symlink("/etc/passwd", dir.join("1.in")).unwrap();
        assert_invalid(read_cases(&dir));
    }
}
