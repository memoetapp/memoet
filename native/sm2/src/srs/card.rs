use rustler::{NifStruct, NifUnitEnum};
use serde::{Deserialize, Serialize};

#[derive(PartialEq, Clone, Copy, Serialize, Deserialize, NifUnitEnum)]
pub enum CardType {
    New = 0,
    Learn = 1,
    Review = 2,
    Relearn = 3,
}

#[derive(PartialEq, Clone, Copy, Serialize, Deserialize, NifUnitEnum)]
pub enum CardQueue {
    // due is the order cards are shown in
    New = 0,

    // due is number of seconds since epoch
    Learn = 1,

    // due is number of days since epoch
    Review = 2,
    DayLearn = 3,

    /// cards are not due in these states
    Suspended = -1,
    Buried = -2,
}

#[derive(Clone, Serialize, Deserialize, NifStruct)]
#[module = "Memoet.SRS.Card"]
pub struct Card {
    pub card_type: CardType,
    pub card_queue: CardQueue,
    pub due: i64,
    pub interval: i32,
    pub ease_factor: i32,
    pub reps: i32,
    pub lapses: i32,
    pub remaining_steps: i32,
}

impl Default for Card {
    fn default() -> Self {
        Self {
            card_type: CardType::New,
            card_queue: CardQueue::New,
            due: 0,
            interval: 0,
            ease_factor: 0,
            reps: 0,
            lapses: 0,
            remaining_steps: 0,
        }
    }
}

impl Card {
    pub fn schedule_as_new(&mut self, position: i64, initial_ease: i32) {
        self.due = position;
        self.card_type = CardType::New;
        self.card_queue = CardQueue::New;
        self.interval = 0;
        if self.ease_factor == 0 {
            self.ease_factor = initial_ease;
        }
    }

    pub fn schedule_as_review(&mut self, interval: i32, today: i64, initial_ease: i32) {
        self.interval = interval.max(1);
        self.due = today + interval as i64;
        self.card_type = CardType::Review;
        self.card_queue = CardQueue::Review;
        if self.ease_factor == 0 {
            self.ease_factor = initial_ease;
        }
    }

    pub fn set_new_position(&mut self, position: i64) {
        if self.card_queue != CardQueue::New || self.card_type != CardType::New {
            return;
        }
        self.due = position;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_set_new_position() {
        let mut card = Card::default();
        assert_eq!(card.due, 0);
        card.set_new_position(1);
        assert_eq!(card.due, 1);

        card.card_queue = CardQueue::Review;
        card.card_type = CardType::Review;
        card.set_new_position(2);
        assert_eq!(card.due, 1);
    }
}
