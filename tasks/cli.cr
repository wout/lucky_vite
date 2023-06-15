require "colorize"
require "option_parser"
require "lucky_template"

module LuckyVite
  struct Cli
    def call
      ensure_arguments
      parse_options
    rescue e : Exception
      puts e.message.colorize.red
    ensure
      exit
    end

    private def ensure_arguments
      return unless ARGV.empty?

      raise <<-ERROR
      Run "bin/lucky_vite --init" to generate the initial files
      ERROR
    end

    private def parse_options
      OptionParser.parse do |parser|
        parser.banner = "Usage: bin/lucky_vite [subcommand] [arguments]"
        parser.on("init", "Set up initial files") do
          parser.banner = "Usage: bin/lucky_vite init [arguments]"
          generate_initial_setup("main")
          parser.on("-n NAME", "--name=NAME", "Set an entry script name") do |name|
            generate_initial_setup(name)
          end
        end
      end
    end

    private def generate_initial_setup(name)
      LuckyTemplate.write!(Path["."]) do |dir|
        {
          "config/lucky_vite.json"  => lucky_vite_json,
          "vite.config.js"          => vite_config_js,
          "src/js/entry/#{name}.js" => entry_main_js,
          "src/css/#{name}.css"     => entry_main_css,
        }.each do |file, content|
          if File.exists?(file)
            report_task(
              file + " " + "exists".colorize.yellow.bold.to_s,
              "⸰".colorize.yellow
            )
          else
            dir.add_file(file, content)
            report_task(file + " " + "created".colorize.yellow.bold.to_s)
          end
        end
      end
      report_task("Done setting up files.", "→")
    end

    private def report_task(message, symbol = "✓".colorize.green)
      String.build do |io|
        io << symbol
        io << " "
        io << message
      end
    end

    private def lucky_vite_json
      <<-JSON
      {
        "aliases": [
          "@css"
          "@js"
          "@images"
          "@fonts"
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

    private def entry_main_js
      <<-JS
      // Add this line to the beginning of every entry script
      import 'vite/modulepreload-polyfill'

      // Add static assets to the manifest (optional)
      import.meta.glob([
      // '@images/**', // <- alias to src/images
      // '@fonts/**',  // <- alias to src/fonts
      ])

      // Point to src/css/main.css
      import '@css/main.css'

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
