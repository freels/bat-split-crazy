module BatSplitCrazy
  class VariateTest
    class << self
      def tests
        @tests ||= Hash.new{|h,k| h[k] = {}.with_indifferent_access }
      end
    end

    attr_accessor :start_date, :end_date, :split_count, :groups, :modulo, :modulo_attr, :report, :name, :qualifier
    
    def initialize
      yield VariateTestDefinition.new(self)
    end

    def start_date
      @start_date || Time.at(0)
    end

    def end_date
      @end_date || Time.now + 1.day
    end

    def qualifier
      if @qualifier.is_a? Proc
        @qualifier
      elsif @qualifier.is_a? Symbol
        meth = @qualifier
        lambda {|r,s,e| d = r.send(meth); d > s and d < e }
      else
        lambda {|r,s,e| Time.now > s and Time.now < e }
      end
    end

    def split_count
      @split_count || @groups.length
    end

    def buckets
      hash = {}.with_indifferent_access
      (0..split_count).each do |i|
        bucket = modulo.call(OpenStruct.new(modulo_attr => i))
        hash[bucket] ||= []
        hash[bucket] << i
      end
      hash
    end

    def modulo_attr
      @modulo_attr || :id
    end

    def modulo
      @modulo || lambda {|r| (@groups)[r.send(modulo_attr) % split_count] }
    end

    def report
      return nil if @report.nil?

      result = ReportTable.new
      @report.call(self, result)
      result
    end
  end

  class VariateTestDefinition
    def initialize(test)
      @test = test
    end

    def start_date(date)
      @test.start_date = if date.is_a? Date
        Time.parse(date.to_s)
      elsif date.is_a? String
        Time.parse(date)
      else
        date
      end
    end

    def split_count(count)
      @test.split_count = count
    end

    def groups(*args)
      @test.groups = Array(args)
    end

    def modulo(&block)
      @test.modulo = block
    end

    def modulo_attr(sym)
      @test.modulo_attr = sym
    end

    def report(&block)
      @test.report = block
    end
  end
end

