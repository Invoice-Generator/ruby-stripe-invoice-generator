require 'json'
require 'sinatra'
require 'stripe_event'
require 'net/http'
require 'uri'
require 'pony'

Stripe.api_key = ENV['STRIPE_API_KEY']

def genInvoice(customer, invoice)
    uri = URI('https://invoice-generator.com')

    from = "Invoiced
701 Brazos St
Austin, TX 78748"

    # TODO could get address from metadata
    to = customer.description

    items = invoice.lines.data.map do |line|
        name = line.type == 'subscription' ? line.plan.name : line.description
        {
            "name" => name,
            "quantity" => line.quantity,
            "unit_cost" => line.amount / 100
        }
    end

    # TODO discounts

    params = {
        "logo" => "https://invoiced.com/img/logo-square.png",
        "from" => from,
        "to" => to,
        "currency" => invoice.currency,
        "number" => invoice.id,
        "payment_terms" => "Auto-Billed - Do Not Pay",
        "date" => Time.at(invoice.date).strftime("%b %-d, %Y"),
        "items" => items,
        "fields" => {
            "tax" => invoice.tax_percent ? "%" : false
        },
        "tax" => invoice.tax_percent,
        "notes" => "Thanks for being an awesome customer!",
        "terms" => "No need to submit payment. You will be auto-billed for this invoice."
    }
    
    req = Net::HTTP::Post.new uri
    req['Content-Type'] = 'application/json'
    req.body = params.to_json

    res = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.ssl_version = :SSLv3
        http.request req
    end
end

StripeEvent.subscribe 'invoice.created' do |event|
    invoice = event.data.object
    puts invoice
    if invoice.amount_due == 0
        return "blank invoice"
    end

    customer = Stripe::Customer.retrieve(invoice.customer)
    pdf = genInvoice(customer, invoice)
    puts customer

    # send the invoice
    body = "Hi " + customer.description + ",

A new invoice was created on your account as part of your subscription. Please keep the attached invoice for your records. Have a nice day!

- Invoiced"

    Pony.mail({
        :to => customer.email,
        :from => 'yourcompany@example.com',
        :subject => 'Invoice from Invoiced'
        :body => body,
        :attachments => {
            "invoice.pdf" => pdf.body,
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