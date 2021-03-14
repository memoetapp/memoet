use chrono::{DateTime, Duration, FixedOffset, Local, TimeZone, Utc};

pub struct Timestamp(i64);

impl Timestamp {
    pub fn now() -> i64 {
        now()
    }

    pub fn day_cut_off() -> i64 {
        get_next_day(
            now(),
            local_minutes_west_for_stamp(Utc::now().timestamp()),
            4,
        )
        .timestamp()
    }
}

pub fn now() -> i64 {
    Utc::now().timestamp()
}

/// - now_secs is a timestamp of the current time
/// - now_mins_west is the current offset west of UTC
/// - rollover_hour is the hour of the day the rollover happens (eg 4 for 4am)
pub fn get_next_day(now_secs: i64, now_mins_west: i32, rollover_hour: u8) -> DateTime<FixedOffset> {
    let now_datetime = fixed_offset_from_minutes(now_mins_west).timestamp(now_secs, 0);
    let today = now_datetime.date();

    // rollover
    let rollover_today_datetime = today.and_hms(rollover_hour as u32, 0, 0);
    let rollover_passed = rollover_today_datetime <= now_datetime;

    if rollover_passed {
        rollover_today_datetime + Duration::days(1)
    } else {
        rollover_today_datetime
    }
}

fn fixed_offset_from_minutes(minutes_west: i32) -> FixedOffset {
    let bounded_minutes = minutes_west.max(-23 * 60).min(23 * 60);
    FixedOffset::west(bounded_minutes * 60)
}

fn local_minutes_west_for_stamp(stamp: i64) -> i32 {
    Local.timestamp(stamp, 0).offset().utc_minus_local() / 60
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::{Local, TimeZone, Utc};

    // static timezone for tests
    const AEST_MINS_WEST: i32 = -600;

    #[test]
    fn fixed_offset() {
        let offset = fixed_offset_from_minutes(AEST_MINS_WEST);
        assert_eq!(offset.utc_minus_local(), AEST_MINS_WEST * 60);
    }

    #[test]
    #[cfg(target_vendor = "apple")]
    /// On Linux, TZ needs to be set prior to the process being started to take effect,
    /// so we limit this test to Macs.
    fn local_minutes_west() {
        // -480 throughout the year
        std::env::set_var("TZ", "Australia/Perth");
        assert_eq!(local_minutes_west_for_stamp(Utc::now().timestamp()), -480);
    }

    #[test]
    fn next_day_at() {
        let rollhour = 4;

        // before the rollover, the next day should be later on the same day
        let now = Local.ymd(2019, 1, 3).and_hms(2, 0, 0);
        let next_day_at = Local.ymd(2019, 1, 3).and_hms(rollhour, 0, 0);
        let today = get_next_day(
            now.timestamp(),
            now.offset().utc_minus_local() / 60,
            rollhour as u8,
        );
        assert_eq!(today.timestamp(), next_day_at.timestamp());

        // after the rollover, the next day should be the next day
        let now = Local.ymd(2019, 1, 3).and_hms(rollhour, 0, 0);
        let next_day_at = Local.ymd(2019, 1, 4).and_hms(rollhour, 0, 0);
        let today = get_next_day(
            now.timestamp(),
            now.offset().utc_minus_local() / 60,
            rollhour as u8,
        );
        assert_eq!(today.timestamp(), next_day_at.timestamp());

        // after the rollover, the next day should be the next day
        let now = Local.ymd(2019, 1, 3).and_hms(rollhour + 3, 0, 0);
        let next_day_at = Local.ymd(2019, 1, 4).and_hms(rollhour, 0, 0);
        let today = get_next_day(
            now.timestamp(),
            now.offset().utc_minus_local() / 60,
            rollhour as u8,
        );
        assert_eq!(today.timestamp(), next_day_at.timestamp());
    }
}
