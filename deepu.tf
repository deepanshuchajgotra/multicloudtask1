#AWS Using TERRAFORM
provider "aws" {
  region = "ap-south-1"
  profile = "deepanshu"
}

#Creating a Security Group
resource "aws_security_group" "dp-security-1" {
  name        = "dp-security-1"
  description = "Allow TLS inbound traffic"

  ingress {
    description = "TCP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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

  tags = {
    Name = "DP-Security"
  }
}

#Creatig the instance
resource "aws_instance" "web" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "mykey111"
  security_groups = [ "dp-security-1" ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Deepanshu Mahajan/Downloads/mykey111.pem")
    host     = aws_instance.web.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "os1"
  }

}

#Creating and attaching the EBS volume
resource "aws_ebs_volume" "esb1" {
  availability_zone = aws_instance.web.availability_zone
  size              = 1
  tags = {
    Name = "ebs"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.esb1.id}"
  instance_id = "${aws_instance.web.id}"
  force_detach = true
}

#Creating an S3 Bucket
resource "aws_s3_bucket" "deep-s3-bucket2612" {
  bucket = "deep-s3-bucket2612"
  acl    = "private"
  region = "ap-south-1"

  tags = {
    Name = "S3_Bucket"
  }
}

locals {
  s3_origin_id = "dp-s3-origin"
}

resource "aws_s3_bucket_object" "deep-s3-bucket2612" {
  bucket = "deep-s3-bucket2612"
  key    = "download.png"
  source = "C:/Users/Deepanshu Mahajan/Desktop/terra/mytest/filemd5/download.png"
}

resource "aws_s3_bucket_public_access_block" "s3_public" {
  bucket = "deep-s3-bucket2612"

  block_public_acls   = false
  block_public_policy = false
}



resource "aws_cloudfront_distribution" "cloudfront_dist" {
  origin {
    domain_name = aws_s3_bucket.deep-s3-bucket2612.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    custom_origin_config {
      http_port = 80
      https_port = 80
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }
  
  enabled = true

  default_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}





output "myos_ip" {
  value = aws_instance.web.public_ip
}


resource "null_resource" "nulllocal2"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.web.public_ip} > publicip.txt"
  	}
}



resource "null_resource" "nullremote3"  {

depends_on = [
    aws_volume_attachment.ebs_att,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Deepanshu Mahajan/Downloads/mykey111.pem")
    host     = aws_instance.web.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/deepanshuchajgotra/multicloudtask1.git /var/www/html/"
    ]
  }
}



resource "null_resource" "nulllocal1"  {


depends_on = [
    null_resource.nullremote3,
  ]

	provisioner "local-exec" {
	    command = "start chrome  ${aws_instance.web.public_ip}"
  	}
}

