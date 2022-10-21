terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token // não pude criar criar a maquina na nuvem
}

# Create a new Web Droplet in the nyc2 region
resource "digitalocean_droplet" "web" {
  image    = "ubuntu-22-04-x64"
  name     = "web-1"
  region   = var.region
  size     = "s-2vcpu-2gb"
  ssh_keys = [data.digitalocean_ssh_key.jornada.id]
}

data "digitalocean_ssh_key" "ssh_key" {
  name = var.ssh_key_name
}

resource "digitalocean_kubernetes_cluster" "k8s" {
  name   = "k8s"
  region = var.region
  # Grab the latest version slug from `doctl kubernetes options versions`
  version = "1.22.8-do.1"

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    node_count = 2

    taint {
      key    = "workloadKind"
      value  = "database"
      effect = "NoSchedule"
    }
  }
}

variable "region" {
  default = ""
}
variable "do_token" {
  default = ""
}
variable "ssh_key_name" {
  default = ""
}

output "jenkins_ip" {
  value = digitalocean_droplet.jenkins.ipv4_address
}

resource "local_file" "foo" {
  contecontent = digitalocean_kubernetes_cluster.k8s.kube_config.0.raw_config
  filefilename = "kube_config.yml"
}