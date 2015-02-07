require 'basalt/version'
require 'basalt/config'
require 'basalt/basaltfile'
require 'basalt/packages/context'
require 'colorize'
require 'docopt'
require 'fileutils'
require 'ostruct'
require 'yaml'

module Basalt #:nodoc:
  class Packages
    DOC = %Q(USAGE:
  %<binname>s package new NAME
  %<binname>s package install NAME...
  %<binname>s package uninstall NAME...
  %<binname>s package sync NAME...
  %<binname>s package update NAME...
  %<binname>s package list
  %<binname>s package list-available
  %<binname>s package list-installed)

    def basaltfile
      @basaltfile ||= Basaltfile.new
    end

    def config
      @config ||= Basalt::Config::Sys.new
    end

    def repoconfig
      @repoconfig ||= OpenStruct.new(pkgdir: basaltfile.pkgdir)
    end

    def context
      @context ||= Context.new(config.get, repoconfig)
    end

    def generate_packages_list(options = {})
      DependecySolver.solve(context.repo.installed, options)
    end

    def generate_packages_require(options = {})
      contents = ''
      contents << "# AutoGenerated by Basalt\n"
      contents << "$: << '#{basaltfile.pkgdir}'\n\n"
      generate_packages_list(options).each do |pkg|
        contents << pkg.entry_point_contents
        contents << "\n" unless contents.ends_with?("\n")
      end
      filename = File.join(basaltfile.pkgdir, 'load.rb')
      File.write(filename, contents)
      STDERR.puts '  GENERATED'.light_green + "\t#{filename}"
    end

    def install
      basaltfile.packages.each do |bpkg|
        context.install(bpkg.name)
      end
      generate_packages_require
    end

    def update
      basaltfile.packages.each do |bpkg|
        context.update(bpkg.name)
      end
      generate_packages_require
    end

    def sync
      basaltfile.packages.each do |bpkg|
        context.sync(bpkg.name)
      end
      generate_packages_require
    end

    def multi_exec(list)
      if list.is_a?(Array)
        list.each do |v|
          begin
            yield v
          rescue
          end
        end
      else
        begin
          yield list
        rescue
        end
      end
    end

    def run(rootfilename, argv)
      doc = DOC % ({ binname: rootfilename })

      data = Docopt.docopt(doc, argv: argv, version: VERSION, help: true)

      names = data['NAME']

      if data['new']
        context.new(name)
      elsif data['install']
        multi_exec(names) { |name| context.install(name) }
      elsif data['uninstall']
        multi_exec(names) { |name| context.uninstall(name) }
      elsif data['sync']
        multi_exec(names) { |name| context.sync(name) }
      elsif data['update']
        multi_exec(names) { |name| context.update(name) }
      elsif data['list']
        context.list
      elsif data['list-available']
        context.list_available
      elsif data['list-installed']
        context.list_installed
      end
    end
  end
end
