//! The report a lossy import leaves beside a statement (ADR-0029)

use std::{fs, io, path::Path};

const REPORT: &str = "import-report.md";

pub fn no_import_report(exercise: &Path) -> io::Result<()> {
    let report = exercise.join(REPORT);
    match fs::symlink_metadata(&report) {
        Ok(_) => Err(io::Error::new(
            io::ErrorKind::InvalidData,
            format!(
                "{}: resolve the import losses, then delete this report",
                report.display()
            ),
        )),
        Err(error) if error.kind() == io::ErrorKind::NotFound => Ok(()),
        Err(error) => Err(error),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::fixtures::{assert_invalid, temp_dir};

    #[test]
    fn exercise_without_report_is_accepted() {
        no_import_report(&temp_dir("import-none")).unwrap();
    }

    #[test]
    fn exercise_with_report_is_refused() {
        let exercise = temp_dir("import-report");
        fs::write(exercise.join(REPORT), "").unwrap();
        assert_invalid(no_import_report(&exercise));
    }
}
