use rustler::NifStruct;
use serde::{Deserialize, Serialize};

#[derive(Clone, Serialize, Deserialize, NifStruct)]
#[module = "Memoet.SRS.Config"]
pub struct Config {
    pub learn_steps: Vec<f32>,
    pub relearn_steps: Vec<f32>,
    pub initial_ease: i32,
    pub easy_multiplier: f32,
    pub hard_multiplier: f32,
    pub lapse_multiplier: f32,
    pub interval_multiplier: f32,
    pub maximum_review_interval: i32,
    pub minimum_review_interval: i32,
    pub graduating_interval_good: i32,
    pub graduating_interval_easy: i32,
    pub leech_threshold: i32,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            learn_steps: vec![1.0, 10.0],
            relearn_steps: vec![10.0],
            initial_ease: 2_500,
            easy_multiplier: 1.3,
            hard_multiplier: 1.2,
            lapse_multiplier: 0.0,
            interval_multiplier: 1.0,
            maximum_review_interval: 36_500,
            minimum_review_interval: 1,
            graduating_interval_good: 1,
            graduating_interval_easy: 4,
            leech_threshold: 8,
        }
    }
}
