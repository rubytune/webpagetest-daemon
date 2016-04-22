require 'web_page_test'

module WebPageTestDaemon
  class TestResultsJob
    @queue = :web_page_test_jobs

    def self.perform(job)
      server = job.fetch("webpagetest_server")
      tests = job["test_ids"].map{ |id| WebPageTest::Test.new(server, id) }
      github.post(job.fetch("pull_request_comments"),
                  body: WebPageTest::Summary.create_comment(tests))
    end

    private

    def self.github
      @github ||= Octokit::Client.new(access_token: ENV["GITHUB_ACCESS_TOKEN"])
    end
  end
end
