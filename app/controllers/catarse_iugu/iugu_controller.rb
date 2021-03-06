class CatarseIugu::IuguController < ApplicationController
  layout false

  def review
    contribution
  end

  def pay
    begin
      payment.save!
      charge = Iugu::Charge.create(
        "token" => params[:token],
        "email" => contribution.payer_email,
        "items" => [
          {
            "description" => contribution.project.name,
            "quantity" => "1",
            "price_cents" => contribution.price_in_cents
          }
        ]
      )

      if charge.success
        flash[:notice] = "Contribuição feita com sucesso!"
        payment.pay!
        PaymentEngines.create_payment_notification contribution_id: contribution.id, payment_id: payment.id
        redirect_to main_app.project_contribution_path(contribution.project, contribution)
      else
        flash[:notice] = "Houve um erro ao realizar o pagamento: #{charge.message}"
        redirect_to main_app.new_project_contribution_path(contribution.project)
      end
    rescue Exception => e
      Rails.logger.info "-----> #{e.inspect}"
      flash[:notice] = "Houve um erro ao realizar o pagamento: #{e.message}"
      return redirect_to main_app.new_project_contribution_path(contribution.project)
    end
  end

  private

    def contribution
      @contribution ||= PaymentEngines.find_contribution(params[:id])
    end

    def payment
      @payment ||= PaymentEngines.new_payment(
        contribution: contribution,
        value: contribution.value,
        gateway: "Iugu",
        payment_method: 'Iugu'
      )
    end
end
