//! Active release reader and the single opening rule.

mod exercise;
mod release;
mod schedule;

pub use exercise::exercise_dir;
pub use release::active_release;
pub use schedule::{Accommodation, ExtraTime, Schedule, Window};

#[cfg(test)]
mod fixtures;
