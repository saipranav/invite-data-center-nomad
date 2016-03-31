job "invite" {
  datacenters = [ "invite" ]

  update {
    stagger = "10s"
    max_parallel = 1
  }

  group "invite-service" {

    restart {
      interval = "5m"
      attempts = 10
      delay    = "25s"
      mode = "delay"
    }

    task "invite" {

      driver = "docker"

      config {
        image = "saipranav/invite-backend"
        network_mode = "host"
      }

      service {
        name = "${TASK}"
        tags = [ "invite" , "service" , "backend" ]
        port = "http"

        check {
          name = "Check for HTTP response"
          type     = "http"
          protocol = "http"
          path = "/"
          interval = "10s"
          timeout = "1s"
        }

      }

      resources {
        cpu = 500 # Mhz
        memory = 256 # MB

        network {
          mbits = 10
          port "http" { }
        }
      }

    }
  }

  group "invite-load-balancer" {

    restart {
      interval = "5m"
      attempts = 10
      delay    = "25s"
      mode = "delay"
    }

    task "invite-lb" {

      driver = "docker"

      config {
        image = "saipranav/nginx"
        network_mode = "host"
      }

      env {
        SERVICE = "invite"
      }

      service {
        name = "${TASK}"
        tags = [ "invite" , "load balancer" ]
        port = "http"

        check {
          name = "Check for HTTP response"
          type     = "http"
          protocol = "http"
          path = "/"
          interval = "10s"
          timeout = "1s"
        }

      }

      resources {
        cpu = 250 # Mhz
        memory = 128 # MB

        network {
          mbits = 10
          port "http" { }
        }
      }

    }
  }

}
