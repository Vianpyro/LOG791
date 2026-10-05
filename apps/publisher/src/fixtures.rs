//! Test fixtures shared by the publisher modules.

use std::{assert_matches, fmt, fs, io, path::PathBuf};

pub(crate) fn temp_dir(name: &str) -> PathBuf {
    let dir = std::env::temp_dir().join(format!("publisher-test-{name}"));
    let _ = fs::remove_dir_all(&dir); // left by a previous run
    fs::create_dir_all(&dir).unwrap();
    dir
}

#[track_caller]
pub(crate) fn assert_invalid<T: fmt::Debug>(result: io::Result<T>) {
    assert_matches!(result, Err(error) if error.kind() == io::ErrorKind::InvalidData);
}
