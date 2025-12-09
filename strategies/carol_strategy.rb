# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require_relative '../lib/strategy/base_strategy'

# Carol's Strategy: The Grudge Holder
# If partner ever betrays (catches too much), remember forever and retaliate
class CarolStrategy < BaseStrategy
  extend T::Sig

  sig { override.params(name: String).void }
  def initialize(name)
    super(name)
    @betrayers = T.let(Set.new, T::Set[String])
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

    # Check if partner has ever betrayed (caught >15)
    if partner_history.any? { |c| c > 15 }
      @betrayers.add(partner_name)
      catch = 30
      log_thought("#{partner_name} BETRAYED! Retaliating: #{catch} fish")
    elsif @betrayers.include?(partner_name)
      catch = 30
      log_thought("#{partner_name} is a known betrayer, continuing punishment: #{catch} fish")
    else
      # Normal cooperation
      catch = [8, pond_fish / 4].min
      log_thought("#{partner_name} is trustworthy, cooperating: #{catch} fish")
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
end
