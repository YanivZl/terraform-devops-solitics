data "local_file" "alb_hostname" {
  filename = "${path.module}/alb_hostname"
}