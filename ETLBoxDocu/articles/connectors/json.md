# Xml

## Json connector package

### JsonSource

Json Source let you read a json. 

Here an example for a json file:

```json
[
  {
    "Col1": 1,
    "Col2": "Test1"
  },
  {
    "Col1": 2,
    "Col2": "Test2"
  },
  {
    "Col1": 3,
    "Col2": "Test3"
  }
]
```

Here is some code that would read that json (and deserialize it into the object type):

```C#
public class MySimpleRow
{
    public int Col1 { get; set; }
    public string Col2 { get; set; }
}

JsonSource<MySimpleRow> source = new JsonSource<Todo>("http://test.com/");
```
This code would then read the three entries from the source and post it into it's connected component.

### Nested arrays

The array doesn't need to be the top node of your json - it could be nested in your json file. 
Like this:
```C#
{
    "data": {
        "array": [
            {
                "Col1": 1,
                "Col2": "Test1"
            },
            ...
        ]
    }
}
```

ETLBox automatically scans the incoming json file and starts reading (and deserializing) after the 
first occurrence of the begin of an array (which is the "[" symbol).

### Working with JsonSerializer

Sometimes you have a more complex json structure. Here an example:

```json
[
    {
        "Column1": 1,
        "Column2": {
            "Id": "A",
            "Value": "Test1"
        }
    },
    ...
]
```

If you defined your POCOs types to deserialize this json you would need to create objects like this:

```C#
public class MyRow
{
    public int Column1 { get; set; }
    public MyIdValueObject Column2 { get; set; }
}

public class MyIdValueObject
{
    public string Id { get; set; }
    public string Value { get; set; }
}
```

Sometimes you don't want to specify all objects that would map your json structure. To get around 
this the underlying JsonSerializer object that is used for deserialization
is exposed by the JsonSource. [`JsonSerializer` belongs to Newtonsoft.Json](https://www.newtonsoft.com/json/help/html/SerializingJSON.htm)  
You could add your own JsonConverter so that you could use JsonPath within your JsonProperty attributes. 
(Please note that the example JsonPathConverter is also part of ETLBox).

```C#
[JsonConverter(typeof(JsonPathConverter))]
public class MySimpleRow
{
    [JsonProperty("Column1")]
    public int Col1 { get; set; }
    [JsonProperty("Column2.Value")]
    public string Col2 { get; set; }
}

JsonSource<MySimpleRow> source = new JsonSource<MySimpleRow>("res/JsonSource/NestedData.json", ResourceType.File);
``` 

### JsonDestination

The result of your pipeline can be written as json using a JsonDestination. 

The following code:

```C#
 public class MySimpleRow
{
    public string Col2 { get; set; }
    public int Col1 { get; set; }
}

JsonDestination<MySimpleRow> dest = new JsonDestination<MySimpleRow>("test.json", ResourceType.File);
```

would result in the following json:

```
[
  {
    "Col1": 1,
    "Col2": "Test1"
  },
  {
    "Col1": 2,
    "Col2": "Test2"
  },
  {
    "Col1": 3,
    "Col2": "Test3"
  }
]
```

Like the JsonSource you can modify the exposed `JsonSerializer` to modify the serializing behavior.
[`JsonSerializer` belongs to Newtonsoft.Json](https://www.newtonsoft.com/json/help/html/SerializingJSON.htm)  

### Using Json with arrays

If you don't want to use objects, you can use arrays with your  `JsonSource`. Your code would look like this:

```C#
JsonSource<string[]> source = new JsonSource<string[]>("https://jsonplaceholder.typicode.com/todos");
```

Now you either have to override the `JsonSerializer` yourself in order to properly convert the json into a string[].
Or your incoming Json has to be in following format:

```Json
[
    [
        "1",
        "Test1"
    ],
    ...
]
```


### Working with dynamic objects

JsonSource and destination support the usage of dynamic object. This allows you to use
a dynamic ExpandoObject instead of a POCO. 

```C#
JsonSource<ExpandoObject> source = new JsonSource<ExpandoObject>("res/JsonSource/TwoColumnsDifferentNames.json", ResourceType.File);

RowTransformation<ExpandoObject> trans = new RowTransformation<ExpandoObject>(
    row =>
    {
        dynamic r = row as ExpandoObject;
        r.Col1 = r.Value1;
        r.Col2 = r.Value2;
        return r;
    });
DbDestination<ExpandoObject> dest = new DbDestination<ExpandoObject>(Connection, "DynamicJson");

source.LinkTo(trans).LinkTo(dest);
source.Execute();
dest.Wait();
```

### 3rd party libraries

It is based on the `Newtonsoft.Json` and the `JsonSerializer`