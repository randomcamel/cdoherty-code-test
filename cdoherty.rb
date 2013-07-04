#!/usr/bin/env ruby

require "parallel"
require "set"

DICT_FILE = "full-dict.txt"
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
      @seen = {}
      load_dict
    end

    # generate the full dict at any time with `egrep -e '^[a-z]{5}$' /usr/share/dict/words`.
    def load_dict
      @raw = File.read(DICT_FILE)
      @words = raw.split("\n").map { |word| word.strip }.reject { |word| word.nil? || word.length == 0 }
      return @raw, @words
    end

    def create_regex(word)
      pieces = []
      for i in 0..word.length - 1 do
        piece = word.clone
        piece[i] = "."
        pieces << piece
      end
      regex = pieces.join "|"
      regex
    end

    def find_transitions(word)
      regex = create_regex(word)

      nexts = []
      @words.each do |word|
        if word =~ /#{regex}/ && !@seen.has_key?(word)
          nexts << word
        end
      end

      # pull out the word itself. easier to do it here than check for it on every iteration.
      nexts = nexts.reject { |w| w == word }.sort
      return nexts
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
