# coding: utf-8

require 'csv'

# todo: document
module Clusters
  VERSION     = '0.0.1'
  EPS         = 1.7
  MIN_POINTS  = 2

  # Precondition checking
  class Preconditions
    def self.check_argument(exp, msg = nil, *fmt)
      unless exp
        raise_exception(ArgumentError, msg, *fmt)
      end
      exp
    end

    def self.raise_exception(e, msg, *fmt)
      message = ''
      message = sprintf(msg, *fmt) unless fmt.empty?
      message = msg                unless msg.nil?

      raise e, message
    end
  end

  # TODO
  class Operations
    def self.inner_product(vector_a, vector_b)
      product = 0.0
      vector_a.zip(vector_b) do |x, y|
        product += x * y
      end
      product
    end

    def self.plus(a, b)
      n = a.size - 1
      v = []
      (0..n).each { |i|
        v[i] = a[i] + b[i]
      }
      v
    end

    def self.sum(vector)
      vector.inject(0.0) { |result, element| result + element }
    end

    def self.sum_square(vector)
      vector.inject(0.0) { |result, element| result + element**2 }
    end

    def self.sqrt_sum_square(vector)
      Math.sqrt(sum_square(vector))
    end

    def self.sum_diff_square(vector_a, vector_b)
      sum = 0.0
      vector_a.zip(vector_b) do |x, y|
        sum += (x - y)**2
      end
      sum
    end
  end

  # TODO
  class Distances
    def check_preconditions(a, b)
      are_arrays        = (is_array?(a) && is_array?(b))
      same_dimension    = have_same_dimension?(a, b)
      non_null_vectors  = !(is_null_vector(a) || is_null_vector(b))
      Preconditions.check_argument(are_arrays, 'You have entered non array vectors')
      Preconditions.check_argument(same_dimension, 'You have entered two vectors with diff dimensions')
      Preconditions.check_argument(non_null_vectors, 'You have entered a null vector')
    end

    def euclid_distance(vector_a, vector_b)
      Math::sqrt(Operations.sum_diff_square(vector_a, vector_b))
    end

    def euclid_similarity(vector_a, vector_b)
      1.0 / (1.0 + euclid_distance(vector_a, vector_b))
    end

    def is_array?(vector)
      vector.instance_of?(Array)
    end


    def have_same_dimension?(vector_a, vector_b)
      vector_a.size == vector_b.size
    end

    def is_null_vector(vector)
      vector.empty?
    end

    def calculate(vector_a, vector_b)
      check_preconditions(vector_a, vector_b)
      euclid_distance(vector_a, vector_b)
    end
  end

  # Single Link Clustering
  class SingleLink
    INFINITY = +1.0/0.0

    # m: measurer
    # k: k clusters
    # data: an array of feature vectors
    def cluster(s, k, data)

      distance = EPS

      while true
        # loop with increasing distance until
        # cluster size is correct
        distance    *= 1.1 # TODO: this may need tuning/parameterization
        clusters    = []
        all_vectors = data

        until all_vectors.empty?
          # build clusters at this distance
          p = all_vectors[0]
          others = all_vectors[1..data.length - 1]

          close = []
          far = []

          others.to_a.each do |i|
            #puts s.calculate(p, i)
            if p != i && s.calculate(p, i) < distance
              close << i unless i.nil?
            else
              far << i unless i.nil?
            end
          end

          close << p
          clusters << close
          all_vectors = far
        end

        if clusters.size <= k
         return clusters
        end
      end
    end


  end

  # TODO
  class DensityBasedScan
    # todo: document
    def initialize(eps, min_pts)
      @distance   = Distances.new
      @eps        = eps
      @min_pts    = min_pts
    end

    def cluster(data)
      clusters = []
      visited  = Hash.new
      eps      = @eps
      min_pts  = @min_pts

      data.each do |vector|
        if visited[vector] != :visited
          visited[vector] = :visited
          neighbors = find_neighbors(data, vector, eps)
          if neighbors.size < min_pts
            visited[vector] = :noise
          else
            cluster = [vector]
            clusters.push(cluster)
            neighbors.each do |neighbor|
              # not contained in the cluster
              unless clusters.map { |val| val.include?(neighbor) }.include?(true)
                expand(data, visited, neighbor, cluster, clusters, eps, min_pts)
              end
            end
          end
        end
      end
      clusters
    end

    def expand(data, visited, vector, cluster, clusters, eps, min_pts)
      cluster.push(vector)
      if visited[vector] != :visited
        visited[vector] = :visited
        neighbors       = find_neighbors(data, vector, eps)
        if neighbors.size >= min_pts
          neighbors.each do |neighbor|
            unless clusters.map {|val| val.include?(neighbor)}.include?(true)
              expand(data, visited, neighbor, cluster, clusters, eps, min_pts)
            end
          end
        end
      end
    end

    def find_neighbors(data, a, eps)
      hood = []
      data.each do |b|
        if alike?(a, b, eps)  # dbscan is < eps
          hood.push(b)
        end
      end
      hood
    end

    # alike, but no the same
    def alike?(a, b, eps)
      distance = @distance.calculate(a, b)
      a != b && distance < eps
    end

  end

  # TODO
  class Plot
    # TODO
    # 1. plot frequency distribution of loops in bind
    # 2. plot clusters
    # 3. build a table (taxonomy)
    # 4. create a document for presentation
  end

  def self.of(data, eps = EPS, min_pts = MIN_POINTS)
    cluster_maker = DensityBasedScan.new(eps, min_pts)
    cluster_maker.cluster(data)
  end


  def self.generate_features(path)
    output   = []

    CSV.foreach(path, :headers => true) do |row|
      features = []

      # loop field
      loop = row['loop']

      features << loop.scan(/update/m).size               # state update
      features << [loop.scan(/while/m).size - 1, 0].max   # inner while
      features << [loop.scan(/for/m).size   - 1, 0].max   # inner for
      features << [loop.scan(/do/m).size    - 1, 0].max   # inner do-while
      features << loop.scan(/if\s*(.*?)/m).size +
                  loop.scan(/switch\s*(.*?)/m).size       # conditionals

      # structs field
      features << row['structs'].split(' ').reject {|s| s == 'none' }.size

      # types field
      features << row['types'].split(' ').reject {|s| s == 'none' }.size

      # number of terms in loop invariant (include those cases where you
      features << row['loopinv'].split( /\s+|\b/ )
                  .reject {|each|
                      each.match(/([\[\]\{\\}\*\?\\])/) # remove [] and () and {}
                  }.size

      output << features
    end
    output
  end

  def self.prune(data)
    output = []
    data.each do |e|
      unless e == []
        ref = output.include?(e)
        if ref
          #nothing
        else
          output << e
        end
      end
    end

  end

  def self.find_distinct(field, path)
    output = []

    CSV.foreach(path, :headers => true) do |row|
      structs = row[field].split(' ')
      structs.each do |e|
        unless e == 'none'
          ref = output.include?(e)
          if ref
            #nothing
          else
            output << e
          end
        end
      end
    end

    output.size
  end

  def self.echo(data)
    puts 'All feature vectors'
    puts '-----------------------------'

    index = 0
    data.each do |feature_vector|
      print "#{index += 1}. " + feature_vector.to_s
      print "\n"
    end
    print "\n"
  end

  def self.dbscan(path)
    # F = [ #updates, #inner_whiles,
    #       #inner_fors, #inner_dowhiles,
    #       #conditionals, #structs,
    #       #user_types, #terms_in_loop_invariant
    # ]
    data = generate_features(path)
    echo(data)
    clusters = of(prune(data))
    overview(data, clusters, 'Using Density based Scan Clustering')
  end

  def self.single_link(path, k)
    data        = generate_features(path)
    single_link = SingleLink.new
    s           = Distances.new
    clusters    = single_link.cluster(s, k, prune(data))
    overview(data, clusters, 'Single Link Clustering')
  end

  def self.min_distance(clusters)
    d   = Distances.new
    max = 0.0

    clusters.each do |cluster|
      clusters.each do |cluster_prime|
        val = d.calculate(cluster, cluster_prime)
        if val > max
          max = val
        end
      end
    end

    max

  end

  def self.overview(data, clusters, msg)
    indexes  = {}
    data.each_with_index { |key, index| indexes[key] = index }

    puts "All clusters (using #{msg})"
    puts "Dimensionality: #{clusters.size}"
    puts '-----------------------------'

    clusters.each_index do |dim|

      puts
      puts "Cluster #{dim + 1} of size #{clusters[dim].size} "
      puts "Cluster's distance between its elements is #{min_distance(clusters[dim])} "

      clusters[dim].each do |cluster|
        print cluster
        print '@('
        print indexes[cluster]
        print ')'
        print "\n"
      end
    end
    print "\n"
  end

end

# Build clusters from collected data in csv file
Clusters.dbscan('structs_and_types.csv')
Clusters.single_link('structs_and_types.csv', 4)

