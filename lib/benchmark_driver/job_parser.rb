require 'benchmark_driver/runner'

module BenchmarkDriver
  class << JobParser = Module.new
    # @param [Hash] config
    def parse(config)
      config = symbolize_keys(config)
      type = config.fetch(:type)
      if !type.is_a?(String)
        raise ArgumentError.new("Invalid type: #{config[:type].inspect} (expected String)")
      elsif !type.match(/\A[A-Za-z0-9_]+\z/)
        raise ArgumentError.new("Invalid type: #{config[:type].inspect} (expected to include only [A-Za-z0-9_])")
      end
      config.delete(:type)

      # Dynamic dispatch for plugin support
      ::BenchmarkDriver.const_get("Runner::#{camelize(type)}::JobParser", false).parse(config)
    end

    private

    def camelize(str)
      str.split('_').map(&:capitalize).join
    end

    # @param [Object] config
    def symbolize_keys(config)
      case config
      when Hash
        config.dup.tap do |hash|
          hash.keys.each do |key|
            case key
            when String, Symbol
              hash[key.to_sym] = symbolize_keys(hash.delete(key))
            else # Struct
              hash[key] = symbolize_keys(hash.delete(key))
            end
          end
        end
      when Array
        config.map { |c| symbolize_keys(c) }
      else
        config
      end
    end
  end
end
