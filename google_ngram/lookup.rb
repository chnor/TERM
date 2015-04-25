
$stdout.sync = true

RANGE_CUT_OFF = 2**10
CACHE_SIZE_LIMIT = 10 * 2**30
# CACHE_SIZE_LIMIT = 1 # Don't keep files open
VERBOSE = true

def load_files
	$files = {} unless $files
	# g_pattern = "downloads/google_ngrams/*/googlebooks-eng-all-*gram-20120701-*_sorted"
	# r_pattern = "downloads/google_ngrams/(1|2)/googlebooks-eng-all-(1|2)gram-20120701-(..?)_sorted"
	g_pattern = "#{File.dirname(__FILE__)}/cache/cache_*_*"
	r_pattern = "#{File.dirname(__FILE__)}/cache/cache_(..?)_(1|2)"
	for f_name in Dir[g_pattern]
		c, n = *Regexp.new(r_pattern).match(f_name)[1..-1]
		n = n.to_i
		$stderr.puts "Found open cache for #{n}-grams (#{c})... " if VERBOSE
		f = open f_name
		f.seek 0, IO::SEEK_SET
		$files[[n, c]] = f
	end
	cache_size = $files.values.map(&:size).inject(0, :+)
	$stderr.puts "Total cache size is #{cache_size / 1048576} MB (#{format("%.2f", 100 * cache_size / CACHE_SIZE_LIMIT)}%)" if VERBOSE
end

def get_file n, c
	c = c.downcase
	$files = {} unless $files
	unless $files.include? [n, c]
		f_name = "#{File.dirname(__FILE__)}/downloads/google_ngrams/#{n}/googlebooks-eng-all-#{n}gram-20120701-#{c}_sorted.gz"
		c_name = "#{File.dirname(__FILE__)}/cache/cache_#{c}_#{n}"
		unless File.exists? c_name
			while $files.values.map(&:size).inject(0, :+) > CACHE_SIZE_LIMIT
				$stderr.puts "Pruning cache..." if VERBOSE
				remove_file *$files.keys.sample
			end

			$stderr.print "Loading cache for #{n}-grams (#{c})... " if VERBOSE
			
			# stat = Sys::Filesystem.stat("/")
			# mb_available = stat.block_size * stat.blocks_available / 1024 / 1024
			# $stderr.print "#{mb_available} MB available" if VERBOSE

			t0 = Time::now
			res = system "zcat #{f_name} > #{c_name}"
			until res
				$stderr.puts
				$stderr.puts "Failed to load cache. Press enter to retry..."
				gets
				res = system "zcat #{f_name} > #{c_name}"
			end
			$stderr.puts format "Done in %.1f s", Time::now - t0 if VERBOSE
		end
		f = open c_name
		f.seek 0, IO::SEEK_SET
		$files[[n, c]] = f
		cache_size = $files.values.map(&:size).inject(0, :+)
		$stderr.puts "Total cache size is #{cache_size / 1048576} MB (#{format("%.2f", 100 * cache_size / CACHE_SIZE_LIMIT)}%)" if VERBOSE
	end
	return $files[[n, c]]
end

def remove_file n, c
	# f_name = "downloads/google_ngrams/#{n}/googlebooks-eng-all-#{n}gram-20120701-#{c}_sorted"
	f_name = "#{File.dirname(__FILE__)}/cache/cache_#{c}_#{n}"
	$stderr.print "Removing cache for #{n}-grams (#{c})... " if VERBOSE
	t0 = Time::now
	res = system "rm #{f_name}"
	$files.delete [n, c]
	if res
		$stderr.puts format "Done in %.1f s", Time::now - t0 if VERBOSE
	else
		$stderr.puts "\033[31mWarning: Failed to cleanup cache\033[0m" if VERBOSE
	end
end

def cleanup_files
	return unless $files

	for n, c in $files.keys
		remove_file n, c
	end
end

def read_pos f
	# To deal with later: entries on the form:
	# 		GONE_X _._ 2006 65 61
	# 		GONE_X __ 1993 1 1
	# Also: period as a token?

	tokens 	= f.readline.split
	# $stderr.puts tokens.join " "
	entry 	= tokens[0..-4]
	year 	= tokens[-3].to_i
	count 	= tokens[-2].to_i

	groups	= entry.map {|e| e.match(/^(.*?)(?:\.([0-9]*))?(?:\_([_A-Z]*))?(?:\.([0-9]*))?$/) }
	entry	= groups.map {|e| e[1] }
	# e_m		= entry.map {|e| e.split "." }
	# entry 	= e_m.map {|e| e[0] }
	# e_n 	= entry.map {|e| e.split "_" }
	# entry	= e_n.map {|e| e[0] }
	entry = entry.join " "

	return entry, year, count
end

def find_range f, i, term
	
	i_input = i

	f.seek i, IO::SEEK_SET
	f.readline

	step = RANGE_CUT_OFF
	found = false
	until found
		i -= step
		if i < 0
			i_0 = 0
			found = true
			break
		end
		step *= 2
		f.seek i, IO::SEEK_SET
		f.readline
		entry, year, count = * (read_pos f)
		if (entry <=> term) < 0
			i_0 = i
			found = true
		end
	end
	t_0 = entry

	i = i_input

	step = RANGE_CUT_OFF
	found = false
	until found
		i += step
		if i > f.size
			i_1 = f.size
			found = true
			break
		end
		step *= 2
		f.seek i, IO::SEEK_SET
		f.readline
		entry, year, count = * (read_pos f)
		if (entry <=> term) > 0
			i_1 = i
			found = true
		end
	end
	t_1 = entry
	$stderr.puts "Tentative range: [#{t_0}, #{t_1}]" if VERBOSE

	return [i_0, i_1]

end

def vectorize h, r
	res = []
	for y in r
		res << ((h.include? y) ? h[y] : 0)
	end
	return res
end

def find term

	# return Hash.new { 0 } unless ('a'..'z').include? term.chars.first

	$stderr.puts "Looking up term '#{term}'..."

	result = Hash.new { 0 }

	t = term.split
	if t.size == 1
		return result unless ('a'..'z').include? term.downcase.chars[0]
		f = get_file 1, term.chars.first
	elsif t.size == 2
		return result unless ('a'..'z').include? term.downcase.chars[0]
		return result unless ('a'..'z').include? term.downcase.chars[1]
		if ('0'..'9').include? term.chars.first
			f = get_file 2, term.chars.first
		else
			f = get_file 2, t.join("_").chars[0..1].join
		end
	else
		raise "Only 1-grams and 2-grams are supported"
	end

	i_0 = 0
	i_1 = f.size

	f.seek i_0, IO::SEEK_SET
	t_0 = f.readline.split.first

	f.seek i_1-100, IO::SEEK_SET
	f.readline
	t_1 = f.readline.split.first

	matched = false
	until matched
		i = i_0 + (i_1 - i_0) / 2
		f.seek i, IO::SEEK_SET
		f.readline
		
		entry, year, count = * (read_pos f)

		# $stderr.puts "Seeking to #{entry} (#{i}) in range [#{i_0}, #{i_1}]"
		$stderr.puts "Seeking to '#{entry}' in range [#{t_0}, #{t_1}] (range is 2^#{Math::log2(i_1 - i_0).round} bytes)" if VERBOSE
		if (i_1 - i_0) < RANGE_CUT_OFF
			matched = true
			f.seek i_0, IO::SEEK_SET
			f.readline
			while f.tell() < i_1
				entry, year, count = * (read_pos f)
				if (entry <=> term) == 0
					result[year] += count
				end
			end
			return result
		else
			if (entry <=> term) < 0
				i_0 = i
				t_0 = entry
			elsif (entry <=> term) > 0
				i_1 = i
				t_1 = entry
			else
				matched = true
				i_0, i_1 = * (find_range f, i, term)
				$stderr.puts "Extracting n-grams from range of size 2^#{Math::log2(i_1 - i_0).round} bytes" if VERBOSE
				# i_0 = i - RANGE_CUT_OFF
				# i_1 = i + RANGE_CUT_OFF
				f.seek i_0, IO::SEEK_SET
				f.readline
				while f.tell() < i_1
					entry, year, count = * (read_pos f)
					if (entry <=> term) == 0
						result[year] += count
					end
				end
				return result
			end
		end
	end

end

def find_all term
	Dir.chdir(File.dirname(__FILE__)) do
		load_files unless $files
		# All combinations (3 x 3)
		res = Hash.new {0}

		tokens = term.split
		if tokens.size == 2
			t1, t2 = *tokens
			if ["_START_", "_END_"].include? t1
				t1 = [t1]
			else
				t1 = [t1.capitalize, t1.downcase, t1.upcase]
			end
			if ["_START_", "_END_"].include? t2
				t2 = [t2]
			else
				t2 = [t2.capitalize, t2.downcase, t2.upcase]
			end
			for t in t1.product t2
				for k, v in find t.join " "
					res[k] += v
				end
			end
		elsif tokens.size == 1
			t1 = tokens[0]
			if ["_START_", "_END_"].include? t1
				t1 = [t1]
			else
				t1 = [t1.capitalize, t1.downcase, t1.upcase]
			end
			for t in t1
				for k, v in find t
					res[k] += v
				end
			end
		else
			raise "Trying to lookup #{tokens.size}-gram count : Not implemented"
		end

		# for k, v in find term.downcase
		# 	res[k] += v
		# end
		# for k, v in find term.upcase
		# 	res[k] += v
		# end
		# for k, v in find term.split.map(&:capitalize).join(" ")
		# 	res[k] += v
		# end
		# for k, v in find term.capitalize
		# 	res[k] += v
		# end
		return res
	end
end

if __FILE__ == $0

	def cached sym, *args
		$cached_results = {} unless $cached_results
		if $cached_results.include? [sym, *args]
			res = $cached_results[[sym, *args]]
		else
			res = send sym, *args
			$cached_results[[sym, *args]] = res
		end
		return res
	end

	require 'benchmark'

	terms = ARGF
	for term in terms
		term.strip!
		puts "#{term.downcase}: #{(vectorize (cached :find_all, term), 1800..2008).join " "}"
	end

end
