
require 'thread'

c1 = ('a'..'z').to_a
c3 = ('a'..'z').to_a + ["_"]
c2 = c1.product(c3).map {|a, b| a + b}

c1 = ('0'..'9').to_a
c2 = ('0'..'9').to_a
# cs = c1.product([1]) + c2.product([2])
cs = c1.product([1])
cs = c2.product([2])
original_files 		= cs.collect {|c, n| "downloads/google_ngrams/#{n}/googlebooks-eng-all-#{n}gram-20120701-#{c}.gz"}

# original_files 		= cs.collect {|c| Dir["downloads/google_ngrams/#{n}/googlebooks-eng-all-#{n}gram-20120701-#{c}.gz"] }.collect {|a| a.empty? ? nil : a[0]}
# uncompressed_files 	= cs.collect {|c| Dir["downloads/google_ngrams/#{n}/googlebooks-eng-all-#{n}gram-20120701-#{c}"] }.collect {|a| a.empty? ? nil : a[0]}
# sorted_files 		= cs.collect {|c| Dir["downloads/google_ngrams/#{n}/googlebooks-eng-all-#{n}gram-20120701-#{c}_sorted"] }.collect {|a| a.empty? ? nil : a[0]}
# output_files 		= cs.collect {|c| Dir["downloads/google_ngrams/#{n}/googlebooks-eng-all-#{n}gram-20120701-#{c}_sorted.gz"] }.collect {|a| a.empty? ? nil : a[0]}

$stdout.sync = true

def filename c, n, suffix
	return "downloads/google_ngrams/#{n}/googlebooks-eng-all-#{n}gram-20120701-#{c}#{suffix}"
	# name = Dir["downloads/google_ngrams/#{n}/googlebooks-eng-all-#{n}gram-20120701-#{c}#{suffix}"]
	# return name.empty? ? nil : name[0]
end

# def File.exists? filename *args
# 	return filename(*args)
# end

queue = []

Unzip 	= Struct.new :input, :output, :size
Zip 	= Struct.new :input, :output, :size
Sort 	= Struct.new :input, :output, :size
Delete 	= Struct.new :filename, :size

class Unzip
	def command
		"gunzip -c #{input} > #{output}"
	end
end
class Zip
	def command
		"gzip -c #{input} > #{output}"
	end
end
class Sort
	def command
		"LC_ALL=C sort #{input} -o #{output}"
	end
end
class Delete
	def command
		"rm -f #{filename}"
	end
end



for c_n, i in cs.each_with_index
	c, n = *c_n
	unless File.exists? filename c, n, "_sorted.gz"
		unless File.exists? filename c, n, "_sorted"
			unless File.exists? filename c, n, ""
				unless File.exists? filename c, n, ".gz"
					puts filename c, n, ".gz"
					# Download
				end
				# unzip
				queue << Unzip.new(filename(c, n, ".gz"), filename(c, n, ""), File.size?(filename(c, n, ".gz")))

				# cleanup
				queue << Delete.new(filename(c, n, ".gz"), File.size?(filename(c, n, ".gz")))
			end
			# sort
			queue << Sort.new(filename(c, n, ""), filename(c, n, "_sorted"), File.size?(filename(c, n, ".gz")))
			queue << Delete.new(filename(c, n, ""), File.size?(filename(c, n, ".gz")))
		end
		# zip sorted
		queue << Zip.new(filename(c, n, "_sorted"), filename(c, n, "_sorted.gz"), File.size?(filename(c, n, ".gz")))
		queue << Delete.new(filename(c, n, "_sorted"), File.size?(filename(c, n, ".gz")))
	end
	if File.exists? filename c, n, "_sorted.gz"
		if File.exists? filename c, n, "_sorted"
			# delete sorted
			queue << Delete.new(filename(c, n, "_sorted"), File.size?(filename(c, n, "_sorted")))
		end
		if File.exists? filename c, n, ""
			# delete unzipped
			queue << Delete.new(filename(c, n, ""), File.size?(filename(c, n, "")))
		end
		if File.exists? filename c, n, ".gz"
			# delete original
			queue << Delete.new(filename(c, n, ".gz"), File.size?(filename(c, n, ".gz")))
		end
	end
end

unzips 	= queue.select {|op| op.is_a? Unzip  }.collect {|op| op.size }
zips 	= queue.select {|op| op.is_a?  Zip   }.collect {|op| op.size }
sorts 	= queue.select {|op| op.is_a?  Sort  }.collect {|op| op.size }
deletes = queue.select {|op| op.is_a? Delete }.collect {|op| op.size }

total = {
	Unzip => unzips.inject(0, :+),
	Zip => zips.inject(0, :+),
	Sort => sorts.inject(0, :+),
	Delete => deletes.inject(0, :+),
}

puts "Total operations:"
puts "#{unzips.size} unzip operation totalling #{unzips.inject(0, :+) / 1048576} MB (compressed)"
puts "#{zips.size} zip operation totalling #{zips.inject(0, :+) / 1048576} MB (compressed)"
puts "#{sorts.size} sort operation totalling #{sorts.inject(0, :+) / 1048576} MB (compressed)"
puts "#{deletes.size} delete operation totalling #{deletes.inject(0, :+) / 1048576} MB (compressed)"

messages = Queue.new
completed = {
	Unzip => 0,
	Zip => 0,
	Sort => 0,
	Delete => 0,
}
elapsed = {
	Unzip => 0,
	Zip => 0,
	Sort => 0,
	Delete => 0,
}
running = true
output_thread = Thread.new do
	buffer_size = 0
	t0 = Time::now
	puts "Run started at #{t0.localtime("+09:00").strftime '%H:%M:%S, %A %B %-d'}"
	while running
		sleep(0.1)
		print "\r"
		print " " * buffer_size
		print "\r"

		until messages.empty?
			puts messages.pop
		end

		z_r = 1.0*completed[Zip] / total[Zip]
		s_r = 1.0*completed[Sort] / total[Sort]
		u_r = 1.0*completed[Unzip] / total[Unzip]
		d_r = 1.0*completed[Delete] / total[Delete]

		t_r = 1.0*completed.values.inject(:+) / total.values.inject(:+)

		# Not very accurate but whatever
		# elapsed = Time::now - t0
		# if t_r > 0
		# 	eta = t0 + elapsed / t_r
		# else
		# 	eta = t0
		# end

		eta = 0
		if z_r > 0
			eta += elapsed[Zip] / z_r
		end
		if s_r > 0
			eta += elapsed[Sort] / s_r
		end
		if u_r > 0
			eta += elapsed[Unzip] / u_r
		end
		if d_r > 0
			eta += elapsed[Delete] / d_r
		end
		eta = t0 + eta

		output = ""
		output += "Completed: "
		output += format("[unzips: %.2f%%, ", 	100*u_r)
		output += format("sorts: %.2f%%, ", 	100*s_r)
		output += format("zips: %.2f%%, ", 		100*z_r)
		output += format("deletes: %.2f%%]", 	100*d_r)
		output += " ETA: #{eta.localtime("+09:00").strftime '%H:%M:%S, %A %B %-d'}"

		buffer_size = output.size
		print output
	end
	puts
end

puts
for op in queue
	# next if op.is_a? Delete
	t0 = Time::now

	messages << op.command
	res = system op.command
	# res = false
	unless res
		messages << "\033[31mFailed\033[0m"
	end

	completed[op.class] += op.size
	sleep(0.1)

	elapsed[op.class] += Time::now - t0
end
running = false
output_thread.join

# paths = cs.select {|c| Dir["downloads/google_ngrams/#{n}/googlebooks-eng-all-#{n}gram-20120701-#{c}_sorted"].empty? }.map {|c| Dir["downloads/google_ngrams/#{n}/googlebooks-eng-all-#{n}gram-20120701-#{c}.gz"] }

# file_sizes = paths.map {|path| File.size? *path }
# total = file_sizes.inject :+

# puts "Extraction started at #{Time.now.strftime '%H:%M:%S, %A %B %-d'}"
# puts "Total file size: #{total / 1048576} MB"

# t0 = Time::now
# extracted = 0

# buffer_size = 0
# for path, file_size in paths.zip file_sizes
# 	in_path = path[0]
# 	out_path = in_path[0..-4] + "_sorted"
# 	output = "Extracting file #{in_path}"
# 	# print "\r" + (" " * output.size) + "\r"
# 	puts output
# 	buffer_size = output.size
# 	`zcat #{in_path} > #{out_path}`
# 	`LC_ALL=C sort #{out_path} -o #{out_path}`

# 	extracted += file_size
# 	elapsed = Time::now - t0
# 	eta = t0 + elapsed * total / extracted
# 	puts "Done #{extracted / 1048576} MB (#{format("%.3f", 100.0 * extracted / total)}% ), ETA #{eta.strftime '%H:%M:%S, %A %B %-d'}"

# end

# puts
# puts "Done."