require 'rubygems'
require 'cast'


#
# "prepare" a line - strip any of the gcc internal stuff from it,
# and any other things we do not understand.
#

def prepare_line(str)
    line = str.strip
    line = line.gsub(/\(\(__.*\)\)/, "").gsub(/__(attribute|extension)__/, "")
    line = line.gsub(/__const /, "const ")
    line = line.gsub(/__restrict /, "")
    line = line.gsub(/__asm__\s*\(.*\)/, "")
    line
end

#
# "prepare" the preprocessed output in array "lines"
# taken from file fname (filename used only for error messages)
#
def prepare_lines(fname, lines)
  # blob that will be parseable by CAST
  real_text = Array.new
  # info about the lines in the blob
  real_info = Array.new
  original_file = fname
  original_lineno = 1
  lines.each_with_index do |line, idx|
    real_line = prepare_line(line)

    if real_line =~ /^#\s+(\d+)\s+"([^"]+)"((?:\s+.*)?)$/
      num = $1.to_i
      fn = $2
      misc = $3
      original_file = fn
      original_lineno = num # minus something ?
      # puts "== set #{original_file}:#{original_lineno}"
      next
    else
      if real_line =~ /^#/
        raise real_line
      end
    end
    unless real_line =~ /^$/
      real_text << real_line
      real_info << { :file => original_file, :lineno => original_lineno,
                   :debug_file => fname, :debug_lineno => idx+1 }
      # puts "#{original_file}:#{original_lineno}:#{real_line}"
    end

    original_lineno += 1
  end
  [ real_text, real_info ]
end

def collect_for_loops(data, statements)
  statements.select {|stmt| stmt.For?}.each do |loop|
    data[:for] << loop 

    if loop.stmt != nil
      collect_for_loops(data, loop.stmt.stmts)
      collect_while_loops(data, loop.stmt.stmts)
    end
  end
end

def collect_while_loops(data, statements)
  statements.select {|stmt| stmt.While?}.each do |loop|
    data[:while] << loop 


    if loop.stmt != nil
      collect_while_loops(data, loop.stmt.stmts)
      collect_for_loops(data, loop.stmt.stmts)
    end
  end
end



def parse_c(fname)
  lines = File.open(fname).read.split("\n")

  text, info = prepare_lines(fname, lines)
  blobtext = text.join("\n")

  parser = C::Parser.new
  parser.type_names << "__builtin_va_list"
  parser.type_names << "double"
  tree = nil

  begin
    print "Parse start...\n"
    
    tree = parser.parse(blobtext)

    data = {:while => [], :dowhile => [], :for => []}

    cc = 0

    # 1. deal with functionDef, which is made of block definitions.
    # each block definition has a list of statements. And, within
    # those statements, there are other blocks, such as Whiles, Fors, 
    # etc.
    tree.entities.select { |n| n.FunctionDef?}.each do |node| 
      statements = node.def.stmts

      collect_for_loops(data, statements)
      collect_while_loops(data, statements)

      # for loops
      # statements.select {|f| f.For?}.each do |floop|
      #   chekofv[:fors] << floop
      #   floop.stmt.stmts.select {|o| o.While? or o.For? }.each do |oloop|
      #     if oloop.While?
      #       if oloop.do?
      #         chekofv[:dowhiles] << oloop
      #       else
      #         chekofv[:whiles] << oloop
      #       end
      #     elsif oloop.For?
      #       chekofv[:fors] << oloop
      #     end
      #   end
      # end 
    end

    data.each do |name, array|
      puts "#{name}: #{array.length}"
    end



    print "Parse end...\n"
  rescue Exception => e
    puts "Got exception: #{e.inspect}"
    if e.message =~ /^(\d+):(.*)$/
      errline = $1.to_i
      errmsg = $2
      ei = info[errline-1]
      src = text[errline-2 .. errline+1].join("\n")
      # puts "source lines: #{src}"

      raise "Error in #{ei[:file]}:#{ei[:lineno]} (#{ei[:debug_file]}:#{ei[:debug_lineno]}) : #{errmsg}"

    else
      raise "unparseable error message from parser"
    end
  end


  tree
end

tree = parse_c("example.c")

# puts tree.to_s
p tree