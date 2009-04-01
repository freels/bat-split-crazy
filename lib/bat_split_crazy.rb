module BatSplitCrazy
  def self.included(base)
    base.send :extend, ClassMethods
  end

  def test_variate(name, options = {})
    test = self.class.variate_tests[name]
    return nil if test.nil?
    return nil unless test.qualifier.call(self, test.start_date, test.end_date)
    
    variate = test.modulo.call(self)
    variate == :control ? nil : variate
  end

  module ClassMethods
    def variate_tests
      VariateTest.tests[self.name]
    end

    def define_variate_test(name, &block)
      test = VariateTest.new(&block)
      test.name = name
      variate_tests[name] = test
    end
    alias variate_test define_variate_test

    def variate_test_report(name)
      variate_tests[name].report.call
    end

    def variate_test_reports
      variate_tests.inject({}) do |reports, kv|
        name, test = kv
        report = test.report
        reports[name] = report unless report.nil?
        reports
      end
    end
  end
end
