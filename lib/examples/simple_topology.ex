defmodule Examples.SimpleTopology do
  use CUL8er

  topology :simple do
    host :local do
      address("localhost")
      platform(:arch_linux)
    end

    resource :web, type: :container, on: :local do
      from_image("images:alpine/3.19")

      limits do
        cpu(cores: 2)
        memory(gigabytes: 4)
      end

      network do
        expose(port: 4000, as: 443, protocol: :https)
      end

      environment do
        set(:MIX_ENV, "prod")
        secret(:SECRET_KEY_BASE, from: :system)
      end
    end

    strategy do
      approach(:rolling)
      batch_size(1)

      healthcheck do
        endpoint("http://localhost:4000/health")
        interval(seconds: 10)
        retries(3)
      end

      rollback do
        on_failure(:automatic)
        snapshot(true)
      end
    end
  end
end
