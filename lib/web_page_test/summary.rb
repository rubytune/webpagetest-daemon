
require 'erb'

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
      ERB.new(erb).result(b)
    end

    def self.create_comment(tests)
      tests.map{ |test| create_gist(test) }.join("\n\n")
    end
  end
end
