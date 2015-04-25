
require './porter.rb'
require 'rubygems'
require 'rexml/document'
require './google_ngram/lookup.rb'

$stdout.sync = true

class String
	include Stemmable
end

def word_to_index w
	$lookup = {} unless $lookup
	unless $lookup.include? w
		$lookup[w] = $lookup.size + 1
	end
	return $lookup[w]
end

class String
	def to_index
		return word_to_index self
	end
end

data = []
for line in ARGF
	data << line.strip.split(", ")
	# STDERR.puts data.last.join " "
end

data = data.zip(unigram_features, bigram_features).map &:flatten
puts "@relation terms"
puts ""
puts "@attribute w string"
# puts "@attribute prev string"
# puts "@attribute file_no numeric"
puts "@attribute label {B, I, O}"
puts "@attribute POS string"
puts "@attribute lemma string"
puts "@attribute mi numeric"
puts "@attribute tf_idf_1_i numeric"
puts "@attribute tf_idf_2_i numeric"
puts ""
puts "@attribute unigram_mean numeric"
puts "@attribute unigram_std numeric"
puts "@attribute unigram_skew numeric"
puts "@attribute bigram_mean numeric"
puts "@attribute bigram_std numeric"
puts "@attribute bigram_skew numeric"
puts ""
puts "@data"

# Dummy data point for the point past the end of the document
data << [nil, nil, nil, "O"]
data.each_cons(1 + 1) do |a_1|

	a = a_1[0..-2]

	w 		= a.map {|p| p[0]}.join " "
	label 	= a.map {|p| p[3]}
	if label[0] == "B" and label[1..-1].all? {|l| l == "I"} and a_1[-1] != "I"
		label = "I"
	else
		label = "O"
	end
	POS 	= a.map {|p| p[4]}.join " "
	lemma 	= a.map {|p| p[5]}.join " "
	mi  	= a.map {|p| p[6]}.first
	tf_idf1 = a.map {|p| p[7]}.first
	tf_idf2	= a.map {|p| p[8]}.first

	mu_1 	= a.map {|p| p[9]}.first
	sigma_1 = a.map {|p| p[10]}.first
	gamma_1	= a.map {|p| p[11]}.first

	mu_2 	= a.map {|p| p[12]}.first
	sigma_2 = a.map {|p| p[13]}.first
	gamma_2	= a.map {|p| p[14]}.first

	p = []
	p << w
	p << label
	p << POS
	p << lemma
	p << mi
	p << tf_idf1
	p << tf_idf2
	p << mu_1
	p << sigma_1
	p << gamma_1
	p << mu_2
	p << sigma_2
	p << gamma_2

	puts p.join ", "
end

STDERR.puts "Done"
