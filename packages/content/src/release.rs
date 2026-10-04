//! Reader of a course's `current` release pointer (ADR-0005).

use std::{
    fs, io,
    path::{Path, PathBuf},
};

pub fn active_release(course_dir: &Path) -> io::Result<PathBuf> {
    let pointer = fs::read_to_string(course_dir.join("current"))?;
    let revision = pointer.trim();
    let is_hash = !revision.is_empty()
        && revision
            .bytes()
            .all(|b| matches!(b, b'0'..=b'9' | b'a'..=b'f'));
    is_hash.ok_or_else(|| {
        io::Error::new(
            io::ErrorKind::InvalidData,
            format!("invalid release pointer: {revision:?}"),
        )
    })?;
    Ok(course_dir.join("releases").join(revision))
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::assert_matches;

    fn course_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("content-test-{name}"));
        fs::create_dir_all(&dir).unwrap();
        dir
    }

    fn course_with_pointer(name: &str, pointer: &str) -> PathBuf {
        let dir = course_dir(name);
        fs::write(dir.join("current"), pointer).unwrap();
        dir
    }

    fn assert_invalid(result: io::Result<PathBuf>) {
        assert_matches!(result, Err(error) if error.kind() == io::ErrorKind::InvalidData);
    }

    #[test]
    fn pointer_names_a_release_directory() {
        let course = course_with_pointer("valid", "ab12cd\n");
        assert_eq!(
            active_release(&course).unwrap(),
            course.join("releases").join("ab12cd")
        );
    }

    #[test]
    fn pointer_cannot_escape_the_course() {
        let course = course_with_pointer("escape", "../abc123");
        assert_invalid(active_release(&course));
    }

    #[test]
    fn empty_pointer_is_invalid() {
        let course = course_with_pointer("empty", "\n");
        assert_invalid(active_release(&course));
    }

    #[test]
    fn missing_pointer_is_not_found() {
        let course = course_dir("missing");
        assert_matches!(
            active_release(&course),
            Err(error) if error.kind() == io::ErrorKind::NotFound
        );
    }
}
