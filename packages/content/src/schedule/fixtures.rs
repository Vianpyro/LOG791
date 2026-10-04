//! Test fixtures shared by the schedule modules.

use super::Window;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

pub(super) fn at(seconds: u64) -> SystemTime {
    UNIX_EPOCH + Duration::from_secs(seconds)
}

pub(super) fn between(opens: u64, closes: u64) -> Window {
    Window {
        opens_at: at(opens),
        closes_at: at(closes),
    }
}
