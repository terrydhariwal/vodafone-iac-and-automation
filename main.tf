provider "google" {
  region = "${var.region}"
  project = "${var.project_name}"
  credentials = "${file(var.account_file_path)}"
}

resource "google_compute_instance" "master" {
  name         = "master"
  machine_type = "n1-standard-1" //machine_type = "g1-small"
  zone         = "us-central1-a"
  create_timeout = 60

  disk {
    #image = "debian-cloud/debian-8"
    #image = "rhel-cloud/rhel-7" //premium image
    image = "centos-cloud/centos-7" 
    #type    = "local-ssd"
    #scratch = true
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
      nat_ip = "${google_compute_address.master.address}"
    }
  }
  
  /* create a key in .ssh*/
  metadata {
    //sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
    //ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
    ssh-keys = "terry:${file("${var.gce_ssh_pub_key_file}")}" //this needed to be changed and NOT use root
  }

  provisioner "file" {
    source = "provisioner-scripts/puppet-server-provisioners-1.sh"
    destination = "/tmp/puppet-server-provisioners-1.sh"

    connection {
      type        = "ssh"
      user        = "terry"
      private_key = "${file("${var.gce_ssh_private_key_file}")}"
      agent       = false
    }
  }

  provisioner "remote-exec" {
    inline = [ 
    "sudo chmod +x /tmp/puppet-server-provisioners-1.sh",
    "sudo /tmp/puppet-server-provisioners-1.sh"
    ]

    connection {
      type        = "ssh"
      user        = "terry"
      private_key = "${file("${var.gce_ssh_private_key_file}")}"
      agent       = false
    }
  }

  provisioner "remote-exec" {
    inline = [ 
    "sudo su - root -c 'mkdir -p /etc/puppetlabs/code/environments/production/manifests/'",
    "sudo su - root -c 'chown -R terry /etc/puppetlabs/code/environments/production/manifests/'",
    ]

    connection {
      type        = "ssh"
      user        = "terry"
      private_key = "${file("${var.gce_ssh_private_key_file}")}"
      agent       = false
    }
  }

  provisioner "file" {
    source = "puppet-code/nodes.pp"
    destination = "/etc/puppetlabs/code/environments/production/manifests/nodes.pp"
    connection {
      type        = "ssh"
      user        = "terry"
      private_key = "${file("${var.gce_ssh_private_key_file}")}"
      agent       = false
    }
  }

  scheduling { 
    //preemptible = true //temporarily turn off because of POC
  }
}

resource "google_compute_address" "master" {
  name = "test-address"
}

/* //can only have one in free tier
resource "google_compute_address" "node" {
  name = "node1-address"
  }*/

resource "google_compute_firewall" "default" {
  name    = "default"
  //network = "${google_compute_network.default.name}"
  network = "default"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "8140", "22", "1000-2000", "7000", "7001", "7199", "9042", "9160", "9142"]
  }

  /*source_tags = ["web"]*/
  source_ranges = ["0.0.0.0/0"]

}

output "master_ip" {
  value = "${google_compute_address.master.address}"
}

output "ssh_user" {
  value = "${var.gce_ssh_user}"
}

output "ssh_command_master" {
  value = "ssh -i ${var.gce_ssh_private_key_file} ${var.gce_ssh_user}@${google_compute_address.master.address}"
}

/*** Spark Load Generator Node ***/
resource "google_compute_instance" "spark" {
  name         = "spark"
  //machine_type = "f1-micro"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

  disk {
    //image = "debian-cloud/debian-8"
    //image = "rhel-cloud/rhel-7" //premium image
    image = "centos-cloud/centos-7"
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
      //nat_ip = "${google_compute_address.node.address}"
    }
  }
  
  metadata {
    ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }


  provisioner "file" {
    source = "provisioner-scripts/puppet-agent-provisioners-1.sh"
    destination = "/tmp/puppet-agent-provisioners-1.sh"

    connection {
      type        = "ssh"
      user        = "terry"
      private_key = "${file("${var.gce_ssh_private_key_file}")}"
      agent       = false
    }
  }

 
  # provisioner "file" {
  #   source = "provisioner-scripts/puppet-daemon.sh"
  #   #destination = "/etc/init.d/puppet-daemon.sh".  # doesn't work - issues with permissions 
  #   destination = "/tmp/puppet-daemon.sh"

  #   connection {
  #     type        = "ssh"
  #     user        = "terry"
  #     private_key = "${file("${var.gce_ssh_private_key_file}")}"
  #     agent       = false
  #   }
  # }

  provisioner "remote-exec" {

    inline = [ 
      //need to run this first 
      "sudo chmod +x /tmp/puppet-agent-provisioners-1.sh",
      "sudo /tmp/puppet-agent-provisioners-1.sh"
    ]

    connection {
      type        = "ssh"
      user        = "terry"
      private_key = "${file("${var.gce_ssh_private_key_file}")}"
      agent       = false
    }
  }

  provisioner "remote-exec" {

    inline = [ 
      "sudo echo 'hello' >> /tmp/test.txt",
      //don't have permissions to use the terraform file provisioner to write to /etc/init.d, so moving the file instead
      //note adding a script in this folder does not run at startup - not sure why
      //so instead I'm using the legacy /etc/rc.d/rc.local file instead
      //"sudo su -c 'mv /tmp/puppet-daemon.sh /etc/init.d/puppet-daemon.sh'",
      //"sudo chmod +x /etc/init.d/puppet-daemon.sh",                                   //manualy polling works up to here
      //"sudo /etc/init.d/puppet-daemon.sh", #incase the first time it doesnt start
      "sudo su -c \"echo 'sudo service puppet stop' >> /etc/rc.d/rc.local\"",
      #made this manual now
      #"sudo su -c \"echo 'sudo /opt/puppetlabs/bin/puppet agent --daemonize --verbose --server=default.c.graceful-matter-161422.internal --runinterval=0' >> /etc/rc.d/rc.local\"",
      "sudo chmod +x /etc/rc.d/rc.local",
      "sudo /etc/rc.d/rc.local", //the first run doesn't execute this - needs a reboot. so running here
    ]

    connection {
      type        = "ssh"
      user        = "terry"
      private_key = "${file("${var.gce_ssh_private_key_file}")}"
      agent       = false
    }
  }
  

  scheduling { 
    //preemptible = true //temporarily turn off because of POC
  }

  depends_on = ["google_compute_instance.master"]
  
}

output "spark_ip" {
  //value = "${google_compute_address.node.address}"
  value = "${google_compute_instance.spark.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "ssh_command_spark" {
  value = "ssh -i ${var.gce_ssh_private_key_file} ${var.gce_ssh_user}@${google_compute_instance.spark.network_interface.0.access_config.0.assigned_nat_ip}"
}

/**** Node 1 ****/
resource "google_compute_instance" "node" {
  name         = "node"
  //machine_type = "f1-micro"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

  disk {
    //image = "debian-cloud/debian-8"
    //image = "rhel-cloud/rhel-7" //premium image
    image = "centos-cloud/centos-7"
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
      //nat_ip = "${google_compute_address.node.address}"
    }
  }
  
  metadata {
    ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }


  provisioner "file" {
    source = "provisioner-scripts/puppet-agent-provisioners-1.sh"
    destination = "/tmp/puppet-agent-provisioners-1.sh"

    connection {
      type        = "ssh"
      user        = "terry"
      private_key = "${file("${var.gce_ssh_private_key_file}")}"
      agent       = false
    }
  }

 
  # provisioner "file" {
  #   source = "provisioner-scripts/puppet-daemon.sh"
  #   #destination = "/etc/init.d/puppet-daemon.sh".  # doesn't work - issues with permissions 
  #   destination = "/tmp/puppet-daemon.sh"

  #   connection {
  #     type        = "ssh"
  #     user        = "terry"
  #     private_key = "${file("${var.gce_ssh_private_key_file}")}"
  #     agent       = false
  #   }
  # }

  provisioner "remote-exec" {

    inline = [ 
      //need to run this first 
      "sudo chmod +x /tmp/puppet-agent-provisioners-1.sh",
      "sudo /tmp/puppet-agent-provisioners-1.sh"
    ]

    connection {
      type        = "ssh"
      user        = "terry"
      private_key = "${file("${var.gce_ssh_private_key_file}")}"
      agent       = false
    }
  }

  provisioner "remote-exec" {

    inline = [ 
      "sudo echo 'hello' >> /tmp/test.txt",
      //don't have permissions to use the terraform file provisioner to write to /etc/init.d, so moving the file instead
      //note adding a script in this folder does not run at startup - not sure why
      //so instead I'm using the legacy /etc/rc.d/rc.local file instead
      //"sudo su -c 'mv /tmp/puppet-daemon.sh /etc/init.d/puppet-daemon.sh'",
      //"sudo chmod +x /etc/init.d/puppet-daemon.sh",                                   //manualy polling works up to here
      //"sudo /etc/init.d/puppet-daemon.sh", #incase the first time it doesnt start
      "sudo su -c \"echo 'sudo service puppet stop' >> /etc/rc.d/rc.local\"",
      #made this manual now
      #"sudo su -c \"echo 'sudo /opt/puppetlabs/bin/puppet agent --daemonize --verbose --server=default.c.graceful-matter-161422.internal --runinterval=0' >> /etc/rc.d/rc.local\"",
      "sudo chmod +x /etc/rc.d/rc.local",
      "sudo /etc/rc.d/rc.local", //the first run doesn't execute this - needs a reboot. so running here
    ]

    connection {
      type        = "ssh"
      user        = "terry"
      private_key = "${file("${var.gce_ssh_private_key_file}")}"
      agent       = false
    }
  }
  

  scheduling { 
    //preemptible = true //temporarily turn off because of POC
  }

  depends_on = ["google_compute_instance.master"]
  
}

output "node_ip" {
  //value = "${google_compute_address.node.address}"
  value = "${google_compute_instance.node.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "ssh_command_node" {
  value = "ssh -i ${var.gce_ssh_private_key_file} ${var.gce_ssh_user}@${google_compute_instance.node.network_interface.0.access_config.0.assigned_nat_ip}"
}

/**** Node 2 ****/
resource "google_compute_instance" "node2" {
  name         = "node2"
  //machine_type = "f1-micro"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

  disk {
    //image = "debian-cloud/debian-8"
    //image = "rhel-cloud/rhel-7" //premium image
    image = "centos-cloud/centos-7"
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
      //nat_ip = "${google_compute_address.node.address}"
    }
  }
  
  metadata {
    ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }


 provisioner "file" {
    source = "provisioner-scripts/puppet-agent-provisioners-1.sh"
    destination = "/tmp/puppet-agent-provisioners-1.sh"

    connection {
      type        = "ssh"
      user        = "terry"
      private_key = "${file("${var.gce_ssh_private_key_file}")}"
      agent       = false
    }
  }

 
  # provisioner "file" {
  #   source = "provisioner-scripts/puppet-daemon.sh"
  #   #destination = "/etc/init.d/puppet-daemon.sh".  # doesn't work - issues with permissions 
  #   destination = "/tmp/puppet-daemon.sh"

  #   connection {
  #     type        = "ssh"
  #     user        = "terry"
  #     private_key = "${file("${var.gce_ssh_private_key_file}")}"
  #     agent       = false
  #   }
  # }

  provisioner "remote-exec" {

    inline = [ 
      //need to run this first 
      "sudo chmod +x /tmp/puppet-agent-provisioners-1.sh",
      "sudo /tmp/puppet-agent-provisioners-1.sh"
    ]

    connection {
      type        = "ssh"
      user        = "terry"
      private_key = "${file("${var.gce_ssh_private_key_file}")}"
      agent       = false
    }
  }

  provisioner "remote-exec" {

    inline = [ 
      "sudo echo 'hello' >> /tmp/test.txt",
      //don't have permissions to use the terraform file provisioner to write to /etc/init.d, so moving the file instead
      //note adding a script in this folder does not run at startup - not sure why
      //so instead I'm using the legacy /etc/rc.d/rc.local file instead
      //"sudo su -c 'mv /tmp/puppet-daemon.sh /etc/init.d/puppet-daemon.sh'",
      //"sudo chmod +x /etc/init.d/puppet-daemon.sh",                                   //manualy polling works up to here
      //"sudo /etc/init.d/puppet-daemon.sh", #incase the first time it doesnt start
      "sudo su -c \"echo 'sudo service puppet stop' >> /etc/rc.d/rc.local\"",
      #made this manual now
      #"sudo su -c \"echo 'sudo /opt/puppetlabs/bin/puppet agent --daemonize --verbose --server=default.c.graceful-matter-161422.internal --runinterval=0' >> /etc/rc.d/rc.local\"",
      "sudo chmod +x /etc/rc.d/rc.local",
      "sudo /etc/rc.d/rc.local", //the first run doesn't execute this - needs a reboot. so running here
    ]

    connection {
      type        = "ssh"
      user        = "terry"
      private_key = "${file("${var.gce_ssh_private_key_file}")}"
      agent       = false
    }
  }

  scheduling { 
    //preemptible = true //temporarily turn off because of POC
  }

  depends_on = ["google_compute_instance.master"]
  
}

output "node2_ip" {
  //value = "${google_compute_address.node.address}"
  value = "${google_compute_instance.node2.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "ssh_command_node2" {
  value = "ssh -i ${var.gce_ssh_private_key_file} ${var.gce_ssh_user}@${google_compute_instance.node2.network_interface.0.access_config.0.assigned_nat_ip}"
}

/**** Node 3 ****/
resource "google_compute_instance" "node3" {
  name         = "node3"
  //machine_type = "f1-micro"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

  disk {
    //image = "debian-cloud/debian-8"
    //image = "rhel-cloud/rhel-7" //premium image
    image = "centos-cloud/centos-7"
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
      //nat_ip = "${google_compute_address.node.address}"
    }
  }
  
  metadata {
    ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }


 provisioner "file" {
    source = "provisioner-scripts/puppet-agent-provisioners-1.sh"
    destination = "/tmp/puppet-agent-provisioners-1.sh"

    connection {
      type        = "ssh"
      user        = "terry"
      private_key = "${file("${var.gce_ssh_private_key_file}")}"
      agent       = false
    }
  }

 
  # provisioner "file" {
  #   source = "provisioner-scripts/puppet-daemon.sh"
  #   #destination = "/etc/init.d/puppet-daemon.sh".  # doesn't work - issues with permissions 
  #   destination = "/tmp/puppet-daemon.sh"

  #   connection {
  #     type        = "ssh"
  #     user        = "terry"
  #     private_key = "${file("${var.gce_ssh_private_key_file}")}"
  #     agent       = false
  #   }
  # }

  provisioner "remote-exec" {

    inline = [ 
      //need to run this first 
      "sudo chmod +x /tmp/puppet-agent-provisioners-1.sh",
      "sudo /tmp/puppet-agent-provisioners-1.sh"
    ]

    connection {
      type        = "ssh"
      user        = "terry"
      private_key = "${file("${var.gce_ssh_private_key_file}")}"
      agent       = false
    }
  }

  provisioner "remote-exec" {

    inline = [ 
      "sudo echo 'hello' >> /tmp/test.txt",
      //don't have permissions to use the terraform file provisioner to write to /etc/init.d, so moving the file instead
      //note adding a script in this folder does not run at startup - not sure why
      //so instead I'm using the legacy /etc/rc.d/rc.local file instead
      //"sudo su -c 'mv /tmp/puppet-daemon.sh /etc/init.d/puppet-daemon.sh'",
      //"sudo chmod +x /etc/init.d/puppet-daemon.sh",                                   //manualy polling works up to here
      //"sudo /etc/init.d/puppet-daemon.sh", #incase the first time it doesnt start
      "sudo su -c \"echo 'sudo service puppet stop' >> /etc/rc.d/rc.local\"",
      #made this manual now
      #"sudo su -c \"echo 'sudo /opt/puppetlabs/bin/puppet agent --daemonize --verbose --server=default.c.graceful-matter-161422.internal --runinterval=0' >> /etc/rc.d/rc.local\"",
      "sudo chmod +x /etc/rc.d/rc.local",
      "sudo /etc/rc.d/rc.local", //the first run doesn't execute this - needs a reboot. so running here
    ]

    connection {
      type        = "ssh"
      user        = "terry"
      private_key = "${file("${var.gce_ssh_private_key_file}")}"
      agent       = false
    }
  }

  scheduling { 
    //preemptible = true //temporarily turn off because of POC
  }

  depends_on = ["google_compute_instance.master"]
  
}

output "node3_ip" {
  //value = "${google_compute_address.node.address}"
  value = "${google_compute_instance.node3.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "ssh_command_node3" {
  value = "ssh -i ${var.gce_ssh_private_key_file} ${var.gce_ssh_user}@${google_compute_instance.node3.network_interface.0.access_config.0.assigned_nat_ip}"
}
