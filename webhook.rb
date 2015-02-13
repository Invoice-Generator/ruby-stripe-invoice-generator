require 'json'
require 'sinatra'
require 'stripe_event'
require 'logger'

enable :logging

Stripe.api_key = ENV['STRIPE_API_KEY']

class InvoiceCreated
  def call(event)
    invoice = event.data.object
    if invoice.amount_due < 0
        return
    end

    date = Time.at(event.data.object.date).strftime("%b %-d, %Y")
  end
end

class BillingEventLogger
  def initialize(logger)
    @logger = logger
  end

  def call(event)
    @logger.info "BILLING:#{event.type}:#{event.id}"
  end
end

StripeEvent.configure do |events|
    events.all BillingEventLogger.new(logger)
    events.subscribe 'invoice.created', InvoiceCreated.new
end

post '/_billing_events' do
    data = JSON.parse(request.body.read, symbolize_names: true)
    StripeEvent.instrument(data)
    200
end