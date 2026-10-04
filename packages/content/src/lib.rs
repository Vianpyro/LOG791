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
