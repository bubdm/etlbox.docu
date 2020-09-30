# In-Memory

## Memory Source

A Memory source is a simple source component that accepts a .NET list or enumerable. Use this component
within your data flow if you already have a collection containing your data available in memory.
When you execute the flow, the memory destination will iterate through the list and 
asynchronously post record by record into the flow.

### Example with own list

Here is an example code that uses your own list object to assign source data to the memory source. 

```C#
MemorySource<MyRow> source = new MemorySource<MyRow>();
source.Data = new List<MyRow>()
{
    new MyRow() { Id = 1, Value = "Test1" },
    new MyRow() { Id = 2, Value = "Test2" },
    new MyRow() { Id = 3, Value = "Test3" }
};
```

The `Data` property of the MemorySource will accept any `IEnumerable<T>`. 

#### Using the internal list

By default, the `Data` property is always initialized with an empty List<T>, where T is the type of your MemorySource. This list can also be used to add data to it. Because the IEnumerable type of `Data` has some limitations regarding records, you can use the property `Data`DataAsList`. This will try to cast the current list stored in `Data` into an `IList<T>`. If you don't get null, this was successfully, and you can use the methods implement on this interface. This allows you to direct write code like this:

```C#
MemorySource<MyRow> source = new MemorySource<MyRow>();
source.DataAsList.Add(new MyRow() { Id = 1, Value = "Test1" });
source.DataAsList.Add(new MyRow() { Id = 2, Value = "Test2" });
source.DataAsList.Add(new MyRow() { Id = 3, Value = "Test3" });
```

#### Using dynamic object

The default implementation of the MemorySource works internally with an ExpandoObject. 

```C#
dynamic row = new ExpandoObject();
row.Id = 1;
row.Value = "Test1";

MemorySource source = new MemorySource();
source.DataAsList.Add(row);            
```

#### Using arrays

You can also use the MemorySource with arrays.  

```C#
 MemorySource<string[]> source = new MemorySource<string[]>();
 source.DataAsList = new List<string[]>()
 {
    new string[] { "1", "Test1" },
    new string[] { "2", "Test2" },
    new string[] { "3", "Test3" },
};
```

### Output buffer

The MemorySource has an output buffer - this means that every data row can be cached before it is send to the next component in the flow. You can restrict the maximal buffer size by setting MaxBufferSize to a value greater than 0. The default value is 100000 rows. 

### MemorySource Api documentation

The full class documentation can be found in the Api documentation.

- If the output type is an array or object, [use the MemorySource that accepts one data type](https://etlbox.net/api/ETLBox.DataFlow.Connectors.MemorySource-1.html).
- If the output type is an ExpandoObject, [use the default implementation](https://etlbox.net/api/ETLBox.DataFlow.Connectors.MemorySource.html).


## MemoryDestination 

A memory destination stores the incoming data within a List. 
You can access the received data within the `Data` property.
Data should be read from this collection when all data has arrived at the destination. If you want to access the data asynchronously while the list is still receiving data from the flow, consider using the `ConcurrentMemoryDestination`. 
As the `Data` property will internally use an `List<T>`, accessing data in this list while your data flow is still running is not thread safe. See below the details for the ConcurrentMemoryDestination. 

### Example 

```C#
MemoryDestination<MyRow> dest = new MemoryDestination<MyRow>();
// data is accessible in dest.Data 
```

#### Using dynamic objects

The default implementation of `MemoryDestination` will use internal the ExpandoObject

```C#
var dest = new MemoryDestination();
```

#### Using array

You can use the MemoryDestination also with arrays.

```C#
var dest = new MemoryDestination<string[]>();
```

### ConcurrentMemoryDestination

A memory destination is a component that store the incoming data within a [BlockingCollection](https://docs.microsoft.com/de-de/dotnet/api/system.collections.concurrent.blockingcollection-1?view=netframework-4.8).
You can access the received data within the `Data` property. The BlockingCollection is designed to be thread-safe. 
Data can be read from this collection as soon as it arrives, and you don't have to wait for you data flow to finish. 

Example:

```C#
ConcurrentMemoryDestination<MySimpleRow> dest = new ConcurrentMemoryDestination<MySimpleRow>();
// data is accessible in dest.Data 
```

### Input buffer

The MemoryDestination as well as the ConcurrentMemoryDestination has an input buffer - this means that every data row can be cached before it is actually processed from your destination. You can restrict the maximal buffer size by setting MaxBufferSize to a value greater than 0. The default value is 100000 rows. 

### MemoryDestination & ConcurrentMemoryDestination Api documentation

The full class documentation can be found in the Api documentation.

#### MemoryDestination:

- If the input type is an array or object, [use the MemoryDestination that accepts one data type](https://etlbox.net/api/ETLBox.DataFlow.Connectors.MemoryDestination-1.html).
- If the input type is an ExpandoObject, [use the default implementation](https://etlbox.net/api/ETLBox.DataFlow.Connectors.MemoryDestination.html).

#### ConcurrentMemoryDestination

- If the input type is an array or object, [use the ConcurrentMemoryDestination that accepts one data type](https://etlbox.net/api/ETLBox.DataFlow.Connectors.ConcurrentMemoryDestination-1.html).
- If the input type is an ExpandoObject, [use the default implementation](https://etlbox.net/api/ETLBox.DataFlow.Connectors.ConcurrentMemoryDestination.html).

