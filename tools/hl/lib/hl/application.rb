require 'httpclient'
require 'json'
require 'pathname'
require 'zlib'
require 'archive/tar/minitar'
include Archive::Tar

module HL
  class Application
    def initialize(argv)
      @name = 'hl'
      @endpoint = 'http://localhost:3000'
      @hatchlearn_directory_name = '.hatchlearn'
      #@params, @files = parse_options(argv)

      #@display        = RCat::Display.new(@params)
    end

    def run
      if ARGV.length == 0
        puts banner
        exit 1
      end
      start = ARGV[0]
      case start
      when 'login'
        command_login(ARGV[1,ARGV.length])
      when 'new'
        command_new(ARGV[1,ARGV.length])
      when 'serve'
        command_serve(ARGV[1,ARGV.length])
      when 'sync'
        command_sync(ARGV[1,ARGV.length])
      end
    end

    def command_login(args)
      puts 'Login Sucessfull!'
    end

    def command_new(args)
      if args.length == 0
        puts "Usage: #{@name} new <REPOSITORY_NAME>"
        exit 1
      end
      library_name = args[0]
      args, params = gather_args_new
      if params['type'].nil?
        params['type'] = 'public'
      end
      creation_response = post('/libraries', name: library_name)
      creation_json = JSON.parse(creation_response.content)
      library_id = creation_json['library']['id']
      Dir.mkdir("./#{library_name}")
      Dir.mkdir("./#{library_name}/learning_modules")
      Dir.mkdir("./#{library_name}/learning_paths")
      Dir.mkdir("./#{library_name}/learning_assets")
      Dir.mkdir("./#{library_name}/#{@hatchlearn_directory_name}")
      File.open("./#{library_name}/#{@hatchlearn_directory_name}/library_id", 'w') { |file| file.write(
        "#{library_id}") }
      File.open("./#{library_name}/#{@hatchlearn_directory_name}/servers", 'w') { |file| file.write(
        "") }
      File.open("./#{library_name}/.gitignore", 'w') { |file| file.write("""
# hatchlearn configuration files
.hatchlearn/
""") }
    end

    def command_serve(args)
      args, params = gather_args_serve
      if args.length < 2
        puts "usage: hl serve PATH_TO_LEARNING_PATH"
        exit 1
      end
      post('/servers', learning_path_name: args[1].split('/')[1])
    end

    def get(dir, *args)
      HTTPClient.get(@endpoint + dir, *args)
    end

    def post(dir, *args)
      HTTPClient.post(@endpoint + dir, *args)
    end

    def put(dir, *args)
      HTTPClient.put(@endpoint + dir, *args)
    end

    def hatchlearn_directory
      root_directory + @hatchlearn_directory_name
    end

    def library_id_file
      hatchlearn_directory + 'library_id'
    end

    def id
      result = nil
      library_id_file.open { |file| result = file.read.to_i }
      result
    end

    def root_directory
      current = Pathname.new(Dir.pwd)
      while not current.children.member?(current + @hatchlearn_directory_name)
        if current.root?
          return nil
        else
          current = current.parent
        end
      end
      return current
    end

    def command_sync(args)
      # hl sync [ BRANCH (defaults to HEAD) ]
      args, params = gather_args_sync
      root_dir = root_directory
      tar_gz_file = File.open("/tmp/#{root_dir.basename}.tar.gz", "wb")
      tgz = Zlib::GzipWriter.new(tar_gz_file)
      Dir.chdir root_dir.parent.realpath.to_s
      Minitar.pack("./#{root_dir.basename}", tgz)
      Dir.chdir root_dir.realpath.to_s
      # It's necessary to reopen because Minitar closes the tgz file.
      response = nil
      File.open("/tmp/#{root_dir.basename}.tar.gz", "rb") do |file|
        response = put("/libraries/#{id}", repository: file)
      end
    end

    def banner
      "#{@name} {command} ..."
    end

    def privacies
      [
        'public',
        'private',
        'sponsored',
        'for_sale']
    end

    def gather_args
      params = {}
      option_parser = OptionParser.new do |opts|
        opts.banner = banner
        opts.separator 'Options:'
        opts.on_tail("-h", "--help", "-H", "Display this help message.") do
          puts opts
          exit 1
        end
        yield opts, params
      end

      args = option_parser.parse(ARGV)
      [args, params]
    end

    def gather_args_serve
      gather_args do |opts, params|
        opts.on('-s', '--server [Server]') do |server|
          params['server'] = server
        end
      end
    end

    def gather_args_new
      gather_args do |opts, params|
        opts.on('--privacy [Privacy]', ['public', 'private', 'sponsored', 'for-sale']) do |type|
          params['type'] = type
        end
      end
    end

    def gather_args_sync
      gather_args do |opts, params|

        opts.on('-l', '--library [Privacy]') do |library|
          params['library'] = library
        end
      end
    end

  end
end
