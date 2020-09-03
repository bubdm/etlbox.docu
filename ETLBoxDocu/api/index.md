# API Documentation

## Welcome 

Welcome to the API documentation of ETLBox. This will give you access to all class and interface definitions that come with ETLBox.
Check the [Github page](https://github.com/etlbox/etlbox) to see the full source code.
Please note that connection managers are now closed source. 

## .NET Standard App

ETLBox is .NET Standard app (.NET Standard 2.0 or higher) and therefore works with many current .NET version. [See the official .NET implementation support for more details.](https://docs.microsoft.com/en-us/dotnet/standard/net-standard)

## Namespaces

ETLBox is divided in several namepsace. 

The most important ones are: `ETLBox.ControlFlow.Tasks`,  `ETLBox.DataFlow.Connectors` and `ETLBox.DataFlow.Transformations`.
They containt the components that you usually work with to create your data flow or control your database. 

To establish connection to a database, file or whereever you'll need a connection manager from the `ETLBox.Connection` namespace.

You'll find tasks related to logging in the namespace `ETLBox.Logging`.

Classes with some useful (mostly static) methods are in the namespace `ETLBox.Helper`.