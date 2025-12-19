# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require_relative '../lib/strategy/base_strategy'

class LynkStrategy < BaseStrategy
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
    # 最后一回合：拿池塘的 40%（假设对手也贪婪，留余量避免双输）
    if turn_number == 10
      return [(pond_fish * 0.4).to_i, 25].min
    end

    # 其他回合：拿池塘的 9%（两人共 18%，基于最坏增长率 15% 可持续）
    [(pond_fish * 0.09).to_i, 10].max
  end

  sig do
    override.params(
      round_number: Integer,
      all_players: T::Array[String],
      all_players_history: T::Hash[String, PlayerHistory]
    ).returns([String, String])
  end
  def choose_partners(round_number, all_players, all_players_history)
    others = all_players.reject { |p| p == name }

    # 过滤危险玩家（平均捕获 > 20 或有池塘枯竭记录）
    safe_players = others.reject { |p| dangerous?(p, all_players_history) }

    # 安全玩家不足时退回全部
    candidates = safe_players.length >= 2 ? safe_players : others

    # 随机选择
    shuffled = candidates.shuffle
    [T.must(shuffled[0]), T.must(shuffled[1] || others.find { |p| p != shuffled[0] })]
  end

  private

  sig { params(player_name: String, history: T::Hash[String, PlayerHistory]).returns(T::Boolean) }
  def dangerous?(player_name, history)
    h = history[player_name]
    return false if h.nil? || h.catches.empty?

    catches = h.catches.flatten
    return false if catches.empty?

    avg = catches.sum.to_f / catches.length
    has_zero_score = h.scores.any? { |s| s == 0 }

    avg > 20 || has_zero_score
  end
end
