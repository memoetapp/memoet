defmodule Memoet.SRS.Config do
  defstruct learn_steps: [1.0, 10.0],
            relearn_steps: [10.0],
            initial_ease: 2_500,
            easy_multiplier: 1.3,
            hard_multiplier: 1.2,
            lapse_multiplier: 0.0,
            interval_multiplier: 1.0,
            maximum_review_interval: 36_500,
            minimum_review_interval: 1,
            graduating_interval_good: 1,
            graduating_interval_easy: 4,
            leech_threshold: 8
end
