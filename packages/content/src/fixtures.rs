//! Test fixtures shared by the content modules.

use std::{assert_matches, fs, io, path::PathBuf};

pub(crate) fn temp_dir(name: &str) -> PathBuf {
    let dir = std::env::temp_dir().join(format!("content-test-{name}"));
    fs::create_dir_all(&dir).unwrap();
    dir
}

#[track_caller]
pub(crate) fn assert_invalid(result: io::Result<PathBuf>) {
    assert_matches!(result, Err(error) if error.kind() == io::ErrorKind::InvalidData);
}
