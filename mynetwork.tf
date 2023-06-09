# Para mas detalles (opocional): export TF_LOG=TRACE


# Create the mynetwork network
resource "google_compute_network" "mynetwork" {
  name                    = "turbofynet-tf"
  auto_create_subnetworks = "true"
  project                 = var.gcp_project
}

# Add a firewall rule to allow HTTP, SSH, RDP, and ICMP traffic on mynetwork
resource "google_compute_firewall" "mynetwork-allow-http-ssh-rdp-icmp" {
  name    = "turbofynet-tf-allow-http-ssh-rdp-icmp"
  network = google_compute_network.mynetwork.name
  allow {
    protocol = "tcp"
    ports    = ["22", "80", "8080"]
  }
  
  # firewall will apply  to traffic that has source IP address in these ranges, any IP: 0.0.0.0/0
  source_ranges = ["0.0.0.0/0"]   

  allow {
    protocol = "icmp"
  }
}
  
module "turbofy-back-vm" {
  source          = "./instance"
  instance_name   = "turbofy-back-vm-tf"
  instance_region = "us-central1"
  instance_zone   = "us-central1-a"
  instance_type   = "n1-standard-1"
  image           = "ubuntu-os-cloud/ubuntu-2004-lts"  #ubuntu-1804-lts"  
  #  startup_script      = "${var.init_scrip_apache2}"
  instance_subnetwork = google_compute_network.mynetwork.self_link
}
  
module "turbofy-front-vm" {
  source          = "./instance"
  instance_name   = "turbofy-front-vm-tf"
  instance_region = "us-central1"
  instance_zone   = "us-central1-a"
  instance_type   = "n1-standard-1"
  image           = "ubuntu-os-cloud/ubuntu-2004-lts"  #ubuntu-1804-lts"  
  #  startup_script      = "${var.init_scrip_apache2}"
  instance_subnetwork = google_compute_network.mynetwork.self_link
}


resource "null_resource" "execute" {
    
  provisioner "remote-exec" {
    connection {
      host        = module.turbofy-front-vm.instance_ip_addr
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
    }

    ## Script inicialización web-deploy-vm
    inline = [
      "sudo apt-get update -y",
      "echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections",
      "echo 'debconf debconf/frontend select Noninteractive'  | sudo debconf-set-selections",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y python-minimal",
      "sudo timedatectl set-timezone Europe/Madrid",
      # Instalacion de docker       
      "sudo apt install apt-transport-https ca-certificates curl software-properties-common -y",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable'",
      "sudo apt update -y",
      "sudo apt install docker-ce docker-ce-cli containerd.io -y",
      "sudo usermod -aG docker $${USER}",
      # Instalacion de docker composer
      "sudo curl -L https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      # Instalacion de Java jdk 8
      "sudo apt install openjdk-8-jdk -y",
      "echo JAVA_HOME=\"/usr/lib/jvm/java-8-openjdk-amd64/jre\" | sudo tee -a /etc/environment",
      # Instalacion de Node JS 16
      "curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -",
      "sudo apt-get install -y nodejs",
      "sudo apt-get install npm -y"

    ]
    on_failure = continue
  }
      
  provisioner "remote-exec" {
    connection {
      host        = module.turbofy-back-vm.instance_ip_addr
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
    }

    ## Script inicialización web-deploy-vm
    inline = [
      "sudo apt-get update -y",
      "echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections",
      "echo 'debconf debconf/frontend select Noninteractive'  | sudo debconf-set-selections",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y python-minimal",
      "sudo timedatectl set-timezone Europe/Madrid",
      # Instalacion de docker       
      "sudo apt install apt-transport-https ca-certificates curl software-properties-common -y",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable'",
      "sudo apt update -y",
      "sudo apt install docker-ce docker-ce-cli containerd.io -y",
      "sudo usermod -aG docker $${USER}",
      # Instalacion de docker composer
      "sudo curl -L https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      # Instalacion de Java jdk 8
      "sudo apt install openjdk-8-jdk -y",
      "echo JAVA_HOME=\"/usr/lib/jvm/java-8-openjdk-amd64/jre\" | sudo tee -a /etc/environment",
      # Instalacion de Node JS 16
      "curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -",
      "sudo apt-get install -y nodejs",
      "sudo apt-get install npm -y"

    ]
    on_failure = continue
  }
  depends_on = [
    # Init script must be created before this IP address could
    # actually be used, otherwise the services will be unreachable.
    module.turbofy-back-vm.instance_ip_addr, module.turbofy-front-vm
  ]
}
