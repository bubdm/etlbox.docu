# Sources and destinations

## Connectors 

There are several connectors available in ETLBox that allow you to connect to a database, a flat file, a web service, a C# collection or any other data source or destination that you like. The connector normally have a Source and a Destination component. The source is used to retrieve data, and the destination used to write or store your data. They are always used at the beginning or the end of data flow (though of course every flow can have multiple sources and destinations.) In between can be transformation that modifies your data. 

### Buffers 

By default, every source has an output buffer and every destination an input buffer. This buffer are needed to improve performance. E.g. while a source is reading data from the source, it can post already data into its output buffer. Data from the output buffer is then fetched from the connected transformations and further processed.  Vice versa for the destination: the transformations can send data to the destination, and the destination can buffer this data while it is busy writing the previous data. 
If you need to adjust the size of the output or input buffer, you can set the MaxBufferSize property of the component. This will restrict the number or rows in the buffer if you set it to a value greater than 0. 

## Database integration

There a numerous database connector packages that come with ETLBox. Add the connector package for the database that you want to connect with.
Then you can access these database using the DbSource and DbDestination. Each database connection also needs the right connection manager. For Sql Server you would the SqlConnectionManager, and for Postgres the PostgresConnectionManager. 

### DbSource

The DbSource is the most common data source for a data flow. It basically connects to a database via ADO.NET and executes a SELECT-statement to start reading the data. 
While data is read from the source, it is simultaneously posted into the dataflow pipe. This enables the DbSource also to handle big amount of data - it constantly can 
read data from a big table while already read data can be processed by the connected componentens. 

To initialize a DbSource, you can simply pass a table (or view) name or a SQL-statement. The DbSource also accepts a connection manager. 

The following code would read all data from the table `SourceTable` and use the default connection manager:

```C#
DbSource source = new DbSource("SourceTable");
```

#### Working with types

In the examples above we used a  object without a type.
This will let ETLBox work internally with an `ExpandoObject` which is a dynamic .NET object type.
Let's assume that SouceTable has two columns:

ColumnName|Data Type
----------|---------
Id|INTEGER
Value|VARCHAR

Reading from this table using the DbSource without type will internally create a dynamic object with two properties: Id of type int and Value of type string.

Working with dynamic objects has some drawbacks, as .NET is a strongly typed language. Of course you can also use a generic object 
to type the DbSource.

Let's assume we create a POCO (Plain old component object) `MySimpleRow` that looks like this:

```C#
public class MySimpleRow {
    public int Id { get; set;}
    public string Value { get; set;}
}
```

Now we can read the data from the source with a generic object:

```C#
DbSource<MySimpleRow> source = new DbSource<MySimpleRow>("SourceTable");
```

ETLBox will automatically extract missing meta information during runtime from the source table and the involved types. In our example, the source table has
the exact same columns as the object - ETLBox will check this and write data from the Id column into the Id property, and data from the column Value into the Value property.
Each record in the source will be a new object that is created and then passed to the connected components. 


### DbDestination

Like the `DbSource`, the `DbDestination` is the common component for sending data into a database. It is initialized with a table name.
Unlike other Destinations, the DbDestination inserts data into the database in batches. The default batch size is 1000 rows - the DbDestination waits
until it's input buffer has reached the batch size before it bulk inserts the data into the database. 

The following example would transfer data from the destination to the source:

```C#
DbSource source = new DbSource("SourceTable");
DbDestination dest = new DbDestination("DestinationTable");
//Link everything together
source.LinkTo(dest);
//Start the data flow
Network.Execute(source);
```

### Connection manager

#### Connection strings

To connect to your database of choice, you will need a string that contains all information needed to connect
to your database (e.g., the network address of the database, user name and password). The specific connection string syntax 
for each provider is defined by the ADO.NET framework. If you need assistance
to create such a connection string, <a href="https://www.connectionstrings.com" target="_blank">have a look at this website that 
provide example strings for almost every database</a>.

#### Database Connections

The `DbSource` and `DbDestination` can be used to connect via ADO.NET to a database server. 
To do so, it will need the correct connection manager and either a raw connection string or a `ConnectionString` object. 
The easiest way is to directly pass a raw connection string and create with it a connection manager.  

Here is an example creating a connection manager for Sql Server and pass it to a DbSource:

```C#
DbSource source = DbSource (
    new SqlConnectionManager("Data Source=.;Integrated Security=SSPI;Initial Catalog=ETLBox;")
    , "SourceTable"
);
```

For other databases the code looks very similar. Please be aware that the connection string might look different.

E.g., this is how you create a connection manager for MySql:

```C#
MySqlConnectionManager connectionManager = new MySqlConnectionManager("Server=10.37.128.2;Database=ETLBox_ControlFlow;Uid=etlbox;Pwd=etlboxpassword;";
```

## Integration of flat files and web services

### Supported types

ETLBox currently supports the following data types:

- Csv
- Json
- Xml
- Text
- Excel 

There is a connector package for each data type that must be included together with the core package. 

All these types can be *read* either from a flat file (e.g. a .csv file on your local machine or a network share) or via any
web services endpoint (e.g. a REST endpoint on `https://test.com/get` that returns a json). 
Also, all these types (except excel) can be *written* into a file or web service. E.g. you can write a text file into a network share at `//foo/bar` or send it as a POST into `https://test.com/postdata`. 

Once the data is read from one of these types into a data flow, all transformation that ETLBox offers can be used to transform the data. So these connectors allow you to send a csv file easily into a database table or to send it as json to a web service. 

#### Resource Type and Web Requests

All flat files sources and destinations in this article can be set to work either with a file
or to use data from a web service. If you want to access a file on your drive or a network share,
use the component with the `ResourceType.File` option.

This is default for CsvSource/CsvDestination, but not for the XmlSource/XmlDestination or JsonSource/JsonDestination.

The other option is `ResourceType.Http` - and allows you to read data from a web service. 
Instead of a filename just provide a url. Furthermore, the components also have 
a `[HttpClient](https://docs.microsoft.com/en-us/dotnet/api/system.net.http.httpclient?view=netframework-4.8)` and for sources a `HttpRequestMessage`property that can be used to configure the http request, e.g. to add authentication or use https instead.


### Example with csv source


A CsvSource simple reads data from a CSV file. 

Let's start with a simple example how to create a flat file source. In this scenario we are using the CsvSource. 

```C#
CsvSource<CsvType> source = new CsvSource<CsvType>("//share/demo.csv");
```

As for the CsvSource, the `ResourceType` is `ResourceType.File` by default. It will read data from the path `//share/demo.cvs`. 
By default, the CsvSource will try to use the header columns of the file to propagate the data into the right properties of the CsvType object. 

If you need to read a csv file from a webservice, your code would look like this:

```
CsvSource<CsvType> source = new CsvSource<CsvType>("http://test.com/csv");
source.ResourceType = ResourceType.Http;
```

Let's assume your csv would look like this:

```csv
Id;Value
1;Test1
2;Test2
```

Then this should be your CsvType class: 

```C#
public class CsvType {
    public int Id { get; set; }
    public int Value { get; set; }
}
```

Now you can use the CsvSource as source for either a transformation or any other destination. If you want to directly convert your data into Json, this would be your working code:

```C#
public class CsvType {
    public int Id { get; set; }
    public int Value { get; set; }
}

public static void Main() {
    CsvSource<CsvType> source = new CsvSource<CsvType>("http://test.com/csv");
    source.ResourceType = ResourceType.Http; //Default is File for CsvSource
    JsonDestination<CsvType> dest = new JsonDestination<CsvType>("test.json");
    dest.ResourceType = ResourceType.File;  //Default is Http for json
    source.LinkTo(dest);
    Network.Execute(source);
}
```

#### Using dynamic objects

For such simple flow you don't necessarily have to create an object. You can use the default implementation of CsvSource and JsonSource, which would use an ExpandoObject. As we don't need a strongly typed object here in this example, we could modify our code like this:

```C#
public static void Main() {
    CsvSource source = new CsvSource("http://test.com/csv");
    source.ResourceType = ResourceType.Http; //Default is File for CsvSource
    JsonDestination dest = new JsonDestination<CsvType>("test.json");
    dest.ResourceType = ResourceType.File; //Default is Http for json
    source.LinkTo(dest);
    Network.Execute(source);
}
```

### Read more

- If you want to read csv data from a file or webservice, [read the article about the csv connector package](../connectors/csv.md)
- If you ned to get json data from a file or webservice, [read the article about the jon connector package](../connectors/json.md)
- If you want to integrate xml as a file or from a web service, [read the article about the xml connector package](../connectors/xml.md).
- If you want to read from excel file, [read the article about the excel connector package](../connectors/excel.md).
- If you want to read from text file, [read the article about the text sources and destinations](../connectors/text.md).


## Other sources and destinations

### In memory connectors
There are more ways to connect with different sources.
You can access any collection in C# that implements IEnumerable directly as input. 
Or you can write into a C# list that implements IList. 
For this purposes you can use the MemorySource, MemoryDestination or ConcurrentMemoryDestination. The latter one is useful if you want to access your data while you are still writing into the destination list. 

### Custom connectors

If no connector of the ones mentioned above suits your needs, you can use the CustomSource and CustomDestination to define your own custom C# to create/read input data or to write/store your output. There are no limitations of what you can do with these connectors. They will allow you to access any kind of structured or unstructured data.

### Read more 

- [Read more about in memory sources and destinations](../connectors/memory.md)
- [Read more about the custom source and destination](../connectors/custom.md)