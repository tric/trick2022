
  Animating Quine with Braille symbols

# how to run

    ruby entry.rb

tested with
ruby 3.1.2p20 (2022-04-12 revision 4491bb740a) [x86_64-darwin19]

And also

    ruby entry.rb | ruby

will do the same thing.

## how to make Braille symbols runnable as Ruby

1. Define `method_missing` on Symbol.

1. The first line starts with `:`. So this is a symbol literal.
   `:` looks very good with Braille symbols.

1. End the line with `.` (which also looks like a Braille symbol BTW.)
   Then the next line is considered as a method call and almost everything
   is valid because of `method_missing`.

1. The problem is that how to detect the end of the program i.e. this is
   the last line or there are more lines left.

   This time I used `⠠`. This looks so close to `.` but actually U+2820!

   U+2820 is a Braille symbol and corresponds to `@` in this program's
   encoding system. It is safe to use it as the end mark because I wrote
   the program without using `@` (it's easy, just don't use instance vars.)

1. In `method_missing` we should return a symbol so that we can do method
   chaining. It returns a symbol

      :"#{self}#{n}"
     
   which is the concatenation of `self` and `n` (wish there is Symbol#+.)

   So there are no global variables to accumlate the lines. Isn't it beautiful? :-)

1. Finally split the whole text into codepoints by `String#unpack` and
   decode it. Encoding algorithm is simple; just convert each ascii code
   to a binary number and then a Braille symbol. (Unicode supports both
   6-points and 8-points Braille system so a Braille can hold 8 bits
   at most.)

## how to make it a quine

The encoded Braille symbols expand into a Ruby program ending with this line.
 
    run :

This is not a valid program - but before eval'ing it, the Braille symbols
are appended to this. Thus this will execute the method `run` with a symbol
with long name as an argument. Then it is easy to make it a quine because
the most important data is passed to `run`.

However this program uses ANSI escape sequences for animation. To make the
output a valid Ruby program, this program uses `%%` and `%;;;`. (This
technique is described in the book 『あなたが知らない超絶技巧プログラミング
の世界』)

    %%
    (animation part)
    %;;; (main program)

1. `%%...%` is just a String literal like `%{...}`.
1. `%;;; (main program)` is also valid because `%;;;` is again a String literal.

## animation

Choose a random point and show it.

- Number of points shown in a tick (0.01sec) accellarates. (n*=dn)

- `ms` and `cr` are two dimentional array. Most of the items are 0 or 1,
  but some are a String to handle non-Brailles (i.e. ":" and "."). 

- I used `Kernel#print` to render the characters one by one. You could make
  a long string and print it at once; it looks much cleaner then, but this
  time I'd like to let the cursors sparkle in the terminal.

## pitfalls

- Note that you cannot use `⠠`(U+2820) directly in the encoded program. It must
  not include non-ascii characters.

  In contrast, the header part may be non-ascii.

- Speaking of the compression ratio, this naive encoding algorithm is not
  the best. I needed a bit of code-golfing to follow the bytesize limit rule.

- The bits of a codepoint of a 8-point Braille are ordered this way,

    0 3
    1 4
    2 5
    6 7

  not this. Be careful (maybe it's for compatibility to the 6-point system.)

    0 4
    1 5
    2 6
    3 7

