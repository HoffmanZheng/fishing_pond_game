# Fishing Pond Game 🎣

A game theory-based coding challenge for backend engineering teams. Learn Sorbet type checking while exploring strategic decision-making in an iterated resource management game.

## Quick Start

```bash
# Install dependencies
bundle install

# Run a quick demo
bin/play --demo

# Test all example strategies
bin/play --dry-run --rounds 4 --reports

# Run tests
bundle exec rspec
```

## Game Overview

- **Players**: n players (even number recommended)
- **Duration**: n rounds
- **Objective**: Catch the most fish across all rounds

### Core Rules

**Pond Dynamics:**
- Initial pond: 100 fish
- Growth rate: 15%-25% per turn (randomly varies each turn to add uncertainty)
- Fishing duration: 10 turns per pairing
- Maximum catch per turn: 30 fish per player

**Fishing:**
- Both players simultaneously decide how many fish to catch (0-30)
- **Success**: If total catch ≤ pond fish, both get their catch and pond grows
- **Overfishing**: If total catch > pond fish, both get 0 and pond depletes

**Pairing:**
- Round 1: Random pairing
- Round 2+: Based on preferences (mutual first choices prioritized)

## Writing Your Strategy

Create a new file in `strategies/` directory:

```ruby
# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require_relative '../lib/strategy/base_strategy'

class MyStrategy < BaseStrategy
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
    # Optional: Log your decision-making process
    log_thought("Pond has #{pond_fish} fish, considering catch amount")

    # Your logic here - return 0-30
    catch = 10

    log_thought("Decided to catch #{catch} fish")
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
    # Optional: Log your partner selection reasoning
    log_thought("Selecting partners for round #{round_number}")

    # Your logic here - return [first_choice, second_choice]
    others = all_players.reject { |p| p == name }
    [T.must(others[0]), T.must(others[1])]
  end
end
```

### Validate Your Strategy

```bash
bin/validate strategies/my_strategy.rb
```

### Using log_thought for Strategy Development

The `log_thought(message)` method allows you to record your strategy's decision-making process. These thoughts are captured in HTML reports, making it easier to:
- Debug your strategy logic
- Understand why your strategy made certain decisions
- Share your reasoning with teammates

Example usage:
```ruby
def choose_catch(...)
  log_thought("Analyzing pond health: #{pond_fish} fish remaining")

  if pond_fish < 30
    log_thought("Pond is low, being conservative")
    return 3
  end

  log_thought("Pond is healthy, catching more aggressively")
  20
end
```

Thoughts are automatically organized by:
- Round number
- Phase (choose_catch or choose_partners)
- Turn number (for choose_catch only)

View them in the generated HTML reports under each player's actions.

## Command Line Options

### bin/play

```bash
# Demo mode (4 random players)
bin/play --demo

# Dry run with built-in strategies
bin/play --dry-run

# Interactive mode (pause after each round)
bin/play --interactive --dry-run

# Generate HTML reports
bin/play --dry-run --reports

# Custom number of rounds
bin/play --dry-run --rounds 6

# Load custom strategies
bin/play --players strategies/*.rb
```

### bin/validate

```bash
# Validate a strategy file
bin/validate strategies/my_strategy.rb
```

## Example Strategies

The game includes 6 example strategies to learn from:

1. **RandomStrategy** - Catches random 10-30 fish
2. **ConservativeStrategy** - Always catches 3 fish, prefers conservative partners
3. **GreedyStrategy** - Maximizes catch while leaving room for partner
4. **TitForTatStrategy** - Mirrors partner's previous catch
5. **AdaptiveStrategy** - Adjusts based on pond health (80+ = aggressive, <30 = conservative)
6. **PunisherStrategy** - Catches 4 normally, but catches 30 if partner ever exceeded 10

## HTML Reports

When you run with `--reports`, HTML files are generated in `reports/`:

- Turn-by-turn breakdown for each pairing
- Success/overfishing indicators
- Current leaderboard with medals
- Strategy insights (cooperation rate, pond depletion rate, etc.)

Open `reports/round_N.html` in your browser to view detailed results.

## Running Tests

```bash
# Run all tests
bundle exec rspec

# Run with documentation format
bundle exec rspec --format documentation

# Run specific test file
bundle exec rspec spec/pond_spec.rb
```

## Tournament Workflow

1. **Monday**: Share CLAUDE.md and example strategies with team
2. **During Week**: Engineers write and test their strategies
3. **Friday 5pm**: Deadline for strategy submissions to `strategies/` folder
4. **Weekly Meeting**:
   - Run tournament interactively: `bin/play --interactive --players strategies/*.rb --reports`
   - Discuss outcomes after each round
   - Review HTML reports
   - Award "Game Theory Champion" to winner

## Project Structure

```
fishing-pond-game/
├── bin/
│   ├── play              # Game runner
│   └── validate          # Strategy validator
├── lib/
│   ├── game/
│   │   ├── tournament.rb # Tournament orchestration
│   │   ├── round.rb      # Single round logic
│   │   ├── pond.rb       # Pond state management
│   │   └── matcher.rb    # Pairing algorithm
│   ├── strategy/
│   │   ├── base_strategy.rb
│   │   └── examples/     # Built-in example strategies
│   ├── types.rb          # Sorbet type definitions
│   └── report_generator.rb
├── strategies/           # User-submitted strategies go here
├── spec/                 # RSpec tests
├── reports/              # Generated HTML reports
└── CLAUDE.md            # Full game specification
```

## Learning Goals

- **Sorbet Practice**: All code uses `# typed: strict` with proper type annotations
- **Game Theory**: Explore cooperation, competition, and reputation building
- **Strategic Thinking**: No single "optimal" strategy - success depends on opponents

## Key Insights

- Too conservative? You'll lose to moderate players
- Too greedy? You'll destroy ponds and lose partnership opportunities
- Reputation matters! Players see all history when choosing partners
- Mutual first choices create powerful alliances

## License

Internal use for team coding challenges.
