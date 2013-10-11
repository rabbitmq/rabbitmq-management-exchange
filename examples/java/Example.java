
import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;
import com.rabbitmq.client.MessageProperties;
import com.rabbitmq.client.QueueingConsumer;

import java.io.IOException;

public class Example {
    public static void main(String[] args) throws IOException, InterruptedException {
        ConnectionFactory f = new ConnectionFactory();
        Connection c = f.newConnection();
        Channel ch = c.createChannel();
        String replyQ = ch.queueDeclare().getQueue();
        ch.exchangeDeclare("mgmt", "x-management");

        AMQP.BasicProperties props = MessageProperties.BASIC.builder().type("GET").replyTo(replyQ).build();
        ch.basicPublish("mgmt", "/queues?columns=name", props, new byte[]{});

        QueueingConsumer consumer = new QueueingConsumer(ch);
        ch.basicConsume(replyQ, true, consumer);
        QueueingConsumer.Delivery del = consumer.nextDelivery();

        System.out.println("Queues are: " + new String(del.getBody()));

        c.close();
    }
}
