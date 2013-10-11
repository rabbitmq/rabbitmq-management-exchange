# RabbitMQ Management Exchange Type

This plugin provides a (slightly hackish) mechanism for making
requests to the RabbitMQ Management API while talking AMQP. In
essence, it allows you to publish messages to a special exchange type,
which then makes an HTTP request to localhost, and publishes the
response to a reply queue.

It currently has one notable limitation: the user name and password
for the HTTP request are taken from your configuration file rather
than the AMQP connection. If there is sufficient interest in this
plugin, we'll work to remove this limitation.

## Building

Build it like any other plugin. See
http://www.rabbitmq.com/plugin-development.html

tl;dr:

  $ hg clone http://hg.rabbitmq.com/rabbitmq-public-umbrella
  $ cd rabbitmq-public-umbrella
  $ make co
  $ git clone https://github.com/simonmacmullen/rabbitmq-management-exchange.git
  $ cd rabbitmq-management-exchange
  $ make -j

## Configuring

Enable the plugin:

  rabbitmq-plugins enable rabbitmq_management_exchange

Configure the plugin to authenticate:

(see http://www.rabbitmq.com/configure.html for general help on that)

    [
      {rabbitmq_management_exchange, [{username, "my-username"},
                                      {password, "my-password"}]}
    ].

## Using

Declare an exchange of type `x-management`. Declare a reply queue (of
any name). Then publish requests to your new exchange. The exchange
will accept the requests and publish responses to your reply queue.

The format of a request message is:

* Query path (e.g. "/overview") in the routing key.
* Reply queue name in the 'reply-to' property.
* HTTP method (e.g. "GET") in the 'type' property.
* JSON body (if there is one) in the message payload.

The format of a reply message is:

* Reply queue name in the routing key.
* HTTP response code (e.g. "200") in the 'type' property.
* JSON response (if there is one) in the message payload.

If you set a correlation-id in the request, it will be preserved in
the response.

Since the exchange accepts requests itself it does not need to be
bound to any queue (and indeed it's an error to do so). This means
that if you publish to the exchange with "mandatory" set, your message
will be returned as unrouted - since it did not go to any queue.

## Examples

There is a usage example using the Java client in `examples/java`. See
also the `test/src` directory for a simple test using the Erlang client.