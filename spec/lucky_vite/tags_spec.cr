require "../spec_helper"

describe LuckyVite::Config do
  before_each do
    ENV["LUCKY_ENV"] = "development"
  end

  describe "#vite_client_tag" do
    it "renders the vite client tag in development" do
      contents = LuckyViteClientTagTestPage.new(context).render.to_s

      contents.should contain(%(<script src="http://127.0.0.1:3010/@vite/client" type="module">))
      contents.should contain(%(<script src="http://127.0.0.1:3010/@vite/client" data-client="tag" type="module"></script>))
    end

    it "renders nothing in production" do
      ENV["LUCKY_ENV"] = "production"
      LuckyViteClientTagTestPage.new(context).render.to_s.should eq("")
    end
  end

  describe "#vite_entry_tags" do
    it "renders the entry script loaded from the vite server in development" do
      contents = LuckyViteEntryTagsPage.new(context).render.to_s

      contents.should contain %(<script src="http://127.0.0.1:3010/@vite/client" data-entry="tags" type="module"></script>)
      contents.should contain %(<script src="http://127.0.0.1:3010/main.js" type="module" data-entry="tags"></script>)
    end

    it "renders the entry script an styles from the manifest in production" do
      ENV["LUCKY_ENV"] = "production"
      contents = LuckyViteEntryTagsPage.new(context).render.to_s

      contents.should_not contain "@vite/client"
      contents.should contain %(<script src="/assets/js/main.2d2335c4.js" type="module" data-entry="tags"></script>)
      contents.should contain %(<link href="/assets/css/main.75de05d8.css" rel="stylesheet" media="screen" data-entry="tags">)
    end
  end

  describe "#vite_js_link" do
    it "renders a script loaded from the vite server in development" do
      contents = LuckyViteJsLinkPage.new(context).render.to_s

      contents.should contain %(<script src="http://127.0.0.1:3010/main.js" type="module" data-js="link"></script>)
    end

    it "renders a script loaded from the manifest in production" do
      ENV["LUCKY_ENV"] = "production"
      contents = LuckyViteJsLinkPage.new(context).render.to_s

      contents.should contain %(<script src="/assets/js/main.2d2335c4.js" type="module" data-js="link"></script>)
    end
  end

  describe "#vite_css_links" do
    it "renders nothing in development" do
      LuckyViteCssLinkPage.new(context).render.to_s.should eq ""
    end

    it "renders a style loaded from the manifest in production" do
      ENV["LUCKY_ENV"] = "production"
      contents = LuckyViteCssLinkPage.new(context).render.to_s

      contents.should contain %(<link href="/assets/css/main.75de05d8.css" rel="stylesheet" media="screen" data-css="link">)
    end
  end

  describe "#vite_react_refresh_tag" do
    it "renders a react refresh tag in development" do
      contents = LuckyViteReactRefreshTagTestPage.new(context).render.to_s

      contents.should contain %(<script type="module">  import RefreshRuntime from 'http://127.0.0.1:3010/@react-refresh')
    end

    it "renders nothing in production" do
      ENV["LUCKY_ENV"] = "production"
      LuckyViteReactRefreshTagTestPage.new(context).render.to_s.should eq("")
    end
  end
end

class LuckyViteClientTagTestPage
  include Lucky::HTMLPage

  def render
    vite_client_tag
    vite_client_tag data_client: "tag"
    view
  end
end

class LuckyViteEntryTagsPage
  include Lucky::HTMLPage

  def render
    vite_entry_tags "main.js", data_entry: "tags"
    view
  end
end

class LuckyViteJsLinkPage
  include Lucky::HTMLPage

  def render
    vite_js_link "main.js", data_js: "link"
    view
  end
end

class LuckyViteCssLinkPage
  include Lucky::HTMLPage

  def render
    vite_css_links "main.js", data_css: "link"
    view
  end
end

class LuckyViteReactRefreshTagTestPage
  include Lucky::HTMLPage

  def render
    vite_react_refresh_tag
    vite_react_refresh_tag data_react: "refresh-tag"
    view
  end
end

private def context : HTTP::Server::Context
  io = IO::Memory.new
  request = HTTP::Request.new("GET", "/")
  response = HTTP::Server::Response.new(io)
  HTTP::Server::Context.new request, response
end
