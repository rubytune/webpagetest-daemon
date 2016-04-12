
require 'web_page_test'

module WebPageTestDaemon
  class StatusCheckJob
    @queue = :web_page_test_jobs

    def self.perform(job)
      server = "http://www.webpagetest.org/"

      tests = job["test_ids"].map{ |id| WebPageTest::Test.new(server, id) }

      if tests.all?(&:complete?)
        report(job, tests)
      else
        Resque.enqueue_in(30, StatusCheckJob, job)
      end
    end

    def self.report(job, tests)
      github.post(job["pull_request_comments"],
                  body: WebPageTest::Summary.create_comment(tests))
    end

    private

    def github
      @github ||= Octokit::Client.new(access_token: ENV["GITHUB_ACCESS_TOKEN"])
    end
  end
end
