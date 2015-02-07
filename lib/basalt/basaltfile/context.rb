module Basalt #:nodoc:
  class Basaltfile #:nodoc:
    class Context
      # @return [String]  target directory to install packages to
      attr_accessor :pkgdir
      # @return [Array<Basalt::Basaltfile::Package>]
      attr_accessor :packages

      def initialize(pkgdir = nil)
        @pkgdir = ENV['BASALT_PKGDIR'] || pkgdir || 'packages'
        @packages = []
      end

      def set(options)
        options.each do |k, v|
          self.send("#{k}=", v)
        end
      end

      def pkg(name, options = {})
        opts = options.dup
        opts[:package] ||= name
        @packages << Package.new(name, opts)
      end

      def eval_data(data, filename = self.class.name)
        instance_eval(data, filename, 1)
      end

      def eval_file(filename)
        str = File.read(filename)
        eval_data(str, filename)
      end

      def to_h
        {
          pkgdir: @pkgdir,
          packages: @packages.map(&:to_h)
        }
      end

      def self.load_file(filename)
        new.tap { |e| e.eval_file(filename) }
      end
    end
  end
end
