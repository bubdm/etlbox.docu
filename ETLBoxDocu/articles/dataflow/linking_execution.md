# Execution, Linking and Completion

## Linking components

Before you can execute a data flow, you need to link your source, transformation and destinations.
The linking is quite easy - every source component and every transformation offers a LinkTo() method.
This method accepts a target, which either is another transformation or a destination. 

Example of Linking a `DbSource` to a `RowTransformation` and the to a `DbDestination`.

```C#
//Create the components
DbSource source = new DbSource("SourceTable");
RowTransformation rowTrans = new RowTransformation( row => row );
DbDestination dest = new DbDestination("DestTable");

//Link the components
source.LinkTo(row);
row.LinkTo(dest);
```

This will result in a flow which looks like this:

DbSource --> RowTransformation --> DbDestination

### Fluent notation

There is also a chained notation available, which give you the same result:

```C#
//Link the components
source.LinkTo(row).LinkTo(dest);
```

This notation can be used most of the time - please note that it won't work with `Multicast` or `MergeJoin` as these
components have more than one input respective output.

If your transformation has a different output type than your input, you need to adjust the linking a little bit. The LinkTo
accepts a type that defines the output of the linking. 
E.g. if you have a `RowTransformation<InputType, OutputType> row`, the linking would look like this:

```C#
source.LinkTo<OutputType>(row).LinkTo(dest)
```

## Predicates

Whenever you link components in a data flow, you can add a filter expression to the link -
this is called a predicate for the link.
The filter expression is evaluated for every row that goes through the link.
If the evaluated expression is true, data will pass into the linked component.
If evaluated to false, the data flow will try the next link to send its data through.

**Note:** Data will be send only into one of the connected links. If there is more than one link,
the first link that either has no predicate or which predicate returns true is used.

If you need data send into two ore more connected components, you can use the Multicast:

```C#
source.LinkTo(multicast);
multicast.LinkTo(dest1, row => row.Value2 <= 2);
multicast.LinkTo(dest2,  row => row.Value2 > 2);
Network.Execute(source);
```

### VoidDestination

Whenever you use predicates, sometime you end up with data which you don't want to write into a destination.
Unfortunately, your DataFlow won't finish until all rows where written into any destination block. That's why 
there is a `VoidDestination` in ETLBox. Use this destination for all records for that you don't wish any further processing. 

```C#
VoidDestination voidDest = new VoidDestination(); 
source.LinkTo(dest, row => row.Value > 0);
souce.Link(voidDest, row => row.Value <= 0);
```

#### Implicit use of VoidDestination

You don't have to define the `VoidDestinatin` explicitly. Assuming that we have a Database Source 
that we want to link to a database destination. But we only want to let data pass through where the 
a column is greater than 0. The rest we want to ignore. Normally, we would need to link the data twice like in 
the example above. But there is a short way to write it: 

```C#
source.LinkTo(dest, row => row.Value > 0,  row => row.Value <= 0);
```

Internally, this will create a `VoidDestination` when linking the components, but you don't have to deal with anymore.
At the end, only records where the Value column is greater 0 will be written into the destination.

## Linking errors

By default, exception won't be handled within you data flow components. Whenever within a source, transformation or 
a destination an error occurs, this exception will be thrown in your user code. You can use the normal try/catch block to handle
these exceptions.

If you want to handle exceptions within your data flow, some components offer the ability to redirect errors.
Beside the normal `LinkTo` method, you can use the  `LinkErrorTo` to redirect erroneous records into a separate pipeline.

Here an example for a database source, where error records are linked into a MemoryDestination:

```C#
DbSource<MySimpleRow> source = new DbSource<MySimpleRow>(connection, "SourceTable");
DbDestination<MySimpleRow> dest = new DbDestination<MySimpleRow>(connection, "DestinationTable");
MemoryDestination<ETLBoxError> errorDest = new MemoryDestination<ETLBoxError>();
source.LinkTo(dest);
source.LinkErrorTo(errorDest);
Network.Execute(source);
```

`LinkErrorTo` only accepts transformations or destinations that have the input type `ETLBoxError`. It will contain
the exception itself and an exception message, the time the error occurred, and the faulted record as json (if it was
possible to convert it).

ETLBoxError is defined like this:

```C#
public class ETLBoxError
{
    public string ErrorText { get; set; }
    public DateTime ReportTime { get; set; }
    public string ExceptionType { get; set; }
    public string RecordAsJson { get; set; }
}
```

### CreateErrorTableTask

If you want to store your exception in a table in a database, ETLBox offers you a task that will automatically 
create this table for you.

```C#
CreateErrorTableTask.Create(connection, "etlbox_error");
```

The table will have three columns: ErrorText, RecordAsJson and ReportTime (with the right data type). Of course you can 
create you own table.

## Multiple inputs

There is no restriction on the amount of inputs that a destination or transformation can have. Instead of having
only single source, you can have multiple source for every component that can be linked.

E.g. this is possible graph for you data flow:

```
DbSource1 ---> RowTransformation1 -|
DbSource2 -|-> RowTransformation2 -|-> DbDestination
CsvSource -|
```

In this example graph, RowTransformation2 has two inputs: DbSource2 & CsvSource. Also, DbDestination has two inputs:
RowTransformation1 & RowTransformation2. The DbDestination will complete when data from all sources 
(DbSource1, DbSource2, CsvSource) was written into the data flow and arrived at the DbDestination. 

*Note*: When you want to merge you data of multiple source before any further processing, consider using the 
`MergeJoin`. If you want to split your data, you can use the `Multicast`. 
[Read more about these transformations here.](../transformations/broadcast_merge_join.md)

## Synchronous Execution

The easiest way to execute a data flow is synchronous. That means that execution of your program is paused
until all data was read from sources and written into all destinations. Using the synchronous execution also makes
debugging a lot easier, as you don't have to deal with async programming and the specialties of exception
handling with tasks.

*Note*: In the background, the data flow is always executed asynchronous! The underlying data flow engine
is based on `Microsoft.TPL.Dataflow`. ETLBox will wrap this behavior into synchronous method calls. 

*Note*: Starting with version 2.3.0, the Execute() on any source is a replace for the Network.Execute(comp) call. 
It will trigger all sources in the network to post their data and will also wait for all destinations. If you want to have a source
to post all data into the network and then return use the Post() method instead.

### Example sync execution

```C#
//Prepare the flow
DbSource source1 = new DbSource1("SourceTable1");
DbSource source2 = new DbSource2("SourceTable2");
RowTransformation rowTrans = new RowTransformation( row => row );
DbDestination dest1 = new DbDestination("DestTable");
DbDestination dest2 = new DbDestination("DestTable");

//Link the flow
source1.LinkTo(row);
source2.LinkTo(row);
row.LinkTo(dest1, row => row.Value < 10);
row.LinkTo(dest2, row => row.Value >= 10);

//Execute the whole data flow
Network.Execute(source1, source2);
```

The `Network.Execute(params DataFlowComponent[])` method will execute the whole data flow and block exeuction until all data has arrived at *all destinations*. 

Please note that you don't have to pass all sources into the Network class. You only have to pass at least *one* component into the Execute method that is part of the network. The following statement also would execute the *whole* data flow:

```C#
Network.Execute(source1);
Network.Execute(row);
Network.Execute(source1, source2, row, dest1, dest2);
Network.Execute(source1, row, dest2);
...
```

#### Using the shortcut on the sources

There is a shortcut for the Network.Execute(..) method.
Every data flow source does offer an Execute() method. This will trigger the corresponding Network.Execute() method, and will pass the source itself. 
For the example above, you could also trigger the *whole* network like this:

```C#
source1.Execute();
```

```C#
source2.Execute();
```

Or run the execution on for both: 
```C#
source1.Execute();
source2.Execute();
```

Though the second execution wouldn't do nothing, as the whole network was already execute.

In versions < 2.3.0, the examples where always using an Execute()/Wait() pattern like this:

```C#
source1.Execute();
source2.Execute();
dest1.Wait();
dest2.Wat();
```

This pattern will still work, but after the execution of source1 the network would be already run and complete. The rest of the code blocks will then immediately return, doing nothing. 

## Asynchronous execution

If you are familiar with async programming, you can also execute the data flow asynchronous. This means that
execution of your program will continue while the data is read from the source and written into the destinations 
in separate task(s) in the background. 

### Example async execution

```C#
//Prepare the flow
DbSource source1 = new DbSource1("SourceTable1");
DbSource source2 = new DbSource2("SourceTable2");
RowTransformation rowTrans = new RowTransformation( row => row );
DbDestination dest1 = new DbDestination("DestTable");
DbDestination dest2 = new DbDestination("DestTable");

//Link the flow
source1.LinkTo(row);
source2.LinkTo(row);
row.LinkTo(dest1, row => row.Value < 10);
row.LinkTo(dest2, row => row.Value >= 10);

//Execute the whole data flow
Task networkCompletion = Network.ExecuteAsync(source1, source2);

//Now you can wait for the whole network
networkCompletion.Wait();
```

#### Using completion tasks on the components

Of course if you want more control over your network you can use the Completion property that exposes the current task of each data flow component. 

E.g. you can trigger your flow like this:

```
source1.ExecuteAsync();
source2.ExecuteAsync();
Task destTask1 = dest1.Completion;
Task destTask1 = dest2.Completion;

Task.WaitAll(destTask1, destTask2);
```

or like this:

```C#
Task sourceTask1 = source1.ExecuteAsync();
Task sourceTask2 = source2.Completion;
Task rowTask = row.Completion;
Task destTask1 = dest1.Completion;
Task destTask1 = dest2.Completion;

Task.WaitAll(destTask1, destTask2, sourceTask1, sourceTask2, rowTask);
```

The `ExecuteAsync()` method will return a Task which completes when all data is read from the source and posted in the data flow. This is the same task that the `Completion` property holds. 
You don't have to wait for this task (but of course you can). But if a destination is completed, all its predecessors are also completed. 

The `Completion` property will return a Task which is completed when all data has be processed by the component. 

