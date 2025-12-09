# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require_relative '../lib/strategy/base_strategy'

# Alice's Strategy: Cautious Follower
# Starts conservative, then adjusts based on partner's behavior
class AliceStrategy < BaseStrategy
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
    log_thought("Pond has #{pond_fish} fish")

    if partner_history.empty?
      # First turn: conservative start
      catch = 5
      log_thought("First turn, playing it safe: #{catch} fish")
    else
      # Follow partner but be slightly more conservative
      partner_avg = partner_history.sum.to_f / partner_history.length
      catch = [(partner_avg * 0.8).round, pond_fish / 3].min
      log_thought("Partner avg #{partner_avg.round(1)}, following conservatively: #{catch} fish")
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
    log_thought("Choosing stable partners")

    others = all_players.reject { |p| p == name }

    # Prefer stable, medium-scoring players
    player_stability = others.map do |player_name|
      history = all_players_history[player_name]
      if history && history.catches.length > 0
        catches = history.catches.flatten
        if catches.length > 0
          avg = catches.sum.to_f / catches.length
          variance = catches.sum { |c| (c - avg) ** 2 } / catches.length
          # Stability score: average - variance penalty
          stability = avg - variance * 0.1
          [player_name, stability]
        else
          [player_name, 0.0]
        end
      else
        [player_name, 0.0]
      end
    end.to_h

    sorted = player_stability.sort_by { |_, score| -score }.map(&:first)

    # Handle case with fewer than 2 other players
    if sorted.length < 2
      sorted += T.cast(others.sample(2 - sorted.length), T::Array[String])
    end

    [T.must(sorted[0]), T.must(sorted[1])]
  end
end
