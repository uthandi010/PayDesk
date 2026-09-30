# PayDesk

A subscription billing and invoicing SaaS — the part of a product that charges customers on a
schedule, sends them invoices, and tells the business how much money is actually coming in.

Built to demonstrate real billing logic, not just CRUD: a pluggable payment-gateway abstraction (so
the whole app runs with zero third-party accounts), all-or-nothing invoice/payment bookkeeping that
never lets a subscription's status drift from what was actually charged, generated PDF invoices, and
a revenue dashboard that normalizes monthly and yearly plans onto a common MRR figure.

## Features

- **Auth** — register/login with JWT, `has_secure_password` (bcrypt)
- **Customers & plans** — each account manages its own customers and the plans it sells them
- **Subscriptions that actually bill** — subscribing a customer to a plan immediately creates and
  charges their first invoice; a declined charge leaves the subscription `past_due` instead of
  silently `active`
- **A pluggable payment gateway** — `PaymentGateways::Base` defines the interface; the app ships
  with `FakeGateway`, a deterministic stand-in that declines charges for two documented "magic"
  customer email domains (the same trick real sandboxes use with test card numbers) so both the
  success and failure paths are exercisable and tested without any real processor
- **Manual renewal** — `POST /subscriptions/:id/renew` advances a subscription into its next billing
  period and bills it, standing in for what a scheduled job would do in production
- **PDF invoices** — a real downloadable PDF per invoice, generated with Prawn
- **A public "pay your invoice" link** — each invoice gets an unguessable token
  (`/invoice/:token`); a customer can view and pay it with no account, the way a real invoicing
  email link works
- **Revenue dashboard** — MRR (yearly plans normalized to 1/12th their price), active subscriptions,
  outstanding invoices, and a zero-filled monthly revenue chart

## Stack

| Layer | Tech |
| --- | --- |
| API | Ruby on Rails 8 (API-only), SQLite |
| Auth | JWT bearer tokens, `has_secure_password` (bcrypt) |
| PDFs | Prawn |
| Client | React 19, React Router, Recharts, Vite |
| Tests | RSpec + FactoryBot (54 examples), Vitest + Testing Library (26 examples) |

No paid services or cloud accounts are required to run this locally.

## Project layout

```
server/   # Rails API - models, controllers, and the Billing/PaymentGateways service objects
client/   # React frontend - the owner dashboard and the public invoice-pay page
```

## Running it locally

### API

```bash
cd server
bundle install
bin/rails db:migrate
bin/rails server -p 3000
```

Run the backend tests:

```bash
cd server
bundle exec rspec
```

### Client

```bash
cd client
cp .env.example .env.local   # adjust VITE_API_BASE_URL if needed
npm install
npm run dev
```

Run the frontend tests:

```bash
cd client
npm test
```

## How billing actually works

`Billing::InvoiceCharger` (`server/app/services/billing/invoice_charger.rb`) is the one place in the
app that talks to a payment gateway. Every invoice charge - the first one at subscription creation,
a manual retry, a renewal, or a customer paying their own public link - goes through it, so an
invoice's status, its subscription's status, and its `Payment` history can never drift apart:

1. Ask the configured gateway to charge the invoice's `customer` for its `amount_cents`.
2. Record a `Payment` either way (`succeeded` or `failed`, with the gateway's reference or failure
   reason).
3. On success: mark the invoice `paid`, stamp `paid_at`, and bring a `past_due` subscription back to
   `active`.
4. On failure: leave the invoice `open` and mark the subscription `past_due` (unless it's already
   `canceled`) - it's never silently treated as paid.

`PaymentGateways::FakeGateway` is the only gateway PayDesk ships with, so the whole app - including
CI - runs end to end with no API keys. It succeeds for any ordinary customer, and deterministically
declines a charge for a customer at `@declined.test` (`card_declined`) or `@insufficientfunds.test`
(`insufficient_funds`), so both outcomes are demoable and tested on demand rather than left to
chance. Swapping in a real processor later means writing one class under
`app/services/payment_gateways` that implements `#charge` the same way, and changing the one line in
`config/initializers/payment_gateway.rb` that wires it up - nothing else in the app references a
gateway class by name.

## Notes on the design

- **MRR normalizes onto a common monthly footing.** A yearly plan counts as 1/12th its price per
  month toward MRR rather than being summed at face value, which is what actually makes "Monthly
  Recurring Revenue" mean something once a business sells more than one billing interval.
- **An invoice's public link is a 32-byte random token, not its database id.** Knowing the token is
  what stands in for authorization on the public pay page - the same shape a real invoicing email
  link takes.
- **Renewal is manual, not scheduled.** In production, advancing every subscription into its next
  period would run as a recurring background job; here it's exposed as an explicit action
  (`Billing::SubscriptionRenewer`) so the recurring part of "recurring billing" is reachable and
  testable without a job scheduler running in the background.
- This app is deliberately single-account (no teams/staff), unlike some of the other projects in
  this set - billing is usually one owner's concern, and it keeps the interesting logic (the gateway
  abstraction, invoice bookkeeping) the focus instead of authorization plumbing.

## What's intentionally left out

This is a portfolio-scale MVP, not a production billing system. A few things that would come next:
automatic scheduled renewals (a real cron/worker calling `SubscriptionRenewer` for every
subscription past its `current_period_end`), dunning emails for a `past_due` subscription, prorated
upgrades/downgrades mid-cycle, and a real payment gateway integration behind the existing
`PaymentGateways::Base` interface.
