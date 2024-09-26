variable "aws_key_pair_1" {
  default = "D:\\Terraform- Docs\\Terraform\\devops-master-class\\terraform\\05-ec2-instances\\terraform-ec2.pem"
}

provider "aws" {
  region = "us-east-1"
  //version = "~> 2.46" (No longer necessary)
}

resource "aws_default_vpc" "default" {

}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

data "aws_ami_ids" "aws_linux_2_latest_ids" {
  //most_recent = true
  //sort_ascending = true
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
    //  values = ["amzn2-ami-kernel-5.10-hvm*"]
  }
}
resource "aws_security_group" "http_server_sg" {
  name = "http_server_sg"
  //vpc_id = "vpc-0f884e23141f6c354"
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "http_server_sg"
  }
}



resource "aws_instance" "http_server" {
  #ami = "ami-0ebfd941bbafe70c6"
  ami           = data.aws_ami_ids.aws_linux_2_latest_ids.ids[0]
  key_name      = "terraform-ec2"
  instance_type = "t2.micro"

  //vpc_security_group_ids = ["sg-0d2686137294d4191"]
  vpc_security_group_ids = [aws_security_group.http_server_sg.id]

  //subnet_id = "subnet-00aa56ee090b4158f"
  subnet_id = data.aws_subnets.default_subnets.ids[0]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.aws_key_pair_1)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd -y",
      "sudo service httpd start",
      "echo Welcome to in28minutes - Virtual Server is at ${self.public_dns} | sudo tee /var/www/html/index.html"
    ]
  }
}