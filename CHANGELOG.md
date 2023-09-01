# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [1.4.0] - 01-Sept-2023
* Add Kafka SASL mechanism options to client ([#80](https://github.com/ManageIQ/manageiq-messaging/pull/80))

## [1.3.0] - 03-Apr-2023
* Add Kafka SSL keystore options to client [#77](https://github.com/ManageIQ/manageiq-messaging/pull/77)

## [1.2.0] - 19-Oct-2022

* Add ssl and ca_file options to `Client.open` [#76](https://github.com/ManageIQ/manageiq-messaging/pull/76)
* Add wait_for_topic option to Kafka [#75](https://github.com/ManageIQ/manageiq-messaging/pull/75)

## [1.1.2] - 6-Oct-2022

* Fix kafka publish_topic on ruby3 [#74](https://github.com/ManageIQ/manageiq-messaging/pull/74)

## [1.1.1] - 6-May-2022

* Ruby 3.0 support [#71](https://github.com/ManageIQ/manageiq-messaging/pull/71)

## [1.1.0] - 09-Feb-2022

* Allow rails 6.1 [#66](https://github.com/ManageIQ/manageiq-messaging/pull/66)

## [1.0.3] - 12-May-2021

* Allow bulk publish of messages to a topic

## [1.0.2] - 4-Jan-2021

* Rails 6.0 Support

## [1.0.1] - 15-Dec-2020

* Allow all kafka options to be passed
* remove sudo:false from .travis.yml
* Use manageiq-style

## [1.0.0] - 28-Sep-2020

* Switch to use rdkafka client

## [0.1.7] - 14-May-2021

* Loosen ActiveSupport dependency to ~> 5.2

## [0.1.6] - 6-July-2020

* Rescue message body decoding errors. Re-raise errors raised by users code of processing received messages. 

## [0.1.5] - 6-Jun-2019

* Allow caller to provide extra headers to the message

## [0.1.4] - 3-Apr-2019

* Add an #ack method to a ReceivedMessage to simplify manual acknowledgements
* Allow caller to provide a session_timeout to kafka consumers, default of 30sec

## [0.1.3] - 25-Feb-2019

## 0.1.2 - 11-Dec-2018

* Allow to set max_bytes to each_batch when subscribe to a Kafka topic.

## 0.1.1 - 20-Nov-2018

* By default upon receiving a message or an event, it is automatically acknowledged. But
  the subscriber can decide to turn off the auto ack feature and ack it in the callback block.

## 0.1.0 - 4-Oct-2018

* Initial release

[Unreleased]: https://github.com/ManageIQ/manageiq-messaging/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/ManageIQ/manageiq-messaging/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/ManageIQ/manageiq-messaging/compare/v1.1.2...v1.2.0
[1.1.2]: https://github.com/ManageIQ/manageiq-messaging/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/ManageIQ/manageiq-messaging/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/ManageIQ/manageiq-messaging/compare/v1.0.3...v1.1.0
[1.0.3]: https://github.com/ManageIQ/manageiq-messaging/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/ManageIQ/manageiq-messaging/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/ManageIQ/manageiq-messaging/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/ManageIQ/manageiq-messaging/compare/v0.1.7...v1.0.0
[0.1.7]: https://github.com/ManageIQ/manageiq-messaging/compare/v0.1.6...v0.1.7
[0.1.6]: https://github.com/ManageIQ/manageiq-messaging/compare/v0.1.5...v0.1.6
[0.1.5]: https://github.com/ManageIQ/manageiq-messaging/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/ManageIQ/manageiq-messaging/compare/v0.1.3...v0.1.4

