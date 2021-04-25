mod srs;
mod svc;

use rustler::{Env, Error, ResourceArc, Term};

use crate::srs::card::Card;
use crate::srs::config::Config;
use crate::srs::scheduler::{Choice, Sched, Scheduler};

mod atoms {
    rustler::atoms! {
        ok,
        error,
    }
}

fn load(env: Env, _: Term) -> bool {
    rustler::resource!(Scheduler, env);
    rustler::resource!(Card, env);
    rustler::resource!(Config, env);
    true
}

#[rustler::nif]
fn new(config: Config, day_cut_off: i64, day_today: i64) -> Result<ResourceArc<Scheduler>, Error> {
    let scheduler = Scheduler::new(config, day_cut_off, day_today);
    Ok(ResourceArc::new(scheduler))
}

#[rustler::nif]
fn next_interval(
    card: Card,
    scheduler: ResourceArc<Scheduler>,
    choice: Choice,
) -> Result<i64, Error> {
    Ok(scheduler.next_interval(&card, choice))
}

#[rustler::nif]
fn next_interval_string(
    card: Card,
    scheduler: ResourceArc<Scheduler>,
    choice: Choice,
) -> Result<String, Error> {
    Ok(scheduler.next_interval_string(&card, choice))
}

#[rustler::nif]
fn answer_card(
    card: Card,
    scheduler: ResourceArc<Scheduler>,
    choice: Choice,
) -> Result<Card, Error> {
    let mut card = card.clone();
    scheduler.answer_card(&mut card, choice);
    Ok(card)
}

#[rustler::nif]
fn bury_card(card: Card, scheduler: ResourceArc<Scheduler>) -> Result<Card, Error> {
    let mut card = card.clone();
    scheduler.bury_card(&mut card);
    Ok(card)
}

#[rustler::nif]
fn unbury_card(card: Card, scheduler: ResourceArc<Scheduler>) -> Result<Card, Error> {
    let mut card = card.clone();
    scheduler.unbury_card(&mut card);
    Ok(card)
}

#[rustler::nif]
fn suspend_card(card: Card, scheduler: ResourceArc<Scheduler>) -> Result<Card, Error> {
    let mut card = card.clone();
    scheduler.suspend_card(&mut card);
    Ok(card)
}

#[rustler::nif]
fn unsuspend_card(card: Card, scheduler: ResourceArc<Scheduler>) -> Result<Card, Error> {
    let mut card = card.clone();
    scheduler.unsuspend_card(&mut card);
    Ok(card)
}

#[rustler::nif]
fn schedule_card_as_new(card: Card, scheduler: ResourceArc<Scheduler>) -> Result<Card, Error> {
    let mut card = card.clone();
    scheduler.schedule_card_as_new(&mut card);
    Ok(card)
}

#[rustler::nif]
fn schedule_card_as_review(
    card: Card,
    scheduler: ResourceArc<Scheduler>,
    min_days: i32,
    max_days: i32,
) -> Result<Card, Error> {
    let mut card = card.clone();
    scheduler.schedule_card_as_review(&mut card, min_days, max_days);
    Ok(card)
}

rustler::init!(
    "Elixir.Memoet.SRS.Sm2",
    [
        new,
        next_interval,
        next_interval_string,
        answer_card,
        bury_card,
        unbury_card,
        suspend_card,
        unsuspend_card,
        schedule_card_as_new,
        schedule_card_as_review
    ],
    load = load
);
