//! Active release reader and the single opening rule.

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

    fn length(&self) -> Duration {
        self.closes_at
            .duration_since(self.opens_at)
            .unwrap_or_default()
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ExtraTime {
    Percent(u32),
    Fixed(Duration),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Accommodation {
    pub extra_time: ExtraTime,
    pub start_shift: Duration,
}

impl Accommodation {
    fn apply(&self, window: Window) -> Window {
        if window.length().is_zero() {
            return window;
        }

        let extra = match self.extra_time {
            ExtraTime::Percent(percent) => window.length() * percent / 100,
            ExtraTime::Fixed(extra) => extra,
        };

        Window {
            opens_at: window.opens_at + self.start_shift,
            closes_at: window.closes_at + self.start_shift + extra,
        }
    }
}

#[derive(Debug, Clone, Copy, Default)]
pub struct Schedule {
    pub extension: Option<Window>,
    pub group: Option<Window>,
    pub offering: Option<Window>,
    pub accommodation: Option<Accommodation>,
    pub mode_applies_accommodation: bool,
}

impl Schedule {
    pub fn window(&self) -> Option<Window> {
        let window = self.extension.or(self.group).or(self.offering)?;
        Some(match self.accommodation {
            Some(accommodation) if self.mode_applies_accommodation => accommodation.apply(window),
            _ => window,
        })
    }

    pub fn is_open(&self, now: SystemTime) -> bool {
        self.window().is_some_and(|window| window.contains(now))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::UNIX_EPOCH;

    fn at(seconds: u64) -> SystemTime {
        UNIX_EPOCH + Duration::from_secs(seconds)
    }

    fn window(opens: u64, closes: u64) -> Option<Window> {
        Some(Window {
            opens_at: at(opens),
            closes_at: at(closes),
        })
    }

    fn half_more_time() -> Option<Accommodation> {
        Some(Accommodation {
            extra_time: ExtraTime::Percent(50),
            start_shift: Duration::ZERO,
        })
    }

    #[test]
    fn closed_without_any_window() {
        assert!(!Schedule::default().is_open(at(5)));
    }

    #[test]
    fn extension_wins_over_group() {
        let schedule = Schedule {
            extension: window(0, 10),
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

    #[test]
    fn accommodation_follows_the_group_window() {
        let schedule = Schedule {
            group: window(100, 200),
            accommodation: half_more_time(),
            mode_applies_accommodation: true,
            ..Default::default()
        };
        assert!(schedule.is_open(at(249)));
        assert!(!schedule.is_open(at(250)));
    }

    #[test]
    fn accommodation_ignored_when_the_mode_does_not_apply_it() {
        let schedule = Schedule {
            group: window(100, 200),
            accommodation: half_more_time(),
            ..Default::default()
        };
        assert!(!schedule.is_open(at(220)));
    }

    #[test]
    fn accommodation_combines_with_extension() {
        let schedule = Schedule {
            extension: window(300, 400),
            group: window(100, 200),
            accommodation: half_more_time(),
            mode_applies_accommodation: true,
            ..Default::default()
        };
        assert!(schedule.is_open(at(449)));
    }

    #[test]
    fn start_shift_delays_opening() {
        let schedule = Schedule {
            group: window(100, 200),
            accommodation: Some(Accommodation {
                extra_time: ExtraTime::Fixed(Duration::ZERO),
                start_shift: Duration::from_secs(30),
            }),
            mode_applies_accommodation: true,
            ..Default::default()
        };
        assert!(!schedule.is_open(at(110)));
        assert!(schedule.is_open(at(229)));
    }

    #[test]
    fn empty_window_stays_closed_with_fixed_extra_time() {
        let schedule = Schedule {
            group: window(200, 100),
            accommodation: Some(Accommodation {
                extra_time: ExtraTime::Fixed(Duration::from_secs(60)),
                start_shift: Duration::ZERO,
            }),
            mode_applies_accommodation: true,
            ..Default::default()
        };
        assert!(!schedule.is_open(at(210)));
    }
}
