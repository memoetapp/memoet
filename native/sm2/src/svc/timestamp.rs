use chrono::{Datelike, Duration, Local, Utc};

pub struct Timestamp {
    pub day_cut_off: i64,
    pub day_today: i64,
}

impl Timestamp {
    pub fn now() -> i64 {
        now()
    }

    #[allow(dead_code)]
    pub fn new() -> Self {
        let now = Local::now();
        let next_day = (now + Duration::days(1)).date().and_hms(0, 0, 0);
        Self {
            day_cut_off: next_day.timestamp(),
            day_today: (next_day.num_days_from_ce() - 719_163) as i64,
        }
    }
}

pub fn now() -> i64 {
    Utc::now().timestamp()
}
