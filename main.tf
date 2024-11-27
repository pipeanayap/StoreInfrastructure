provider "digitalocean" {
    token = var.DO_TOKEN
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

resource "digitalocean_project" "api-tienda-project" {
    name        = "api-tienda"
    description = "Servidor para la tienda de Star Wars"
    resources   = [digitalocean_droplet.api-tienda-droplet.urn]
}

resource "digitalocean_ssh_key" "api-tienda-ssh-key" {
    name       = "api-tienda-ssh-key"
    public_key = file("./keys/api-tienda-keys.pub")  
}

resource "digitalocean_droplet" "api-tienda-droplet" {
    image      = "ubuntu-20-04-x64"
    name       = "api-tienda"
    region     = "sfo3"
    size       = "s-2vcpu-4gb-120gb-intel"
    ssh_keys   = [digitalocean_ssh_key.api-tienda-ssh-key.id]
    user_data  = file("./docker-install.sh")

    provisioner "remote-exec" {
        inline = [
            "mkdir -p /projects",
            "mkdir -p /volumes/nginx/html",
            "mkdir -p /volumes/nginx/certs",
            "mkdir -p /volumes/nginx/vhostd",
            "touch /projects/.env",
            "echo \"DB_NAME=${var.DB_NAME}\" >> /projects/.env",
            "echo \"DB_USER=${var.DB_USER}\" >> /projects/.env",
            "echo \"DB_CLUSTER=${var.DB_CLUSTER}\" >> /projects/.env",
            "echo \"DB_PASSWORD=${var.DB_PASSWORD}\" >> /projects/.env",
            "echo \"DOMAIN=${var.DOMAIN}\" >> /projects/.env",
            "echo \"USER_EMAIL=${var.USER_EMAIL}\" >> /projects/.env",
            "echo \"API_DOMAIN=${var.API_DOMAIN}\" >> /projects/.env",
            "echo \"MONGO_URI=${var.MONGO_URI}\" >> /projects/.env",
            "echo \"DO_TOKEN=${var.DO_TOKEN}\" >> /projects/.env"
        ]


        connection {
            type        = "ssh"
            host        = self.ipv4_address
            user        = "root"
            private_key = file("./keys/api-tienda-keys")
        }
    }

    provisioner "file" {
        source      = "./docker-compose.yml"
        destination = "/projects/docker-compose.yml"

        connection {
            type        = "ssh"
            host        = self.ipv4_address
            user        = "root"
            private_key = file("./keys/api-tienda-keys")
        }
    }
}

resource "time_sleep" "wait-docker-install" {
    depends_on = [digitalocean_droplet.api-tienda-droplet]
    create_duration = "130s"
}

resource "null_resource" "init-api" {
    depends_on = [time_sleep.wait-docker-install]
    provisioner "remote-exec" {
        inline = [
            "cd /projects",
            "docker-compose up -d"
        ]

        connection {
            type        = "ssh"
            host        = digitalocean_droplet.api-tienda-droplet.ipv4_address
            user        = "root"
            private_key = file("./keys/api-tienda-keys")
        }
    }
}

output "ip" {
    value = digitalocean_droplet.api-tienda-droplet.ipv4_address 
}
