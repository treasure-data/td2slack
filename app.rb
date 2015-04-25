require 'sinatra'
require 'json'
require 'slack-notifier'

SLACK_NOTIFIER = Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL'])

put '/:template' do
  channel = params[:channel]
  template = params[:template]
  begin
    payload = JSON.parse(request.body.read)  
    # payload is formatted like
    # { "column_names": ["foo", "bar"],
    #   "data": [[1,2,3], ['a', 'b', 'c']],
    #   "column_type": ["long", "string"]
    # }
    # See http://docs.treasuredata.com/articles/result-into-web
    @td = Hash[payload['column_names'].zip(payload['data'].transpose)]
    s = erb template.to_sym, :layout => false
    SLACK_NOTIFIER.ping(s) 
  rescue => e
    STDERR.puts e.backtrace
  end
end

