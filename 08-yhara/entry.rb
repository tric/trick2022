module Kumimoji
  class UnitMismatch < StandardError; end

  class Value
    def initialize(amount, unit)
      @amount, @unit = Rational(amount), unit
    end
    attr_reader :amount, :unit

    def ==(other)
      @amount == other.amount && @unit == other.unit
    end

    %i(+ -).each do |o|
      define_method o do |other|
        raise UnitMismatch if other.unit != @unit
        Value.new(@amount.send(o, other.amount), @unit)
      end
    end

    %i(* /).each do |o|
      define_method o do |other|
        case other
        when Value
          raise UnitMismatch if other.unit != @unit
          @amount.send(o, other.amount)
        when Numeric
          Value.new(@amount.send(o, other))
        else
          raise TypeError, "invalid arg for #{o}: #{other.inspect}"
        end
      end
    end

    def to_s
      "#{@amount.to_f}#{@unit}"
    end

    def inspect
      "#<Kumimoji::Value #{@amount} #{@unit}>"
    end
  end

  refine Numeric do
    %w(㌰ -12 ㌨ -9 ㍃ -6 ㍉ -3 ㌢ -2 _ 0 ㌥ 1 ㌔ 3 ㍋ 6 ㌐ 9).each_slice(2) do |m, s|
      %w(㍍ ㌘ ㌃ ㍑ ㍗).each do |u|
        define_method "#{m if m != '_'}#{u}" do
          Value.new((10r ** s.to_i) * self, u)
        end
      end
    end
    
    %w(
      1 ㌅ = 2.54 ㌢㍍
      1 ㌳ = 30.48 ㌢㍍
      1 ㍎ = 0.9144 ㍍
      1 ㍄ = 1609.344 ㍍
      1 ㍀ = 453.6 ㌘
      1 ㌎ = 3.785_412 ㍑
      1 ㌴ = 35.239_070_166_88 ㍑
      1 ㌭ = 158.987_294_928 ㍑
      1 ㌶ = 100 ㌃
      1 ㌧ = 1000 ㌔㌘
      1 ㍌ = 1_000_000 ㌧
      1 ㌋ = 1852 ㍍
    ).each_slice(5) do |_, name, _, amount, unit|
      define_method name do
        amount.to_r.send(unit)
      end
    end

    alias ㌖ ㌔㍍
    alias ㌕ ㌔㌘
    alias ㌗ ㌔㍗
    alias ㍈ ㍃㍍ 
    alias ㍏ ㍎ 
  end
end
using Kumimoji

a = 1.㌢㍍
b = 10.㍉㍍

p a == b
puts "a + b = #{a + b}"
puts

a = 1.㌋
b = 1.㍄
printf "1㌋ ≒ %f㍄\n", a/b
puts

%w(㌅ ㌳ ㍎ ㍄).each_cons(2) do |x, y|
  puts "1#{y} is #{1.send(y) / 1.send(x)}#{x}"
end
