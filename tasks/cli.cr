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
        parser.on("--init", "Sets up the initial files") do
          report_changes(generate_initial_setup)
          puts report_change("Done setting up files.", "→")
        end
      end
    end

    private def generate_initial_setup
      LuckyTemplate.write!(Path["."]) do |dir|
        dir.add_file("config/lucky_vite.json", lucky_vite_json)
        dir.add_file("vite.config.js", vite_config_js)
        dir.add_file("src/js/entry/main.js", entry_main_js)
        dir.add_file("src/css/main.css", entry_main_css)
      end
    end

    private def report_changes(folder)
      LuckyTemplate.snapshot(folder).keys.each do |name|
        puts report_change(name)
      end
    end

    private def report_change(message, symbol = "✓".colorize.green)
      String.build do |io|
        io << symbol
        io << " "
        io << message
      end
    end

    private def lucky_vite_json
      <<-JSON
      {
        "aliases": {
          "@css": "src/css",
          "@js": "src/js",
          "@images": "src/images",
          "@fonts": "src/fonts"
        },
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
