# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require_relative '../base_strategy'

class RandomStrategy < BaseStrategy
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
    log_thought("池子里还有 #{pond_fish} 条鱼")

    catch = 10 + rand(20)

    log_thought("决定捕 #{catch} 条鱼")

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
    log_thought("随机选两个搭档")

    others = all_players.reject { |p| p == name }
    choices = T.cast(others.sample(2), T::Array[String])

    log_thought("选了 #{choices[0]} 和 #{choices[1]}")

    [T.must(choices[0]), T.must(choices[1])]
  end
end
