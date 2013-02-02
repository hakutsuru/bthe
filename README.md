## bthe [Brutish Towers of Hanoi Exercise]
### Orientation

*Disclaimer: I may never use github the way it is intended. I have plans to share gems and projects that may involve collaboration, but I suspect most of my "projects" will be little more than code showcases.*

[Towers of Hanoi](http://en.wikipedia.org/wiki/Tower_of_Hanoi) is a classic math puzzle. I was given the task as a programming exercise. The organization is seeking strong Ruby experience -- if I had more work on GitHub, I would huff. But without direction, I have been studying devops (and reconsidering PHP), so this challenge was interesting enough to keep me awake *thinking*.

Any smart programmer could get this done. But a the coder does not know Ruby, it could take days. The company claimed this task small and (hopefully) fun, and I agree.

The task is to solve Towers of Hanoi for four disks, without using well-known algorithms, and display a solution to the puzzle. Efficiency is not a goal, and the desired program was described as *small*.

Unfortunately, I failed to learn the lessons of [warpt](https://github.com/hakutsuru/warpt). When I program, I like to make heroic gestures toward usefulness and robustness. Considering this task, as there is must be more than one solution (series of moves), this should be revealed by any *inefficient* but *thorough* exploration of the puzzle (though we may terminate the search early to satisfy the task description).

### Environment
     ~ $ ruby --version
    ruby 1.9.3p194 (2012-04-20 revision 35410) [x86_64-darwin11.4.0]

### Example Code Run
      ~ $ ruby [...]/bthe/bthe.rb
      bthe - Brutish Tower of Hanoi Exercise
      Brute force solving Towers of Hanoi
        Number of disks: 4
        Seek mode: lazy
        -- halts when any solution found
        Branch mode: standard
        Narration: none
        Minimum moves to solve: 15

      Solution #1
      Steps Required 27
        1234-xxxx-xxxx
        x234-xxx1-xxxx
        xx34-xxx1-xxx2
        x134-xxxx-xxx2
        x134-xxx2-xxxx
        xx34-xx12-xxxx
        xxx4-xx12-xxx3
        xx14-xxx2-xxx3
        xx14-xxxx-xx23
        xxx4-xxx1-xx23
        xx24-xxx1-xxx3
        x124-xxxx-xxx3
        x124-xxx3-xxxx
        xx24-xx13-xxxx
        xxx4-xx13-xxx2
        xx14-xxx3-xxx2
        xx14-xx23-xxxx
        xxx4-x123-xxxx
        xxxx-x123-xxx4
        xxx1-xx23-xxx4
        xxx1-xxx3-xx24
        xxxx-xx13-xx24
        xxx2-xx13-xxx4
        xx12-xxx3-xxx4
        xx12-xxxx-xx34
        xxx2-xxx1-xx34
        xxxx-xxx1-x234
        xxxx-xxxx-1234

      Puzzle solved!
      States Evaluated: 28
      [finis]

### Installation

[placeholder]

### Basic Rules

Given three rods and a number of disks, move the tower of disks from the first rod to the third rod according to these standard rules...

    • Only one disk may be moved at a time.
    • Each move consists of taking the upper disk from one of the rods
      and sliding it on to another rod. The moved disk will always be
      the top disk on the new rod.
    • No disk may be placed on top of a smaller disk.

Without researching the mathematics, visualization leads one to realize there will never be more than two possible moves from any game state. Thus, the problem space is a binary tree, though I chose to treat it as general tree (with an unrestricted number of potential moves from any given state).

When evaluating potential moves, I implemented additional rules...

    • No disk may be moved twice in a row.
    • No game state may be repeated during the game.
    • If a potential move wins the game, others will be invalid.

As there are two empty rods, and either could be chosen "third", it follows there is always more than one potential solution.

### Goals

Aside from completing the challenge, it would be nice to achieve ancillary goals.

    1] Find all valid solutions.
    2] Avoid needless inefficiency.
    3] Provide useful options.
    4] Include testing.
    5] Create gem.
    6] Seek wisdom.

[1] Walking the decision tree is a brute force method, which is a requirement of the challenge, and should discover every valid solution. I thought of two brute-force approaches (yet avoided learning about the puzzle in depth, to avoid known solutions).

[2] There are differing interpretations of efficiency, being a brute force solution, we cannot expect to achieve much in terms of performance. Managing memory and garbage collection can make programs run faster, but exploring a tree is *recursive*.

(Eliminating branches once evaluated is a sensible tactic to allow the program to handle larger numbers of disks, or at least minimize wasted memory, *except* that many objects must be stored in stack memory, which is severely limited...)

[3] Default operation should satisfy the task requirements. But anyone who would run such a program would want to explore all possible solutions. Also, it is natural to want to experiment with different numbers of disks. Another simple option would be to change the order branch walking, which should alter the order of solutions found.

[4] Ruby is a testing-obsessed community. Testing should help illuminate a program, and ensure it is inexpensive to maintain. I found [*Practical Object-Oriented Design in Ruby*](http://www.poodr.info) to be instructive, and wish to emulate its author's approach.

[5] I have been asked if I ever created a gem, *sigh*. Another book is relevant to creating tools such as this -- [*Build Awesome Command-Line Applications in Ruby*](http://pragprog.com/book/dccar/build-awesome-command-line-applications-in-ruby).

[6] At Boston University, I was taught to focus on the requirements, and only after those were fully met, to add polish. After many interviews, I am intrigued by the extravagant desires of organizations seeking developers. Ruby can be a perilously zealous community, yet like most such cultures, also hypocritical.

Let's be blunt, if you have some development task that you believe I could not handle with minimal ramp up, eat your dog food: [YAGNI](http://en.wikipedia.org/wiki/You_aren't_gonna_need_it).

### Solution

I considered two solutions, a tree walk and iterating through permutations. I envisioned the data structure for permutations to be complex and unwieldy.

Walking a tree is recursive by nature, but easy to reason about... I thought following each branch out to a leaf, then backtracking to the next branch *while discarding leaves* could minimize resource consumption.

(One interesting idea is spawning threads to follow new branches, with the caveat that this would introduce thread pool management -- as there are far too many branches to be managed in parallel as the number of disk grows.)

Minimizing the data for each node may seem like an vital optimization, but actually, there is a critical problem with any recursive solution... limitations on stack memory [see *Issues*]. I doubly linked the tree to ease navigation, and stored history in nodes to avoid redundantly walking the tree. Even if node instance data could be minimized, permutations grow exponentially with the number of disks, so stack limitations would be exceeded.

The tree solution was instructive and fun. A significant benefit of this solution is that it makes me much more confident about trying an iterative approach (which should yield complete results for more complex puzzles and allow interesting experiments with garbage collection).

Running this solution in exhaustive mode for three disks reveals 12 solutions. It validates the theoretical minimum moves required as seven (2^N -1).

### Issues


**Correction**

The original algorithm was naive. I created a game node, then called *play* on the node. On reaching a leaf, I would *prune* the node parent. In *prune*, I would then check for other branches and follow those (via *play*). Thus, the recursion was loopy, and exhausted stack memory (when seeking all solutions and playing with more than three disks).

Logically, stack calls should be nearly equivalent to the number of moves in the history of any puzzle state (or node). When dealing with recursion, it makes sense to only call the recursive function from *itself*, to make it easier to evaluate.

Attempting to trap SystemStackError is futile (Ruby 1.9.3p194). The best one can do is keep track of *caller* depth, and warn when it is growing beyond a certain threshold.

The current algorithm reveals 1872 solutions for a puzzle with *four* disks, yet fails to find any solutions for *eight* disks due to stack memory limitations.

**Original Observations**

When running the program for some number of disks greater than three [depending on seek mode], you should encounter "stack level too deep (SystemStackError)".

I attempted to work around this by adjusting stack size, but it seemed ineffective.

    ~ $ ruby [...]/bthe/bthe.rb 
    ...
    node: 4379
    [...]/bthe/bthe.rb:117: stack level too deep (SystemStackError)
     ~ $ ulimit -s
    8192
     ~ $ ulimit -s hard
     ~ $ ulimit -s
    65532
    ~ $ ruby [...]/bthe/bthe.rb 
    ...
    node: 4379
    [...]/bthe/bthe.rb:117: stack level too deep (SystemStackError)

I believe increasing stack size would minimally effective and complicated, as the number of nodes to evaluate increases rapidly with the number of disks.

Perhaps there is a flaw in the naive way I devised the tree solution that makes this issue worse, but it seems intractable. Note: the classical recursive algoritm achieves the *minimal number of moves possible*, but reveals nothing of other possible solutions -- it is inherently more scalable, as it is focuses on constructing one permutation.

### Curds and Whey

I write tests while building structures, and tend to write methods as class methods for isolated testing. Many of the tests I write are quick, and one would argue they should be preserved, and drive development.

But I think testing increases costs unless the problem space is well-known. When creating a solution, most code would be in one or two classes as various states and messages are being explored. But as one becomes uncomfortable with having unrelated details in a class or with glaring dependancies, such would be moved into new classes and modules. Testing helps you refactor, to keep code *working* while being extended and improved. If your code does not work, testing is an expensive distraction.

(I have enough experience to have seen terribly broken code undergird by a plethora of seemingly sensible tests, so I have sympathy for [Hickey's heretical stance](http://www.codequarterly.com/2011/rich-hickey/) on testing. If code is to be cost effective and reliable, generally, it must be easy to read and reason about.

At the risk of embarrassment, I left vestigial tests in comments. I hope to refactor *bthe*, so the code may become more refined, and include proper tests. *bthe* is little more than a hack, and making it *right* will take time, but the author of the task did not ask for fully polished code.)

I am also skeptical of over-simplified methods. I found the example refactoring in [*Eloquent Ruby*](http://eloquentruby.com) to be compelling and instructive. Nevertheless, while I know *analyze_options* and *play* could be more elegant, I am not sure breaking them up into several smaller methods would improve the clarity and simplicity of the code.

Like most developers, I am averse to deeply nested logic and long methods, but keeping related lines of code in one place can make it more cohesive.

### Feedback

#### Response to "initial commit" (quick-draft)

    Your source code appears very complex to me. The long methods makes it hard for
    you to implement it in an easier way. A good approach is usually to break down
    the complex problem in very small and easily solvable pieces.
    That's something I'm missing in your source. 

I doubt it possible to solve this puzzle in a brute force way *that would be significantly more simple*. Feedback was provided by the CTO who supplied the challenge. If you can scale a database to 10,000 operations/second, and could make this puzzle seem trivial, *and* want to join a startup in New York City -- let me put you in touch...


### License

[placeholder]

