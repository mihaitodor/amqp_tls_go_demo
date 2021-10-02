# RabbitMQ Golang client with TLS (x509 certificate) authentication mechanism example

This repo contains an example of how to configure and run RabbitMQ in a Docker container which only allows client
connections via the TLS (x509 certificate) authentication mechanism. It also contains sample consumer and producer apps
built using https://github.com/rabbitmq/amqp091-go

Currently, https://github.com/rabbitmq/amqp091-go (which is the maintained clone of https://github.com/streadway/amqp)
does not support this mechanism and [this PR](https://github.com/rabbitmq/amqp091-go/pull/20) has been created to
address this limitation.

First, create certs using [`terraform`](https://www.terraform.io/). Note that the `tls_cert_request` uses `guest` as the
`common_name` in the `subject`, which corresponds to the user that RabbitMQ will determine from the incoming connection
cert. This is the default user in the RabbitMQ container and additional configuration is needed when configuring a
different user. I had no clue that Terraform can do this on localhost in such a clean and easy way. Thanks
[@jonasoneves](https://github.com/jonasoneves) for sharing this code
[here](https://github.com/Jeffail/benthos/discussions/761#discussioncomment-1416494)!

```shell
> terraform init
> terraform apply -auto-approve
```

Then run the RabbitMQ container with the [`rabbitmq-auth-mechanism-ssl`](https://github.com/rabbitmq/rabbitmq-auth-mechanism-ssl)
plugin enabled

```shell
> docker run --rm -v$(pwd):/workspace -e RABBITMQ_CONFIG_FILE=/workspace/rabbitmq.conf -p 5671:5671 --name=rabbitmq rabbitmq bash -c "rabbitmq-plugins enable rabbitmq_auth_mechanism_ssl && rabbitmq-server"
```

Optionally, configure another user in RabbitMQ if you don't wish to connect using the builtin `guest` user
```shell
> # docker exec rabbitmq bash -c "rabbitmqctl add_user client1 '' && rabbitmqctl set_permissions client1 '.*' '.*' '.*'"
```

Then use OpenSSL to validate the RabbitMQ config

```shell
> docker run --rm -v$(pwd):/workspace alpine/openssl s_client -connect host.docker.internal:5671 -cert /workspace/client-cert.pem -key /workspace/client-privkey.pem -CAfile /workspace/ca-cert.pem
```

Finally run the sample consumer and producer

```shell
> go run ./cmd/consumer
> # Open a new terminal
> go run ./cmd/producer
```
