provider "aws"{
   region = "ap-south-1"
   profile = "mytask"
}

resource "tls_private_key" "web_key" {
    algorithm   =  "RSA"
    rsa_bits    =  4096
}
resource "local_file" "private_key" {
    content         =  tls_private_key.web_key.private_key_pem
    filename        =  "web.pem"
    file_permission =  0400
}
resource "aws_key_pair" "gen_key" {
    key_name   = "web"
    public_key = tls_private_key.web_key.public_key_openssh
}

resource "aws_security_group" "grpname" {
  name        = "shivam_launch_wizard_task"
  description = "Allow inbound traffic-http,shh."
  vpc_id      = "vpc-f1908c99"

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "grpname"
  }
}

resource "aws_instance" "taskos" {

  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.gen_key.key_name
  security_groups = [ aws_security_group.grpname.name ]
  
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.web_key.private_key_pem
    host     = aws_instance.taskos.public_ip 
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "shivam1"
  }
}

output "myzone" {
       value = aws_instance.taskos.availability_zone
}

resource "aws_ebs_volume" "taskvol" {
  depends_on = [
    aws_instance.taskos
  ]
  availability_zone = aws_instance.taskos.availability_zone
  size              = 1

  tags = {
    Name = "myteratask"
  }
}

output "taskid" {
       value = aws_ebs_volume.taskvol.id
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.taskvol.id
  instance_id = aws_instance.taskos.id
  //force_detach = true
}

resource "null_resource" "nulltaskvol1"  {

depends_on = [
    aws_volume_attachment.ebs_att
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.web_key.private_key_pem
    host     = aws_instance.taskos.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4 /dev/xvda",
      "sudo mount /dev/xvda /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo setenforce 0",
      "sudo git clone https://github.com/shivamagarwal1999/aws-terraform.git /var/www/html" 
      
    ]
  }
}


resource "aws_s3_bucket" "buk_task1" {
  bucket = "task-bucket2"
  acl    = "public-read"


  tags = {
    Name        = "task_buk12"
  }
}


resource "aws_s3_bucket_object" "taskimage" {
  bucket = aws_s3_bucket.buk_task1.bucket
  key    = "terraform.png"
  source = "C://Users/shivam/Desktop/terraform.png"
  acl="public-read"
}
output "myoutput" {
           value = aws_s3_bucket.buk_task1
}
output "mytaskos_ip" {
  value = aws_instance.taskos.public_ip
}


resource "aws_cloudfront_distribution" "s3_task_distribution" {
  origin {
    domain_name = aws_s3_bucket.buk_task1.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.buk_task1.id
  }	

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "mytaskcloudfront"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.buk_task1.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
  }
 price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "IN"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.web_key.private_key_pem
    host        = aws_instance.taskos.public_ip
}


  provisioner "remote-exec" {
        inline  = [
            "sudo rm -f /var/www/html/*",
            "sudo git clone https://github.com/shivamagarwal1999/aws-terraform.git /var/www/html/",
            
            "sudo echo \"<img src=\"https://${aws_cloudfront_distribution.s3_task_distribution.domain_name}/${aws_s3_bucket_object.taskimage.key}\">\" >> /var/www/html/index.html"
            ]
    }
}
resource "null_resource" "nulllocal1"  {


depends_on = [
    null_resource.nulltaskvol1,aws_instance.taskos,aws_cloudfront_distribution.s3_task_distribution
  ]

	provisioner "local-exec" {
	    command = "start chrome ${aws_instance.taskos.public_ip}"
  	}
}


