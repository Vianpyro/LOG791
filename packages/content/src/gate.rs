//! The single gate every read of an exercise goes through (ADR-0020)

use crate::{Schedule, active_release, exercise::exercise_dir};
use contracts::Id;
use std::{
    io,
    path::{Path, PathBuf},
    time::SystemTime,
};

pub fn accessible_exercise(
    course_dir: &Path,
    id: &Id,
    schedule: &Schedule,
    now: SystemTime,
) -> io::Result<PathBuf> {
    let dir = exercise_dir(&active_release(course_dir)?, id)?;
    schedule.is_open(now).ok_or_else(|| {
        io::Error::new(
            io::ErrorKind::PermissionDenied,
            format!("exercise {:?} is closed", id.as_str()),
        )
    })?;
    Ok(dir)
}
