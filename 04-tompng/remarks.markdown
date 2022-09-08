### Remarks

Just run it with no argument:

    ruby entry.rb

Or run it with 1 or 2 integer arguments:

    ruby entry.rb 90
    ruby entry.rb 110 40

ARGV[0]: rule number of cellular automaton. default: 30
ARGV[1]: output lines. default: 32

I confirmed the following implementations/platforms:

* ruby 3.0.0p0 (2020-12-25 revision 95aff21468) [x86_64-darwin19]
* ruby 3.1.0p0 (2021-12-25 revision fb4df44d16) [x86_64-darwin20]

### Description

This program displays an image of elementary cellular automaton.
By using a local variable trick, this code can be parsed in 5 different ways.

### Internals

Parsing Ruby is difficult.
In the sample code below, `some_method /a#/` is interpreted as method call `some_method(regexp)` and `local_var /a#/` is interpreted as division `local_var / a`.

```ruby
some_method /a#/ # method call
local_var = 1
local_var /a#/ # division

# With regexp named capture

foo /a/i #=> method call
/(?<foo>)/ =~ ''
foo /a/i #=> division

bar /a/i if /(?<bar>)/ =~ '' #=> method call
/(?<baz>)/ =~ '' if baz /a/i #=> division

# More unreadable cases used in this entry

a /%{(?<a>)/ =~ %} if + %} - %[ #}#] #=> a(/regexp(?<a>)/ =~ (%}string}) - (%[string]))
a /%{(?<a>)/ =~ %} if + %} - %[ #}#] #=> a / %{string} if +(%}string})

c /%+(?<c>)/ =~ %+ if + %+ - %< #+#> #=> c(/regexp(?<c>)/ =~ (%+string+) % (+(-(%<string>))))
c /%+(?<c>)/ =~ %+ if + %+ - %< #+#> #=> c / %+string+ if +(%+string+)
```

This program uses `eval(File.read(__FILE__))` instead of a normal loop.
In the first four step of the eval loop, this program defines a new local variable and `eval` will parse this code differently in the next step.

```ruby
# First step
['if' % TRICK - 2022 % "%]\n#"] \
if a(/regexp_that_defines_a/ =~ %}string} - %[string]) \
if a / %{string} \
if code_on_line_12
eval(File.read f ||= __FILE__)

# Second step
['if' % TRICK - 2022 % "%]\n#"] \
if a / %{string} if +(%}string}) \
if b(/regexp_that_defines_b/ =~ %>string> + %{string}) \
if b / %<string> \
if code_on_line_11 && eval(File.read f ||= __FILE__)

# Third step
['if' % TRICK - 2022 % "%]\n#"] \
if a / %{string} if +(%}string}) \
if b / %<string> if -(%>string>) \
if c(/regexp_that_defines_c/ =~ %+string+ % (+(-(%<string>)))) \
if c / %+string+ \
if code_on_line_10
eval(File.read f ||= __FILE__)

# Fourth step
['if' % TRICK - 2022 % "%]\n#"] \
if a / %{string} if +(%}string}) \
if b / %<string> if -(%>string>) \
if c / %+string+ if +(%+string+) \
if d(/regexp_that_defines_d/ =~ %-string- % (-(+(%+string+)))) \
if d / %-string- \
if code_on_line_9
eval(File.read f ||= __FILE__)

# Fifth step
['if' % TRICK - 2022 % "%]\n#"] \
if a / %{string} if +(%}string}) \
if b / %<string> if -(%>string>) \
if c / %+string+ if +(%+string+) \
if d / %-string- if -(%-string-) \
if e f, g, h, /regexp/ if def e(f, g, h, *) = eval(File.read f ||= __FILE__)
```

In the fifth step, eval is executed inside method `e`, a clean environment just like in the first step, that local variables `a, b, c, d` are not defined.
