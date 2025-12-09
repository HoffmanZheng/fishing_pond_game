# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require_relative '../types'

class BaseStrategy
  extend T::Sig
  extend T::Helpers
  abstract!

  sig { params(name: String).void }
  def initialize(name)
    @name = name
    @thoughts = T.let({}, T::Hash[Integer, T::Hash[String, T.any(T::Array[String], T::Hash[Integer, T::Array[String]])]])
    @current_round = T.let(0, Integer)
    @current_turn = T.let(nil, T.nilable(Integer))
    @current_phase = T.let("", String)
  end

  sig { returns(String) }
  attr_reader :name

  sig { params(round: Integer, phase: String, turn: T.nilable(Integer)).void }
  def set_context(round:, phase:, turn: nil)
    @current_round = round
    @current_turn = turn
    @current_phase = phase
  end

  sig { params(message: String).void }
  def log_thought(message)
    @thoughts[@current_round] ||= {}
    round_thoughts = T.must(@thoughts[@current_round])

    if @current_phase == "choose_catch" && @current_turn
      round_thoughts[@current_phase] ||= {}
      catch_thoughts = round_thoughts[@current_phase]
      if catch_thoughts.is_a?(Hash)
        catch_thoughts[@current_turn] ||= []
        turn_thoughts = catch_thoughts[@current_turn]
        turn_thoughts << message if turn_thoughts.is_a?(Array)
      end
    else
      round_thoughts[@current_phase] ||= []
      phase_thoughts = round_thoughts[@current_phase]
      phase_thoughts << message if phase_thoughts.is_a?(Array)
    end
  end

  sig { returns(T::Hash[Integer, T::Hash[String, T.any(T::Array[String], T::Hash[Integer, T::Array[String]])]]) }
  def all_thoughts
    @thoughts
  end

  sig do
    abstract.params(
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
  end

  sig do
    abstract.params(
      round_number: Integer,
      all_players: T::Array[String],
      all_players_history: T::Hash[String, PlayerHistory]
    ).returns([String, String])
  end
  def choose_partners(round_number, all_players, all_players_history)
  end
end
