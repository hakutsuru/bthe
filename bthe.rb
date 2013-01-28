require 'pp'


class Node
  attr_reader :disk, :state, :history
  NUMBER_OF_DISKS = 4
  EMPTY_CHARACTER = "x"
  TOWER_DELIMITER = "-"
  BRANCH_MODE = "standard" # [standard, reverse]
  SEEK_MODE = "lazy" # [lazy, exhaustive]
  NARRATION = "none" # [none, verbose]
  # child == potential new node in solution tree
  # towers == state of puzzle, collection of arrays
  Child = Struct.new(:disk_moved, :new_state, :node)
  Towers = Struct.new(:one, :two, :three)

  def initialize (disk_moved, state, parent)
    $nodes_created += 1
    if NARRATION == "verbose"
      pp "node: #{$nodes_created}"
      pp "state: #{state}"
    end
    if $nodes_created == 1000 && $solutions_found == 0
      pp "Warning: 1000 nodes created without solution found..."
      pp "consider altering branch traversal mode."
      pp "[stack limit will be exceeded, depending on context"
      pp "this may seem like an infinite loop.]"
      puts "\n"
    end
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
    if NARRATION == "verbose"
      pp "brood:"
      pp @brood
      puts "\n"
    end
  end

  # [meta: 04]
  def play
    case
    when state == $solved_state
      # report solution, improve via method?
      $solutions_found += 1
      puts "Solution ##{$solutions_found}"
      puts @history
      puts "\n"
      if SEEK_MODE == "lazy"
        puts "Puzzle solved!"
        puts "[finis]"
        abort
      end
      @parent.prune
    when @brood == []
      @parent.prune
    else
      move = pick_branch
      move.node = Node.new(move.disk_moved, move.new_state, self)
      move.node.play
    end
  end
  
  # [meta: 03]
  def self.solve_puzzle
    # ugly, introduce puzzle object?
    $nodes_created = 0
    $solutions_found = 0
    full_tower = (1..NUMBER_OF_DISKS).to_a
    towers = Towers.new
    # initial puzzle state
    towers.one = full_tower
    towers.two = []
    towers.three = []
    $initial_state = serialize_towers(towers)
    # solved puzzle state
    towers.one = []
    towers.two = []
    towers.three = full_tower
    $solved_state = serialize_towers(towers)
    # clean up
    towers = nil
    # solve
    root = Node.new(nil, $initial_state, nil)
    root.play
  end

  # string representation of game state
  # puzzle object and node objects would share towers, module?
  # state  => "1234-xxxx-xxxx"
  # towers => #<struct Node::Towers one=[1, 2, 3, 4], two=[], three=[]>

  # [meta: 01]
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

  # [meta: 03]
  def pick_branch
    case
    when BRANCH_MODE == "standard"
      move = @brood.first
    when BRANCH_MODE == "reverse"
      move = @brood.last
    else
      move = @brood.last
    end
    move
  end

  # [meta: 03]
  def prune
    # removed evaluated branch
    @brood.reject! { |move| move.node != nil }
    # choose another branch
    move = pick_branch
    if move.nil?
      if @parent.nil?
        return
      else
        @parent.prune
      end
    else
      move.node = Node.new(move.disk_moved, move.new_state, self)
      move.node.play
    end
  end

  # [meta: 02]
  def analyze_options(previous_disk, state, history)
    possible_moves = []
    towers = Node.build_towers(state)
    towers.each_with_index do |source_tower, source_index|
      game_disk = source_tower[0]
      if !game_disk.nil? && game_disk != previous_disk
        towers.each_with_index do |destination_tower, destination_index|
          destination_disk = destination_tower[0].to_i
          if game_disk < destination_disk || destination_disk == 0
            # beware shallow copy, do not #dup
            mock_towers = Node.build_towers(state)
            mock_towers[source_index].shift
            mock_towers[destination_index].unshift(game_disk)
            new_state = Node.serialize_towers(mock_towers)
            redundant_state = history.include?(new_state)
            if !redundant_state
              possible_moves << Child.new(game_disk,new_state,nil)
            end
            mock_towers = nil
          end
        end
      end
    end
    # check for puzzle solution
    possible_moves = scan_for_solution(possible_moves)
    # array of decision tree children
    possible_moves
  end

  # perhaps create redundant_state?(new_state)

  def scan_for_solution(possible_moves)
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
  # Meta: begin project with rough idea for puzzle node [move state]
  # 01 - start easy, serialization and rod models 
  # 02 - work through finding possible moves
  # 03 - puzzle initialization, removing branches
  # 04 - play [recognizing solution, branching, backtracing]
  # narration and seek mode added for debugging

  # [meta: 01]
  # pp Node.build_tower("1234")
  # pp Node.build_tower("23")
  # pp Node.serialize_tower([2,3])
  # pp towers = Node.build_towers("x234-xxxx-xxx1")
  # towers.each_with_index do |tower, index|
  #   pp index
  #   pp tower
  # end
  # pp Node.serialize_towers(towers)

  # [meta: 02]
  # pp towers = Node.build_towers("x234-xxxx-xxx1")
  # history = []
  # history << "1234-xxxx-xxxx"
  # pp history
  # pp Node.analyze_options(towers,history)

  # [meta: 03]
  # Node.solve_puzzle
  # Child = Struct.new(:disk_moved, :new_state, :node)
  # this_one = Child.new(3,"xx12-xxxx-xx34",nil)
  # this_two = Child.new(4,$solved_state,nil)
  # groovy = [this_one, this_two]
  # pp Node.scan_for_solution(groovy)

  # Child = Struct.new(:disk_moved, :new_state, :node)
  # dat_thing = Child.new(0,"junk", nil)
  # this_one = Child.new(3,"xx12-xxxx-xx34",nil)
  # this_two = Child.new(4,"xx12-xxxx-xx32",dat_thing)
  # groovy = [this_one, this_two]
  # pp groovy
  # puts "\n"
  # pp Node.prune(groovy)

  Node.solve_puzzle
  puts "Puzzle solved!"
  puts "Moves Evaluated: #{$nodes_created-1}"
  puts "[finis]"
end
