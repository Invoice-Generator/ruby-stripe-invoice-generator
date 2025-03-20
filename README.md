Ruby Stripe Invoice Generator
=====
Generate and send invoices from Stripe webhooks in Ruby with the [Invoice Generator API](https://github.com/Invoiced/invoice-generator-api).

## About

This simple Stripe webhook was built using Sinatra. It emails an invoice to your customer whenever the `invoice.created` webhook is received from Stripe. It uses the invoice-generator.com API to produce the PDF.

## Setup

Enter your company details into `webhook.rb`. Then you can host this app somewhere like Heroku and add a Stripe webhook for `https://example.com/_billing_events`.