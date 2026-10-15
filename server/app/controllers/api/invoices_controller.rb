module Api
  class InvoicesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_invoice, only: [ :show, :retry, :pdf ]

    def index
      invoices = current_user.invoices.includes(subscription: [ :customer, :plan ]).order(created_at: :desc)
      render json: invoices.map { |i| invoice_json(i) }
    end

    def show
      render json: invoice_json(@invoice, include_payments: true)
    end

    def retry
      result = Billing::InvoiceCharger.new.call(@invoice)
      render json: invoice_json(result.invoice, include_payments: true)
    rescue Billing::InvoiceCharger::NotChargeableError => e
      render json: { message: e.message }, status: :unprocessable_content
    end

    def pdf
      pdf_data = Billing::InvoicePdf.new(@invoice).render
      send_data pdf_data, filename: "invoice-#{@invoice.id}.pdf", type: "application/pdf", disposition: "attachment"
    end

    private

    def set_invoice
      @invoice = current_user.invoices.find(params[:id])
    end

    def invoice_json(invoice, include_payments: false)
      json = {
        id: invoice.id,
        amountCents: invoice.amount_cents,
        status: invoice.status,
        overdue: invoice.overdue?,
        dueDate: invoice.due_date,
        paidAt: invoice.paid_at,
        publicToken: invoice.public_token,
        customer: { id: invoice.customer.id, name: invoice.customer.name, email: invoice.customer.email },
        plan: { id: invoice.plan.id, name: invoice.plan.name }
      }
      json[:payments] = invoice.payments.order(created_at: :desc).map { |p| payment_json(p) } if include_payments
      json
    end

    def payment_json(payment)
      {
        id: payment.id,
        amountCents: payment.amount_cents,
        status: payment.status,
        gatewayReference: payment.gateway_reference,
        failureReason: payment.failure_reason,
        createdAt: payment.created_at
      }
    end
  end
end
