require 'json'
require 'sinatra'
require 'stripe_event'
require 'net/http'
require 'uri'

Stripe.api_key = ENV['STRIPE_API_KEY']

def getInvoice(url)
    Net::HTTP.post_form(URI.parse(url), {
        "from" => "Your Name",
        "to" => "To"
    })
end

StripeEvent.subscribe 'invoice.created' do |event|
    puts event

    invoice = event.data.object
    if invoice.amount_due < 0
        return
    end

    date = Time.at(event.data.object.date).strftime("%b %-d, %Y")

    pdf = getInvoice('https://invoice-generator.com')
    puts pdf
end

post '/_billing_events' do
    data = JSON.parse(request.body.read, symbolize_names: true)
    StripeEvent.instrument(data)
    200
end