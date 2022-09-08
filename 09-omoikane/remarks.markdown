### Ikaruga Snake

This is a snake game, with scoring rules from Ikaruga.

### Usage

Runs without arguments:

    ruby entry.rb

Use arrow keys or WSAD keys to change direction, most other keys will change snake color.  Running into an item that matches the current snake color will eat the item and score some points.  Running into the wall or an item of the opposite color ends the game.

This game prevents most suicide attempts by disallowing the snake to turn into itself or into the wall.  For example, if you were going right, trying to go left results in the action being ignored.  But note that attempts to turn into items of opposite color are not blocked (and would result in instant death).

Snake moves ~5 units every second by default, but you can make it run faster or slower by specifying an extra argument between 0.1 (very slow) and 50 (very fast and unplayable).  For example, to have an extremely laid back game that pauses ~10 seconds between moves, try:

    ruby entry.rb 0.1

Hint: press forward direction to move forward immediately, without having to wait.


### Scoring

* Eating items will earn 10 points each.
* Eating 3 consecutive items of the same color forms a chain, which comes with 100 points bonus.
* The chain bonus is doubled for every unbroken chain up 9 (25600 points).
* The grade assigned at the end of each game is based on either score or area coverage.


### Compatibility

Verified to work with these versions of Ruby:

* ruby 2.1.5p273 (2014-11-13) [x86_64-linux-gnu]
* ruby 2.5.1p57 (2018-03-29 revision 63029) [i386-linux-gnu]
* ruby 2.6.4p104 (2019-08-28 revision 67798) [x86_64-cygwin]
* ruby 3.0.3p157 (2021-11-24 revision 3fb7d2cadc) [x86_64-linux-gnu]
* ruby 3.0.4p208 (2022-04-12 revision 3fa771dded) [x86_64-linux-gnu]

Requires "io/console" and "zlib".

I recommend playing in some variant of `xterm`, although most terminals seem to run this game just fine, including Windows `cmd.exe`.  The only exception appears to be the Linux system console where I get all sorts of color artifacts (only recommended for people who like glitchy games).
