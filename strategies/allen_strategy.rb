# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require_relative '../lib/strategy/base_strategy'

# Allen's Strategy: Adaptive Cooperative with Reputation Tracking
# Combines adaptive fishing, cooperative behavior, and reputation management
class AllenStrategy < BaseStrategy
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
    log_thought("Pond has #{pond_fish} fish")

    # Check if partner is a known betrayer (caused overfishing before)
    if @betrayers.include?(partner_name)
      # If partner is a betrayer, be more aggressive to maximize before they destroy pond
      catch = if pond_fish >= 60
                [20, pond_fish / 2].min
              else
                [15, pond_fish / 2].min
              end
      log_thought("#{partner_name} is a known betrayer, maximizing catch: #{catch} fish")
      return catch
    end

    # Check if partner has been greedy in this pairing (caught >15)
    if partner_history.any? { |c| c > 15 }
      @betrayers.add(partner_name)
      log_thought("#{partner_name} caught >15, marking as betrayer")
    end

    # Adaptive strategy based on pond health
    base_catch = if pond_fish >= 80
                   # Pond is healthy: be moderately aggressive
                   18
                 elsif pond_fish >= 50
                   # Pond is moderate: balanced approach
                   12
                 elsif pond_fish >= 30
                   # Pond is low: conservative
                   7
                 else
                   # Pond is very low: very conservative
                   4
                 end

    # Cooperative adjustment: if partner has been reasonable, mirror their level
    if !partner_history.empty? && partner_history.length >= 2
      partner_avg = partner_history.sum.to_f / partner_history.length

      # If partner is cooperative (avg 5-12), adjust to be slightly more cooperative
      if partner_avg >= 5 && partner_avg <= 12
        # Mirror partner's level but be slightly more conservative
        cooperative_catch = [(partner_avg * 0.9).round, base_catch].min
        base_catch = [cooperative_catch, base_catch].max
        log_thought("Partner is cooperative (avg #{partner_avg.round(1)}), adjusting to #{base_catch} fish")
      elsif partner_avg > 12 && partner_avg <= 18
        # Partner is moderately aggressive, match them
        base_catch = [partner_avg.round, base_catch].min
        log_thought("Partner is moderate (avg #{partner_avg.round(1)}), matching: #{base_catch} fish")
      end
    end

    # Ensure we don't overfish: leave at least 20% of pond for partner and growth
    safe_catch = [base_catch, (pond_fish * 0.4).floor].min
    catch = [safe_catch, 0].max

    # Cap at maximum
    catch = [catch, 30].min

    log_thought("Final catch: #{catch} fish (adaptive + cooperative)")

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
    log_thought("Choosing cooperative but successful partners")

    others = all_players.reject { |p| p == name }

    # Filter out known betrayers if possible
    trustworthy = others.reject { |p| @betrayers.include?(p) }

    # If we have at least 2 trustworthy players, choose from them
    candidates = trustworthy.length >= 2 ? trustworthy : others

    # Score players based on: moderate catches (6-12 ideal), success, and cooperation
    player_scores = candidates.map do |player_name|
      history = all_players_history[player_name]

      if history && !history.catches.empty?
        catches = history.catches.flatten
        avg_catch = catches.sum.to_f / catches.length

        # Ideal partner: moderate catches (6-12), successful, cooperative
        # Score = success - penalty for being too conservative or too greedy
        total_score = history.scores.sum
        cooperation_bonus = if avg_catch >= 6 && avg_catch <= 12
                              # Perfect range: high bonus
                              50
                            elsif avg_catch >= 4 && avg_catch <= 15
                              # Good range: moderate bonus
                              30
                            elsif avg_catch < 4
                              # Too conservative: small penalty
                              -10
                            else
                              # Too greedy: penalty
                              -20
                            end

        # Check for overfishing incidents (ponds that depleted)
        overfishing_penalty = history.scores.count { |s| s == 0 } * 10

        final_score = total_score + cooperation_bonus - overfishing_penalty
        [player_name, final_score]
      else
        # New player: neutral score
        [player_name, 0]
      end
    end.to_h

    # Sort by score (highest first)
    sorted = player_scores.sort_by { |_, score| -score }.map(&:first)

    # Handle case with fewer than 2 players
    if sorted.length < 2
      sorted += T.cast(candidates.sample(2 - sorted.length), T::Array[String])
    end

    first_choice = T.must(sorted[0])
    second_choice = T.must(sorted[1])

    log_thought("Selected #{first_choice} (score: #{player_scores[first_choice]&.round(1)}) and #{second_choice} (score: #{player_scores[second_choice]&.round(1)})")

    [first_choice, second_choice]
  end
end


