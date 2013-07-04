#!/usr/bin/env ruby

require "parallel"

DICT_FILE = "short-dict.txt"
DEFAULT_NUM_PROCS = 7

module Cdoherty

  # a vertex is any object, but happens to be strings for us.
  class Graph
    def initialize
      @adj_list = {}
    end

    def add(v1, v2)
      @adj_list[v1] ||= []

      v2 = [v2] unless v2.class == Array
      @adj_list[v1] |= v2    # pipe (|) on arrays performs a set union, to eliminate duplicates.
    end

    def neighbors(v1)
      @adj_list[v1] || []
    end

    def edges
      @adj_list
    end

    def find_path(start, target, opts={})
      return_all_paths = !!opts[:return_all_paths]   # !! is an idiom to convert values to boolean.

      discovered = Hash.new(false)
      processed = Hash.new(false)

      parents = {}
      q = []
      v_current = start
      q.push(v_current)
      discovered[v_current] = true
      parents = {}

      while q.size > 0
        v_current = q.shift
        puts "about to visit '#{v_current}'"
        processed[v_current] = true
        self.neighbors(v_current).each do |neighbor|

          puts "processing node #{neighbor}" unless !processed[neighbor]

          if !discovered[neighbor]
            q.push(neighbor)
            discovered[neighbor] = true
            parents[neighbor] = v_current
          end
        end
        puts "done processing node '#{v_current}'"
      end

      return parents
    end
  end

  class GraphBuilder

    attr_accessor :raw, :words

    def initialize
      load_dict
    end

    # generate the full dict at any time with `egrep -e '^[a-z]{5}$' /usr/share/dict/words`.
    def load_dict
      @raw = File.read(DICT_FILE)
      @words = raw.split("\n").map { |word| word.strip }.reject { |word| word.nil? || word.length == 0 }
      return @raw, @words
    end

    def valid_transition?(s1, s2)
      diffs = 0
      s1.length.times do |i|
        if s1[i] != s2[i]
          diffs += 1
          return false if diffs > 1
        end
      end
      return diffs == 1
    end

    def find_transitions(word)
      transitions = []
      @words.each do |dict_word|
        if valid_transition?(word, dict_word)
          transitions << dict_word
        end
      end
      return transitions.reject { |w| w == word }.sort
    end

    def generate_graph(parallel=false)
      graph = Graph.new

      nprocs = parallel ? DEFAULT_NUM_PROCS : 0

      # the parallel gem maintains the order of the results...
      words_transitions =
        Parallel.map(@words, :in_processes => nprocs) do |word|
        find_transitions(word)
      end
      # ...so we can just iterate over the input array and it's the same index.
      @words.each_with_index do |word, i|
        words_transitions[i].each do |transition|
          graph.add(word, transition)
        end
      end
      return graph
    end
  end
end

start = "smart"
FINAL = "brain"
