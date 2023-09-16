# Stripe.js faker script
# our script calls Stripe.card.createToken $form, callBack -- our goal is to spoof that

fakeStripe = ->
  this.setPublishableKey = (input) ->
  this.card = new fakeCard()
  return this

fakeCard = ->
  this.createToken = (form, callback) ->
    status = '200'
    response = fakeStripeResponse()
    callback(status, response)
  return this

fakeStripeResponse = ->
  token = $("meta#mock-stripe-token").data("stripe-token")
  response = {
              id: token,
              created: 1,
              livemode: false,
              type: "card",
              object: "token",
              used: false,
              card: {
                name: null,
                address_line1: "12 Main Street",
                address_line2: "Apt 42",
                address_city: "Palo Alto",
                address_state: "CA",
                address_zip: "94301",
                address_country: "US",
                country: "US",
                exp_month: 2,
                exp_year: 2016,
                last4: "4242",
                object: "card",
                brand: "Visa",
                funding: "credit"
              }
            }

test = ->
  Stripe.card.createToken "whatever", validateCCandEnableForm
sampleCallback = (status, response) ->
  console.log "callback received with token: "
  console.log response.id
# $(document).ready(test)


window.Stripe = new fakeStripe()
