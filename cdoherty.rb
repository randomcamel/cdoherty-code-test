#!/usr/bin/env ruby

DICT_FILE = "short-dict.txt"

# generate the full dict at any time with `egrep -e '^.{5}$' /usr/share/dict/words`.
def load_dict
  File.read(DICT_FILE).split("\n").map { |word| word.strip }.reject { |word| word.nil? || word.length == 0 }
end

words = load_dict

words.each do |w|
  puts w
  puts "----"
end
