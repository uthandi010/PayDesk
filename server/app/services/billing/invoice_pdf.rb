module Billing
  # Renders a one-page PDF for an invoice using Prawn. Kept deliberately
  # simple - a real invoicing product would add a logo, tax lines, and a
  # templating layer, but this covers what a customer actually needs to see:
  # who's being billed, for what, how much, and whether it's been paid.
  class InvoicePdf
    def initialize(invoice)
      @invoice = invoice
    end

    def render
      Prawn::Document.new(page_size: "A4", margin: 50) do |pdf|
        pdf.text "PayDesk", size: 22, style: :bold
        pdf.text "Invoice ##{invoice.id}", size: 14, color: "555555"
        pdf.move_down 20

        pdf.text "Billed to: #{invoice.customer.name}", size: 12
        pdf.text invoice.customer.email, size: 10, color: "555555"
        pdf.move_down 20

        pdf.table(
          [
            [ "Description", "Amount" ],
            [ "#{invoice.plan.name} subscription", format_cents(invoice.amount_cents) ]
          ],
          header: true,
          width: pdf.bounds.width
        ) do |t|
          t.row(0).font_style = :bold
          t.cells.padding = 8
        end

        pdf.move_down 20
        pdf.text "Status: #{invoice.status.upcase}", size: 12, style: :bold
        pdf.text "Due date: #{invoice.due_date.strftime('%B %-d, %Y')}", size: 10
        pdf.text "Paid at: #{invoice.paid_at.strftime('%B %-d, %Y')}", size: 10 if invoice.paid_at
      end.render
    end

    private

    attr_reader :invoice

    def format_cents(cents)
      format("$%.2f", cents / 100.0)
    end
  end
end
