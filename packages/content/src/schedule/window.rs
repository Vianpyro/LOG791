use std::time::{Duration, SystemTime};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Window {
    pub opens_at: SystemTime,
    pub closes_at: SystemTime,
}

impl Window {
    pub fn contains(&self, now: SystemTime) -> bool {
        self.opens_at <= now && now < self.closes_at
    }

    pub(super) fn length(&self) -> Duration {
        self.closes_at
            .duration_since(self.opens_at)
            .unwrap_or_default()
    }
}

#[cfg(test)]
mod tests {
    use crate::schedule::fixtures::{at, between};
    use std::time::Duration;

    #[test]
    fn contains_its_opening_instant() {
        assert!(between(10, 20).contains(at(10)));
    }

    #[test]
    fn excludes_instants_before_opening() {
        assert!(!between(10, 20).contains(at(9)));
    }

    #[test]
    fn reversed_window_has_zero_length() {
        assert_eq!(between(20, 10).length(), Duration::ZERO);
    }
}
