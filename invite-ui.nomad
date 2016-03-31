job "invite-ui" {
  datacenters = [ "invite" ]

  update {
    stagger = "10s"
    max_parallel = 1
  }

  group "invite-ui" {

    restart {
      interval = "5m"
      attempts = 10
      delay    = "25s"
      mode = "delay"
    }

    task "invite-ui" {

      driver = "docker"

      config {
        image = "saipranav/invite-frontend"
        network_mode = "host"
      }

      service {
        name = "${TASK}"
        tags = [ "invite" , "ui" , "frontend" ]
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

  group "invite-ui-load-balancer" {

    restart {
      interval = "5m"
      attempts = 10
      delay    = "25s"
      mode = "delay"
    }

    task "invite-ui-lb" {

      driver = "docker"

      constraint {
        attribute = "${attr.hostname}"
        value     = "LAMP31"
      }

      config {
        image = "saipranav/nginx"
        network_mode = "host"
        port_map {
          http = 80
        }
      }

      env {
        SERVICE = "invite-ui"
      }

      service {
        name = "${TASK}"
        tags = [ "invite-ui" , "load balancer" ]
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
          port "http" { 
            static = 80
          }
        }
      }

    }
  }

}
