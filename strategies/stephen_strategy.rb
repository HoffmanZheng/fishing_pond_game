# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require_relative '../lib/strategy/base_strategy'

# Stephen's Strategy: You can always trust Stephen
# Be a good man is the only key to success
class StephenStrategy < BaseStrategy
  extend T::Sig

  sig { override.params(name: String).void }
  def initialize(name)
    super(name)
  end

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

    if turn_number < 3
      log_thought("Show love to fish and partners")
      return 0
    end

    if turn_number < 5 && !aggressive_player?(partner_history, pond_fish)
      if partner_history.sum < 10
        log_thought("Partner is cooperating, matching them")
        return 0
      else
        return partner_history.last.to_i
      end
    end

    return 30 # Time to fish hard
  end

  sig do
    override.params(
      round_number: Integer,
      all_players: T::Array[String],
      all_players_history: T::Hash[String, PlayerHistory]
    ).returns([String, String])
  end
  def choose_partners(round_number, all_players, all_players_history)
    log_thought("Avoiding betrayers")

    others = all_players.reject { |p| p == name }

    # Prefer players who have never betrayed
    trustworthy = others.reject { |p| @betrayers.include?(p) }

    if trustworthy.length >= 2
      # Choose from trustworthy players
      choices = T.cast(trustworthy.sample(2), T::Array[String])
      log_thought("Choosing trustworthy #{choices[0]} and #{choices[1]}")
    else
      # Must choose others if not enough trustworthy players
      choices = T.cast(others.sample(2), T::Array[String])
      log_thought("Forced to choose #{choices[0]} and #{choices[1]}")
    end

    [T.must(choices[0]), T.must(choices[1])]
  end

  sig { params(partner_history: T::Array[Integer], pond_fish: Integer).returns(T::Boolean) }
  def aggressive_player?(partner_history, pond_fish)
    false if partner_history.to_a.size < 3 # Give patner one chance

    partner_average_catches = partner_history.sum / partner_history.size

  end

  def aggressive_score?(partner_history)
    false if partner_history.to_a.size < 2 # Give patner one chance

    partner_history.sum / partner_history.size > 20
  end

  sig { params(pond_fish: Integer, partner_history: T::Array[Integer], round_number: Integer).returns(Integer) }
  def estimate_pond_remain_round(pond_fish, partner_history, round_number)
    remaining_rounds = 10 - round_number

    return remaining_rounds if partner_history.empty?

    partner_average_catches = partner_history.sum / partner_history.size

    estimated_pond_remain = pond_fish - (partner_average_catches * remaining_rounds)

    estimated_pond_remain
  end
end
