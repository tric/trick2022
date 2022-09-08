#!/usr/bin/ruby
# This is a slightly more readable version of entry.rb.  You can produce this
# file yourself by changing "eval" on line 1 to "print" to uncompress the
# code, insert some spaces for formatting, and add all the comments.  I just
# saved you a bit of typing.  Well, I also have rationale on why certain
# things are implemented the way they are, some of which are not obvious, so
# hopefully these comments would be interesting to read.
#
# I didn't rename the variables back to their original names, because in the
# process of trying to compress the code down to size, variables that have
# distinct lifetimes or shadow each other will likely share the same single
# character identifier, so the meaning of each identifier will change
# depending on context.


# This script only needs "io/console".  Almost every Ruby distribution I tried
# came with "io/console" available by default, so that's nice.  It would be a
# real chore to try to do input in a portable way otherwise.
#
# Not seen in this uncompressed text, but the final entry.rb also requires
# "zlib".  I tried pretty hard to implement my own compression scheme, but I
# just couldn't trim the final ~100 bytes or so without also dropping some
# features.  Eventually I resorted to using zlib and uuencode, but you can see
# many vestiges left in this code where I intentionally increased redundancy.
# I suppose those would have been useful for zlib as well.
require "io/console"


# D = unit vectors of the up/down/right/left directions, plus a "false" at
#     the end to simplify one input handling conditional (see comments near
#     "d = d ?" later).
#
# The up/down/right/left order is the same order as how ANSI escape codes for
# cursor movement are sorted ("\e[A" .. "\e[D").  These are also used for
# arrow keys.  I ordered most operations this way just in case if I were to
# make use of the code-to-direction translations, but ended up not using it.
D = [[0, -1], [0, 1], [1, 0], [-1, 0], !1]

# R = color palette and sprite palette:
#     [0] = "\e[0m", which is the ANSI escape code to reset.
#     [1..14] = colors of the form "\e[<foreground>;<background>m", stored
#               as ASCII character pairs.  The -5 offset for foreground
#               colors is to avoid storing unprintable characters.
#               Encoding the colors this way saved about 80 bytes.
#     [15..23] = sprite strings, stored as character pairs.
#
# r = temporary variable needed for sprite decompression, below.  It needs
#     to be declared here so that it's outside the scope of map{}, so that
#     it maintains state across different map{} iterations.
#
# r is also later used to indicate whether the game is currently running or
# not (search for the two places with "while r").  I saved 3 bytes by leaving
# it in a non-false value after decoding sprites.
r =
R = ["\e[0m"] +
    "#,'h_(e(#kek#df/)de/`(f)f.#j".scan(/../).map{|x|
       "\e[#{x.ord - 5};#{x[1].ord}m"
    } +
    "##  []()@@OO%%XX++".scan(/../)

# S = List of sprites.  It's two 2D arrays merged into one:
#     [0..9] = sprites used for the chain display in upper left corner,
#              indexed by "current chain length * 2 + current chain color".
#              The last two entries are used for the blinking effect when
#              the current chain is at maximum length.
#     [10..31] = sprites used to draw grid tiles, indexed by
#                "tile type * 2 + current player color".
#     [32] = one extra unused sprite at the end due to split() handling.
#
# These sprites are encoded as a list of words, where each character in the
# word indexes into R[] above to fetch either a color or a sprite string.
# The words are separated by "y".  Because Ruby's split() will drop trailing
# elements, an extra unused sprite is added at the end so that the input
# string does not end with "y".
#
# An empty word (i.e. two consecutive "y"s) means "repeat last sprite",
# which is handy since some of the sprites are identical across the two
# color indices.  The sprite to be repeated is tracked in "r" variable
# declared above.
#
# This R[] and S[] packing scheme for sprites and colors saved about 244
# bytes.
#
# Note that there are exactly two sets of tile sprites (indexed by player
# color), and the only blinking that happens is during max chain status.
# Earlier version of this game had 4 sets of sprites to implement a glittering
# effect for all items in the game field.  This was later scrapped because the
# extra bandwidth needed to redraw the entire game field on every frame made
# the game unplayable across SSH.  And it cost 29+ more bytes of code.
S = "aqqqyydraqqyfsaqqydrraqyfssaqyerrraygsssaydrrrayfsssaycpyybqyyerydryfsygsyetyguyjvykpyhvyipyhwyixyltymuycryycsyya".split(/y/).map{|x|
       x == "" ? r
               : r = x.bytes.map{|y| R[y - 97] } * ""
    }

# p, q = terminal height and width.
#
# Note that most other places follow an alphabetical convention ("p, q"
# and "x, y" means "column, row"), but here "p" is height and "q" is
# width.  It's done this way to increase redundancy with other instances
# of "p, q".
p, q = IO.console.winsize

# Enforce minimum dimensions, partly so that there is enough space to draw
# everything, and partly so that there is enough space to generate
# sufficient items to make the game fun.  We can probably get away with
# something as small as 26 columns by 10 rows, but those games tend to be
# not very interesting.
#
# By the way, you might think that a really small grid will make an easy
# game, but what that really provides is a short game.  It's actually more
# difficult to score long chains with a small grid because there is less
# room to maneuver.
if p < 12 || q < 39
   # Output an error message and exit.
   #
   # In earlier versions, this was a more descriptive "window size too
   # small, need X by Y" kind of text, but now I have a more succinct text
   # which uses the word "console" to increase redundancy.  I am not sure
   # how well zlib made use of that, but with my custom compressor, sharing
   # this "console" word saved 15 bytes.
   print "console too small\n"
   exit
end

# Hide cursor, then clear the screen.  Actually, hide the cursor repeatedly,
# which saves me 3 bytes from not using a separate string.
#
# Clearing screen is done by writing width*height number of spaces.  It's
# done this way as opposed to the more efficient way of writing height
# number of newlines, because I found that if the program was started with
# the cursor exactly at the last column of the terminal, sometimes we need
# one extra newline to fully make room for the grid.  Writing spaces seems
# more reliable.
#
# Getting the cursor exactly at the last column might seem like a rare
# condition because this program normally runs without arguments, but it's
# quite easy to encounter that condition given a small enough terminal.
print " \e[?25l" * p * q

# W, H = grid width and height.
#
# Terminal dimensions are converted to grid dimensions by applying these
# adjustments:
#
# - Width minus 1 is to avoid margins, otherwise things may wrap poorly.
#
# - Width divided by 2 is to account for 1:2 aspect ratio of the character
#   cell.  Well, my terminal fonts are close enough to 1:2, yours might be
#   vastly different, but there isn't a cheap way to detect and adjust for
#   this.
#
# - Height minus 2 is to account for margin and status bar.
#
# Since these are constant from here on, they are stored as constants.  This
# is great, because single-letter-lowercase variable names are a precious
# resource.  I could have saved 1 byte here by doing "p-=2", but by
# assigning "H=p-2", the "p" variable becomes available for greater savings
# elsewhere.
W = ~-q / 2
H = p - 2

# Here we initialize various game states.  They are assigned here so that
# they can be visible to the "ef" and "rf" procedures and "it" thread later
# (i.e. make sure the variable exists in the global scope so that they are
# not interpreted as local variables later).
#
# They are mostly assigned together, because chaining assignments saves
# ~14 bytes.
#
# c = player color (0 or 1).
# o = game grid, a 2D array with H rows and W columns.
# h = position history, a list of [x,y] pairs.
# b = current player direction (0..3).  Initial direction is right (2).
#     This is also an index into the "D" array defined earlier.
# g = growth target.  Snake length will grow one unit per movement until
#     this target is met.
# a = color of last item eaten (7 or 8).  This is used to check if the
#     player is continuing an ongoing chain.  Since the initial chain
#     length is 0, it kind of doesn't matter which color we start off
#     with, as long as it's either 7 or 8.
# f = next item to be placed.  Initial value doesn't matter.
# e = endgame state (true or false).
#
# Endgame is a special state where we hold the generated item color to be
# constant, see comments near "e ||=" for additional notes on endgame mode.
c = 1
o = h = []
b = g = 2
a = 8
f = e = !1

# p = desired speed in units per second, from command line argument.
#
# Adjusting game speed was mostly a debugging feature, because it was too
# difficult to test item generation heuristics at full speed.  But this was
# too good a feature to keep to myself, so I made it adjustable via command
# line arguments.
p = ARGV[0].to_f

# M = amount of time in seconds to wait between movements.  This is
#     assigned to a constant to free up a lowercase variable.
M = p >= 0.1 ? 1 / p : 0.2

# ii = input buffer.  A ring buffer of input commands, see comments near
#      "Thread.new" for additional notes on input handling.  "ii" has 8
#      elements because 8 is the largest power of 2 that is a single digit.
#      I suspect we can actually get away with just 4.
# s = score.  See comments near "s += 10" for additional notes on scoring.
# m = number of items in the current chain.
# n = current chain length.
# l = maximum achieved chain length.
# cc = 1 bit frame counter for blinking effect (0 or 2).
# j = next position to write to in "ii" buffer.
# k = next position to read from in "ii" buffer.
#
# Notice the use of "ii" and "cc", meaning I ran out of single letter
# variables names.  The choice of "cc" was deliberate because there are
# exactly two places where we do XOR, once with "cc ^= 2" and another with
# "c ^= 1", and the extra redundancy in "c^=" helped my compressor slightly.
#
# "ii" did not have the same 3-byte redundancy to be exploited, so I just
# picked whatever.  "ii" is a good name if you know Japanese.
ii = [s = m = n = l = cc = j = k = 0] * 8

# Initialize grid with walls along all 4 borders.  5=wall, 6=space.
#
# Having explicit wall tiles means I don't have to add special bounds
# checks.  Also, when a player dies by running into a wall, we would be
# able to show where they hit because walls are part of the grid that is
# drawn.  It's difficult to achieve the same effect with implicit
# invisible walls.
H.times{|w| o += [[5] +
                  [w > 0 && w < H - 1 ? 6 : 5] * (W - 2) +
                  [5]]
}

# Initialize player position, and also mark the initial player head cell (9).
#
# p, q = snake head position (column, row).  Players start off in the center
#        row, about 1/4 of the way from the left side of the screen.
# C = center row offset.  Saving this value here saves 4 bytes in the game
#     over message.
#
# "p, q" now mostly means player location in global scope, although note
# that there is still one place with "|p, q|", thanks to Ruby's variable
# shadowing that allows me to free up a few lowercase variables.
o[q = C = H / 2][p = W / 4] = 9

# Place an initial item (8=white) right across from the player, about 1/4 of
# the way from the right side of the screen.
#
# Note that this is on the same row as the player, and the player's initial
# direction is right (2), which means the first item is along the path to be
# eaten by the player if they take no action at all.  This is all the
# tutorial I have implemented for this snake game, if that qualifies as a
# tutorial.
#
# This tutorial feature isn't as important as the fact that this placement
# guarantees that there is at least one item in play.  This is important
# because on sufficiently small grids, we could start off with no items at
# all, in which case there is nothing to do except to wait and die.  You
# might think the probability of generating an empty grid is very small, and
# I used to think that way too until I encountered one during testing.
o[q][W - p] = 8

# z = item serial number.
#
# Item serial number starts at 4.  Items are generated in groups of threes
# (see comment near "z % 6 / 3" below), so 4 here means "second item in the
# first white item group".
#
# z=0 -> group 1 first black.
# z=1 -> group 1 second black.
# z=2 -> group 1 third black.
# z=3 -> group 2 first white = initial item that was placed above.
# z=4 -> group 2 second white = next item to be placed.
# z=5 -> group 2 third white.
z = 4


# ef = eligibility function.  Given an (x, y) position, return true if this
#      position is eligible for new item placements.  This is used
#      throughout the majority of the game but not during the endgame.
#
# As a side effect, this also updates the next item to be placed (f).
ef = ->(x, y) {
   # Compute the next item to be placed from item serial number (z).  Result
   # is either 7=black or 8=white.  This expression generates items with the
   # same color in alternating groups of threes deterministically, which means
   # if a player maintained perfect chain status since the beginning of the
   # game, they will be able to maintain chain status all the way to the end.
   #
   # Deterministic selection of items makes this game feel more like Ikaruga,
   # compared to random selection which would make it feel more like Tetris.
   # Top Ikaruga players tend to play by memorizing enemy patterns because so
   # much of that game is deterministic, so I was going to make the item
   # selection and placement deterministic.  In the end I didn't do that
   # because it requires a lot more heuristics to make it fun for different
   # terminal sizes.
   f = z % 6 / 3 + 7

   # Do not allow an item to be placed unless it's surrounded by other items
   # of the same color (f) or space (6).  This means new items are not
   # immediately adjacent to obstacles, which makes the game easier to play.
   #
   # This function used to also count the number of neighboring cells of the
   # same color to avoid generating large clusters of the same color, but
   # not doing that saves ~14 bytes.
   [*-1..1].product([*-1..1]).all?{|p, q|
      i = o[y + q][x + p];
      i == f || i == 6
   }
}


# Generate initial set of items, by applying eligibility function to all
# grid positions in random order, with a few extra constraints:
#
# - Don't place initial items near the same rows as where the player started.
#
# - Only try to place an item 10% of the time.  This avoids starting off
#   with a grid that is too dense, and lower density makes the game easier
#   to play.
#
# This shuffled list of positions could have been reused for ongoing
# regeneration of items.  This was implemented in an earlier version of this
# game where the positions are shuffled once, and subsequent item placements
# are taken from this list with round-robin assignment.  Doing it that way
# costs 2 more variables to maintain round-robin state and some extra loop
# management, which turned out to not be worth it.
#
# The one thing I was worried about was doing product and shuffle repeatedly
# would be expensive, but generating ~1000 positions costs less than a
# millisecond on my machine, so I figured most people aren't going to notice
# that delay.
[*1..W-2].product([*1..H-2]).shuffle.map{|x, y|
   if (y - q).abs > 1 && rand < 0.1 && ef.call(x, y)
      # Place the item and increase the item serial number (z).
      o[y][x] = f
      z += 1
   end
}


# rf = render function.  This function replaces the entire screen with new
#      grid contents.
#
# Notice how this function is named "rf" while the eligibility function is
# named "ef".  This is so that I can gain a bit of redundancy on "f.call"
# substring.
rf = ->{
   # w = score text.
   w = " #{s}"

   # v = chain counter, to be placed in the middle part of the top of the
   #     screen.  It's just plain whitespaces unless the player has made at
   #     least 1 chain.
   v = " " * (W * 2 - 6 - w.size)
   if n > 0
      # Show the current number of consecutive unbroken chains.
      v = "  %-#{W * 2 - 8 - w.size}s" % "#{n} chain"

      # Change the chain background color as another visual indication of
      # chain length.  This bar grows longer as the number of chains grows,
      # for as much space as there is available without having to overlap
      # with score text.
      #
      # If the current chain length is 9 or longer, the background color
      # changes to a brighter cyan, and the "chain" text changes to
      # uppercase "CHAIN".  This is meant to tell the player that they have
      # attained maximum chain bonus.  Ikaruga would have flashed "max
      # chain" text near the player instead, but doing it that way is too
      # distracting with a low-resolution text mode game.
      #
      # Ikaruga also has a growing power bar, which is originally vertical
      # but horizontal in some versions.  I made this bar horizontal only
      # because it was more convenient to draw this way, and I would be able
      # to fit this together with the chain counter text, although
      # personally I preferred the look of that vertical power bar.
      i = [v.size, n * 2].min
      v = R[n > 8 ? (v.upcase!; 14) : 13] + v[0, i] + "\e[0m" + v[i, v.size]
   end

   # Move the cursor to the top of the screen and draw the status bar:
   # - Current chain status in upper left corner (6 characters wide).
   # - Score in upper right corner (right-aligned).
   # - Ongoing chain status in the middle (fill remaining horizontal space).
   print "\e[#{H + 1}A\r" + S[m * 2 + a - 7] + v + "\e[1m#{w}\e[0m\n\r" +
         # Following chain status, here is where we draw the grid contents,
         # which simply translates numeric tiles into sprites and joins them
         # together.
         o.map{|x|
            x.map{|y| S[y * 2 + c] } * ""
         } * "\e[0m\n\r" +
         "\n"
}


# it = input thread.
#
# Input for this game works by doing a blocking read in a separate thread,
# and then writing the input event to a ring buffer to be consumed by the
# main game thread.  Traditional games might be looking for key up/down
# events in an event loop, but I am not sure if the libraries distributed
# with default installations of Ruby allows me to do that in a portable way.
# Also, we don't really have a constant frame rate, and having players adapt
# to an unstable event loop makes the game more difficult.
#
# The non-constant frame rate is also why we have an input buffer -- a
# common thing to do in snake games is to go to an adjacent row by making
# two consecutive turns quickly, and I found that it's very difficult to
# time my keystrokes to make that happen consistently, regardless of how
# fast this input loop runs.  The only way to support quick sequence of keys
# is to buffer inputs.
#
# I could have also avoided this separate input thread by doing a
# read-with-timeout in the game loop, but that introduces a serious input
# lag on Windows, so I stopped doing that.
it = Thread.new{
   # Loop until game over condition is met (r is false).
   #
   # Usually the game ends while this thread is still waiting for a
   # keystroke, so the last thing that the main game loop does is to display
   # a game over message to encourage players to press a key to continue.
   # If the player already has some keystrokes queued then the message might
   # disappear before it's noticed by the player, otherwise the player will
   # need to press an extra key to get out of the blocking read.  In both
   # cases, the thread is terminated gracefully.
   #
   # Alternatively, I could have avoided the game over message by killing
   # the input thread.  Usually this means the thread is getting killed
   # while it's waiting for STDIN.getch to return, and depending on the
   # environment, often the program will exit with echo disabled (despite
   # STDIN.echo=true at the end).  It was just very annoying to have a
   # non-working terminal after dying in a snake game, so I added that game
   # over message to make sure the last keystroke is consumed and input
   # thread is not waiting on STDIN.getch before terminating.
   while r
      # w = input keystroke.
      # v = keystroke translated to a numeric command index.
      #
      # First we ignore the "\e" and "[" that would be received with arrow
      # keys, and then we translate those arrow keys or WSAD keys into an
      # index into the direction vector.  Directions are translated to 0..3,
      # everything else gets 4.
      #
      # I could have saved a few bytes here by not supporting WSAD keys, but
      # WSAD seems to work better when playing left-handed, and I know some
      # keyboards that don't have arrow keys at all, so it's worth keeping
      # WSAD as a fallback.
      v = "\e[".index(w = STDIN.getch) ? !1
                                       : ("AwBsCdDa".index(w) || 8) / 2
      if v
         # Write to input buffer:
         # 1. Assign w to be the next ring buffer position to write.
         # 2. Write the translated command to the input buffer.
         # 3. Commit the written position to global j.
         #
         # I assumed that accesses to a pre-allocated non-resizing ring
         # buffer would be thread-safe, and that updates to a small integer
         # variable would be atomic.  But I think these assumptions are
         # implementation-dependent and aren't promised by Ruby specs.  In
         # the end, this whole game is built on top of race conditions, but
         # practically it does seem to work in all environments I tested.
         ii[w = -~j % 8] = v
         j = w
      end
   end
}


# Disable echo, otherwise any keystrokes pressed between calls to getch will
# mess up our game field.
STDIN.echo = !1

# Draw initial frame.
rf.call

# tt = timestamp of last movement.
#
# This variable is named "tt" so that I gain a bit of redundancy on the
# "t=Time" substring.
tt = Time::now

# This is the main game loop, which loops until "r" is false.  "r" was
# initialized to a non-false state while it was being used to initialize "S"
# near the beginning.
while r
   # Make the chain status flash if current item count (m) is 3, i.e. flash
   # if the player has just completed a chain.
   if m > 2
      print "\e[#{H + 1}A\r#{S[a - 1 + cc]}\e[#{H + 1}B"
      cc ^= 2
   end

   # If input read index (k) differs from input write index (j), it means
   # there is some buffered input command.
   if k != j
      # w = next input command, which is either a direction (0..3) or a
      #     color change (4).
      # d = next direction, either a unit vector or "false".
      d = D[w = ii[k = -~k % 8]]

      # d = If w was in the range of 0..3, d will evaluate to a direction on
      #     input, and this expression will evaluate to a tile value in the
      #     range of 5..15.
      #
      #     If w was 4, d will evaluate to "false" on input, and this
      #     expression evaluates to (c^=1) which toggles player's current
      #     color, and leaves d in the range of 0..1.
      d = d ? o[q + d[1]][p + d[0]]
            : (c ^= 1)

      # Commit the direction change if d is in the acceptable range of tile
      # values.  Acceptable values are:
      # 6 = space.
      # 7 = black item.
      # 8 = white item.
      #
      # Unacceptable values include walls and snake body tiles.  In other
      # words, this conditional prevents most suicides.  Not having this
      # suicide prevention feature would have saved me about 33 bytes,
      # but having this feature means I wouldn't have to worry about deaths
      # due to accidentally pressing the opposite direction key.  It also
      # means I can run straight up against a wall without running into the
      # wall.  And even if I didn't have buffered input, I still wouldn't
      # need to worry about premature turns.  This last part was actually
      # why I added the feature, and I kept it because it made the game much
      # more pleasant to play.
      #
      # This feature doesn't prevent deaths due to turning into an item of
      # opposite color.  It didn't occur to me that I should block those
      # because usually that only happened to me when I wanted to end a game
      # early on purpose.  Also, not doing that check saves 4 bytes.
      if d > 5 && d < 9
         # Update current player direction (b) with the new direction (w).
         b = w

         # Reset last movement timestamp (tt) such that the movement happens
         # immediately.  This means turns happen without delay, which makes
         # U-turn behavior more intuitive.
         #
         # This also means pressing the player is able to skip the movement
         # delay by pressing direction keys repeatedly.  This is very handy
         # when the game is configured to run at a very low speed (with high
         # value of M).
         tt = Time.at(0)
      end

      # Redraw the whole screen on input.  This is actually only needed if
      # there is a color change, so it could have been moved to an "else"
      # branch in the conditional above, but not doing that saves 4 bytes.
      rf.call
   end

   # t = current time.
   t = Time::now

   # Compare current time (t) with last movement time (tt) to see if it's
   # time to move.
   if t - tt < M
      # If it's not time to move yet, wait a bit before checking the input
      # buffer again.  0.02 was found to be a good enough interval, and
      # produced a better blinking effect for the max chain status compared
      # to 0.01.
      #
      # Actual amount of time slept is actually not very accurate depending
      # on the environment.  I got these results with my benchmark:
      #
      # Requested   Actual (Linux)   Actual (Windows)
      # ---------   --------------   ----------------
      # 0.5         0.51480103       0.51480103
      # 0.2         0.20041497       0.20306458
      # 0.1         0.10032557       0.10934742
      # 0.05        0.05046370       0.06247209  :(
      # 0.02        0.02031967       0.03124863    :(
      # 0.01        0.01029934       0.01560753       what's up with these?
      # 0.005       0.00529562       0.01562527       ?
      # 0.002       0.00238278       0.01561795       ??
      # 0.001       0.00150982       0.01561525       ??!
      # 0.0005      0.00060497       0.00052573
      # 0.0002      0.00027596       0.00020474
      # 0.0001      0.00017230       0.00010939
      #
      # In other words, sleep was observed to be pretty good on Linux, and
      # not very consistent on Windows.  It was so terrible that earlier
      # versions of this game starts with a benchmark to compute a subset of
      # the table above, and fell back to busy loops without sleeps if the
      # accuracy was too low.  I was pegging one whole CPU core on Windows
      # just to run my snake game, it was embarrassing.
      sleep 0.02

      # Instead of the huge "else" branch below, I could have done "next".
      # The number of bytes needed would be the same both ways, but "next"
      # would have reduced the nesting level needed.  Still, I have
      # standardized on using "else" throughout this program, because doing
      # that increases redundancy.

   else
      # Sufficient time has elapsed since the last movement.  This is the
      # branch where most of the game logic happens.

      # Update last movement timestamp (tt) with current time (t).
      #
      # "t" is not needed anymore, and the identifier is immediately
      # recycled below.
      tt = t

      # Append current player location (p,q) to history (h).
      #
      # t = list of dirty pixels to redraw, in [x,y] pairs.
      h += t = [[p,q]]

      # Update grid (o) to replace the current cell with a pixel marking
      # the snake tail (10).  Previously it was the head of the snake (9).
      o[q][p] = 10

      # i = coordinate of the middle point of the snake body.
      #
      # This used to draw the latter half of the snake body with a different
      # tile (11).  This is also added to the list of dirty pixels (t).
      #
      # I wanted different tiles for different segments of the snake body so
      # that players can gauge which direction the snake is moving and how
      # much they need to wait for a spot to clear.  Usually what happens
      # after playing for a while is that the folded snake body ends up as
      # one contiguous blob, and there is just no sense of how it will
      # unfold.  Knowing which portion of that blob belongs to the fore or
      # aft sections of the snake provides a hint for the unfolding order,
      # which helps navigation a bit.  Doing this also results in a neat
      # stretching effect when the snake grows.
      #
      # If I can be sure that the terminal has the right locale, drawing the
      # snake tail using Unicode box-drawing characters might have been a
      # better solution, but it's not portable.  I have also tried drawing
      # the snake tail with "AAVV>><<" characters to indicate direction, but
      # it looked weird.  Also, it costs a few extra bytes to store sprites
      # for a directional tail.
      t += [i = h[h.size / 2]]
      o[i[1]][i[0]] = 11

      # Same heuristic as the above, but update the last 1/4 segment of the
      # snake tail with yet another sprite (12).
      #
      # These 3 statements seem repetitive and could have been replaced by a
      # loop, but I found that I saved more space by unrolling the loop and
      # let the compressor take care of the redundancy.
      t += [i = h[h.size / 4]]
      o[i[1]][i[0]] = 12

      # d = direction of where the player is moving next.
      d = D[b]

      # d = tile of where the player landed on.
      d = o[q += d[1]][p += d[0]]

      # Check for collisions.
      if d != 6
         # Player landed on a non-space tile.
         if d == c + 7
            # Player landed on an item of matching color.
            #
            # This is the branch where we apply Ikaruga scoring rules.

            # Base score for eating any item is 10.
            #
            # This appears to be a video game tradition -- minimum points
            # for normal things are multiples of 10, and continuing after
            # game over earns 1 point per continue.  Ikaruga does this too.
            # I am not sure how I would have implemented continues in this
            # snake game though, so basically scores from this game are
            # always multiples of 10.
            s += 10

            if m % 3 > 0
               # Current item count (m) is 1 or 2.
               if a == d
                  # Current in-progress chain color (a) matches the tile
                  # that the player has landed on (d), so we are continuing
                  # the current chain.

                  # Increment item count (m).
                  m += 1
                  if m == 3
                     # We have completed a chain, increment chain count (n).
                     n += 1

                     # Update maximum achieved chain count (l).
                     l = [l, n].max

                     # Add chain bonus to score.  Chain bonus starts at 100
                     # and doubles until it reaches 25600, same as Ikaruga.
                     s += 2 ** [n - 1, 8].min * 100
                  end
               else
                  # Current in-progress chain color (a) differs from the
                  # tile that the player has landed on (d), so we have
                  # broken the chain.

                  # Update current in-progress chain color (a) to be the tile
                  # that the player has just landed on (d).
                  a = d

                  # Set current time count (m) to 1 to indicate that we are
                  # starting a new chain.
                  m = 1

                  # Reset chain count (n) to 0 since we have broken the chain.
                  n = 0
               end
            else
               # Current item count (m) is 0 or 3, so we are starting a new
               # chain.

               # Set in-progress chain color (a) to match tile (d).
               a = d

               # Set item count (m) to 1 to indicate that we are starting a
               # new chain.
               m = 1
            end

            # Increment growth target (g).
            g += 2

            # Mark new player position with head tile (9).  This also
            # removes the item from the current cell.
            #
            # In earlier versions, it was important to do this removal
            # before placing new items, because we might want to count the
            # number of items to determine whether to enter endgame mode or
            # not.  In the current version it kind of doesn't matter whether
            # we do this removal early or late.
            o[q][p] = 9

            # u = need to place item (1 or false).
            u = 1

            # Try item placement in three passes.
            3.times{|w|
               # Try all grid positions in random order to determine where
               # new items would be placed.
               [*1..W-2].product([*1..H-2]).shuffle.map{|x, y|
                  # Items would be placed at (x,y) if these constraints are
                  # satisfied:
                  # [0] No item has been placed yet (u).
                  # [1] (x,y) contains space (6).
                  # [2] (x,y) is at least 3 units away from snake head (p,q).
                  # [3] (x,y) satisfies eligibility function (ef).
                  #
                  # In the first pass (w=0), all constraints must be satisfied.
                  # [3] is dropped for the second pass (w=1), [2] and [3] are
                  # dropped for the final pass (w=2).
                  if [u,
                      o[y][x] == 6,
                      (x - p).abs > 3 || (y - q).abs > 3,
                      ef.call(x, y)].take(4 - w).all?

                     # If we had to resort to second or third pass (w>0)
                     # without having placed an item (u), it means the grid
                     # has gotten too crowded for normal item generation, and
                     # we would now enter endgame mode (e=true).
                     #
                     # The amount of available spaces for placing items
                     # shrinks as the snake grows longer, which means at some
                     # point, we will be forced to place new items near where
                     # the snake head is, and the player might not have time
                     # to react.  This is not a problem in classical snake
                     # games since player can just eat those newly placed
                     # items without even noticing, but it is a problem for
                     # this game if the newly placed item is of opposite color
                     # from current player color, and having an obstacle that
                     # pops up without giving players time to react would seem
                     # unfair and not fun.
                     #
                     # My solution to the crowded placement problem is to
                     # detect when it happens, and make this game enter an
                     # "endgame" mode where all item colors are fixed,
                     # effectively turning it into a classical snake game from
                     # there on.  The lower right corner of the grid is marked
                     # with a "hint" tile to show that we are now in endgame
                     # mode, and also to show which color we have settled on.
                     #
                     # The only condition for entering endgame is having to
                     # resort to second or third pass, and the only heuristic
                     # for selecting endgame item color is to just hold the
                     # next selected item color constant.  This means if a
                     # player were able to maintain perfect chains before
                     # endgame mode is enabled, they will still have the right
                     # items for maintaining chains all the way to the end.  I
                     # used to have a much more sophisticated heuristic here
                     # that ensures perfect chains are possible even if the
                     # player did not play perfectly before endgame, but not
                     # doing that saved about 221 bytes.
                     e ||= w > 0 && (o[H - 1][W - 1] = f + 7)

                     # Write selected item to the grid.
                     o[y][x] = f

                     # Update bit to say that we no longer need to place more
                     # items (u=false), but skip setting this bit with some
                     # low probability.  This means occasionally we would get
                     # 2 or more items generated after eating just 1.  This
                     # is different from other snake games I have tested where
                     # players always get one item generated for every item
                     # eaten, and this difference is exactly why I did it.
                     #
                     # "rand < 0.1" is used here to increase redundancy with
                     # the earlier "rand < 0.1".  Also, I found that 0.1 has
                     # just the subtleness that I liked, 0.2 and above makes
                     # the effect more obvious, and is somewhat unsettling
                     # because the grid gets filled up much faster than
                     # expected.
                     #
                     # Occasionally generating more items means players might
                     # get more items to choose from than initially available,
                     # which makes small grids more fun (the effect is only
                     # subtly noticeable on normal size grids).
                     #
                     # This feature might also cause us to enter endgame
                     # slightly earlier than expected, which can be avoided
                     # with a bitmask encoding of "u" (probabilistically set
                     # bit for w=0, unconditionally set bit for w=1 and
                     # w=2).  But this is a low probability event, and not
                     # doing that bitmask scheme saved me 9 bytes.
                     u = rand < 0.1

                     # Increment item serial number (z) if we are not in
                     # endgame mode (e).  This means new item colors will be
                     # alternating (in groups of threes) before endgame, while
                     # remaining fixed during endgame.
                     z += e ? 0 : 1
                  end
               }
            }

            # Redraw the whole grid to show the newly placed item.
            rf.call

         else
            # Player landed on some tile that is not an item of matching
            # color.  Choices are:
            # 5 = wall
            # 7..8 = opposite color item
            # 10..12 = snake body
            #
            # All of these are interpreted as obstacles.

            # Mark the current player location with a tombstone (13) to
            # show where the collision happened.
            o[q][p] = 13

            # Do a full redraw to make the tombstone visible.
            rf.call

            # Show game over text in the center.  This is meant to encourage
            # players to press a key to get out of STDIN.getch, if they don't
            # have a keystroke buffered already.
            #
            # In earlier versions, there was a more explicit text that says
            # "press any key".  Not showing that saved 28 bytes.
            print "\e[#{C + 1}A\r\e[#{W - 8}C\e[0m    GAME OVER    ",
                  "\n\r" * C

            # Set running state (r) to false, which causes the game loop and
            # input thread to exit.
            r = !1
         end

      else
         # Player landed on a space tile.

         # Mark new snake head (9).
         o[q][p] = 9

         # Add snake head location (p,q) to the list of dirty pixels (t).
         t += [[p, q]]

         # Check if snake length (h.size) has exceeded growth target (g).
         if h.size > g
            # Snake length has exceeded growth target, so we need to erase
            # one tail pixel by replacing the tile with space (6), and add
            # that position to the list of dirty pixels (t).
            x, y = h.shift
            o[y][x] = 6
            t += [[x, y]]

            # Check item count to decide if we need to stop blinking.
            if m == 3
               # If a player has just completed a chain, and the snake has
               # moved enough units such that it stopped growing, it means the
               # max chain status has blinked for long enough and it can stop
               # blinking now.  Setting item count (m) to zero does that.
               #
               # This means the snake growth target (g) also acts as a
               # timer to stop blinking.  Doing it this way means the blink
               # time is not guaranteed to be constant, but it will be
               # stable on average because the next items will often be
               # more than 2 cells away.  Overloading "g" this way saved me
               # at least 4 bytes.
               m = 0

               # Redraw the whole screen.  This is needed to reset the chain
               # status display.
               rf.call

               # Since a full redraw of the grid had just happened, I could
               # have inserted "next" here to skip redrawing the dirty pixels
               # below, but not doing that saved me 4 bytes.
            end
         end

         # Draw the dirty pixels.
         print "\e[#{H}A" +
               t.map{|x, y|
                  "\e[#{y}B\r\e[#{x * 2}C#{S[o[y][x] * 2 + c]}\e[#{y}A"
               } * "" +
               "\e[#{H}B"
      end
   end
end

# Main game loop has ended.  Wait for the input thread to complete.
it.join

# Do another redraw to erase the "game over" text.
rf.call


# Grade the player's performance.  The grade that Ikaruga gives out at the
# end of each level appears to be purely based on score, and I could have
# made a purely score-based grading system here as well, but:
#
# - Due to the exponential bonus from chains, getting high scores will require
#   maximizing the number of consecutive chains.
#
# - Snake game is hard enough as it is, and players who try to maximize
#   consecutive chains might not survive very long.  Those high-scoring
#   short-lived snakes will probably only cover a small portion of the grid.
#
# In other words, getting high scores and high coverage appears to be
# conflicting goals, which is a shame since I would like to reward both
# styles of play.  So, I settled on the heuristic where higher grade is
# rewarded on either high score *or* high coverage.

# a = maximum possible area.
a = H - 2
a *= W - 2

# g = grade.  Default rating is "Dot eater", used when the player did not
#     complete any chains.
#
# Getting a high score while maintaining "Dot eater" is actually the hardest
# way to play this game because it requires changing player colors very often.
# Also, due to the items being fixed during endgame, it would be very
# difficult to attain "dot eater" rating with a high coverage.
g = "Dot eater"

if l > 0
   # Player has made at least one chain (l>0), and deserves a C/B/A/S grade.

   # i = maximum number of items possible.
   #
   # Since the snake length is proportional to double the number of items
   # eaten, it seems that maximum area (a) divided by 2 would be a
   # reasonable estimate for maximum number of items.  This is only an
   # estimate, because the number of items generated for each item eaten is
   # not always one.
   i = a / 2

   # Check the four levels of achievements to see where the player is at.
   4.times{|w|
      # Move the player grade up one level depending on threshold:
      #
      # C: -10% area, or eating all items with no chains.
      # B: 20% area, or eating all items with 1-chain bonus on average.
      # A: 50% area, or eating all items with 4-chain bonus on average.
      # S: 80% area, or eating all items with 7-chain bonus on average.
      #
      # The first threshold with negative area means players will always get
      # a "C" grade at a minimum, if they completed at least one chain.
      if h.size > a * (w * 0.3 - 0.1) ||
         s > i * 10 + i / 3 * 100 * 2 ** (w * 3 - 2)
         g = "CBAS"[w]
      end
   }
end

# Output the final stats: area, score, max chain, grade.
#
# It's similar to Ikaruga's stats at the end of each chapter, except we have
# "area" instead of "boss destroy bonus".  Area is of interest to me because
# I needed it to debug the grading system, but it seems like a good stat to
# keep because it tells them how much progress they would have made if this
# was a classical snake game.
#
# Other stats I could have tracked include how many chains were made total
# (in addition to the longest chain achieved), and also how long the player
# has played.  But I figured I will keep the stats minimal like Ikaruga, and
# save me a few bytes.
#
# The one feature I honestly would like to implement is a replay mode, but
# that would require keeping track of all generated item positions.  Also,
# making the recorded data playable across different terminal sizes would be
# nontrivial.  It would have been easier if this game required a particular
# terminal size, but that wouldn't be as fun.
print "\e[0m\e[?25h\nArea: \e[1m#{h.size * 100 / a}%\e[0m\nScore: \e[1m#{s}\e[0m\nMax: \e[1m#{l} chain\e[0m\nGrade: \e[1m#{g}\e[0m\n"

# Restore terminal echo.
STDIN.echo = true
