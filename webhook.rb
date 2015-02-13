require 'json'
require 'sinatra'
use Rack::Logger
require 'stripe_event'

Stripe.api_key = ENV['STRIPE_API_KEY']

StripeEvent.subscribe 'invoice.created' do |event|
    logger.info(event)

    invoice = event.data.object
    if invoice.amount_due < 0
        return
    end

    date = Time.at(event.data.object.date).strftime("%b %-d, %Y")
end

post '/_billing_events' do
    data = JSON.parse(request.body.read, symbolize_names: true)
    StripeEvent.instrument(data)
    200
end