require File.join(File.dirname(__FILE__), 'parallel_tests')
require 'erb'

class ParallelSpecs < ParallelTests
  def self.run_tests(test_files, process_number, options)
    cmd = "#{color} #{executable} #{options} #{spec_opts(process_number)} #{test_files*' '}"
    execute_command(cmd, process_number)[:stdout]
  end

  def self.executable
    cmd = if File.file?("script/spec")
      "script/spec"
    elsif bundler_enabled?
      cmd = (run("bundle show rspec") =~ %r{/rspec-1[^/]+$} ? "spec" : "rspec")
      "bundle exec #{cmd}"
    else
      %w[spec rspec].detect{|cmd| system "#{cmd} --version > /dev/null 2>&1" }
    end
    cmd or raise("Can't find executables rspec or spec")
  end

  protected

  # so it can be stubbed....
  def self.run(cmd)
    `#{cmd}`
  end

  def self.spec_opts(num)
    opts = ['spec/parallel_spec.opts', 'spec/spec.opts'].detect{|f| File.file?(f) }
    if opts
      # TODO: setting ENV here is not good idea though...
      ENV["TEST_ENV_NUMBER"] = num.to_s
      parsed_opts = ERB.new(File.open(opts).read).result
      f_name = ".parallel_spec#{num}.opts"
      File.open(f_name, "w") {|f| f.write(parsed_opts) }
      opts ? "-O #{f_name}" : nil
    else
      nil
    end
  end

  #display color when we are in a terminal
  def self.color
    ($stdout.tty? ? 'RSPEC_COLOR=1 ; export RSPEC_COLOR ;' : '')
  end

  def self.test_suffix
    "_spec.rb"
  end
end
