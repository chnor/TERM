
require './porter.rb'
require 'rubygems'
require 'rexml/document'
require '../google_ngram/lookup.rb'

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

# posses = {}
# for foreground, ds in data.chunk {|d| d[3] != "O" }
# 	next unless foreground
# 	poss = ds.map {|d| d[4] }
# 	STDERR.puts "#{poss.join " "}: #{ds.map(&:first).join(" ")}"
# 	posses[poss] = 0 unless posses.include? poss
# 	posses[poss] += 1
# end
# total = posses.values.inject 0, :+
# STDERR.puts 
# cumsum = 0
# for poss, count in posses.sort_by {|k, v| -v }
# 	cumsum += 100 * count.to_f/total
# 	break if cumsum > 99
# 	break if 100 * count.to_f/total < 0.5
# 	STDERR.puts "\t#{poss.join(" ")} & #{(100 * count.to_f/total).round(1)} \\\% \\"
# end
# STDERR.puts cumsum

# exit

Dir.chdir(File.dirname(__FILE__)) do
	# tf 		= {}
	File.open("cooc_file_in", "w") do |f|
		for w, prev_w, file_no, filename, label, tag, lemma in data
			# unless tf.include? [file_no, w.to_index]
			# 	tf[[file_no, w.to_index]] = 0
			# end
			# tf[[file_no, w.to_index]] += 1
			f.write "#{prev_w.downcase.to_index} "
			f.write "#{w.downcase.to_index} "
			f.write "#{[prev_w, w].join(" ").downcase.to_index} "
			f.write "#{file_no.to_i} "
			f.write "\n"
		end
	end
	# for k, v in tf
	# 	STDERR.puts "tf(#{k}) = #{v}"
	# end

	STDERR.puts "Extracting mutual information and tf-idf..."
	STDERR.puts `matlab nosplash -nodesktop -minimize -wait -r "extract_mi_tf_idf('cooc_file_in', 'cooc_file_mi', 'cooc_file_tf_idf'); quit;"`
	STDERR.puts "Done."

	mi 		= {}
	mi.default = 0
	tf_idf 	= {}
	tf_idf.default = 0
	for line in open 'cooc_file_mi'
		prev_w, w, c = *line.split
		# STDERR.puts "I(#{prev_w.to_i}, #{w.to_i}) = #{c}"
		mi[[prev_w.to_i, w.to_i]] = c
	end
	for line in open 'cooc_file_tf_idf'
		file_no, w, c = *line.split
		# STDERR.puts "tf-idf(#{file_no.to_i}, #{w.to_i}) = #{c}"
		tf_idf[[file_no.to_i, w.to_i]] = c
	end

	for d_i in data
		w 		   = d_i[0]
		prev_w 	   = d_i[1]
		file_no    = d_i[2]
		bigram 	   = [prev_w, w].join(" ")
		mi_i 	   = mi[[prev_w.downcase.to_index, w.downcase.to_index]]
		tf_idf_1_i = tf_idf[[file_no.to_i, w.downcase.to_index]]
		tf_idf_2_i = tf_idf[[file_no.to_i, bigram.downcase.to_index]]

		d_i << mi_i
		d_i << tf_idf_1_i
		d_i << tf_idf_2_i

		# STDERR.puts d_i.join ", "
	end
end

STDERR.puts "Extracting timelines"
timelines = {}
unigrams = data.map(&:first).uniq.sort
bigrams  = data.map {|c| "#{c[1]} #{c[0]}" }.uniq.sort
for term in unigrams
	timelines[term.downcase] = vectorize (find_all term), 1800..2008
	# timelines[term.downcase] = vectorize ({}), 1800..2008
end
for term in bigrams
	timelines[term.downcase] = vectorize (find_all term), 1800..2008
	# timelines[term.downcase] = vectorize ({}), 1800..2008
end
STDERR.puts "Done"

unigram_timelines = []
bigram_timelines  = []
for p in data
	w 	= p[0]
	p_w = p[1]
	unigram_timeline = timelines[w.downcase]
	bigram_timeline  = timelines["#{p_w} #{w}".downcase]
	unigram_timelines << unigram_timeline
	bigram_timelines  << bigram_timeline
end

STDERR.puts "Extracting features from timelines"
unigram_features = []
bigram_features  = []
Dir.chdir('../google_ngram') do
	File.open("timelines_temp_file_in", "w") do |f|
		for t in unigram_timelines
			f.write "#{t.join " "}\n"
		end
		for t in bigram_timelines
			f.write "#{t.join " "}\n"
		end
	end

	STDERR.puts "Extracting features from timelines..."
	STDERR.puts `matlab nosplash -nodesktop -minimize -wait -r "extract_continuous_features_1('timelines_temp_file_in', 'timelines_temp_file'); quit;"`
	STDERR.puts "Done."
	
	c = -1
	for line in open("timelines_temp_file")
		c += 1
		features = line.split
		if c < data.size
			unigram_features << features
		else
			bigram_features << features
		end
	end
end
STDERR.puts "Done"

raise "Features not of equal size" unless unigram_features.size == bigram_features.size

STDERR.puts "Outputting"

data = data.zip(unigram_features, bigram_features).map &:flatten
for p in data
	puts p.join ", "
	# A CRFSuite chunking bug ignores all input until we
	# output a blank line.
	puts if p[6] == "." # Blank line after each sentence
end
puts

STDERR.puts "Done"
