require 'active_support/core_ext/string'
require 'ostruct'
require 'yaml'

module Basalt #:nodoc:
  class Packages #:nodoc:
    class Package
      FILENAME = 'pkg.yml'

      attr_accessor :path
      attr_accessor :refname
      attr_accessor :data

      def initialize(path, refname, data = nil)
        @path = path
        @refname = refname
        @data = data || default_data
      end

      def default_data
        {
          name: refname.titlecase,
          author: ENV['USER'],
          summary: '',
          description: '',
          entry_point: '_basalt.rb',
          deps: []
        }
      end

      def name
        @data['name']
      end

      def author
        @data['author']
      end

      def description
        @data['description']
      end

      def summary
        @data['summary'] || description
      end

      def entry_point
        @data['require'] || @data['entry_point']
      end

      def deps
        @data['deps']
      end

      def entry_point_contents
        File.read(File.join(@path, entry_point))
      end

      def pkgfile
        File.join(@path, FILENAME)
      end

      def save
        File.write(pkgfile, @data.to_h.to_yaml)
        self
      end

      def load
        @data = OpenStruct.new(YAML.load_file(pkgfile))
        self
      end
    end
  end
end
