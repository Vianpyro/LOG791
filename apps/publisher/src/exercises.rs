//! The exercises of a content repository (ADR-0005)

use std::{
    collections::BTreeMap,
    fs, io,
    path::{Path, PathBuf},
};

use contracts::Id;

pub fn exercises(content: &Path) -> io::Result<BTreeMap<Id, PathBuf>> {
    fs::read_dir(content.join("exercises"))?
        .map(|entry| {
            let entry = entry?;
            let dir = entry.path();
            let id = entry
                .file_name()
                .to_str()
                .and_then(|name| name.parse::<Id>().ok());
            match id {
                Some(id) if entry.file_type()?.is_dir() => Ok((id, dir)),
                _ => Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    format!("{}: expected a directory named [a-z0-9-]+", dir.display()),
                )),
            }
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::assert_matches;

    fn content_with(name: &str, ids: &[&str]) -> PathBuf {
        let content = std::env::temp_dir().join(format!("publisher-test-{name}"));
        fs::create_dir_all(content.join("exercises")).unwrap();
        for id in ids {
            fs::create_dir_all(content.join("exercises").join(id)).unwrap();
        }
        content
    }

    #[track_caller]
    fn assert_invalid(result: io::Result<BTreeMap<Id, PathBuf>>) {
        assert_matches!(result, Err(error) if error.kind() == io::ErrorKind::InvalidData);
    }

    #[test]
    fn exercises_are_sorted_by_identifier() {
        let found = exercises(&content_with("exercises-sorted", &["sum", "hello"])).unwrap();
        assert_eq!(
            found.keys().map(Id::as_str).collect::<Vec<_>>(),
            ["hello", "sum"]
        );
    }

    #[test]
    fn invalid_identifier_is_refused() {
        assert_invalid(exercises(&content_with("exercises-name", &["Sum"])));
    }

    #[test]
    fn file_is_not_an_exercise() {
        let content = content_with("exercises-file", &[]);
        fs::write(content.join("exercises").join("notes"), "").unwrap();
        assert_invalid(exercises(&content));
    }

    #[cfg(unix)]
    #[test]
    fn symbolic_link_is_not_an_exercise() {
        let content = content_with("exercises-link", &[]);
        let link = content.join("exercises").join("link");
        let _ = fs::remove_file(&link); // left by a previous run
        std::os::unix::fs::symlink(std::env::temp_dir(), &link).unwrap();
        assert_invalid(exercises(&content));
    }
}
