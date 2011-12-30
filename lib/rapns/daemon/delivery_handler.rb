module Rapns
  module Daemon
    class DeliveryHandler
      STOP = 0x666

      def start
        Thread.new do 
          loop do
            break if @stop
            handle_next_notification
          end
        end
      end

      def stop
        @stop = true
      end

      protected

      def deliver(notification)
        Rapns::Daemon.connection_pool.claim_connection do |connection|
          begin
            connection.write(notification.to_binary)

            notification.delivered = true
            notification.delivered_at = Time.now
            notification.save(:validate => false)

            Rapns::Daemon.logger.info("Notification #{notification.id} delivered to #{notification.device_token}")
          rescue Rapns::DeliveryError => error
            handle_delivery_error(notification, error)
          end
        end
      end

      def handle_delivery_error(notification, error)
        Rapns::Daemon.logger.error(error)

        notification.delivered = false
        notification.delivered_at = nil
        notification.failed = true
        notification.failed_at = Time.now
        notification.error_code = error.code
        notification.error_description = error.description
        notification.save!(:validate => false)
      end

      def handle_next_notification
        notification = Rapns::Daemon.delivery_queue.pop
        begin
          return if notification == STOP
          deliver(notification)
        rescue StandardError => e
          Rapns::Daemon.logger.error(e)
        ensure
          Rapns::Daemon.delivery_queue.handler_available
        end
      end
    end
  end
end
