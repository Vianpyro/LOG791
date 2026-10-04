//! End of a session (ADR-0020).

use std::time::SystemTime;

use super::Schedule;

pub fn session_closes_at(students: &[Schedule]) -> Option<SystemTime> {
    students
        .iter()
        .filter_map(Schedule::window)
        .map(|window| window.closes_at)
        .max()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::schedule::{
        Accommodation, ExtraTime,
        fixtures::{at, between},
    };
    use std::time::Duration;

    fn group_student() -> Schedule {
        Schedule {
            group: Some(between(100, 200)),
            ..Default::default()
        }
    }

    #[test]
    fn closes_at_the_last_accommodated_window() {
        let accommodated = Schedule {
            accommodation: Some(Accommodation {
                extra_time: ExtraTime::Percent(50),
                start_shift: Duration::ZERO,
            }),
            mode_applies_accommodation: true,
            ..group_student()
        };
        assert_eq!(
            session_closes_at(&[group_student(), accommodated]),
            Some(at(250))
        );
    }

    #[test]
    fn student_without_a_window_does_not_count() {
        assert_eq!(
            session_closes_at(&[Schedule::default(), group_student()]),
            Some(at(200))
        );
    }

    #[test]
    fn no_student_window_means_no_closing() {
        assert_eq!(session_closes_at(&[Schedule::default()]), None);
        assert_eq!(session_closes_at(&[]), None);
    }
}
