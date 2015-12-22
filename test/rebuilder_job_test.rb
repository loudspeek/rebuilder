require 'test_helper'

describe RebuilderJob do
  class RebuilderJob
    def with_git_repo(repo, options, &block)
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p('data/Australia/Senate')
          block.call(dir)
        end
      end
    end

    def run(*args)
      'Build output'
    end
  end

  around { |test| VCR.use_cassette('countries_json', &test) }

  it 'rebuilds the selected source' do
    RebuilderJob.new.perform('Australia', 'Senate')
    assert_equal 1, CreatePullRequestJob.jobs.size
    args = CreatePullRequestJob.jobs.first['args']
    assert args[0].match(/australia-senate-\d+/)
    assert_equal 'Australia: refresh data', args[1]
    expected = <<-EXPECTED.chomp
Automated data refresh for Australia - Senate

#### Output

```
Build output
```
    EXPECTED
    assert_equal expected, args[2]
  end
end
