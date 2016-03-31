job "person" {
  datacenters = [ "invite" ]

  update {
    stagger = "10s"
    max_parallel = 1
  }

  group "person-service" {

    count = 2

    restart {
      interval = "5m"
      attempts = 10
      delay    = "25s"
      mode = "delay"
    }

    task "person" {

      driver = "docker"

      config {
        image = "saipranav/person-backend"
        network_mode = "host"
      }

      service {
        name = "${TASK}"
        tags = [ "person" , "service" , "backend" ]
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

  group "person-load-balancer" {

    restart {
      interval = "5m"
      attempts = 10
      delay    = "25s"
      mode = "delay"
    }

    task "person-lb" {

      driver = "docker"

      config {
        image = "saipranav/nginx"
        network_mode = "host"
      }

      env {
        SERVICE = "person"
      }

      service {
        name = "${TASK}"
        tags = [ "person" , "load balancer" ]
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
