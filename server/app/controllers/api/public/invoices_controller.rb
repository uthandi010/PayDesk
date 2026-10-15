module Api
  module Public
    # No authentication here on purpose: an invoice's public_token is an
    # unguessable 32-byte random value (like a real billing product's "view
    # your invoice" email link), not a sequential id, so knowing it is what
    # stands in for authorization.
    class InvoicesController < ApplicationController
      before_action :set_invoice

      def show
        render json: invoice_json(@invoice)
      end

      def pay
        result = Billing::InvoiceCharger.new.call(@invoice)
        render json: invoice_json(result.invoice)
      rescue Billing::InvoiceCharger::NotChargeableError => e
        render json: { message: e.message }, status: :unprocessable_content
      end

      private

      def set_invoice
        @invoice = Invoice.find_by!(public_token: params[:token])
      end

      def invoice_json(invoice)
        {
          id: invoice.id,
          amountCents: invoice.amount_cents,
          status: invoice.status,
          overdue: invoice.overdue?,
          dueDate: invoice.due_date,
          paidAt: invoice.paid_at,
          business: invoice.user.name,
          customer: { name: invoice.customer.name, email: invoice.customer.email },
          plan: { name: invoice.plan.name }
        }
      end
    end
  end
end
