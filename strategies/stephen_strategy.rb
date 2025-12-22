# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require_relative '../lib/strategy/base_strategy'

# Stephen's Strategy: You can always trust Stephen
# Be a good man is the only key to success
class StephenStrategy < BaseStrategy
  extend T::Sig

  # start with 0 to avoid 1-based index confusion, round 11 should not be used
  PERFECT_POND_REMAIN_FISH = [100, 100, 120, 144, 172, 206, 180, 156, 127, 92, 50, 0].freeze

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

    return 30 if should_punish_partner?(turn_number, pond_fish, partner_history)

    ideal_catch(turn_number, pond_fish)
  end

  sig do
    override.params(
      round_number: Integer,
      all_players: T::Array[String],
      all_players_history: T::Hash[String, PlayerHistory]
    ).returns([String, String])
  end
  def choose_partners(round_number, all_players, all_players_history)
    log_thought("Choosing partners who has bigger sight...")

    others = all_players.reject { |p| p == name }

    # Handle edge case: if less than 2 other players
    if others.length < 2
      # Pad with available players
      return [others[0] || name, others[1] || others[0] || name].map { |p| T.must(p) }
    end

    my_history = all_players_history[self.name]
    my_last_partner = my_history && !my_history.partners.empty? ? my_history.partners.last : nil
    candidates = all_players_history.reject { |name, _history| name == self.name || name == my_last_partner }

    # Rank by early cooperation (low catches in first few rounds)
    rank = candidates.sort_by do |name, history|
      # Sum catches from first few rounds (handle empty history)
      history.catches.map { |turn_catches| turn_catches[0..3] }.flatten.sum
    end

    rank[0..1].map(&:first)
  end


  sig { params(turn_number: Integer, pond_fish: Integer, partner_history: T::Array[Integer]).returns(T::Boolean) }
  def should_punish_partner?(turn_number, pond_fish, partner_history)
    return false if turn_number < 3
    return false if partner_history.empty?

    pond_health = pond_fish - PERFECT_POND_REMAIN_FISH[turn_number]
    return false if pond_health > 0

    # Check last 2 catches (corrected syntax)
    recent_catches = partner_history.length >= 2 ? partner_history[-2..-1] : partner_history
    partner_is_cooperating = recent_catches.all? { |catch| catch < 10 }
    return false if partner_is_cooperating

    pond_health < -30
  end

  sig { params(turn_number: Integer, pond_fish: Integer).returns(Integer) }
  def ideal_catch(turn_number, pond_fish)
    next_round_ideal_pond_remain = PERFECT_POND_REMAIN_FISH[turn_number + 1]
    estimated_grow_rate = 1.2

    # (pond_fish - should_catch * 2) * estimated_grow_rate = next_round_ideal_pond_remain
    # (pond_fish - should_catch * 2) = next_round_ideal_pond_remain / estimated_grow_rate - pond_fish
    # should_catch = (next_round_ideal_pond_remain / estimated_grow_rate - pond_fish) / -2
    should_catch = [(next_round_ideal_pond_remain / estimated_grow_rate - pond_fish) / -2, 0].max.round
    [[should_catch, 30].min, 0].max
  end
end
