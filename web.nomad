job "web" {
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
        MAIL_AUTH_PASSWORD = "Password@123"
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

  group "load-balancer" {

    constraint {
      attribute = "${attr.hostname}"
      value     = "LAMP31"
    }

    restart {
      interval = "5m"
      attempts = 10
      delay    = "25s"
      mode = "delay"
    }

    task "nginx" {

      driver = "docker"

      config {
        image = "saipranav/nginx"
        network_mode = "host"
        port_map {
          http = 80
        }
      }

      service {
        name = "${TASK}"
        tags = [ "invite" , "load balancer" ]
        port = "http"

        check {
          name = "Check for HTTP response on port 80"
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
          port "http" { 
            static = 80
          }
        }
      }

    }
  }

}
