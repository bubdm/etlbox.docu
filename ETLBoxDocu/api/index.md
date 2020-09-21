# API Documentation

## Source Code 
This is the complete API documentation of ETLBox. It lists all classes and interface definitions that are available with all ETLBox packages. Most classes are part of the core packages, some classes (the connectors) are part of the connector packages. 
Check the [Github page](https://github.com/etlbox/etlbox) to see the full source code for the core package. Please note that connection managers are now closed source. It is possible to get access to the source code of the connector packages if you purchase a paid license.

### .NET Standard App

ETLBox is .NET Standard app (.NET Standard 2.0 or higher) and therefore works with many current .NET version. [See the official .NET implementation support for more details.](https://docs.microsoft.com/en-us/dotnet/standard/net-standard)

### Namespaces

ETLBox is divided in several namespace. 

The most important ones are: `ETLBox.ControlFlow.Tasks`,  `ETLBox.DataFlow.Connectors` and `ETLBox.DataFlow.Transformations`.
They contain the components that you usually work with to create your data flow or control your database. 

To establish a connection to a database you will need a connection manager from the `ETLBox.Connection` namespace.

Tasks related to logging reside in the namespace `ETLBox.Logging`.

Classes with some useful (mostly static) methods are in the namespace `ETLBox.Helper`.

### 3rd party dependencies

ETLBox core and the connector packages may rely on different 3rd party libraries. 

- The implementation for the Excel Source is based on https://github.com/ExcelDataReader/ExcelDataReader
- The CsvSource is based on https://joshclose.github.io/CsvHelper/