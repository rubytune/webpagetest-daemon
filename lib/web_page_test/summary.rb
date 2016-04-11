
require 'erb'

require 'octokit'

module WebPageTest
  class Summary
    def self.create_gist(test)
      erb =
<<-EOF
## [<%= test_url %>](<%= webpagetest_url %>)

                                         | Waterfall                                                     | Screen Shot
-----------------------------------------|---------------------------------------------------------------|--------------------------------------------------------------
First View (<%= sprintf('%.2fs', first_view.load_time/1000.0) %>)   | <img src="<%= first_view.waterfall %>" width="250">  | <img src="<%= first_view.screenshot %>" width="250" height="160">
Repeat View (<%= sprintf('%.2fs', repeat_view.load_time/1000.0) %>) | <img src="<%= repeat_view.waterfall %>" width="250"> | <img src="<%= first_view.screenshot %>" width="250" height="160">
EOF

      b = test.instance_eval{ binding }

      github = Octokit::Client.new
      gist = github.create_gist(
        files: {
          "webpagetest-#{test.id}.md" => { content: ERB.new(erb).result(b) }
        }
      )

      gist[:html_url]
    end
  end
end
