//! Active release reader and the single opening rule.

use std::time::SystemTime;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Window {
    pub opens_at: SystemTime,
    pub closes_at: SystemTime,
}

impl Window {
    pub fn contains(&self, now: SystemTime) -> bool {
        self.opens_at <= now && now < self.closes_at
    }
}

#[derive(Debug, Clone, Copy, Default)]
pub struct Schedule {
    pub student: Option<Window>,
    pub group: Option<Window>,
    pub offering: Option<Window>,
}

impl Schedule {
    pub fn window(&self) -> Option<Window> {
        self.student.or(self.group).or(self.offering)
    }

    pub fn is_open(&self, now: SystemTime) -> bool {
        self.window().is_some_and(|window| window.contains(now))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::{Duration, UNIX_EPOCH};

    fn at(seconds: u64) -> SystemTime {
        UNIX_EPOCH + Duration::from_secs(seconds)
    }

    fn window(opens: u64, closes: u64) -> Option<Window> {
        Some(Window {
            opens_at: at(opens),
            closes_at: at(closes),
        })
    }

    #[test]
    fn closed_without_any_window() {
        assert!(!Schedule::default().is_open(at(5)));
    }

    #[test]
    fn student_override_wins_over_group() {
        let schedule = Schedule {
            student: window(0, 10),
            group: window(20, 30),
            ..Default::default()
        };
        assert!(schedule.is_open(at(5)));
    }

    #[test]
    fn offering_applies_without_group_window() {
        let schedule = Schedule {
            offering: window(0, 10),
            ..Default::default()
        };
        assert!(schedule.is_open(at(5)));
    }

    #[test]
    fn closed_at_closing_instant() {
        let schedule = Schedule {
            group: window(0, 10),
            ..Default::default()
        };
        assert!(!schedule.is_open(at(10)));
    }
}
