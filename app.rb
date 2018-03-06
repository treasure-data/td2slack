require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'slack-notifier'

SLACK_NOTIFIER = {
  test: ENV['SLACK_WEBHOOK_URL_TEST'] && Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL_TEST']),
  default: ENV['SLACK_WEBHOOK_URL'] && Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL']),
}

unless SLACK_NOTIFIER[:default]
  puts "You must set the SLACK_WEBHOOK_URL environment variable with the Slack incoming webhook URL."
  exit 1
end

# TD's job result HTTP PUT payload is formatted like this:
# {
#   "column_names": ["foo", "bar"],
#   "data": [[1,2,3], ['a', 'b', 'c']],
#   "column_type": ["long", "string"]
# }
# See http://docs.treasuredata.com/articles/result-into-web

def slack_notifier(params)
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
  slack_notifier
end

put '/:template' do
  template = params[:template]

  begin
    payload = JSON.parse(request.body.read)
    @td = Hash[payload['column_names'].zip(payload['data'].transpose)]
    s = erb template.to_sym, :layout => false
    slack_notifier(params).ping(s)
  rescue => e
    STDERR.puts e.backtrace
  end
end

put '/' do
  begin
    payload = JSON.parse(request.body.read)
    @td = Hash[payload['column_names'].zip(payload['data'].transpose)]
    s = erb :root, :layout => false
    slack_notifier(params).ping(s)
  rescue => e
    STDERR.puts e.backtrace
  end
end

get '/' do
  """
  <head>
  </head>
  <body>
    <tt>
    <h1>Usage</h1>
      <div style='margin-left:2em'>
        <div>
          <h2><strong>GET /</strong></h2>
          <p>
            Get this help.
          </p>
          <br/>
        </div>
        <div>
          <h2><strong>PUT /</strong></h2>
          <p>
            Forwards a message through Slack.
          </p>
          <p>
            Required payload format and content is for the message to expressed<br/>
            as string value of a column named 'message'.
          </p>
          <div style='margin-left:2em'>
            body:
            <pre>
  {
    \"column_names\":[\"message\"],
    \"data\":[
      [\"message #1\"]
    ],
    \"column_type\":[\"string\"]
  }
            </pre>
          </div>
        </div>
        <br/>

        <div>
          <h2>PUT /:template_name</h2>
          <p>
            Uses any of the implented templates to build and send a through on Slack.
          </p>
          <p>
            Required payload format and content depends on the template implementation.</br>
            The example below applies to the '/streaming_import' template, requiring a<br/>
            single integer value within the a column named 'count'.
          </p>
          <div style='margin-left:2em'>
            body:
            <pre>
  {
    \"column_names\":[\"count\"],
    \"data\":[[123]],
    \"column_type\":[\"long\"]
  }
              </pre>
          </div>
        </div>
      </div>
    </tt>
  </body>
  """
end

