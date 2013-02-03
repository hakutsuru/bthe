require 'pp' #remove later
require 'rubygems'
require 'json'

module Towering
  EMPTY_CHARACTER = "x"
  TOWER_DELIMITER = "-"
  Towers = Struct.new(:one, :two, :three)
  # string representation of game state
  # state  => "1234-xxxx-xxxx"
  # towers => #<struct Node::Towers one=[1, 2, 3, 4], two=[], three=[]>

  def self.build_towers(state)
    towers = Towers.new
    towers.one = build_tower(state[0,NUMBER_OF_DISKS])
    towers.two = build_tower(state[(NUMBER_OF_DISKS+1),NUMBER_OF_DISKS])
    towers.three = build_tower(state[2*(NUMBER_OF_DISKS+1),NUMBER_OF_DISKS])
    towers
  end

  def self.build_tower(state)
    tower = []
    state.each_char { |char| tower << char.to_i if char != EMPTY_CHARACTER }
    tower
  end

  def self.serialize_towers(towers)
    state = serialize_tower(towers.one)
    state += TOWER_DELIMITER + serialize_tower(towers.two)
    state += TOWER_DELIMITER + serialize_tower(towers.three)
  end

  def self.serialize_tower(tower)
    mock_tower = tower.dup
    while mock_tower.size < NUMBER_OF_DISKS
      mock_tower.unshift(EMPTY_CHARACTER)
    end
    mock_tower.join
  end
end

module Reporting
  def self.announce
    if RESPONSE == "human"
      puts "bthe - Brutish Tower of Hanoi Exercise"
      puts "Brute force solving Towers of Hanoi"
      puts "[Use Control-C to halt program]"
      puts "  Number of disks: #{NUMBER_OF_DISKS}"
      puts "  Seek mode: #{SEEK_MODE}"
      if SEEK_MODE == "lazy"
        puts "  -- halts when any solution found"
      end
      puts "  Branch mode: #{BRANCH_MODE}"
      puts "  Narration: #{NARRATION}"
      puts "  Minimum moves to solve: #{2**NUMBER_OF_DISKS - 1}"
      puts "\n"
    end
  end

  def self.update(state, possible_moves)
    if NARRATION == "verbose" && RESPONSE == "human"
      puts "node: #{$nodes_created}"
      puts "state: #{state}"
      puts "brood:"
      if possible_moves.empty?
        puts "  [none]"
      else
        possible_moves.each { |move| puts "  #{move}" }
      end
      puts "\n"
    end
  end

  def self.publish(move_history)
    if RESPONSE == "human"
      print "\b\b" # clean up cursor
      puts "Solution ##{$solutions.size}"
      puts "Steps Required #{move_history.length - 1}"
      move_history.each { |move| puts "  #{move}" }
      puts "\n"
    end
  end

  def self.retire
    if RESPONSE == "json"
      response = { "number_of_disks" => NUMBER_OF_DISKS,
                  "branch_mode"      => BRANCH_MODE,
                  "seek_mode"        => SEEK_MODE,
                  "solutions"        => $solutions }
      puts response.to_json
    else
      print "\b\b" # clean up cursor
      puts "Puzzle solved!"
      puts "States Evaluated: #{$nodes_created}"
      puts "[finis]"
    end
  end
end

class Puzzle
  include Towering

  def self.solve
    Reporting.announce
    $nodes_created = 0
    $solutions = []
    full_tower = (1..NUMBER_OF_DISKS).to_a
    towers = Towers.new
    # initial puzzle state
    towers.one = full_tower
    towers.two = []
    towers.three = []
    $initial_state = Towering.serialize_towers(towers)
    # solved puzzle state
    towers.one = []
    towers.two = []
    towers.three = full_tower
    $solved_state = Towering.serialize_towers(towers)
    # clean up
    towers = nil
    # solve
    root = Node.new(nil, $initial_state, nil)
    root.play
  end
end

class Node
  include Towering
  attr_reader :disk, :state, :history
  Child = Struct.new(:disk_moved, :new_state, :node)
  # child - potential new node in solution tree

  def initialize(disk_moved, state, parent)
    $nodes_created += 1
    # initialize instance
    @disk = disk_moved
    @state = state
    @parent = parent
    if parent
      @history = parent.history.dup << state
    else # root node
      @history = [] << state
    end
    if (state != $solved_state)
      # mixing metaphors, branch offsprings
      @brood = analyze_options(@disk, @state, @history)
    else
      @brood = []
    end
    Reporting.update(state, @brood)
  end

  def play
    puzzle_solved = (state == $solved_state)
    no_valid_moves = (@brood == [])
    case
    when puzzle_solved
      publish_solution
    when no_valid_moves
      return
    else
      until no_valid_moves do
        move = pick_branch
        move.node = Node.new(move.disk_moved, move.new_state, self)
        move.node.play
        prune_evaluated_branch
        no_valid_moves = (@brood == [])
      end
    end
  end

  def publish_solution
    $solutions << @history
    Reporting.publish(@history)
    if SEEK_MODE == "lazy"
      Reporting.retire
      abort
    end
  end

  def pick_branch
    case
    when BRANCH_MODE == "standard"
      move = @brood.first
    when BRANCH_MODE == "reverse"
      move = @brood.last
    else
      move = @brood.first
    end
    move
  end

  def prune_evaluated_branch
    @brood.reject! { |move| move.node != nil }
  end

  def analyze_options(previous_disk, state, history)
    possible_moves = []
    towers = Towering.build_towers(state)
    towers.each_with_index do |source_tower, source_index|
      game_disk = source_tower[0]
      if !game_disk.nil? && game_disk != previous_disk
        towers.each_with_index do |destination_tower, destination_index|
          destination_disk = destination_tower[0].to_i
          destination_disk_larger = (game_disk < destination_disk)
          destination_tower_empty = (destination_disk == 0)
          if destination_disk_larger || destination_tower_empty
            new_state = next_state(state, source_index, destination_index)
            if !redundant_state?(new_state, history)
              possible_moves << Child.new(game_disk,new_state,nil)
            end
          end
        end
      end
    end
    possible_moves = impose_solution(possible_moves)
    # array of decision tree children
    possible_moves
  end

  def next_state(state, source_index, destination_index)
    # beware shallow copy, do not #dup
    mock_towers = Towering.build_towers(state)
    game_disk = mock_towers[source_index].shift
    mock_towers[destination_index].unshift(game_disk)
    Towering.serialize_towers(mock_towers)
  end

  def redundant_state?(state, history)
    history.include?(state)
  end

  def impose_solution(possible_moves)
    # if any move results in solved puzzle
    # other move options are irrelevant
    solved = false
    possible_moves.each do |move|
      if move.new_state == $solved_state
        possible_moves = [move]
        break
      end
    end
    possible_moves
  end
end

if $0 == __FILE__
  NUMBER_OF_DISKS = 4
  BRANCH_MODE = "standard" # [standard, reverse]
  SEEK_MODE = "lazy" # [lazy, exhaustive]
  NARRATION = "none" # [none, verbose]
  RESPONSE = "human" # [human, json]
  
  trap("SIGINT") do
    # capture Ctl-C
    print "\b\b"
    puts "bthe - user quit"
    exit
  end

  Puzzle.solve
  Reporting.retire
end
