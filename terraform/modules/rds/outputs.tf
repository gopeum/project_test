output "writer_endpoint" {
  value     = aws_db_instance.writer.address
  sensitive = true
}

output "reader_endpoint" {
  value     = aws_db_instance.reader.address
  sensitive = true
}

output "db_port" {
  value = aws_db_instance.writer.port
}

output "db_writer_ssm" {
  value = aws_ssm_parameter.db_writer_endpoint.name
}

output "db_reader_ssm" {
  value = aws_ssm_parameter.db_reader_endpoint.name
}

output "db_password_ssm" {
  value = aws_ssm_parameter.db_password.name
}