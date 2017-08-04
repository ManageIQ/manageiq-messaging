# Examples for manageiq-messaging


```bash
docker run -d -p 61616:61616 \
           -e ARTEMIS_USERNAME=admin \
           -e ARTEMIS_PASSWORD=smartvm \
           vromero/activemq-artemis
```


```bash
cd examples
bundle exec ruby message.rb
bundle exec ruby background_job.rb
```
