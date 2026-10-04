//! Resolution of an exercise identifier in a release, the single gate's first step.

use std::{
    fs, io,
    path::{Path, PathBuf},
};

use contracts::Id;

pub fn exercise_dir(release: &Path, id: &Id) -> io::Result<PathBuf> {
    let dir = release.join("exercises").join(id.as_str());
    let is_dir = fs::symlink_metadata(&dir)?.is_dir();
    is_dir.ok_or_else(|| {
        io::Error::new(
            io::ErrorKind::InvalidData,
            format!("exercise {:?} is not a directory", id.as_str()),
        )
    })?;
    Ok(dir)
}
