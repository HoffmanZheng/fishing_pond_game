# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require_relative '../lib/strategy/base_strategy'

# Bob's Strategy: Opportunist
# Aggressive when pond is healthy, conservative when it's depleted
class BobStrategy < BaseStrategy
  extend T::Sig

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
    log_thought("Pond: #{pond_fish} fish")

    catch = if pond_fish >= 80
              # Pond is healthy, be aggressive
              aggressive = [25, pond_fish / 2].min
              log_thought("Pond healthy, aggressive: #{aggressive} fish")
              aggressive
            elsif pond_fish >= 40
              # Medium pond, moderate fishing
              moderate = [15, pond_fish / 3].min
              log_thought("Pond moderate, balanced: #{moderate} fish")
              moderate
            else
              # Pond struggling, be very conservative
              conservative = [5, pond_fish / 4].min
              log_thought("Pond struggling, conservative: #{conservative} fish")
              conservative
            end

    catch
  end

  sig do
    override.params(
      round_number: Integer,
      all_players: T::Array[String],
      all_players_history: T::Hash[String, PlayerHistory]
    ).returns([String, String])
  end
  def choose_partners(round_number, all_players, all_players_history)
    log_thought("Choosing high-scoring partners")

    others = all_players.reject { |p| p == name }

    # Choose players with highest total scores
    player_scores = others.map do |player_name|
      history = all_players_history[player_name]
      total_score = history && !history.scores.empty? ? history.scores.sum : 0
      [player_name, total_score]
    end.to_h

    sorted = player_scores.sort_by { |_, score| -score }.map(&:first)

    # Handle case with fewer than 2 other players
    if sorted.length < 2
      sorted += T.cast(others.sample(2 - sorted.length), T::Array[String])
    end

    log_thought("Selected #{sorted[0]} and #{sorted[1]}")
    [T.must(sorted[0]), T.must(sorted[1])]
  end
end
