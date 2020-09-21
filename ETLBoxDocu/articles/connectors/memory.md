# In-Memory

## Memory Source

A Memory source is a simple source component that accepts a .NET list or enumerable. Use this component
within your data flow if you already have a collection containing your data available in memory.
When you execute the flow, the memory destination will iterate through the list and 
asynchronously post record by record into the flow.

Example code:

```C#
MemorySource<MySimpleRow> source = new MemorySource<MySimpleRow>();
source.Data = new List<MySimpleRow>()
{
    new MySimpleRow() { Col1 = 1, Col2 = "Test1" },
    new MySimpleRow() { Col1 = 2, Col2 = "Test2" },
    new MySimpleRow() { Col1 = 3, Col2 = "Test3" }
};
```

## MemoryDestination 

A memory destinatio stores the incoming data within a List. 
You can access the received data within the `Data` property.
Data should be read from this collection when all data has arrived at the destination. If you want to access the data asynchronously while the list is still receiving data from the flow, consider using the `ConcurrentMemoryDestination`. 

```C#
MemoryDestination<MySimpleRow> dest = new MemoryDestination<MySimpleRow>();
// data is accessible in dest.Data 
```

## ConcurrentMemoryDestination

A memory destination is a component that store the incoming data within a [BlockingCollection](https://docs.microsoft.com/de-de/dotnet/api/system.collections.concurrent.blockingcollection-1?view=netframework-4.8).
You can access the received data within the `Data` property.
Data can be read from this collection as soon as it arrives. 

Example:

```C#
ConcurrentMemoryDestination<MySimpleRow> dest = new ConcurrentMemoryDestination<MySimpleRow>();
// data is accessible in dest.Data 
```

