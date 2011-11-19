module Rapns
  module Daemon
    class Feeder
      def self.start(foreground)
        loop do
          break if @stop
          enqueue_notifications
        end
      end

      def self.stop
        @stop = true
      end

      protected

      def self.enqueue_notifications
        begin
          Rapns::Notification.ready_for_delivery.each do |notification|
            Rapns::Daemon.delivery_queue.push(notification)
          end

          Rapns::Daemon.delivery_queue.wait_for_available_handler
        rescue StandardError => e
          Rapns::Daemon.logger.error(e)
        end

        sleep Rapns::Daemon.configuration.poll
      end

      def self.sleep_to_avoid_thrashing
        sleep 2
      end
    end
  end
end
