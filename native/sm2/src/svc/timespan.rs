/// Short string like '4d' to place above answer buttons.
pub fn answer_button_time(seconds: f32) -> String {
    let span = Timespan::from_secs(seconds).natural_span();
    let amount = span.as_rounded_unit();
    let key = match span.unit() {
        TimespanUnit::Seconds => "s",
        TimespanUnit::Minutes => "m",
        TimespanUnit::Hours => "h",
        TimespanUnit::Days => "d",
        TimespanUnit::Months => "mo",
        TimespanUnit::Years => "y",
    };
    format!("{}{}", amount, key)
}

/// Describe the given seconds using the largest appropriate unit.
/// If precise is true, show to two decimal places, eg
/// eg 70 seconds -> "1.17 minutes"
pub fn time_span(seconds: f32, precise: bool) -> String {
    let span = Timespan::from_secs(seconds).natural_span();
    let amount = if precise {
        span.as_unit()
    } else {
        span.as_rounded_unit()
    };
    let key = match span.unit() {
        TimespanUnit::Seconds => "second",
        TimespanUnit::Minutes => "minute",
        TimespanUnit::Hours => "hour",
        TimespanUnit::Days => "day",
        TimespanUnit::Months => "month",
        TimespanUnit::Years => "year",
    };
    format!("{} {}{}", amount, key, if amount > 1.0 { "s" } else { "" })
}

const SECOND: f32 = 1.0;
const MINUTE: f32 = 60.0 * SECOND;
const HOUR: f32 = 60.0 * MINUTE;
const DAY: f32 = 24.0 * HOUR;
const MONTH: f32 = 30.0 * DAY;
const YEAR: f32 = 12.0 * MONTH;

#[derive(Clone, Copy)]
pub(crate) enum TimespanUnit {
    Seconds,
    Minutes,
    Hours,
    Days,
    Months,
    Years,
}

#[derive(Clone, Copy)]
pub(crate) struct Timespan {
    seconds: f32,
    unit: TimespanUnit,
}

impl Timespan {
    pub fn from_secs(seconds: f32) -> Self {
        Timespan {
            seconds,
            unit: TimespanUnit::Seconds,
        }
    }

    /// Return the value as the configured unit, eg seconds=70/unit=Minutes
    /// returns 1.17
    pub fn as_unit(self) -> f32 {
        let s = self.seconds;
        match self.unit {
            TimespanUnit::Seconds => s,
            TimespanUnit::Minutes => s / MINUTE,
            TimespanUnit::Hours => s / HOUR,
            TimespanUnit::Days => s / DAY,
            TimespanUnit::Months => s / MONTH,
            TimespanUnit::Years => s / YEAR,
        }
    }

    /// Round seconds and days to integers, otherwise
    /// truncates to one decimal place.
    pub fn as_rounded_unit(self) -> f32 {
        match self.unit {
            // seconds/days as integer
            TimespanUnit::Seconds | TimespanUnit::Days => self.as_unit().round(),
            // other values shown to 1 decimal place
            _ => (self.as_unit() * 10.0).round() / 10.0,
        }
    }

    pub fn unit(self) -> TimespanUnit {
        self.unit
    }

    /// Return a new timespan in the most appropriate unit, eg
    /// 70 secs -> timespan in minutes
    pub fn natural_span(self) -> Timespan {
        let secs = self.seconds.abs();
        let unit = if secs < MINUTE {
            TimespanUnit::Seconds
        } else if secs < HOUR {
            TimespanUnit::Minutes
        } else if secs < DAY {
            TimespanUnit::Hours
        } else if secs < MONTH {
            TimespanUnit::Days
        } else if secs < YEAR {
            TimespanUnit::Months
        } else {
            TimespanUnit::Years
        };

        Timespan {
            seconds: self.seconds,
            unit,
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn answer_buttons() {
        assert_eq!(answer_button_time(30.0), "30s");
        assert_eq!(answer_button_time(70.0), "1.2m");
        assert_eq!(answer_button_time(1.1 * MONTH), "1.1mo");
    }

    #[test]
    fn time_spans() {
        assert_eq!(time_span(1.0, false), "1 second");
        assert_eq!(time_span(30.3, false), "30 seconds");
        assert_eq!(time_span(30.3, true), "30.3 seconds");
        assert_eq!(time_span(90.0, false), "1.5 minutes");
        assert_eq!(time_span(45.0 * 86_400.0, false), "1.5 months");
        assert_eq!(time_span(365.0 * 86_400.0 * 1.5, false), "1.5 years");
    }
}
