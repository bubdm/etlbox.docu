# Custom sources & destinations

ETLBox allows you to write your own implementation of sources and destinations. This gives you a 
great flexibility if you need to integrate systems that are currently now included in the list of default 
connectors.

## CustomSource

A custom source can generate any type of  output you need. 
It will accept tow function: One function that generates the your output, and another one that return true if you reached the end of your data. 

### Simple example

Let's look at a simple example. Assuming we have a list of strings, and we want to return these string wrapped into an object data for our source.

First we define an object

```C#
public class MyRow {
    public int Id { get; set; }
    public string Value { get; set; }
}

List<string> Data = new List<string>() { "Test1", "Test2", "Test3" };
int _readIndex = 0;

CustomSource<MySimpleRow> source = new CustomSource<MySimpleRow>(
    () => {
        return new MyRow()
        {
            Id = _readIndex++,
            Value = Data[_readIndex]
        };
    }, 
    () => _readIndex >= Data.Count);
```

CustomSource also works with dynamic ExpandoObject and arrays. 


## Custom Destination

The use of a custom destination is even simpler - a custom destination 
just calls an action for every received record.

Here is an example:

```C#
CustomDestination<MySimpleRow> dest = new CustomDestination<MySimpleRow>(
    row => {
        SqlTask.ExecuteNonQuery(Connection, "Insert row",
            $"INSERT INTO dbo.CustomDestination VALUES({row.Id},'{row.Value}')");
    }
);
```

CustomDestination also works with dynamic ExpandoObject and arrays. 