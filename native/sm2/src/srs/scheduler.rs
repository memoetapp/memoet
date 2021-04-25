use std::cmp::{max, min};

use rand::distributions::{Distribution, Uniform};
use rand::Rng;

use crate::srs::card::{Card, CardQueue, CardType};
use crate::srs::config::Config;
use crate::svc::timespan::answer_button_time;
use crate::svc::timestamp::Timestamp;

use rustler::{NifStruct, NifUnitEnum};
use serde_repr::{Deserialize_repr, Serialize_repr};

#[derive(Clone, Copy, Serialize_repr, Deserialize_repr, NifUnitEnum)]
#[repr(i8)]
pub enum Choice {
    Again = 1,
    Hard = 2,
    Ok = 3,
    Easy = 4,
}

pub trait Sched {
    fn next_interval(&self, card: &Card, choice: Choice) -> i64;
    fn next_interval_string(&self, card: &Card, choice: Choice) -> String;

    fn answer_card(&self, card: &mut Card, choice: Choice);

    fn bury_card(&self, card: &mut Card);
    fn unbury_card(&self, card: &mut Card);

    fn suspend_card(&self, card: &mut Card);
    fn unsuspend_card(&self, card: &mut Card);

    fn schedule_card_as_new(&self, card: &mut Card);
    fn schedule_card_as_review(&self, card: &mut Card, min_days: i32, max_days: i32);
}

#[derive(NifStruct)]
#[module = "Memoet.SRS.Scheduler"]
pub struct Scheduler {
    pub config: Config,
    pub day_cut_off: i64,
    pub day_today: i64,
}

impl Scheduler {
    pub fn new(config: Config, day_cut_off: i64, day_today: i64) -> Self {
        Self {
            config,
            day_cut_off,
            day_today,
        }
    }

    fn fuzz_interval(interval: i32) -> i32 {
        let (min, max) = Self::fuzz_interval_range(interval);
        let mut rng = rand::thread_rng();
        rng.gen_range(min..=max)
    }

    fn fuzz_interval_range(interval: i32) -> (i32, i32) {
        match interval {
            0..=1 => (1, 1),
            2 => (2, 3),
            _ => {
                let fuzz = if interval < 7 {
                    (interval as f32 * 0.25) as i32
                } else if interval < 30 {
                    max(2, (interval as f32 * 0.15) as i32)
                } else {
                    max(4, (interval as f32 * 0.05) as i32)
                };
                let fuzz_int = max(fuzz, 1);
                (interval - fuzz_int, interval + fuzz_int)
            }
        }
    }
}

impl Sched for Scheduler {
    fn next_interval(&self, card: &Card, choice: Choice) -> i64 {
        match card.card_queue {
            CardQueue::New | CardQueue::Learn | CardQueue::DayLearn => {
                self.next_learn_interval(card, choice) as i64
            }
            _ => {
                if matches!(choice, Choice::Again) {
                    let steps = &self.config.relearn_steps;
                    if !steps.is_empty() {
                        (steps[0] * 60.0) as i64
                    } else {
                        self.lapse_interval(card) as i64 * 86_400
                    }
                } else {
                    self.next_review_interval(card, choice, false) as i64 * 86_400
                }
            }
        }
    }

    fn next_interval_string(&self, card: &Card, choice: Choice) -> String {
        let interval_secs = self.next_interval(card, choice);
        answer_button_time(interval_secs as f32)
    }

    fn answer_card(&self, card: &mut Card, choice: Choice) {
        self.answer(card, choice);
    }

    fn bury_card(&self, card: &mut Card) {
        card.card_queue = CardQueue::Buried;
    }

    fn unbury_card(&self, card: &mut Card) {
        self.schedule_card_as_new(card);
    }

    fn suspend_card(&self, card: &mut Card) {
        card.card_queue = CardQueue::Suspended;
    }

    fn unsuspend_card(&self, card: &mut Card) {
        card.card_queue = match card.card_type {
            CardType::Learn | CardType::Relearn => {
                if card.due > 1_000_000_000 {
                    CardQueue::Learn
                } else {
                    CardQueue::DayLearn
                }
            }
            CardType::New => CardQueue::New,
            CardType::Review => CardQueue::Review,
        }
    }

    fn schedule_card_as_new(&self, card: &mut Card) {
        card.schedule_as_new(0, self.config.initial_ease);
    }

    fn schedule_card_as_review(&self, card: &mut Card, min_days: i32, max_days: i32) {
        let mut rng = rand::thread_rng();
        let distribution = Uniform::from(min_days..=max_days);
        let interval = distribution.sample(&mut rng);
        card.schedule_as_review(interval, self.day_today, self.config.initial_ease);
    }
}

impl Scheduler {
    fn answer(&self, card: &mut Card, choice: Choice) {
        card.reps += 1;

        if matches!(card.card_queue, CardQueue::New) {
            card.card_queue = CardQueue::Learn;
            card.card_type = CardType::Learn;
            card.remaining_steps = self.start_remaining_steps(card);
        }

        match card.card_queue {
            CardQueue::Learn | CardQueue::DayLearn => {
                self.answer_learn_card(card, choice);
            }
            CardQueue::Review => {
                self.answer_review_card(card, choice);
            }
            _ => {}
        }
    }

    fn start_remaining_steps(&self, card: &Card) -> i32 {
        let steps = match card.card_type {
            CardType::Relearn => &self.config.relearn_steps,
            _ => &self.config.learn_steps,
        };

        let total_steps = steps.len();
        let total_remaining = self.remaining_today(steps, total_steps);
        total_steps as i32 + total_remaining * 1_000
    }

    // The number of steps that can be completed by the day cutoff
    fn remaining_today(&self, steps: &[f32], remaining: usize) -> i32 {
        let mut now = Timestamp::now() as f32;
        let from_idx = if steps.len() > remaining {
            steps.len() - remaining
        } else {
            0
        };
        let remaining_steps = &steps[from_idx..steps.len()];
        let mut remain = 0;
        let day_cut_off = self.day_cut_off as f32;
        for (i, item) in remaining_steps.iter().enumerate() {
            now += item * 60.0;
            if now > day_cut_off {
                break;
            }
            remain = i
        }
        (remain + 1) as i32
    }

    fn answer_learn_card(&self, card: &mut Card, choice: Choice) {
        let steps = &self.config.learn_steps.clone();
        match choice {
            Choice::Easy => self.reschedule_as_review(card, true),
            Choice::Ok => {
                if card.remaining_steps % 1_000 <= 1 {
                    self.reschedule_as_review(card, false)
                } else {
                    self.move_to_next_step(card, steps)
                }
            }
            Choice::Hard => self.repeat_step(card, steps),
            Choice::Again => self.move_to_first_step(card, steps),
        }
    }

    fn reschedule_as_review(&self, card: &mut Card, early: bool) {
        match card.card_type {
            CardType::Review | CardType::Relearn => self.reschedule_graduating_lapse(card, early),
            _ => self.reschedule_new(card, early),
        }
    }

    fn reschedule_graduating_lapse(&self, card: &mut Card, early: bool) {
        if early {
            card.interval += 1
        }
        card.due = self.day_today + card.interval as i64;
        card.card_type = CardType::Review;
        card.card_queue = CardQueue::Review;
    }

    fn reschedule_new(&self, card: &mut Card, early: bool) {
        card.interval = self.graduating_interval(card, early, true);
        card.due = self.day_today + card.interval as i64;
        card.ease_factor = self.config.initial_ease;
        card.card_queue = CardQueue::Review;
        card.card_type = CardType::Review;
    }

    fn graduating_interval(&self, card: &Card, early: bool, fuzzy: bool) -> i32 {
        match card.card_type {
            CardType::Review | CardType::Relearn => {
                let bonus = if early { 1 } else { 0 };
                card.interval + bonus
            }
            _ => {
                let ideal = if early {
                    self.config.graduating_interval_easy
                } else {
                    self.config.graduating_interval_good
                };

                if fuzzy {
                    Self::fuzz_interval(ideal)
                } else {
                    ideal
                }
            }
        }
    }

    fn answer_review_card(&self, card: &mut Card, choice: Choice) {
        let early = false;
        match choice {
            Choice::Again => self.reschedule_lapse(card),
            _ => self.reschedule_review(card, choice, early),
        }
    }

    fn reschedule_review(&self, card: &mut Card, choice: Choice, early: bool) {
        if early {
            self.update_early_review_interval(card, choice)
        } else {
            self.update_review_interval(card, choice)
        }

        card.ease_factor = max(
            1_300,
            card.ease_factor + vec![-150, 0, 150][choice as usize - 2],
        );
        card.due = self.day_today + card.interval as i64;
    }

    fn update_early_review_interval(&self, card: &mut Card, choice: Choice) {
        card.interval = self.early_review_interval(card, choice)
    }

    fn early_review_interval(&self, card: &mut Card, choice: Choice) -> i32 {
        let elapsed = self.day_today + card.interval as i64;

        let mut easy_bonus = 1.0;
        let mut min_new_interval = 1;
        let factor: f32;

        match choice {
            Choice::Hard => {
                factor = self.config.hard_multiplier;
                min_new_interval = (factor / 2.0) as i32;
            }
            Choice::Ok => {
                factor = card.ease_factor as f32 / 1_000.0;
            }
            _ => {
                factor = card.ease_factor as f32 / 1_000.0;
                let bonus = self.config.easy_multiplier;
                easy_bonus = bonus - (bonus - 1.0) / 2.0
            }
        }

        let mut interval = f32::max(elapsed as f32 * factor, 1.0);
        interval = f32::max((card.interval * min_new_interval) as f32, interval) * easy_bonus;
        self.constrain_interval(interval, 0, false)
    }

    fn constrain_interval(&self, interval: f32, previous: i32, fuzzy: bool) -> i32 {
        let mut interval = (interval * self.config.interval_multiplier) as i32;
        if fuzzy {
            interval = Self::fuzz_interval(interval);
        }
        interval = max(max(interval as i32, previous + 1), 1);
        min(interval, self.config.maximum_review_interval)
    }

    fn update_review_interval(&self, card: &mut Card, choice: Choice) {
        card.interval = self.next_review_interval(card, choice, true)
    }

    fn next_review_interval(&self, card: &Card, choice: Choice, fuzzy: bool) -> i32 {
        let factor = card.ease_factor as f32 / 1_000.0;
        let delay = self.days_late(card);
        let hard_factor = self.config.hard_multiplier;
        let hard_min = if hard_factor > 1.0 { card.interval } else { 0 } as i32;
        let mut interval =
            self.constrain_interval(card.interval as f32 * hard_factor, hard_min, fuzzy);
        if matches!(choice, Choice::Hard) {
            return interval;
        }

        interval = self.constrain_interval(
            (card.interval as f32 + delay as f32 / 2.0) * factor,
            interval,
            fuzzy,
        );
        if matches!(choice, Choice::Ok) {
            return interval;
        }

        self.constrain_interval(
            ((card.interval + delay) as f32 * factor) * self.config.easy_multiplier,
            interval,
            fuzzy,
        )
    }

    fn reschedule_lapse(&self, card: &mut Card) {
        card.lapses += 1;
        card.ease_factor = max(1_300, card.ease_factor - 200);

        let leech = self.check_leech(card);
        // Always suspend card on leech
        if leech {
            card.card_queue = CardQueue::Suspended
        }
        let suspended = matches!(card.card_queue, CardQueue::Suspended);

        let steps = &self.config.relearn_steps.clone();
        if !steps.is_empty() && !suspended {
            card.card_type = CardType::Relearn;
            self.move_to_first_step(card, steps);
        } else {
            self.update_review_interval_on_fail(card);
            self.reschedule_as_review(card, false);

            if suspended {
                card.card_queue = CardQueue::Suspended;
            }
        }
    }

    fn update_review_interval_on_fail(&self, card: &mut Card) {
        card.interval = self.lapse_interval(card);
    }

    fn lapse_interval(&self, card: &Card) -> i32 {
        max(
            1,
            max(
                self.config.minimum_review_interval,
                (card.interval as f32 * self.config.lapse_multiplier) as i32,
            ),
        )
    }

    fn check_leech(&self, card: &mut Card) -> bool {
        let lt = self.config.leech_threshold;
        if lt == 0 {
            false
        } else {
            card.lapses >= lt && (card.lapses - lt) % (max(lt / 2, 1)) == 0
        }
    }

    fn days_late(&self, card: &Card) -> i32 {
        max(0, self.day_today - card.due) as i32
    }

    fn move_to_next_step(&self, card: &mut Card, steps: &[f32]) {
        let remaining = (card.remaining_steps % 1_000) - 1;
        card.remaining_steps = self.remaining_today(steps, remaining as usize) * 1_000 + remaining;

        self.reschedule_learn_card(card, steps, None);
    }

    fn repeat_step(&self, card: &mut Card, steps: &[f32]) {
        let delay = self.delay_for_repeating_grade(steps, card.remaining_steps);
        self.reschedule_learn_card(card, steps, Some(delay))
    }

    fn reschedule_learn_card(&self, card: &mut Card, steps: &[f32], delay: Option<i32>) {
        let delay = match delay {
            None => self.delay_for_grade(steps, card.remaining_steps),
            Some(value) => value,
        };

        card.due = Timestamp::now() + delay as i64;

        if card.due < self.day_cut_off {
            let max_extra = min(300, (delay as f32 * 0.25) as i64);
            let mut rng = rand::thread_rng();
            let fuzz = rng.gen_range(0..=max(1, max_extra));
            card.due = min(self.day_cut_off - 1, card.due + fuzz);
            card.card_queue = CardQueue::Learn;
        } else {
            let ahead = ((card.due - self.day_cut_off) / 86_400) + 1;
            card.due = self.day_today + ahead;
            card.card_queue = CardQueue::DayLearn;
        }
    }

    fn delay_for_repeating_grade(&self, steps: &[f32], remaining: i32) -> i32 {
        let delay1 = self.delay_for_grade(steps, remaining);
        let delay2 = if steps.len() > 1 {
            self.delay_for_grade(steps, remaining - 1)
        } else {
            delay1 * 2
        };
        (delay1 + max(delay1, delay2)) / 2
    }

    fn delay_for_grade(&self, steps: &[f32], remaining: i32) -> i32 {
        let left = (remaining % 1_000) as usize;
        let delay = if steps.is_empty() {
            1.0
        } else if steps.len() >= left && left > 0 {
            steps[steps.len() - left]
        } else {
            steps[0]
        };
        (delay * 60.0) as i32
    }

    fn move_to_first_step(&self, card: &mut Card, steps: &[f32]) {
        card.remaining_steps = self.start_remaining_steps(card);
        if matches!(card.card_type, CardType::Relearn) {
            self.update_review_interval_on_fail(card)
        }
        self.reschedule_learn_card(card, steps, None)
    }

    fn next_learn_interval(&self, card: &Card, choice: Choice) -> i32 {
        let steps = &self.config.learn_steps;
        match choice {
            Choice::Again => self.delay_for_grade(steps, steps.len() as i32),
            Choice::Hard => self.delay_for_repeating_grade(steps, steps.len() as i32),
            Choice::Easy => self.graduating_interval(card, true, false) * 86_400,
            Choice::Ok => {
                let remaining = if matches!(card.card_queue, CardQueue::New) {
                    self.start_remaining_steps(card)
                } else {
                    card.remaining_steps
                };

                let left = remaining % 1_000 - 1;

                if left <= 0 {
                    self.graduating_interval(card, false, false) * 86_400
                } else {
                    self.delay_for_grade(steps, left)
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::srs::card::CardType;
    use crate::svc::timestamp::Timestamp;

    use super::*;

    fn check_interval(card: &Card, interval: i32) -> bool {
        let (min, max) = Scheduler::fuzz_interval_range(interval);
        card.interval >= min && card.interval <= max
    }

    #[test]
    fn test_new() {
        let ts = Timestamp::new();
        let scheduler = Scheduler::new(Config::default(), ts.day_cut_off, ts.day_today);
        let mut card = Card::default();
        scheduler.answer_card(&mut card, Choice::Again);
        assert!(matches!(card.card_queue, CardQueue::Learn));
        assert!(matches!(card.card_type, CardType::Learn));
        assert!(card.due >= Timestamp::now());
    }

    #[test]
    fn test_change_steps() {
        let ts = Timestamp::new();
        let mut scheduler = Scheduler::new(Config::default(), ts.day_cut_off, ts.day_today);
        let mut card = Card::default();
        scheduler.config.learn_steps = vec![1.0, 2.0, 3.0, 4.0, 5.0];
        scheduler.answer_card(&mut card, Choice::Ok);
        scheduler.config.learn_steps = vec![1.0];
        scheduler.answer_card(&mut card, Choice::Ok);
    }

    #[test]
    fn test_learn() {
        let ts = Timestamp::new();
        let mut scheduler = Scheduler::new(Config::default(), ts.day_cut_off, ts.day_today);
        let mut card = Card::default();

        // Fail it
        scheduler.config.learn_steps = vec![0.5, 3.0, 10.0];
        scheduler.answer(&mut card, Choice::Again);
        // Got 3 steps before graduation
        assert_eq!(card.remaining_steps % 1_000, 3);
        assert_eq!(card.remaining_steps / 1_000, 3);
        // Due in 30 seconds
        let t1 = card.due - Timestamp::now();
        assert!(t1 >= 25 && t1 <= 40);

        // Pass it once
        scheduler.answer(&mut card, Choice::Ok);
        // Due in 3 minutes
        let t2 = card.due - Timestamp::now();
        assert!(t2 >= 178 && t2 <= 225);
        assert_eq!(card.remaining_steps % 1_000, 2);
        assert_eq!(card.remaining_steps / 1_000, 2);

        // Pass again
        scheduler.answer(&mut card, Choice::Ok);
        // Due in 10 minutes
        let t3 = card.due - Timestamp::now();
        assert!(t3 >= 599 && t3 <= 750);
        assert_eq!(card.remaining_steps % 1_000, 1);
        assert_eq!(card.remaining_steps / 1_000, 1);

        // Graduate the card
        assert!(matches!(card.card_type, CardType::Learn));
        assert!(matches!(card.card_queue, CardQueue::Learn));
        scheduler.answer(&mut card, Choice::Ok);
        assert!(matches!(card.card_type, CardType::Review));
        assert!(matches!(card.card_queue, CardQueue::Review));
        // Due tomorrow with interval of 1
        assert_eq!(card.due, scheduler.day_today + 1);
        assert_eq!(card.interval, 1);
        // Or normal removal
        card.card_type = CardType::New;
        card.card_queue = CardQueue::Learn;
        scheduler.answer(&mut card, Choice::Easy);
        assert!(matches!(card.card_type, CardType::Review));
        assert!(matches!(card.card_queue, CardQueue::Review));
        assert!(check_interval(&card, 4));
    }

    #[test]
    fn test_initial_hard() {
        let ts = Timestamp::new();
        let scheduler = Scheduler::new(Config::default(), ts.day_cut_off, ts.day_today);
        let mut card = Card::default();

        scheduler.answer(&mut card, Choice::Hard);
        let expected = Timestamp::now() + 330;
        assert!(card.due >= expected - 10 && card.due <= (expected as f32 * 1.25) as i64);
    }

    #[test]
    fn test_relearn() {
        let ts = Timestamp::new();
        let scheduler = Scheduler::new(Config::default(), ts.day_cut_off, ts.day_today);
        let mut card = Card::default();

        card.interval = 100;
        card.due = scheduler.day_today;
        card.card_queue = CardQueue::Review;
        card.card_type = CardType::Review;

        // Fail the card
        scheduler.answer(&mut card, Choice::Again);
        assert!(matches!(card.card_type, CardType::Relearn));
        assert!(matches!(card.card_queue, CardQueue::Learn));
        assert_eq!(card.interval, 1);

        // Immediately graduate it
        scheduler.answer(&mut card, Choice::Easy);
        assert!(matches!(card.card_type, CardType::Review));
        assert!(matches!(card.card_queue, CardQueue::Review));
        assert_eq!(card.interval, 2);
        assert_eq!(card.due, scheduler.day_today + card.interval as i64);
    }

    #[test]
    fn test_relearn_no_steps() {
        let ts = Timestamp::new();
        let mut scheduler = Scheduler::new(Config::default(), ts.day_cut_off, ts.day_today);
        let mut card = Card::default();

        card.interval = 100;
        card.due = scheduler.day_today;
        card.card_queue = CardQueue::Review;
        card.card_type = CardType::Review;

        scheduler.config.relearn_steps = vec![];
        // Fail the card
        scheduler.answer(&mut card, Choice::Again);
        assert!(matches!(card.card_type, CardType::Review));
        assert!(matches!(card.card_queue, CardQueue::Review));
    }

    #[test]
    fn test_learn_day() {
        let ts = Timestamp::new();
        let mut scheduler = Scheduler::new(Config::default(), ts.day_cut_off, ts.day_today);
        let mut card = Card::default();

        scheduler.config.learn_steps = vec![1.0, 10.0, 1440.0, 2880.0];

        // Pass it
        scheduler.answer(&mut card, Choice::Ok);
        assert_eq!(card.remaining_steps % 1_000, 3);
        assert_eq!(card.remaining_steps / 1_000, 1);
        assert_eq!(scheduler.next_interval(&mut card, Choice::Ok), 86_400);

        // Learn it
        scheduler.answer(&mut card, Choice::Ok);
        assert_eq!(card.due, scheduler.day_today + 1);
        assert!(matches!(card.card_queue, CardQueue::DayLearn));

        // Move back a day
        card.due -= 1;
        assert_eq!(scheduler.next_interval(&mut card, Choice::Ok), 86_400 * 2);

        // Fail to answer it
        scheduler.answer(&mut card, Choice::Again);
        assert!(matches!(card.card_queue, CardQueue::Learn));

        // Ok to answer it
        scheduler.answer(&mut card, Choice::Ok);
        assert_eq!(scheduler.next_interval(&mut card, Choice::Ok), 86_400);
        assert!(matches!(card.card_queue, CardQueue::Learn));
    }

    #[test]
    fn test_review() {
        let ts = Timestamp::new();
        let scheduler = Scheduler::new(Config::default(), ts.day_cut_off, ts.day_today);
        let mut card = Card::default();

        card.card_type = CardType::Review;
        card.card_queue = CardQueue::Review;
        card.due = scheduler.day_today - 8;
        card.ease_factor = 2_500;
        card.reps = 3;
        card.lapses = 1;
        card.interval = 100;

        let card_copy = card.clone();

        // Hard
        scheduler.answer(&mut card, Choice::Hard);
        assert!(matches!(card.card_queue, CardQueue::Review));
        assert!(check_interval(&card, 120));
        assert_eq!(card.due, scheduler.day_today + card.interval as i64);
        assert_eq!(card.ease_factor, 2_350);
        assert_eq!(card.lapses, 1);
        assert_eq!(card.reps, 4);

        // Ok
        card = card_copy.clone();
        scheduler.answer(&mut card, Choice::Ok);
        assert!(matches!(card.card_queue, CardQueue::Review));
        assert!(check_interval(&card, 260));
        assert_eq!(card.due, scheduler.day_today + card.interval as i64);
        assert_eq!(card.ease_factor, 2_500);

        // Easy
        card = card_copy.clone();
        scheduler.answer(&mut card, Choice::Easy);
        assert!(matches!(card.card_queue, CardQueue::Review));
        assert!(check_interval(&card, 351));
        assert_eq!(card.due, scheduler.day_today + card.interval as i64);
        assert_eq!(card.ease_factor, 2_650);

        // Leech
        card = card_copy.clone();
        card.lapses = 7;
        scheduler.answer(&mut card, Choice::Again);
        assert!(matches!(card.card_queue, CardQueue::Suspended));
    }

    #[test]
    fn test_spacing_button() {
        let ts = Timestamp::new();
        let mut scheduler = Scheduler::new(Config::default(), ts.day_cut_off, ts.day_today);
        let mut card = Card::default();

        card.card_type = CardType::Review;
        card.card_queue = CardQueue::Review;
        card.due = scheduler.day_today;
        card.reps = 1;
        card.interval = 1;

        assert_eq!(
            scheduler.next_interval_string(&mut card, Choice::Hard),
            "2d"
        );
        assert_eq!(scheduler.next_interval_string(&mut card, Choice::Ok), "3d");
        assert_eq!(
            scheduler.next_interval_string(&mut card, Choice::Easy),
            "4d"
        );

        // Hard multiplier = 1, not increase day
        scheduler.config.hard_multiplier = 1.0;
        assert_eq!(
            scheduler.next_interval_string(&mut card, Choice::Hard),
            "1d"
        );
    }

    #[test]
    fn test_bury() {
        let ts = Timestamp::new();
        let scheduler = Scheduler::new(Config::default(), ts.day_cut_off, ts.day_today);
        let mut card = Card::default();

        scheduler.bury_card(&mut card);
        assert!(matches!(card.card_queue, CardQueue::Buried));

        scheduler.unbury_card(&mut card);
        assert!(matches!(card.card_queue, CardQueue::New));
    }

    #[test]
    fn test_suspend() {
        let ts = Timestamp::new();
        let scheduler = Scheduler::new(Config::default(), ts.day_cut_off, ts.day_today);
        let mut card = Card::default();

        card.due = scheduler.day_today;
        card.interval = 100;
        card.card_queue = CardQueue::Review;
        card.card_type = CardType::Review;

        scheduler.answer(&mut card, Choice::Again);
        assert!(card.due > Timestamp::now());
        assert!(matches!(card.card_type, CardType::Relearn));
        assert!(matches!(card.card_queue, CardQueue::Learn));

        let due = card.due;
        scheduler.suspend_card(&mut card);
        scheduler.unsuspend_card(&mut card);

        assert!(matches!(card.card_type, CardType::Relearn));
        assert!(matches!(card.card_queue, CardQueue::Learn));
        assert_eq!(card.due, due);
    }

    #[test]
    fn test_reschedule() {
        let ts = Timestamp::new();
        let scheduler = Scheduler::new(Config::default(), ts.day_cut_off, ts.day_today);
        let mut card = Card::default();

        scheduler.schedule_card_as_review(&mut card, 0, 0);
        assert_eq!(card.due, scheduler.day_today);
        assert_eq!(card.interval, 1);
        assert!(matches!(card.card_queue, CardQueue::Review));
        assert!(matches!(card.card_type, CardType::Review));

        scheduler.schedule_card_as_review(&mut card, 1, 1);
        assert_eq!(card.due, scheduler.day_today + 1);
        assert_eq!(card.interval, 1);

        scheduler.schedule_card_as_new(&mut card);
        assert_eq!(card.due, 0);
        assert!(matches!(card.card_queue, CardQueue::New));
        assert!(matches!(card.card_type, CardType::New));
    }

    #[test]
    fn test_fail_multiple() {
        let ts = Timestamp::new();
        let mut scheduler = Scheduler::new(Config::default(), ts.day_cut_off, ts.day_today);
        let mut card = Card::default();

        card.interval = 100;
        card.due = scheduler.day_today - 100;
        card.card_queue = CardQueue::Review;
        card.card_type = CardType::Review;
        card.ease_factor = 2_500;
        card.reps = 3;
        card.lapses = 3;

        scheduler.config.lapse_multiplier = 0.5;
        scheduler.answer(&mut card, Choice::Again);
        assert!(matches!(card.interval, 50));
        scheduler.answer(&mut card, Choice::Again);
        assert!(matches!(card.interval, 25));
    }

    #[test]
    fn test_ok_multiple_times() {
        let ts = Timestamp::new();
        let scheduler = Scheduler::new(Config::default(), ts.day_cut_off, ts.day_today);
        let mut card = Card::default();

        for _ in 1..1000 {
            scheduler.answer(&mut card, Choice::Ok);
            assert!(scheduler.next_interval(&card, Choice::Ok) > 0);
        }

        scheduler.answer(&mut card, Choice::Again);
        scheduler.answer(&mut card, Choice::Hard);
        assert!(scheduler.next_interval(&card, Choice::Ok) > 0);
    }
}
