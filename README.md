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

## Installation

Install the corresponding .ez files from our
[Community Plugins page](http://www.rabbitmq.com/community-plugins.html).

After installing, enable it with the following command:

    rabbitmq-plugins enable rabbitmq_management_exchange

## Usage

Declare an exchange of type `x-management`. Declare a reply queue (of
any name). Then publish requests to your new exchange. The exchange
will accept the requests and publish responses to your reply queue.

The format of a request message is:

* Query path (e.g. "/overview") in the routing key.
* Reply queue name in the 'reply_to' property.
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

## Configuration

It is possible to configure the plugin to use a non-default user
to authenticate HTTP API requests:

    [
      {rabbitmq_management_exchange, [{username, "my-username"},
                                      {password, "my-password"}]}
    ].

If the above section is skipped, `guest/guest` will be used.

See [RabbitMQ configuration guide](http://www.rabbitmq.com/configure.html) for details.

## Examples

There is a usage example using the Java client in `examples/java`. See
also the `test/src` directory for a simple test using the Erlang client.

## Building from Source

Build it like any other plugin. See [Plugin Development](http://www.rabbitmq.com/plugin-development.html).
