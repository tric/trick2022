# TRICK 2022 (Returns)

The 4th (Returns) Transcendental Ruby Imbroglio Contest for rubyKaigi

## Winners

* Top 3
  * Gold: "Best fishbowl" -- Tomoya Ishida (tompng)
  * Silver: "Most interactive code" -- Tomoya Ishida (tompng)
  * Bronze: "Most anti-gravity" -- Yusuke Endoh

* Judges' awards
  * shinh award: "Most orderly code" -- Tomoya Ishida
  * leonid award: "Most accessible" -- Yutaka HARA
  * eto award: "Most global" -- Yusuke Endoh
  * matz award: "Most reactive and diffusive" -- Sergey Kruk
  * fragitious award: "Most likely to be required" -- Yutaka HARA
  * yhara award: "Most playable" – Don Yang
  * mame award: "Most calculating" -- SAITOH Jinroq

## Goals of the TRICK

* To write the most Transcendental, Imbroglio Ruby program.
* To illustrate some of the subtleties (and design issues) of Ruby.
* To show the robustness and portability of Ruby interpreters.
* To stabilize the spec of Ruby by the presence of valuable but unmaintainable code.

## Rules

These rules are tentative.

1. Your entry must be a complete Ruby program.
1. The size of your program must be <= 4096 bytes in length. The number of non-space characters must be <= 2048. The total size of your compressed submission must be less than ten megabyte in size.
1. You can submit multiple entries, and your team may consist of any number of members.
1. The entirety of your entry must be submitted under [MIT License](http://opensource.org/licenses/MIT).
1. Your entry must bring the judges a surprise, excitement, and/or laughter.

## Guidelines

These are not strict rules but hints or suggestions. You can ignore them but we'd recommend you to follow them.

* Matz Ruby Implementation (MRI) 3.1 is recommended.
* You can use implementations other than MRI, such as JRuby and Rubinius.
* The judges would prefer more stoic, more portable, and/or more funny entries.
* You are encouraged to study the winners of [previous TRICK contests](https://github.com/tric/).
* You can use a gem library.
  * Note that we will expect such entries to be much more interesting than an entry that uses no library; hence we will judge them strictly.
  * It is highly discouraged to abuse gem to get around the size limit.
* To judge without bias, we will try to keep each entry anonymous during judgment. Do not include anything that reveal your identity (such as a signature, copyright, URL, etc.) in your program.

## How to submit

* Your submission must consist of the following files:
  * `entry.rb` (program source)
  * `remarks.markdown`
  * `authors.markdown`
  * `Gemfile`, `Gemfile.lock` (if you use any gem library)
  * data files (if needed)
* `remarks.markdown` must include the following information:
  * Ruby implementation, version, platform that you use (it is a good idea to copy and paste the output of `ruby -v`)
  * How to run
* `authors.markdown` must include the following information (and the `remarks.markdown` must NOT have them):
  * Your name (handle is ok)
  * ccTLD of your country/region
* Compress your entry as a zip file called `entry.zip` and send it to `trick.submit at gmail.com` as an attachment.
  * You must include the words `TRICK 2022 submission` in the subject of your email.
  * See [an example of `entry.zip`](entry.zip).

If you have any question, please send a mail to `trick-judges at googlegroups.com`.

## Important Dates

* 9th Sep. 2021: Contest open
* 31st Jul. 2022: Submission deadline *Now closed*. We have been sent a receipt email to every applicant. If you do not receive a receipt email, please let me know (`trick.submit at gmail.com` or [@mametter][mametter]).
* 8th Sep. 2022: Result announcement (at RubyKaigi 2022)

## Judges

Alphabetical order.

* Yusuke Endoh ([@mametter][mametter]. Ruby committer. [The world's No.1 IOCCC player][ioccc_endoh].)
* Koichiro Eto ([@eto][eto]. Media Artist. [Chairman at NicoNicoGakkai Beta][niconicogakkai].)
* Shinichiro Hamaji ([@shinh][shinh]. [The admin of anarchy golf][golf]. [IOCCC winner][ioccc_shinh].)
* Yutaka Hara ([@yhara][yhara]. [The author of Japanese esolang book][esolangbook].)
* Yukihiro Matsumoto (a.k.a. matz. [@yukihiro_matz][yukihiro_matz]. The creator of Ruby.)
* Sun Park (a.k.a. leonid. [The 1st super Ruby golfer][golfers].)
* Darren Smith (a.k.a. flagitious. [The author of some esolangs including GolfScript][golfscript].)

[mametter]: https://twitter.com/mametter
[eto]: https://twitter.com/eto
[shinh]: https://twitter.com/shinh
[yhara]: https://twitter.com/yhara
[yukihiro_matz]: https://twitter.com/yukihiro_matz
[ioccc_endoh]: http://www.ioccc.org/winners.html#Yusuke_Endoh
[ioccc_shinh]: http://www.ioccc.org/winners.html#Shinichiro_Hamaji
[niconicogakkai]: http://niconicogakkai.jp/
[golf]: http://golf.shinh.org/
[esolangbook]: http://esolang-book.route477.net/
[golfers]: http://golf.shinh.org/u.rb?rb
[golfscript]: http://www.golfscript.com/

## Legal

This work is licensed under the MIT License.

    Copyright (c) 2022, TRICK Winners and Judges.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
