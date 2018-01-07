class Benchmark::Output::Ips
  # This class requires runner to measure following fields in `Benchmark::Driver::BenchmarkResult` to show output.
  REQUIRED_FIELDS = [:real]

  NAME_LENGTH = 20

  # @param [Array<Benchmark::Driver::Configuration::Job>] jobs
  # @param [Array<Benchmark::Driver::Configuration::Executable>] executables
  # @param [Benchmark::Driver::Configuration::OutputOptions] options
  def initialize(jobs:, executables:, options:)
    @jobs        = jobs
    @executables = executables
    @options     = options
    @results     = []
    @name_by_result = {}
  end

  def start_warming
    $stdout.puts 'Warming up --------------------------------------'
  end

  # @param [String] name
  def warming(name)
    if name.length > NAME_LENGTH
      $stdout.puts(name)
    else
      $stdout.print("%#{NAME_LENGTH}s" % name)
    end
  end

  # @param [Benchmark::Driver::BenchmarkResult] result
  def warmup_stats(result)
    $stdout.puts "#{humanize(result.ip100ms)} i/100ms"
  end

  def start_running
    $stdout.puts 'Calculating -------------------------------------'
    if @executables.size > 1
      $stdout.print(' ' * NAME_LENGTH)
      @executables.each do |executable|
        $stdout.print(" %10s " % executable.name)
      end
      $stdout.puts
    end
  end

  def running(name)
    warming(name)
    @row_results = []
  end

  # @param [Benchmark::Driver::BenchmarkResult] result
  def benchmark_stats(result)
    executable = @executables[@row_results.size]
    $stdout.print("#{humanize(result.ips, [10, executable.name.length].max)} ")

    @results << result
    @row_results << result
    if @row_results.size == @executables.size
      $stdout.print("i/s - #{humanize(result.iterations)} in")
      @row_results.each do |r|
        $stdout.print(" %3.6fs" % r.real)
      end
      if @row_results.size == 1
        sec = @row_results[0].real
        iter = result.iterations
        if File.exist?('/proc/cpuinfo') && (clks = estimate_clock(sec, iter)) < 1_000
          $stdout.print(" (#{pretty_sec(sec, iter)}/i, #{clks}clocks/i)")
        else
          $stdout.print(" (#{pretty_sec(sec, iter)}/i)")
        end
      end
      $stdout.puts
    end

    @name_by_result[result] = executable.name
  end

  def finish
    if @results.size > 1 && @options.compare
      compare
    end
  end

  private

  def humanize(value, width = 10)
    scale = (Math.log10(value) / 3).to_i
    suffix =
      case scale
      when 1; 'k'
      when 2; 'M'
      when 3; 'G'
      when 4; 'T'
      when 5; 'Q'
      else # < 1000 or > 10^15, no scale or suffix
        scale = 0
        ' '
      end
    "%#{width}.3f#{suffix}" % (value.to_f / (1000 ** scale))
  end

  def pretty_sec sec, iter
    r = Rational(sec, iter)
    case
    when r >= 1
      "#{'%3.2f' % r.to_f}s"
    when r >= 1/1000r
      "#{'%3.2f' % (r * 1_000).to_f}ms"
    when r >= 1/1000_000r
      "#{'%3.2f' % (r * 1_000_000).to_f}us"
    else
      "#{'%3.2f' % (r * 1_000_000_000).to_f}ns"
    end
  end

  def estimate_clock sec, iter
    hz = File.read('/proc/cpuinfo').scan(/cpu MHz\s+:\s+([\d\.]+)/){|(f)| break hz = Rational(f.to_f) * 1_000_000}
    r = Rational(sec, iter)
    Integer(r/(1/hz))
  end

  def compare
    $stdout.puts("\nComparison:")
    results = @results.sort_by { |r| -r.ips }
    first   = results.first

    results.each do |result|
      if result == first
        slower = ''
      else
        slower = '- %.2fx  slower' % (first.ips / result.ips)
      end

      name = result.job.name
      if @executables.size > 1
        name = "#{name} (#{@name_by_result.fetch(result)})"
      end
      $stdout.puts("%#{NAME_LENGTH}s: %11.1f i/s #{slower}" % [name, result.ips])
    end
    $stdout.puts
  end
end
