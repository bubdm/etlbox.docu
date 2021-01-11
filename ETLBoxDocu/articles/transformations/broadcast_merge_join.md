# Broadcasting, merging, splitting and joining data 

## Multicast - broadcasting data

The `Multicast` is a component which basically clones your data and send them to all connected target. It has one input and two or more outputs. (Technically, it could also be used with only one output, but then it wouldn't do much.)

#### Brodcast example

The following code demonstrate a simple example where data would be duplicated and copied into two destinations - 
a database table and a Json file. 

```C#
public class MyRow
{
    public int Id { get; set; }
    public string Value{ get; set; }
}

public static void Main()
{
    var source = new MemorySource<MyRow>();
    source.DataAsList.Add(new MyRow() { Id = 1, Value = "A" });
    source.DataAsList.Add(new MyRow() { Id = 2, Value = "B" });

    var dest1 = new MemoryDestination<MyRow>();
    var dest2 = new MemoryDestination<MyRow>();

    var multicast = new Multicast<MyRow>();

    source.LinkTo(multicast);
    multicast.LinkTo(dest1);
    multicast.LinkTo(dest2);

    source.Execute();
    dest1.Wait();
    dest2.Wait();

    Console.WriteLine($"Destination 1");
    foreach (var row in dest1.Data)
        Console.WriteLine($"{row.Id}{row.Value}");

    Console.WriteLine($"Destination 2");
    foreach (var row in dest2.Data)
        Console.WriteLine($"{row.Id}{row.Value}");

    //Outputs
    //Destination 1
    //1A
    //2B
    //Destination 2
    //1A
    //2B
}
```

### Splitting data 

The Multicast is useful when you want to broadcast your data to all linked target. If you want to split up your data on the connected target, you don't need to use the Multicast. You can simple use predicates for this purpose.  Predicates allow you to let only certain data pass to a target.  This works because you can always link every component to more than one output component. But without Multicast or predicates in place, all message would be send only to the target that was linked first. 

Predicates are conditions that describe to which target the data is send if the condition evaluates to true. Let's modify the example above so that we send the row with the Id 1 or smaller to destination 1 and the row with Id 2 or higher to destination 2.

#### Splitting data example 

```C#
public class MyRow
{
    public int Id { get; set; }
    public string Value{ get; set; }
}

public static void Main()
{
    var source = new MemorySource<MyRow>();
    source.DataAsList.Add(new MyRow() { Id = 1, Value = "A" });
    source.DataAsList.Add(new MyRow() { Id = 2, Value = "B" });

    var dest1 = new MemoryDestination<MyRow>();
    var dest2 = new MemoryDestination<MyRow>();
                   
    source.LinkTo(dest1, row => row.Id <= 1);
    source.LinkTo(dest2, row => row.Id >= 2);
            
    source.Execute();
    dest1.Wait();
    dest2.Wait();

    Console.WriteLine($"Destination 1");
    foreach (var row in dest1.Data)
        Console.WriteLine($"{row.Id}{row.Value}");

    Console.WriteLine($"Destination 2");
    foreach (var row in dest2.Data)
        Console.WriteLine($"{row.Id}{row.Value}");

    //Outputs
    //Destination 1
    //1A
    //Destination 2
    //2B
}
```

*Please note*: make sure when using predicates that always all rows arrive at any kind of destination. Use a `VoidDestination`
for records that you don't want to keep. 

[Read more about predicates and linking.](../dataflow/linking_execution.md).

### Error Linking

This transformation allows you to redirect erroneous records. By default, any exception in your flow would bubble up into your application the stop the flow. If you want to redirect data rows that would raise an exception, use the `LinkErrorTo` method to send the faulted rows into an error data flow. 

### Non blocking transformation

The Multicast is a non blocking transformation. There is no data kept in memory when using this transformation. 
The Multicast has one input buffer, which may store incoming messaged to improve throughput.   
To restrict the number of rows stored in the input buffer, set the `MaxBufferSize` property to a value greater than 0. E.g. a value of 500 will only allow up to 500 rows in the input buffer of the Multicast.

### Multicast Api documentation

The full class documentation can be found in the Api documentation.

- If you want to broadcast an object, [use the MergeJoin with data type](https://etlbox.net/api/ETLBox.DataFlow.Transformations.Multicast-1.html).
- If you want to broadcast an ExpandoObject, [use the non generic Multicast class](https://etlbox.net/api/ETLBox.DataFlow.Transformations.Multicast.html).

## MergeJoin - merging or joining data

The MergeJoin transformation joins the outcome of two sources or transformations into one data record.
This allows you to merge the data of two inputs into one output. 

### Summary

The MergeJoin accepts two inputs and has one output. 
The first input is referred as left input and the second input as right input. 
A function describes how the two inputs are combined into one output. 
E.g.,  you can link two sources with the MergeJoin, define a method how to combine these records and produce a new merged output. The data type of the output and the inputs can be different, as long as you handle it in the join function.
If you want to join only two records if they match, you can pass a comparison function the join. The MergeJoin then can simulate behavior like a classic "FULL OUTER JOIN".

### Always join  

By default, the MergeJoin will always join every row from the left in put with a row from the right input. 
This works best if data for both inputs has the exact same amount of rows. 
A row from the left will always be send together with a row from the right into the MergeJoin function. 
The MergeJoin function is a Func that defines how both records are combined. The result can be a new record of the same of a different type.

*Note:* If there are more rows coming from one input than there is in the other input, the rest of the rows will be joined with null values. 

#### Always join example

An example for a simple merge join, where data is always joined:

```C#
public class MyLeftRow
{
    public string FirstName { get; set; }        
}

public class MyRightRow
{
    public string LastName { get; set; }
}

public class MyOutputRow
{
    public string FullName { get; set; }
}

public static void Main()
{
    var source1 = new MemorySource<MyLeftRow>();
    source1.DataAsList.Add(new MyLeftRow() { FirstName = "Elvis" });
    source1.DataAsList.Add(new MyLeftRow() { FirstName = "Marilyn" });
    var source2 = new MemorySource<MyRightRow>();
    source2.DataAsList.Add(new MyRightRow() { LastName = "Presley" });
    source2.DataAsList.Add(new MyRightRow() { LastName = "Monroe" });

    var join = new MergeJoin<MyLeftRow, MyRightRow, MyOutputRow>(
        (leftRow, rightRow) =>
        {
            return new MyOutputRow()
            {
                FullName = leftRow.FirstName + " " + rightRow.LastName
            };
        });

    var dest = new MemoryDestination<MyOutputRow>();
    source1.LinkTo(join.LeftInput);
    source2.LinkTo(join.RightInput);
    join.LinkTo(dest);

    Network.Execute(source1, source2);    

    foreach (var row in dest.Data)
        Console.WriteLine(row.FullName);

    //Outputs
    //Elvis Presley
    //Marilyn Monroe
}
```

### Join with comparison

A MergeJoin allows you to define a match and comparison function that describe which records are supposed to be joined. This behavior
is similar to a LEFT/RIGHT/FULL JOIN. 
For performance reason, the MergeJoin will need sorted input on both sides. The order of the rows needs to be on the property you are using the comparison for. 
Then you can pass a ComparisonFunc<TInput1, TInput2, int> which returns an int value:
If the ComparisonFunc is defined, records are compared regarding their sort order and only joined if they match.

- It returns 0 if both records match and should be joined. 
- It returns a value little than 0 if the record of the left input is in the sort order before the record of the right input. 
- It returns a value greater than 0 if the record for the right input is in the order before the record from the left input.

### Join with comparison example 

Here an example how this would look like

```C#
public class MyRow
{
    public int Id { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string FullName { get; set; }
}

public void JoinWithComparisonExample()
{
    var source1 = new MemorySource<MyRow>();
    source1.DataAsList.Add(new MyRow() { Id = 1, FirstName = "Elvis" });
    source1.DataAsList.Add(new MyRow() { Id = 2, FirstName = "Psy" });
    source1.DataAsList.Add(new MyRow() { Id = 3, FirstName = "Marilyn" });
    var source2 = new MemorySource<MyRow>();
    source2.DataAsList.Add(new MyRow() { Id = 1, LastName = "Presley" });
    source2.DataAsList.Add(new MyRow() { Id = 3, LastName = "Monroe" });

    var join = new MergeJoin<MyRow>(
        (leftRow, rightRow) =>
        {
            if (rightRow == null)
                leftRow.FullName = leftRow.FirstName + " " + "Unknown";
            else 
                leftRow.FullName = leftRow.FirstName + " " + rightRow.LastName;
            return leftRow;
        });

    join.ComparisonFunc = (inputRow1, inputRow2) =>
    {
        if (inputRow1.Id == inputRow2.Id)
            return 0;
        else if (inputRow1.Id < inputRow2.Id)
            return -1;
        else 
            return 1;                
    };

    var dest = new MemoryDestination<MyRow>();
    source1.LinkTo(join.LeftInput);
    source2.LinkTo(join.RightInput);
    join.LinkTo(dest);

    Network.Execute(source1, source2);

    foreach (var row in dest.Data)
        Console.WriteLine(row.FullName);

    //Outputs
    //Elvis Presley
    //Psy Unknown
    //Marilyn Monroe
}
```

### Types 

The data type of the inputs and outputs can be different. The MergeJoin can accept three different type - two types for the inputs and one type for the output. There is a simplified MergeJoin that only accepts one type - then all inputs and output will be of the same type. If no type is given, the MergeJoin will use the ExpandoObject. 

### Sorted input

Input data for both inputs needs to be sorted if you use the comparison function. Either use the Sort transformation or try to get sorted output from the source. The order of the incoming rows has a direct effect on the join behavior. The MergeJoin does not check if the input is sorted - it will either always join both incoming rows (no comparison function defined) or it will call the comparison func to identify matches and order for the current incoming rows. The latter one will lead to unexpected results if both inputs are not sorted on the same property that the comparison function uses. 

### Non blocking transformation

The MergeJoin is a non blocking transformation. There is no data kept in memory when using this transformation. 
Nevertheless, like most data flow transformation the MergeJoin has input and output buffers. It comes with one input buffer for each input and one for the output. This allows a higher throughput of data in the flow.  
To restrict the number of rows stored in all of these buffers, set the `MaxBufferSize` property to a value greater than 0. E.g. a value of 500 will only allow up to 500 rows in each buffer. 

### MergeJoin Api documentation

The full class documentation can be found in the Api documentation.

- If the input or output types are different, [use the MergeJoin that accepts three data types](https://etlbox.net/api/ETLBox.DataFlow.Transformations.MergeJoin-3.html).
- If the input and output types are the same, [use the MergeJoin that accepts only one data type](https://etlbox.net/api/ETLBox.DataFlow.Transformations.MergeJoin-1.html).
- If the input and output types should use the ExpandoObject, [use the non generic MergeJoin class](https://etlbox.net/api/ETLBox.DataFlow.Transformations.MergeJoin.html).

## CrossJoin

The CrossJoin allows you to combine every record from one input with every record from the other input. This allows you to simulate a cross join like behavior as in sql (also known as Cartesian product). 

### Example

Let's assume you have two input sets.
Set one is a list of first names: "Elvis", "James" and "Marilyn". Set two is a list of last names: "Presley" and "Monroe". Our cross join should produce a list of all possible combinations of first and last name: "Elvis Presley", "Elvis Monroe", "James Presley", "James Monroe", "Marilyn Presley", "Marilyn Monroe".

This is our code:

```C#
public class MyLeftRow
{
    public string FirstName { get; set; }
}

public class MyRightRow
{
    public string LastName { get; set; }
}

public class MyOutputRow
{
    public string FullName { get; set; }
}

public static void Main()
{
    var source1 = new MemorySource<MyLeftRow>();
    source1.DataAsList.Add(new MyLeftRow() { FirstName = "Elvis" });
    source1.DataAsList.Add(new MyLeftRow() { FirstName = "James" });
    source1.DataAsList.Add(new MyLeftRow() { FirstName = "Marilyn" });
    var source2 = new MemorySource<MyRightRow>();
    source2.DataAsList.Add(new MyRightRow() { LastName = "Presley" });
    source2.DataAsList.Add(new MyRightRow() { LastName = "Monroe" });

    var join = new CrossJoin<MyLeftRow, MyRightRow, MyOutputRow>(
        (leftRow, rightRow) =>
        {
            return new MyOutputRow()
            {
                FullName = leftRow.FirstName + " " + rightRow.LastName
            };
        });

    var dest = new MemoryDestination<MyOutputRow>();
    source1.LinkTo(join.InMemoryTarget);
    source2.LinkTo(join.PassingTarget);
    join.LinkTo(dest);

    Network.Execute(source1, source2);

    foreach (var row in dest.Data)
        Console.WriteLine(row.FullName);

    //Outputs
    //Elvis Presley
    //James Presley
    //Marilyn Presley
    //Elvis Monroe
    //James Monroe
    //Marilyn Monroe
}
```

*Note*: The source where you expect the smaller amount of incoming data should always go into the InMemory target of the CrossJoin. This is because the CrossJoin is a partial blocking transformation where all rows from the InMemoryTarget are stored in memory before the actual join can be performed. 

### Error Linking

This transformation allows you to redirect erroneous records. By default, any exception in your flow would bubble up into your application the stop the flow. If you want to redirect data rows that would raise an exception, use the `LinkErrorTo` method to send the faulted rows into an error data flow. [Read more about error linking](../dataflow/linking_execution.md).

### Partial blocking transformation

The CrossJoin is a partial blocking transformation. The input for the first table will be loaded into memory before the actual join can start. After this, every incoming row will be joined with every row of the InMemory-Table using the cross join function.
 The InMemory target should always be the target with the smaller amount of data to reduce memory consumption and processing time.

 The passing target of the CrossJoin func does not store any rows in memory. But like most data flow transformation the CrossJoin has an input buffer to increase throughput. To restrict the number of rows stored in this input buffer, set the `MaxBufferSize` property to a value greater than 0. E.g. a value of 500 will only allow up to 500 rows in the input buffer. 

### CrossJoin Api documentation

The full class documentation can be found in the Api documentation.

- If the input or output types are different, [use the CrossJoin that accepts three data types](https://etlbox.net/api/ETLBox.DataFlow.Transformations.CrossJoin-3.html).
- If the input and output types are the same, [use the CrossJoin that accepts only one data type](https://etlbox.net/api/ETLBox.DataFlow.Transformations.CrossJoin-1.html).
- If the input and output types should use the ExpandoObject, [use the non generic CrossJoin class](https://etlbox.net/api/ETLBox.DataFlow.Transformations.CrossJoin.html).

