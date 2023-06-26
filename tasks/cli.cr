require "colorize"
require "option_parser"

module LuckyVite
  struct Cli
    enum Action
      Init
    end

    def call
      parse_options
    rescue e : Exception
      puts e.message.colorize.red
    ensure
      exit
    end

    private def parse_options
      action = nil
      entry_name = "main"

      options_parser = OptionParser.parse do |parser|
        parser.banner = "Usage: bin/lucky_vite [subcommand] [arguments]"
        parser.on("init", "Set up initial files") do
          action = Action::Init
          parser.banner = "Usage: bin/lucky_vite init [arguments]"
          parser.on("-n NAME", "--name=NAME", "Set an entry script name") do |name|
            entry_name = name
          end
        end
        parser.on("-h", "--help", "Show this help") do
          puts parser
          exit
        end
      end

      case action
      when Action::Init
        generate_initial_setup(entry_name)
      else
        puts options_parser
        exit 1
      end
    end

    private def generate_initial_setup(name)
      {
        "config/lucky_vite.json"  => lucky_vite_json,
        "vite.config.js"          => vite_config_js,
        "src/js/entry/#{name}.js" => entry_main_js(name),
        "src/css/#{name}.css"     => entry_main_css,
      }.each { |file, content| generate_file(file, content) }

      report_task("Done setting up files.", "→")
    end

    private def generate_file(file, content)
      ensure_dir_exists(file)

      if File.exists?(file)
        report_task(
          "Existing".colorize.yellow.to_s + " " + file,
          "⸰".colorize.yellow
        )
      else
        File.write(file, content)
        report_task("Creating".colorize.green.to_s + " " + file)
      end
    end

    private def ensure_dir_exists(file)
      dir = File.dirname(file)
      Dir.mkdir_p(dir) unless File.directory?(dir)
    end

    private def report_task(message, symbol = "✓".colorize.green)
      puts String.build { |io|
        io << symbol
        io << " "
        io << message
      }
    end

    private def lucky_vite_json
      <<-JSON
      {
        "aliases": [
          "css",
          "js",
          "images",
          "fonts"
        ],
        "outDir": "public/assets",
        "entry": "entry",
        "host": "127.0.0.1",
        "port": 3010,
        "root": "src/js"
      }

      JSON
    end

    private def vite_config_js
      <<-JS
      import { defineConfig } from 'vite'
      import LuckyPlugin from 'vite-plugin-lucky'

      export default defineConfig({
        plugins: [
          LuckyPlugin()
        ]
      })

      JS
    end

    private def entry_main_js(name)
      <<-JS
      // Add this line to the beginning of every entry script
      import 'vite/modulepreload-polyfill'

      // Add static assets to the manifest (optional)
      import.meta.glob([
        // '@images/**', // <- alias to src/images
        // '@fonts/**',  // <- alias to src/fonts
      ])

      // Point to src/css/#{name}.css
      import '@css/#{name}.css'

      console.log('🚀️ Lucky Vite!')

      JS
    end

    private def entry_main_css
      <<-CSS
      /* Add some styling and enjoy HMR */
      CSS
    end
  end
end
