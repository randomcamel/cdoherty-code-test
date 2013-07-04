#!/usr/bin/env ruby

require "parallel"

DICT_FILE = "medium-dict.txt"
DEFAULT_NUM_PROCS = 8

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

    def bfs(start, target)
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

    def generate_graph
      graph = Graph.new
      @words.each do |word|
        transitions = find_transitions(word)
        transitions.each do |neighbor|
          graph.add(word, neighbor)
        end
      end
      return graph
    end
  end
end

start = "smart"
FINAL = "brain"
