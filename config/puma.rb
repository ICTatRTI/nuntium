if defined?(Puma)
  on_worker_boot do
    # Init AMQP queues
    Queues.init

    # Init ActiveRecord connection
    ActiveSupport.on_load(:active_record) do
      ActiveRecord::Base.establish_connection
    end
  end
end
