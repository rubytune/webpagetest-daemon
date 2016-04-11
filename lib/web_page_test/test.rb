
require 'net/http'
require 'json'
require 'ostruct'

module WebPageTest
  class Test
    class Results < OpenStruct; end

    attr_reader :server, :id, :api_data

    def initialize(server, test_id)
      @server = server
      @id = test_id

      fetch_api_data
    end

    def test_url
      api_data['data']['testUrl']
    end

    def webpagetest_url
      "#{server}/result/#{id}/"
    end

    def first_view
      @first_view ||= view_data(api_data['data']['runs']['1']['firstView'])
    end

    def repeat_view
      @repeat_view ||= view_data(api_data['data']['runs']['1']['repeatView'])
    end

    protected

    def view_data(view)
      Results.new(
        waterfall: view['images']['waterfall'],
        screenshot: view['images']['screenShot'],
        load_time: view['loadTime']
      )
    end

    def fetch_api_data
      url = URI("#{server}/result/#{id}/?f=json")
      resp = Net::HTTP.get_response(url)

      if resp.is_a?(Net::HTTPOK) && resp.code == '200'
        @api_data = JSON.parse(resp.body)
      end
    end
  end
end
