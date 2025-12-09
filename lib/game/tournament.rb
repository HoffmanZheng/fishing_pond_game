# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require_relative '../types'
require_relative '../strategy/base_strategy'
require_relative 'round'

class TournamentResult < T::Struct
  const :total_rounds, Integer
  const :round_results, T::Array[RoundResult]
  const :final_scores, T::Hash[String, Integer]
  const :winner, String
end

class Tournament
  extend T::Sig

  sig do
    params(
      strategies: T::Hash[String, BaseStrategy],
      total_rounds: Integer,
      config: GameConfig
    ).returns(TournamentResult)
  end
  def self.play(strategies, total_rounds, config = GameConfig.new)
    players = strategies.keys

    # Initialize player history
    all_players_history = {}
    players.each do |name|
      all_players_history[name] = PlayerHistory.new(
        partners: [],
        catches: [],
        scores: []
      )
    end

    round_results = []

    # Play each round
    total_rounds.times do |round_idx|
      round_number = round_idx + 1

      round_result = Round.play(round_number, strategies, all_players_history, config)
      round_results << round_result

      # Update player history
      update_player_history(all_players_history, round_result)
    end

    # Calculate final scores
    final_scores = {}
    all_players_history.each do |name, history|
      final_scores[name] = history.scores.sum
    end

    # Find winner
    winner_entry = T.cast(final_scores.max_by { |_name, score| score }, [String, Integer])
    winner = winner_entry[0]

    TournamentResult.new(
      total_rounds: total_rounds,
      round_results: round_results,
      final_scores: final_scores,
      winner: winner
    )
  end

  sig do
    params(
      all_players_history: T::Hash[String, PlayerHistory],
      round_result: RoundResult
    ).void
  end
  private_class_method def self.update_player_history(all_players_history, round_result)
    # Track who played with whom and their scores
    player_round_data = Hash.new { |h, k| h[k] = { partner: "", catches: [], score: 0 } }

    round_result.pairing_results.each_value do |pairing_result|
      p1_name = pairing_result.player1_name
      p2_name = pairing_result.player2_name

      player_round_data[p1_name] = {
        partner: p2_name,
        catches: pairing_result.player1_catches,
        score: pairing_result.player1_total
      }

      player_round_data[p2_name] = {
        partner: p1_name,
        catches: pairing_result.player2_catches,
        score: pairing_result.player2_total
      }
    end

    # Update each player's history
    all_players_history.each do |name, history|
      data = player_round_data[name]
      if data
        history.partners << data[:partner]
        history.catches << data[:catches]
        history.scores << data[:score]
      else
        # Player sat out (odd number scenario)
        history.partners << ""
        history.catches << []
        history.scores << 0
      end
    end
  end
end
