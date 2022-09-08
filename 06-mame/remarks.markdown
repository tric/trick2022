### Remarks

This is a Quine-like program that contains a globe.
You can rotate the globe 45 degrees by running it normally.

```
$ ruby entry.rb
```

The output is a valid ruby program that has the same behavior as the original one.
Thus, you can see the globe rotated 90 degrees by the following command.

```
$ ruby entry.rb | ruby
```

You will see the orignal program by applying `ruby` eight times in total.

```
$ ruby entry.rb | ruby | ruby | ruby | ruby | ruby | ruby | ruby
```

(If you know Yusuke Endoh's [qlobe](http://mamememo.blogspot.com/2010/09/qlobe.html), you may think it is the same, but please read to the end!)

### Advanced usage

You can specify the rotation angle by using a command-line argument.
For example, this example below will rotate the globe 10 degrees.

```
$ ruby entry.rb 10
```

You may want to use this feature to see an animation of the globe rotating.

```
$ for i in `seq 5 5 360`; do ruby entry.rb $i; done
```

This command allows you to enjoy the animation with less flickering.

```
$ clear; for i in `seq 5 5 360`; do tput cup 0 0; ruby entry.rb $i; done
```

### Internal

This program contains the globe data as a set of spherical polygons whose vertexes have latitude and longitude, and dynamically renders it as a globe by using spherical trigonometry.
The polygon data is encoded with only 286 printable characters by using [Exp-Golomb coding](https://en.wikipedia.org/wiki/Exponential-Golomb_coding).
You can decode the data and see the world map with lat/lon projection by passing zero, or non-Integer argument:

```
$ ruby entry.rb dump
```

If the output is too large, you can specify the line count via the second command-line argument.

```
$ ruby entry.rb dump 24
```

This will output the world map with 24 lines whose each line has 96 (= 24 x 4) characters.

### One more thing

Try this and look around San Francisco, on the west coast of the United States.
You will see an `X` mark,

```
$ ruby entry.rb dump 40 38 -122
```

The thrid and fourth arguments represent latitude and longitude to put the mark in the world map.
`38 -122` means 38N and 122W.

Here are some other examples you may want to try:

* New York: `ruby entry.rb dump 40 41 -74`
* Los Angels: `ruby entry.rb dump 40 34 -118`
* London: `ruby entry.rb dump 40 52 0`
* Paris: `ruby entry.rb dump 40 45 2`
* Moscow: `ruby entry.rb dump 40 56 38`
* Rio de Janeiro: `ruby entry.rb dump 40 -23 -43`
* Sydney: `ruby entry.rb dump 40 -34 151`
* Tokyo: `ruby entry.rb dump 40 36 140`

### Credits

* This program is a tribute to [Qlobe](http://mamememo.blogspot.com/2010/09/qlobe.html), which was created by Yusuke Endoh. Qlobe contains a simple raster map, and uses zlib to compress the data. In contrast, our program uses vector map data, which allows to tilt rotation axis 23.4 degrees as the earth. Also, it implements a dedicated compression algorithm based on Exp-Golomb coding, and two dynamic renderers for the globe and lat/lon projection world map.
* The globe data is based on the [1:110m coastline data](https://www.naturalearthdata.com/downloads/110m-physical-vectors/110m-coastline/) of [Natural Earth](https://en.wikipedia.org/wiki/Natural_Earth), which is public domain.
* The feature to put a mark is inspired by [a winning entry of IOCCC 1992](https://github.com/ioccc-src/winner/blob/master/1992/westley.c).
