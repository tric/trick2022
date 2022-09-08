rule = $*[00]&.to_i || 30
h  ||= $*[01]&.to_i || 32
[ % if % TRICK-2022 %% %]
# ] if a /%{(?<a>)/ =~ %} if + %} - %[
# } if b /%<(?<b>)/ =~ %> if - %> + %{
# > if c /%+(?<c>)/ =~ %+ if + %+ - %<
# + if d /%-(?<d>)/ =~ %- if - %- + %+
# - if e f, g, h, / =~ %/ if def e(f, g, h, *) =
# + if d /%-(?<d>)/ =~ %- if g.map! do rule.[] _1.join.to_i 2 end.!
# > if c /%+(?<c>)/ =~ %+ if !(g = *[g[-1], *g, g[0]].each_cons(3))
# } if b /%<(?<b>)/ =~ %> if puts(g.join.tr '01', ' #') || h > 0 &&
# ] if a /%{(?<a>)/ =~ %} if !g ||= [*g = [0] * h, 1] + g if h -= 1
eval(File.read f ||= __FILE__)
