# Kumimoji

This program demonstrates Ruby's flexibility in an idiomatic code.

### Remarks

Just run it with no argument:

    ruby entry.rb

I confirmed the following implementations/platforms:

- ruby 3.0.2p107 (2021-07-07 revision 0db68f0233) [x86_64-darwin19]

You need a terminal which can display kumimoji characters.

### Description

This tiny library provides a DSL somewhat like `100.days` of ActiveSupport but instead of
english words it uses Japanese "組み文字(kumimoji)" of Unicode.
https://en.wiktionary.org/wiki/%E3%81%8F%E3%81%BF%E3%82%82%E3%81%98#Japanese

Examples:
    
    p 1.㌢㍍ == 10.㍉㍍

Prints `true` because 1 senti-meter equals 10 milli-meters.

    puts 1.㌢㍍ + 10.㍉㍍

Prints `0.02㍍` (= 0.02 meters).

It also supports units used in U.S. - as far as it is in Unicode.

    p (1.㌅ / 1.㌢㍍).to_f

Prints 2.54 because 1 inch is 2.54 centi-meters.

### Appeal points

- I didn't obfuscate the logic to show that you can still do something interesting
  without any obfuscation.

- The extension is defined as a refinement. You can use this library only where
  you want; it does not "pollute" the core classes globally.

- Methods are defined by metaprogramming because there are many combinations of
  prefixes (like "milli", "giga") and units (like "meter", "gram"). After the `refine`
  keyword you see the list of prefixes with powers of 10.

- Values are calculated in Rational rather than Float so that you won't be bothered
  by floating-point errors. Thanks to Ruby's Rational literals, the code to calculate
  a power of 10 in Rational is very concise.

          Value.new((10r ** s.to_i) * self, u)

- There some kumimoji's which are combinations of the prefix and the base unit.
  These are supported by this short and clear code.

    alias ㌖ ㌔㍍

- Methods for US units are defined with another metaprogramming.

    %w(
      1 ㌅ = 2.54 ㌢㍍
      1 ㌳ = 30.48 ㌢㍍
      ...
    ).each_slice(5) do |_, name, _, amount, unit|
      define_method name do
        amount.to_r.send(unit)
      end
    end

  This list reads very clear (if you can read Japanese) thanks to `1` and `=` that
  are not nesessary for conversion. It is also notable that Ruby can convert a String
  into Rational just by calling `#to_r`.

### Internals

The class Kumimoji::Value holds a Rational number and its base unit in String.

You can add two Value's if the base unit are the same.

You can multiply/divide a Value with a number (Value of the same unit returned.)

You can also multiply/divide a Value with other Value if the base unit are the same.
In this case a number is returned instead of a Value.

### Limitation

- As his library refines Numeric, you can call these methods on Complex too, but
  it does not make sense. Should raise error for this case.

- Should support more base units like ㌍ ㍊ ㌹ ㌟ ㍂ ㌂ ㌒ ㌲ ㌾ ㌿ ㍅ ㍕ ㍖ ㌙ ㌩.  

