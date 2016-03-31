job "database" {
  datacenters = [ "invite" ]

  update {
    stagger = "10s"
    max_parallel = 1
  }

  group "database" {

    restart {
      interval = "5m"
      attempts = 10
      delay    = "25s"
      mode     = "delay"
    }

    task "mongo" {

      driver = "docker"

      config {
        image = "saipranav/mongodb:3.2"
        port_map {
          db = 27017
        }
      }

      env {}

      service {
        name = "${TASKGROUP}-${TASK}"
        tags = [ "invite" , "mongo" , "database" ]
        port = "db"
        check {
          name = "alive"
          type = "tcp"
          interval = "10s"
          timeout = "2s"
        }
      }

      resources {
        cpu = 500 # Mhz
        memory = 256 # MB

        network {
          mbits = 10
          port "db" { 
            static = 27017
          }
        }
      }

    }
  }

}