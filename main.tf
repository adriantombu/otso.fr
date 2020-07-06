provider "aws" {
  version = "~> 2.69"
  region  = "eu-west-1"
}

resource "aws_s3_bucket" "b" {
  bucket = "otso.fr"
  arn    = "arn:aws:s3:::otso.fr"
  acl    = "public-read"
  policy = file("policy.json")

  website {
    index_document = "index.html"
  }
}

provider "cloudflare" {
  version   = "~> 2.8"
  api_token = var.cloudflare_token
}

resource "cloudflare_record" "main" {
  zone_id    = var.cloudflare_zone_id
  type       = "CNAME"
  name       = "otso.fr"
  value      = "otso.fr.s3-website-eu-west-1.amazonaws.com"
  proxied    = true
  depends_on = [aws_s3_bucket.b]
}

resource "cloudflare_record" "www" {
  zone_id    = var.cloudflare_zone_id
  type       = "CNAME"
  name       = "www"
  value      = "otso.fr.s3-website-eu-west-1.amazonaws.com"
  proxied    = true
  depends_on = [aws_s3_bucket.b]
}

resource "cloudflare_page_rule" "redirect" {
  zone_id  = var.cloudflare_zone_id
  target   = "www.otso.fr/*"
  priority = 3

  actions {
    forwarding_url {
      url         = "https://otso.fr/$1"
      status_code = 301
    }
  }
}

resource "cloudflare_page_rule" "main-https" {
  zone_id  = var.cloudflare_zone_id
  target   = "http://otso.fr/"
  priority = 2

  actions {
    always_use_https = true
  }
}

resource "cloudflare_page_rule" "blog-https" {
  zone_id  = var.cloudflare_zone_id
  target   = "http://blog.otso.fr/"
  priority = 1

  actions {
    always_use_https = true
  }
}
