require 'sinatra'
require 'json'
require 'slack-notifier'
require 'tilt/erubis'

ENV['SLACK_WEBHOOK_URL'] =      'https://hooks.slack.com/services/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'
ENV['SLACK_WEBHOOK_URL_TEST'] = 'https://hooks.slack.com/services/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'

SLACK_NOTIFIER = {
  test: Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL_TEST']),
  default: Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL']),
}

put '/:template' do
  template = params[:template]

  begin
    payload = JSON.parse(request.body.read)
    # payload is formatted like:
    # {
    #   "column_names": ["foo", "bar"],
    #   "data": [[1,2,3], ['a', 'b', 'c']],
    #   "column_type": ["long", "string"]
    # }
    # See http://docs.treasuredata.com/articles/result-into-web
    @td = Hash[payload['column_names'].zip(payload['data'])]
    s = erb template.to_sym, :layout => false

    slack_notifier = nil
    if params.has_key?('env')
      if SLACK_NOTIFIER[params['env'].to_sym]
        slack_notifier = SLACK_NOTIFIER[params['env'].to_sym]
      else
        puts "no slack environment definition for '#{params['env']}'. Falling back to 'default'."
      end
    end
    if slack_notifier.nil?
      slack_notifier = SLACK_NOTIFIER[:default]
    end
    slack_notifier.ping(s)
  rescue => e
    STDERR.puts e.backtrace
  end
end

get '/' do
  """
  <head>
  </head>
  <body>
  <div>Use <tt><strong>PUT</strong> /template_name</tt></div>
  </body>
  """
end

