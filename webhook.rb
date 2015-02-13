require 'json'
require 'sinatra'
require 'stripe_event'
require 'net/http'
require 'uri'
require 'pony'

Stripe.api_key = ENV['STRIPE_API_KEY']

def getInvoice(url)
    Net::HTTP.post_form(URI.parse(url), {
        "from" => "*Your Company*",
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

    # get customer from stripe
    customer = Stripe::Customer.retrieve(invoice.customer)
    puts customer

    # fetch invoice pdf
    pdf = getInvoice('https://invoice-generator.com')
    Pony.mail({
        :to => customer.email,
        :from => 'yourcompany@example.com',
        :subject => 'Invoice from *Your Company*',
        :attachments => {
            "invoice.pdf" => pdf.body
        }
    })
end

post '/_billing_events' do
    data = JSON.parse(request.body.read, symbolize_names: true)
    StripeEvent.instrument(data)
    200
end