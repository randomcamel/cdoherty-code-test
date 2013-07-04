## Chris Doherty's coding problem.

As presented:

-------

    Given two five letter words, A and B, and a dictionary of five letter words, find a
    shortest transformation from A to B, such that only one letter can be changed at a
    time and all intermediate words in the transformation must exist in the dictionary.


    Your implementation should take advantage of multiple CPU cores. Please also include
    test cases against your algorithm.

------

## To run it, you will need:

- A working Ruby installation, in the 1.9.x range or newer.

- The `parallel` gem, available by typing `sudo gem install parallel`.

- The `scope` gem.


## Why do I need to install a gem?

Like its kindred Perl and Python, Ruby has a global interpreter lock which means that Ruby
threads are interpreter-scheduled ("green") threads, entirely invisible to the operating
system. You can spawn as many Ruby threads as you like, and you'll only be using a single
CPU. (Threads in the JRuby interpreter are CPU-scheduled JVM threads, but requiring that
you use a specific Ruby implementation seemed a bit much.) You can see this in action, if you change
the GraphBuilder's `:in_processes` parameter to Parallel to `:in_threads`, then run the
script again.

This means that to go multi-core in Ruby, you have to spawn multiple Unix
processes. Coordinating work between Unix processes is:

a. Intricate.

b. Prone to bugs even when you know what you're doing.

c. Not something I've done a lot of.

The `parallel` gem abstracts that work away, and you can read more about it
[here](https://github.com/grosser/parallel).

`scope` is the unit testing framework we use at work.

## Okay, gem's installed. How do I run this?

- You can run `rake test` to run the tests.

- Simply execute `./cdoherty.rb` for a usage message.

- There are three dictionaries, named appropriately. The full list was pulled with the
   command `egrep -e '^[a-z]{5}$' /usr/share/dict/words`.

- Ruby is unfortunately very environment-dependent. If you'd like help running it, please
  let me know. I tried running it in a Vagrant VM and was defeated by the Ruby-Ubuntu
  intersections.

Chris Doherty
chris [at] randomcamel.net

