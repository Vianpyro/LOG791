//! The standard I/O cases of an exercise: each `<name>.in` with its `<name>.out` (ADR-0013, ADR-0023)

use std::{
    ffi::OsStr,
    fs, io,
    path::{Path, PathBuf}
}

use crate::sandbox::MAX_OUTPUT;

// An expected output beyond what the sandbox keeps could never match
const MAX_CASE_FILE: u64 = MAX_OUTPUT;

#[derive(Debug, PartialEq, Eq)]
pub struct Case {
    pub input: Vec<u8>,
    pub expected: Vec<u8>,
}

pub fn read_cases(assessment: &Path) -> io::Result<Vec<Case>> {}

pub fn read_case_file(path: &Path) -> io::Result<Vec<u8>> {}

#[cfg(test)]
mod tests {
    use super::*;
    use std::assert_matches;

    fn assessment(name: &str, files: &[(&str, &str)]) -> PathBuf {}

    fn case(input: &str, expected: &str) -> Case {
        Case {
            input: input.into(),
            expected: expected.into(),
        }
    }

    #[track_caller]
    fn assert_invalid(result: io::Result<Vec<Case>>) {}

    #[test]
    fn cases_are_paired_in_name_order() {}

    #[test]
    fn example_exercise_has_its_three_cases() {}

    #[test]
    fn missing_expected_output_is_named() {}

    #[test]
    fn exercise_without_case_is_invalid() {}

    #[test]
    fn oversized_file_is_invalid() {}

    #[cfg(unix)]
    #[test]
    fn symbolic_link_is_invalid() {}
}
