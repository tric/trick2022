### Remarks

Just run it with no argument:

```
ruby entry.rb
```

I confirmed the following implementations/platforms:

- ruby 3.1.2p20 (2022-04-12 revision 4491bb740a) [x86_64-linux]

### Description

This is a program that does simple output.

```
TRICK2022
```

### Internals

This program consists only of built-in methods, operators, and 0 and 2.
No variables are used.

Also, numbers appear in the order "2 -> 0 -> 2 -> 2 -> ...".
The second argument of Numbered parameters is also included.

### Limitation

You MUST use MRI that supported numbered parameters.
