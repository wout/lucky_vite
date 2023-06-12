require "../spec_helper"

describe LuckyVite::Config do
  before_each do
    ENV["LUCKY_ENV"] = "development"
  end

  describe "#vite_client_tag" do
    it "renders the vite client tag in development" do
      LuckyViteClientTagTestPage.new(context).render.to_s
        .should eq the_vite_client_tag
    end

    it "renders nothing in production" do
      ENV["LUCKY_ENV"] = "production"
      LuckyViteClientTagTestPage.new(context).render.to_s.should eq("")
    end
  end

  describe "#vite_entry_tags" do
    it "renders the entry script loaded from the vite server in development" do
      contents = LuckyViteEntryTagsPage.new(context).render.to_s

      contents.should contain the_vite_client_tag
      contents.should contain the_vite_entry_tag("main.js")
    end

    it "renders the entry script an styles from the manifest in production" do
      ENV["LUCKY_ENV"] = "production"
      contents = LuckyViteEntryTagsPage.new(context).render.to_s

      contents.should_not contain the_vite_client_tag
      contents.should contain the_script_tag("main.2d2335c4.js")
      contents.should contain the_style_tag("main.75de05d8.css")
    end
  end
end

class LuckyViteClientTagTestPage
  include Lucky::HTMLPage

  def render
    vite_client_tag
    view
  end
end

class LuckyViteEntryTagsPage
  include Lucky::HTMLPage

  def render
    vite_entry_tags "main.js"
    view
  end
end

private def context : HTTP::Server::Context
  io = IO::Memory.new
  request = HTTP::Request.new("GET", "/")
  response = HTTP::Server::Response.new(io)
  HTTP::Server::Context.new request, response
end

private def the_vite_client_tag
  %(<script src="http://127.0.0.1:3010/@vite/client" type="module"></script>)
end

private def the_vite_entry_tag(name)
  %(<script src="http://127.0.0.1:3010/#{name}" type="module"></script>)
end

private def the_script_tag(name)
  %(<script src="/assets/js/#{name}" type="module"></script>)
end

private def the_style_tag(name)
  %(<link href="/assets/css/#{name}" rel="stylesheet" media="screen">)
end
