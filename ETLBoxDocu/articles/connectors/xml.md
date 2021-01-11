# Xml

## Xml connector package

If you need to work with xml code, make sure to add the latest nuget package [with the xml connector for ETLbox](https://www.nuget.org/packages/ETLBox.Xml/)

### XmlSource

The xml source let you read data from a xml source.

Let's assume your xml file looks like this:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Root>
    <MySimpleRow Col1="1">
        <Col2>Test1</Col2>
    </MySimpleRow>
    <MySimpleRow Col1="2">
        <Col2>Test2</Col2>
    </MySimpleRow>
</Root>
```

Xml reading is based on the Microsoft XmlSerializer (using System.Xml.Serialization). You can make use of the default xml attribute 
annotations to influence how data is read by the XmlSerializer. For the example xml above, the following code could read the xml file:

```C#
[XmlRoot("MySimpleRow")]
public class MyRow
{
    [XmlAttribute]
    public int Col1 { get; set; }
    public string Col2 { get; set; }
}

XmlSource<MyRow> source = new XmlSource<MyRow>("source.xml", ResourceType.File);
```

#### Using dynamic objects

XmlSource does also support the dynamic ExpandoObject. If you want to use it, you can define an ElementName that contains the data you actually
want to parse - as you normally are not interested in your root element. ETLBox then will look for this Element and parse every occurrence of
it into an ExpandoObject and send it into the connected components. 

Here is an example. If your xml looks like this:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Root>
    <MySimpleRow>
        <Column1>1</Column1>
        <Column2>Test1</Column2>
    </MySimpleRow>
    <MySimpleRow>
        <Column1>2</Column1>
        <Column2>Test2</Column2>
    </MySimpleRow>
<Root>
```

You can parse the two elements <MySimpleRow> with the following code:

```C#
XmlSource source = new XmlSource("demo2.xml", ResourceType.File)
{
    ElementName = "MySimpleRow"
};
```

### XmlDestination

The xml destination will use the same XmlSerializer to serialize the data and write them into an xml file.

Here is an example how to influence the XmlSerializer using attributes:

```C#
[XmlRoot("MySimpleRow")]
public class MyRow
{
    [XmlAttribute]
    public int Col1 { get; set; }
    [XmlAttribute]
    public string Col2 { get; set; }
}

XmlDestination<MyRow> dest = new XmlDestination<MyRow>("dest.xml", ResourceType.File);
```

Could create an output that looks like this:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Root>
  <MySimpleRow Col1="1" Col2="Test1" />
  <MySimpleRow Col1="2" />
</Root>
```


### XmlSchemaValidation

This transformation validates a given string that contains xml with a defined Xml schema definition. Not valid xml is redirected to 
the error output. 

Here is an example code:

```C#
string xsdMarkup = @"<xsd:schema xmlns:xsd='http://www.w3.org/2001/XMLSchema'>
   <xsd:element name='Root'>
      <xsd:complexType>
         <xsd:sequence>
            <xsd:element name='Child1' minOccurs='1' maxOccurs='1'/>
            <xsd:element name='Child2' minOccurs='1' maxOccurs='1'/>
         </xsd:sequence>
     </xsd:complexType>
   </xsd:element>
</xsd:schema>";

public class MyXmlRow
{
  public string Xml { get; set; }
}

string _validXml => $@"<?xml version=""1.0"" encoding=""utf-8""?>
<Root>
  <Child1>Content1</Child1>
  <Child2>Content2</Child2>
</Root>";

string _invalidXml => $@"<?xml version=""1.0"" encoding=""utf-8""?>
<Root>
  <Child1>Content1</Child1>
  <Child3>Content3</Child3>
</Root>";

var source = new MemorySource<MyXmlRow>();
source.DataAsList.Add(new MyXmlRow() { Xml = _validXml });
source.DataAsList.Add(new MyXmlRow() { Xml = _invalidXml });
MemoryDestination<MyXmlRow> dest = new MemoryDestination<MyXmlRow>();
MemoryDestination<ETLBoxError> error = new MemoryDestination<ETLBoxError>();

XmlSchemaValidation<MyXmlRow> schemaValidation = new XmlSchemaValidation<MyXmlRow>();
schemaValidation.XmlSelector = r => r.Xml;
schemaValidation.XmlSchema = xsdMarkup;
source.LinkTo(schemaValidation);
schemaValidation.LinkTo(dest);
schemaValidation.LinkErrorTo(error);
source.Execute();
```


### 3rd party libraries

 The xml connector package is based on `System.Xml`. 