//! Active release reader and the single opening rule.

mod release;
mod schedule;

pub use release::active_release;
pub use schedule::{Accommodation, ExtraTime, Schedule, Window};
