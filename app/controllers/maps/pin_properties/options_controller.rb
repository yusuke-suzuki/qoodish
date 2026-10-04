module Maps
  module PinProperties
    class OptionsController < ApplicationController
      before_action :authenticate_user!

      def create
        @option = PinPropertyOption.record!(
          user: current_user,
          pin_property: editable_pin_property,
          **option_params
        )
      end

      def update
        @option = editable_pin_property.options.published.find_by!(id: params[:id])
        @option.revise!(user: current_user, **option_params)
      end

      def destroy
        editable_pin_property.options.published.find_by!(id: params[:id]).discard!(user: current_user)
      end

      private

      def editable_pin_property
        PinProperty
          .published
          .where(map: current_user.editable_maps)
          .find_by!(id: params[:pin_property_id], map_id: params[:map_id])
      end

      def option_params
        params.permit(:name, :position).to_h.symbolize_keys
      end
    end
  end
end
