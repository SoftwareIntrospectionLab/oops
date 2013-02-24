# coding: utf-8

#
# author - Huascar Sanchez
#

require 'rubygems'
require 'find'
require 'csv'


# Result is a record class that will hold
# any collected data related to loops in BIND
class Result
  attr_accessor :dir, :file, :loop, :count, :content

  def initialize(dir, file, loop, count, content = [])
    @dir      = dir
    @file     = file
    @loop     = loop
    @count    = count
    @content  = content
  end

  def to_s
    "Result{dir=#{dir}, file=#{file}, loop=#{loop}, count=#{count}, content=#{content}}"
  end
end


# Public: finds all files matching a given file extension(s).
#
# dir - path/to/your/files
# ext - file extension
#
# Returns an array of files matching the extension.
def find(dir, ext = 'c|h')
  files = []

  # copy file and path to array if
  # filename ends in ext. e.g., ".c" or ".h"
  Find.find(dir) do |f|
    files << f if f.match(/\.#{ext}\Z/)
  end

  files
end


# Public: calculates frequency of loops
#
# files     - array of files matching a given extension: e.g., .c, .h
# directory - path/to/your/files
#
# Returns an array of results.
def count_loops(files, directory)
  result = []

  files.each do |file|
    begin
      # ignore statements that start with '#'
      curated_code  = IO.popen("cpp #{file}").readlines.select { |line| not line.match(/^#/) }

      # collect while and for loops
      all_while = curated_code.select {|line| line.match('while *\(.*\)')}
      all_for   = curated_code.select {|line| line.match('for *\(.*\)')}

      if all_while.length > 0
        content = []
        all_while.each do |w|
          content  << w.strip
        end
        result << Result.new(directory, File.basename(file), 'while', all_while.length, content )
      end

      if all_for.length > 0
        content = []
        all_for.each do |f|
          content  << f.strip
        end
        result << Result.new(directory, File.basename(file), 'for', all_for.length, content )
      end

    rescue Exception => e
      puts "Got exception: #{e.inspect}"
    end
  end

  result

end

# makes a new csv file
def makefile(directory)
  begin
    File.new("result/data-#{directory.gsub('/', '-')}.csv", 'w').close
  rescue Exception => e
    puts "Got exception: #{e.inspect}"
  end
end


# Public: extracts items from results and writes them into a csv file.
#
# result    - array of results
# directory - path/to/your/files
#
# Returns nothing.
def copy_to_csv(result, directory)

  makefile(directory)

  CSV.open("result/data-#{directory.gsub('/', '-')}.csv", 'wb') do |csv|
    csv << [:dir, :file, :loop, :count, :content]
    result.each do |item|
      begin
        csv << [
            "#{item.dir}",
            "#{item.file}",
            "#{item.loop}",
            "#{item.count}",
            item.content.join('>>>')]
      rescue Exception => e
        puts "Got exception: #{e.inspect}"
      end
    end
  end
end

def play
  directories = %w(
    bind/lib/dns
    bind/lib/bind9
    bind/lib/export
    bind/lib/irs
    bind/lib/isc
    bind/lib/isccc
    bind/lib/isccfg
    bind/lib/lwres
    bind/lib/tests
    bind/lib/win32
  )

  directories.each do |dir|
    copy_to_csv(count_loops(find(dir), dir), dir)
    sleep(15.seconds) # will avoid the vfork problem - not enough resources
  end
end

# Public: prints any given string.
#
# s = String output
#
# Prints to STDOUT and returns.
def output(s)
  puts(s)
end

# Public: prints a tidy overview of your Lists in descending order of
# number of Items.
#
# Returns nothing.
def overview
  output '  Total Loops | Total Whiles | Total Fors '

  total_whiles  = 0
  total_fors    = 0

  CSV.foreach('result/data.csv', :headers => true) do |row|
    increment     =  row['count'].to_i
    total_whiles +=  increment if row['loop'] == 'while'
    total_fors   +=  increment if row['loop'] == 'for'
  end

  output "   \t#{total_whiles + total_fors}   \t\t\t#{total_whiles}   \t\t#{total_fors}"
  output "\n"
end

# Public: prints the detailed view of all collected data.
#
# Returns nothing.
def breakdown

  dns      = {:while=>0, :for=>0, :total=>0, :dir => 'bind/lib/dns'}
  bind9    = {:while=>0, :for=>0, :total=>0, :dir => 'bind/lib/bind9'}
  export   = {:while=>0, :for=>0, :total=>0, :dir => 'bind/lib/export'}
  irs      = {:while=>0, :for=>0, :total=>0, :dir => 'bind/lib/irs'}
  isc      = {:while=>0, :for=>0, :total=>0, :dir => 'bind/lib/isc'}
  isccc    = {:while=>0, :for=>0, :total=>0, :dir => 'bind/lib/isccc'}
  isccfg   = {:while=>0, :for=>0, :total=>0, :dir => 'bind/lib/isccfg'}
  lwres    = {:while=>0, :for=>0, :total=>0, :dir => 'bind/lib/lwres'}
  test     = {:while=>0, :for=>0, :total=>0 ,:dir => 'bind/lib/tests'}


  CSV.foreach('result/data.csv', :headers => true) do |row|
    increment     =  row['count'].to_i

    # calculate total loops
    dns[:total]      += increment if row['dir']  == dns[:dir]
    bind9[:total]    += increment if row['dir']  == bind9[:dir]
    export[:total]   += increment if row['dir']  == export[:dir]
    irs[:total]      += increment if row['dir']  == irs[:dir]
    isc[:total]      += increment if row['dir']  == isc[:dir]
    isccc[:total]    += increment if row['dir']  == isccc[:dir]
    isccfg[:total]   += increment if row['dir']  == isccfg[:dir]
    lwres[:total]    += increment if row['dir']  == lwres[:dir]
    test[:total]     += increment if row['dir']  == test[:dir]

    # counts whiles and fors
    dns[:while]      += increment if row['dir']  == dns[:dir]  and row['loop'] == 'while'
    bind9[:while]    += increment if row['dir']  == bind9[:dir]  and row['loop'] == 'while'
    export[:while]   += increment if row['dir']  == export[:dir]   and row['loop'] == 'while'
    irs[:while]      += increment if row['dir']  == irs[:dir]  and row['loop'] == 'while'
    isc[:while]      += increment if row['dir']  == isc[:dir]  and row['loop'] == 'while'
    isccc[:while]    += increment if row['dir']  == isccc[:dir]  and row['loop'] == 'while'
    isccfg[:while]   += increment if row['dir']  == isccfg[:dir]   and row['loop'] == 'while'
    lwres[:while]    += increment if row['dir']  == lwres[:dir]  and row['loop'] == 'while'
    test[:while]     += increment if row['dir']  == test[:dir]   and row['loop'] == 'while'
  end

  # counts the for loops
  dns[:for]     = dns[:total]    - dns[:while]
  bind9[:for]   = bind9[:total]  - bind9[:while]
  export[:for]  = export[:total] - export[:while]
  irs[:for]     = irs[:total]    - irs[:while]
  isc[:for]     = isc[:total]    - isc[:while]
  isccc[:for]   = isccc[:total]  - isccc[:while]
  isccfg[:for]  = isccfg[:total] - isccfg[:while]
  lwres[:for]   = lwres[:total]  - lwres[:while]
  test[:for]    = test[:total]   - test[:while]

  output "  Directory \t| While Loops | For Whiles | Total "
  output "  #{dns[:dir]}     #{dns[:while]}     #{dns[:for]}  #{dns[:total]}"
  output "  #{bind9[:dir]}   #{bind9[:while]}   #{bind9[:for]}  #{bind9[:total]}"
  output "  #{export[:dir]}  #{export[:while]}  #{export[:for]}  #{export[:total]}"
  output "  #{irs[:dir]}     #{irs[:while]}  #{irs[:for]}  #{irs[:total]}"
  output "  #{isc[:dir]}     #{isc[:while]} #{isc[:for]} #{isc[:total]}"
  output "  #{isccc[:dir]}   #{isccc[:while]}   #{isccc[:for]}  #{isccc[:total]}"
  output "  #{isccfg[:dir]}  #{isccfg[:while]} #{isccfg[:for]}  #{isccfg[:total]}"
  output "  #{lwres[:dir]}   #{lwres[:while]}  #{lwres[:for]}  #{lwres[:total]}"
  output "  #{test[:dir]}   #{test[:while]}  #{test[:for]}   #{test[:total]}"


  chart({})

end

def chart(hash)
  hash
  # TODO (Huascar) use google charts gem to create a chart
end

overview
breakdown
