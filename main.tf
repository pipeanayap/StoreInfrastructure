provider "digitalocean" {
    token =  var.DO_TOKEN
}

terraform {
  required_providers {
    digitalocean = {
        source = "digitalocean/digitalocean"
        version = "~> 2.0"
    }
  }

    backend "s3" {
        endpoints = {
            s3 = "https://nyc3.digitaloceanspaces.com"
        }
        bucket                      = "devpipap"
        key                         = "terraform.tfstate"
        skip_credentials_validation = true
        skip_requesting_account_id  = true
        skip_metadata_api_check     = true
        skip_s3_checksum            = true
        region                      = "us-east-1"
    }
}

resource "digitalocean_project" "api_tienda_project"{
    name = "apitienda"
    description="servidor para la tienda de star wars"
    resources =  [digitalocean_droplet.api_tienda_droplet.urn]
}

resource "digitalocean_ssh_key" "api_tienda_ssh_key" {
    name       = "api_tienda_ssh_key"
    public_key = file("./keys/api_tienda_keys.pub")  
}

resource "digitalocean_droplet" "api_tienda_droplet" {
    image  = "ubuntu-20-04-x64"
    name   = "api_tienda"
    region = "sfo3"
    size   = "s-2vcpu-4gb-120gb-intel"
    ssh_keys = [digitalocean_ssh_key.api_tienda_ssh_key.id]
    user_data = file("./docker-install.sh")

    provisioner "remote-exec" {
        inline = [
            "mkdir -p /projects",
            "mkdir -p /volumes/nginx/html",
            "mkdir -p /volumes/nginx/certs",
            "mkdir -p /volumes/nginx/vhostd",
            "touch /proyects/.env",
            "echo \"DB_NAME=${var.DB_NAME}\" >> /proyects/.env",
            "echo \"DB_USER=${var.DB_USER}\" >> /proyects/.env",
            "echo \"DB_CLUSTER=${var.DB_CLUSTER}\" >> /proyects/.env",
            "echo \"DB_PASSWORD=${var.DB_PASSWORD}\" >> /proyects/.env",
            # "echo \"DOMAIN=${var.DOMAIN}\" >> /proyects/.env",
            # "echo \"USER_EMAIL=${var.USER_EMAIL}\" >> /proyects/.env"
        ]

        connection {
            type        = "ssh"
            host        = self.ipv4_address
            user        = "root"
            private_key = file("./keys/api_tienda_keys")
      
        }
    }   

    provisioner "file" {
        source      = "./docker-compose.yml"
        destination = "/projects/docker-compose.yml"

        connection {
            type        = "ssh"
            host        = self.ipv4_address
            user        = "root"
            private_key = file("./keys/api_tienda_keys")
  
        }

    }
}

resource "time_sleep" "wait_docker_install" {
    depends_on = [ digitalocean_droplet.api_tienda_droplet ]
    create_duration = "200s"
}

resource "null_resource" "init_api"{
        depends_on = [ time_sleep.wait_docker_install ]
    provisioner "remote-exec" {
        inline = [
            "cd /projects",
            "docker-compose up -d"
        ]

        connection {
            type        = "ssh"
            host        = digitalocean_droplet.api_tienda_droplet.ipv4_address
            user        = "root"
            private_key = file("./keys/api_tienda_keys")
      
        }
    }
}

output "ip" {
    value = digitalocean_droplet.api_tienda_droplet.ipv4_address 
}

