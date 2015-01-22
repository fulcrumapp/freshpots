express    = require 'express'
logfmt     = require 'logfmt'
bodyParser = require 'body-parser'
request    = require 'request'

constants = require './constants'

port = Number process.env.PORT or 5000

app = express()

app.use logfmt.requestLogger()
app.use bodyParser.json()
app.use bodyParser.urlencoded()

app.get '/', (req, res) ->
  res.send 'You should POST to me'

app.post '/', (req, resp) ->
  payload = req.body
  processPayload payload
  resp.send "Thanks Fulcrum. You're the best!"

app.listen port, ->
  console.log 'Listening on port ' + port

processPayload = (payload) ->
  unless payload.data.form_id is constants.form_id
    console.log 'Ignoring webhook because form id'
    return

  unless payload.type is 'record.create'
    console.log 'Ignoring webhook because type was not record.create'
    return

  console.log 'Processing webhook'

  person          = payload.data.created_by
  coffee_type     = payload.data.form_values[constants.form_keys.coffee_type]
  brewing_status  = payload.data.form_values[constants.form_keys.brewing_status]

  if brewing_status is 'brewing'
    chat_string = "Fresh pot! #{person} started brewing some #{coffee_type} coffee.  Give it a couple of minutes before you make a run for it."
  else
    chat_string = "Fresh pot! #{person} brewed some #{coffee_type} coffee, and it's ready to drink."

  console.log chat_string
  postToSlack chat_string

postToSlack = (chat_string) ->
  data =
    channel    : '#hq'
    text       : chat_string
  headers =
    'Content-Type': 'application/json'
  options =
    url     : "https://spatialnetworks.slack.com/services/hooks/incoming-webhook?token=#{constants.slack_api_token}"
    JSON    : data
    headers : headers

  console.log options.url
  callback = ->
  request options, callback