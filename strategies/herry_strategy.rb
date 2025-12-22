# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require_relative '../lib/strategy/base_strategy'

class HerryStrategy < BaseStrategy
  extend T::Sig

  # Ecological Constants based on game theory analysis of 100-fish ponds.
  # These represent safe harvesting ceilings for different partner archetypes.
  YIELD_CONSERVATIVE = 19
  YIELD_STANDARD = 15
  YIELD_INITIAL = 10

  sig do
    override.params(
      round_number: Integer,
      turn_number: Integer,
      pond_fish: Integer,
      my_history: T::Array[Integer],
      partner_history: T::Array[Integer],
      partner_name: String,
      all_players_history: T::Hash[String, PlayerHistory]
    ).returns(Integer)
  end

  def choose_catch(round_number, turn_number, pond_fish, my_history, partner_history, partner_name, all_players_history)
    # Phase 1: Market Calibration (Turn 1)
    # Establish a non-threatening baseline to collect data on partner behavior.
    return YIELD_INITIAL if turn_number == 1

    # Phase 2: Partner Profiling
    # Calculate partner's consumption velocity.
    # We use a weighted average, but simple average suffices for this model.
    partner_total = partner_history.sum
    partner_count = partner_history.length.to_f
    partner_avg = partner_count > 0 ? (partner_total / partner_count) : 0.0

    # Phase 3: Yield Optimization
    # Determine the maximum safe yield based on the partner's profile.

    target_catch = 0

    # Profile A: "Low Consumption Partner" (Avg < 8)
    # These partners are passive. To reach market equilibrium, we must
    # increase our share. However, we stay below 20 to maintain the
    # appearance of a "sustainable" actor in the eyes of observers.
    if partner_avg < 8
      target_catch = YIELD_CONSERVATIVE # 19
      log_thought("Partner consumption low. Maximizing yield within sustainable bounds.")

      # Profile B: "High Consumption Partner" (Avg >= 8)
      # These partners are active competitors.
      # To avoid a "Tragedy of the Commons" scenario (or triggering retaliation mechanisms),
      # we strictly cap our consumption at 15.
      # Mathematical models suggest >15 is a common trigger for 'tit-for-tat' defection.
    else
      target_catch = YIELD_STANDARD # 15
      log_thought("Partner consumption high. Capping yield to prevent competitive escalation.")
    end

    # Phase 4: End-of-Lifecycle Liquidation (Turns 9 & 10)
    # As the game horizon closes, reputation value depreciates to zero.
    # We switch to maximum extraction.
    if turn_number >= 9
      target_catch = 30
      log_thought("Horizon closing. Switching to maximum extraction.")
    end

    # Phase 5: Ecological Safety Valve
    # Calculate the absolute limit to prevent resource collapse (0 fish).
    # We attempt to leave a seed population unless it's the final turn.
    seed_buffer = (turn_number == 10) ? 0 : 2
    predicted_partner_catch = (partner_history.last || 10)

    # Adjust prediction for known high-velocity partners in healthy ponds
    if partner_avg > 15 && pond_fish > 80
      predicted_partner_catch = [predicted_partner_catch, 18].max
    end

    max_ecological_catch = pond_fish - predicted_partner_catch - seed_buffer

    # Final Reconciliation
    final_decision = [target_catch, max_ecological_catch].min
    [[final_decision, 30].min, 0].max
  end

  sig do
    override.params(
      round_number: Integer,
      all_players: T::Array[String],
      all_players_history: T::Hash[String, PlayerHistory]
    ).returns([String, String])
  end
  def choose_partners(round_number, all_players, all_players_history)
    log_thought("Analyzing historical sustainability metrics.")

    others = all_players.reject { |p| p == name }

    # Scoring Algorithm: "Symbiotic Potential"
    # We prioritize partners who leave the most resources on the table.

    scores = others.map do |player|
      history = all_players_history[player]
      metric = 0.0

      if history && !history.catches.empty?
        catches = history.catches.flatten
        avg = catches.sum.to_f / catches.length

        # Tier 1: High Symbiosis (Avg < 8)
        # Allows for maximum "YIELD_CONSERVATIVE" (19) exploitation.
        if avg < 8
          metric = 100.0

          # Tier 2: Moderate Symbiosis (8 <= Avg <= 14)
          # Allows for "YIELD_STANDARD" (15-18) extraction.
        elsif avg <= 14
          metric = 75.0

          # Tier 3: Low Symbiosis (Avg > 14)
          # Forces restricted caps (15) or indicates dangerous greed.
        elsif avg <= 20
          metric = 50.0

          # Tier 4: Negative Symbiosis (Greedy)
        else
          metric = -50.0
        end

        # Penalty for Resource Collapse events (0 scores)
        collapses = history.scores.count(0)
        metric -= (collapses * 25.0)
      else
        # Unknown entities are treated as neutral opportunities
        metric = 60.0
      end

      [player, metric]
    end.to_h

    # Select top 2 candidates based on Symbiotic Potential
    sorted = scores.sort_by { |_, metric| -metric }.map(&:first)

    # Fallback mechanism for small player pools
    if sorted.length < 2
      remaining = others - sorted
      sorted += T.cast(remaining.sample(2 - sorted.length), T::Array[String])
    end

    [T.must(sorted[0]), T.must(sorted[1])]
  end
end