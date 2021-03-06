require 'benchmark_driver/struct'

module BenchmarkDriver
  DefaultJob = ::BenchmarkDriver::Struct.new(
    :name,       # @param [String] name - This is mandatory for all runner
    :script,     # @param [String] benchmark
    :prelude,    # @param [String,nil] prelude (optional)
    :teardown,   # @param [String,nil] after (optional)
    :loop_count, # @param [Integer,nil] loop_count (optional)
    :required_ruby_version, # @param [String,nil] required_ruby_version (optional)
    defaults: { prelude: '', teardown: '' },
  ) do
    def runnable_execs(executables)
      if required_ruby_version
        executables.select do |executable|
          Gem::Version.new(executable.version) >= Gem::Version.new(required_ruby_version)
        end.tap do |result|
          if result.empty?
            raise "No Ruby executables conforming required_ruby_version (#{required_ruby_version}) are specified"
          end
        end
      else
        executables
      end
    end
  end
end
