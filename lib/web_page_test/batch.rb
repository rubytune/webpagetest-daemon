
require 'optparse'
require 'net/http'

require 'web_page_test/test'
require 'web_page_test/summary'

module WebPageTest
  class Batch
    attr_accessor :server, :api_key, :pingback_url, :notify_email
    attr_accessor :nruns, :first_view_only, :screenshots, :javascript
    attr_accessor :mobile, :mobile_dpr

    alias_method :first_view_only?, :first_view_only
    alias_method :screenshots?, :screenshots
    alias_method :javascript?, :javascript
    alias_method :mobile?, :mobile

    attr_reader :status_url

    def initialize
      @server = "http://www.webpagetest.org/"
      @screenshots = true
      @javascript = true
    end

    def run(test_url)
      @status_url = nil

      query = { url: test_url }
      query[:k] = api_key if api_key
      query[:pingback] = pingback_url if pingback_url
      query[:notify] = notify_email if notify_email
      query[:runs] = runs if nruns
      query[:fvonly] = '1' if first_view_only?
      query[:noimages] = '1' unless screenshots?
      query[:noscript] = '1' unless javascript?
      query[:mobile] = '1' if mobile?
      query[:dpr] = mobile_dpr if mobile_dpr

      uri = URI("#{server}/runtest.php")
      api_response = Net::HTTP.post_form(uri, query)

      if api_response.is_a?(Net::HTTPFound)
        api_response['Location'].match(%r{result/([^/]+)})[1]
      end
    end

    def option_parser
      @option_parser ||= OptionParser.new do |opts|
        opts.on('--server URL'){ |url| self.server = url }

        opts.on('--api-key KEY', '-k'){ |key| self.api_key = key }

        opts.on('--pingback URL'){ |url| self.pingback_url = url }

        opts.on('--notify EMAIL'){ |email| self.notify_email = email }

        opts.on('--runs N', '-n'){ |n| self.nruns = n.to_i }

        opts.on('--first-view', '-q'){ self.first_view_only = true }

        opts.on('--no-screenshots'){ self.screenshots = false }

        opts.on('--no-javascript'){ self.javascript = false }

        opts.on('--mobile', '-m'){ self.mobile = true }

        opts.on('--mobile-dpr N'){ |n| self.mobile_dpr = n.to_i }

        opts.on('--status ID') do |id|
          test = Test.new(server, id)

          require 'pry'
          binding.pry
        end

        opts.on('--gist ID') do |id|
          test = Test.new(server, id)
          puts WebPageTest::Summary.create_gist(test)
        end
      end
    end
  end
end
