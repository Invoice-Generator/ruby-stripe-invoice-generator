require 'json'
require 'sinatra'
require 'stripe_event'
require 'net/http'
require 'uri'
require 'pony'

Stripe.api_key = ENV['STRIPE_API_KEY']

def getInvoice(customer, invoice)
    date = Time.at(invoice.date).strftime("%b %-d, %Y")

    Net::HTTP.post_form(URI.parse("https://invoice-generator.com"), {
        "from" => "*Your Company*",
        "to" => customer.name,
        "number" => invoice.id,
        "payment_terms" => "Auto-Billed - Do Not Pay",
        "date" => date,
        # TODO items
        "notes" => "Thanks for being an awesome customer!",
        "terms" => "No need to submit payment. You will be auto-billed for this invoice."
    })
end

StripeEvent.subscribe 'invoice.created' do |event|
    puts event

    invoice = event.data.object
    if invoice.amount_due < 0
        return
    end

    # get customer from stripe
    customer = Stripe::Customer.retrieve(invoice.customer)
    puts customer

    # fetch invoice pdf
    pdf = getInvoice(customer)

    # send the invoice
    Pony.mail({
        :to => customer.email,
        :from => 'yourcompany@example.com',
        :subject => 'Invoice from *Your Company*',
        :body => "Hi #{customer.name},

A new invoice was created on your account as part of your subscription. Please keep the attached invoice for your records. Have a nice day!

- *Your Company*",
        :attachments => {
            "invoice.pdf" => pdf.body
        },
        :via => :smtp,
        :via_options => {
            :address => ENV['SMTP_SERVER'],
            :port => ENV['SMTP_PORT'],
            :domain => 'heroku.com',
            :user_name => ENV['SMTP_USERNAME'],
            :password => ENV['SMTP_PASSWORD'],
            :authentication => :plain,
            :enable_starttls_auto => true
        }
    })
end

post '/_billing_events' do
    data = JSON.parse(request.body.read, symbolize_names: true)
    StripeEvent.instrument(data)
    200
end