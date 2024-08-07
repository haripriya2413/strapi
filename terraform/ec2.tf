variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
}
resource "random_id" "this" {
  byte_length = 8
}

resource "aws_security_group" "strapi_sg" {
  name = "StrapiInstance1"
  description = "Security group for Strapi EC2 instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"] # Canonical
}


resource "aws_instance" "strapi" {
  ami           = data.aws_ami.ubuntu.id  # Correct AMI ID for ap-south-1
  instance_type = var.instance_type             # Changed to t2.medium
  key_name      = var.key_pair               # Your key pair name
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]

  tags = {
    Name = "StrapiServer1"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y curl git",
      "curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -",
      "sudo apt-get install -y nodejs",
      "sudo npm install -g pm2",
      "if [ ! -d /srv/strapi ]; then sudo git clone https://github.com/haripriya2413/strapi-project /srv/strapi; else cd /srv/strapi && sudo git pull origin main; fi",
      #"sudo chmod u+x /srv/strapi/generate_env_variables.sh*",
      #"cd /srv/strapi",
      #"sudo ./generate_env_variables.sh",
    

    
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }
}

output "instance_ip" {
  value = aws_instance.strapi.public_ip
}
