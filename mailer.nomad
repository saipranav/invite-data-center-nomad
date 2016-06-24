job "mailer" {
  datacenters = [ "invite" ]

  update {
    stagger = "10s"
    max_parallel = 1
  }

  group "mailer-service" {

    restart {
      interval = "5m"
      attempts = 10
      delay    = "25s"
      mode = "delay"
    }

    task "mailer" {

      driver = "docker"

      config {
        image = "saipranav/mailer-backend"
        network_mode = "host"
      }

      env {
        MAIL_AUTH_USERNAME = "saipranav_r@listertechnologies.com"
        MAIL_AUTH_PASSWORD = "Welcome@123"
        ROOT_TO_BOOK = "daffodil@listertechnologies.com"
      }

      service {
        name = "${TASK}"
        tags = [ "mailer" , "service" , "backend" ]
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

  group "mailer-load-balancer" {

    restart {
      interval = "5m"
      attempts = 10
      delay    = "25s"
      mode = "delay"
    }

    task "mailer-lb" {

      driver = "docker"

      config {
        image = "saipranav/nginx"
        network_mode = "host"
      }

      env {
        SERVICE = "mailer"
      }

      service {
        name = "${TASK}"
        tags = [ "mailer" , "load balancer" ]
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
