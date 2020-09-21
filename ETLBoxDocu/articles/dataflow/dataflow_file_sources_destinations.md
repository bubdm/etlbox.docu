# Integration of flat files and web services

## Supported types

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

### Resource Type and Web Requests

All flat files sources and destinations in this article can be set to work either with a file
or to use data from a web service. If you want to access a file on your drive or a network share,
use the component with the `ResourceType.File` option.

This is default for CsvSource/CsvDestination, but not for the XmlSource/XmlDestination or JsonSource/JsonDestination.

The other option is `ResourceType.Http` - and allows you to read data from a web service. 
Instead of a filename just provide a url. Furthermore, the components also have 
a `[HttpClient](https://docs.microsoft.com/en-us/dotnet/api/system.net.http.httpclient?view=netframework-4.8)` and for sources a `HttpRequestMessage`property that can be used to configure the http request, e.g. to add authentication or use https instead.


## Example with csv source


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
    source.Execute();
    dest.Wait();
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
    source.Execute();
    dest.Wait();
}
```

## Read more

- If you want to read csv data from a file or webservice, [read the article about the csv connector package](../connectors/csv.md)
- If you ned to get json data from a file or webservice, [read the article about the jon connector package](../connectors/json.md)
- If you want to integrate xml as a file or from a web service, [read the article about the xml connector package](../connectors/xml.md).
- If you want to read from excel file, [read the article about the excel connector package](../connectors/excel.md).



