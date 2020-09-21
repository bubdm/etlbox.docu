# Row transformations and manipulations 

## RowTransformation

The RowTransformation will apply a custom transformation function to each row of incoming data. This transformation is useful in many scenarios, as it allows you to apply any .NET code to your data. 

### Examples

#### Simple transformation

The basic idea is simply explain with this example. Two data rows are created - both have the property `InputValue`, which is multiplied with two in the row transformation and the result stored in the property `Result`. 

```C#
 public class MyRow
{
    public int InputValue { get; set; }
    public int Result{ get; set; }
}

public static void Main()
{
    var source = new MemorySource<MyRow>();
    source.DataAsList.Add(new MyRow() { InputValue = 1 });
    source.DataAsList.Add(new MyRow() { InputValue = 2 });

    var rowTrans = new RowTransformation<MyRow>(
        row => {
            row.Result = row.InputValue * 2;
            return row;
        }
    );

    var dest = new MemoryDestination<MyRow>();

    source.LinkTo(rowTrans).LinkTo(dest);
    source.Execute();
    dest.Wait();

    foreach (var row in dest.Data)
        Console.WriteLine($"InputValue:{row.InputValue} Result:{row.Result}");

    //Outputs
    //InputValue:1 Result:2
    //InputValue:2 Result:4
}
```


#### Converting data types 

In the example above only one data type was used. In this case, the RowTransformation<MyRow> is the short definition for RowTransformation<MyRow,MyRow> - input and output types are the same. But you can also have different input and output types. 

Here is an example that converts a string array into an object, using both type parameters of the RowTransformation:

```C#
public class MyArray
{
    public int Col1 { get; set; }
    public string Col2 { get; set; }
}

public static void Main()
{
    var source = new MemorySource<string[]>();
    source.DataAsList.Add( new string[] { "1", "A"});
    source.DataAsList.Add( new string[] { "2", "B"});

    var rowTrans = new RowTransformation<string[], MyArray>();
    rowTrans.TransformationFunc =
        row =>
        {
            return new MyArray()
            {
                Col1 = int.Parse(row[0]),
                Col2 = row[1]
            };
        };

    var dest = new MemoryDestination<MyArray>();

    source.LinkTo<MyArray>(rowTrans).LinkTo(dest);
    source.Execute();
    dest.Wait();

    foreach (var row in dest.Data)
        Console.WriteLine($"Col1:{row.Col1} Col2:{row.Col2}");

    //Output
    //Col1:1 Col2:A
    //Col1:2 Col2:B
}
```

### Using dynamic objects

THe default implementation of the RowTransform works with an ExpandoObject: `RowTransformation` and `RowTransformation<ExpandoObject,ExpandoObject>` are both the same. Working with ExpandoObject allows the user to access properties in the object during runtime - no object type is needed before compilation. 

Let's assume we have an example input csv file that looks like this:

Id|Value
--|---------------
1 |A
2 |B
3 |C

Normally, you would create an object the contains the properties Id and Value to store the data. But you could also work with ExpandoObject. The default implementation of all connectors and transformations is using the ExpandoObject as type. So by using CsvSource and RowTransformation we can access the data from the source directly, without the need of creating any data object. 

```C#
 public static void Main()
{
    var source = new CsvSource("example_input.csv");

    var rowTrans = new RowTransformation();
    rowTrans.TransformationFunc =
        row =>
        {
            dynamic dynrow = row as dynamic;
            Console.WriteLine($"Id:{dynrow.Id} Value:{dynrow.Value}");
            return row;
        };

    var dest = new VoidDestination();

    source.LinkTo(rowTrans).LinkTo(dest);
    source.Execute();
    dest.Wait();

    //Output
    //Id:1 Value:A
    //Id:2 Value:B
    //Id:3 Value:C
}
```

As the RowTransformation is used to write the output already, we are not interested in storing the data somewhere. But a data flow can't complete if not all records arrived at a destination. As we just want to discard the data, we use the `VoidDestination` as target. 


### InitAction

The RowTransformation allow to define custom code that is executed when the first data records arrives at the RowTransformation.
This can be very useful as you can be sure that everything is properly initialized in your flow and the components before when the first record arrives at the transformation.

```C#
var rowTrans = new RowTransformation();
row.TransformationFunc = row => {
    row.Col1 += IdOffset;
    return row;
};
row.InitAction = () => IdOffset = 100;
```

### Error Linking

This transformation allows you to redirect erroneous records. By default, any exception in your flow would bubble up into your application the stop the flow. If you want to redirect data rows that would raise an exception, use the `LinkErrorTo` method to send the faulted rows into an error data flow. [Read more about error linking](../dataflow/linking_execution.md).

### Non Blocking transformation 

The RowTransformation is a non blocking transformation, so it won't use up much memory even for high amounts of data.

Like all data flow transformations the RowTransformation has an input buffer for incoming data. This allows a higher throughput of data in the flow. To restrict the number of rows stored in the input buffer, set the `MaxBufferSize` property to a value greater than 0. E.g. a value of 500 will only allow up to 500 rows in the buffer. 


### RowTransformatiom Api documentation

The full class documentation can be found in the Api documentation.

- If the input or output types are different, [use the RowTransformation that accepts two data types](https://etlbox.net/api/ETLBox.DataFlow.Transformations.RowTransformation-2.html).
- If the input and output types are the same, [use the RowTransformation that accepts only one data type](https://etlbox.net/api/ETLBox.DataFlow.Transformations.RowTransformation-1.html).
- If the input and output types should use the ExpandoObject, [use the default implementation ](https://etlbox.net/api/ETLBox.DataFlow.Transformations.RowTransformation.html).

## RowDuplication

### Duplication

The RowDuplication simply creates duplicates of the incoming rows. You can specify how many copies you want, or if you want to create a copy only if certain predicate evaluates to true. 

Here a simple example for duplication:

```C#
public class MyRow
{
    public string Value { get; set; }
}

public static void Main()
{
    var source = new MemorySource<MyRow>();
    source.DataAsList.Add(new MyRow() { Value = "A" });
    source.DataAsList.Add(new MyRow() { Value = "B" });

    var duplication = new RowDuplication<MyRow>();
    duplication.NumberOfDuplicates = 2;

    var dest = new MemoryDestination<MyRow>();

    source.LinkTo(duplication).LinkTo(dest);
    source.Execute();
    dest.Wait();

    foreach (var row in dest.Data)
        Console.WriteLine($"Value:{row.Value}");

    //Output
    /*  Value:A
        Value:A
        Value:A
        Value:B
        Value:B
        Value:B
    */
}
```

The default value for the RowDuplication is one, which means that every row creates one copy. 

You can set up a predicate that only creates a copy of the row if it evaluates to true. If we set the CanDuplicate property
in the example above:

```C#
    var duplication = new RowDuplication<MyRow>();
    duplication.NumberOfDuplicates = 2;
    duplication.CanDuplicate = row => row.Value == "A";
);
```

This would change the output to this:

```C#
    //Output
    /*  Value:A
        Value:A
        Value:A
        Value:B
    */
```

### Non Blocking transformation 

The RowDuplication is a non blocking transformation and has an input buffer for incoming data. To restrict the number of rows stored in the input buffer, set the `MaxBufferSize` property to a value greater than 0.

### RowDuplication Api documentation

The full class documentation can be found in the Api documentation.

- If your input data is an object, [use the generic RowDuplication ](https://etlbox.net/api/ETLBox.DataFlow.Transformations.RowDuplication-1.html).
- If your input data is an ExpandoObject, [use the default implementation](https://etlbox.net/api/ETLBox.DataFlow.Transformations.RowDuplication.html).



### RowMultiplication

The RowMultiplication allows to create multiple records out of one input record. It works like a RowTransformation - so it accepts an input and an output type - but instead of just modifying one records it can return an array of records (when you return an empty list, it will even remove the incoming row).

Let's start with an example where input and output type are the same - we can use the simplified `RowMultiplication<TInput>` for this. In this example, we use one input record that contains a string ("ABC") and split it into three output records for each character. 

```C#
 public class MyRow
{
    public string Text { get; set; }
    public char Char { get; set; }
}

public static void Main()
{
    var source = new MemorySource<MyRow>();
    source.DataAsList.Add(new MyRow() { Text = "ABC" });
    var multi = new RowMultiplication<MyRow>();
    multi.MultiplicationFunc =
        row =>
        {
            var result = new List<MyRow>();
            foreach (char c in row.Text)
                result.Add(new MyRow() { Char = c });
            return result;
        };

    var dest = new MemoryDestination<MyRow>();

    source.LinkTo(multi).LinkTo(dest);
    source.Execute();
    dest.Wait();

    foreach (var row in dest.Data)
        Console.WriteLine($"Char:{row.Char}");

    //Output
    /*  Char:A
        Char:B
        Char:C
    */
}
```

### Error Linking

This transformation allows you to redirect erroneous records. By default, any exception in your flow would bubble up into your application the stop the flow. If you want to redirect data rows that would raise an exception, use the `LinkErrorTo` method to send the faulted rows into an error data flow. [Read more about error linking](../dataflow/linking_execution.md).


### Non Blocking transformation 

The RowMulitplication is a non blocking transformation and has an input buffer for incoming data. To restrict the number of rows stored in the input buffer, set the `MaxBufferSize` property to a value greater than 0.

### RowMulitplication Api documentation

The full class documentation can be found in the Api documentation.

- If the input or output types are different, [use the RowMultiplication that accepts two data types](https://etlbox.net/api/ETLBox.DataFlow.Transformations.RowMultiplication-2.html).
- If the input and output types are the same, [use the RowMultiplication that accepts only one data type](https://etlbox.net/api/ETLBox.DataFlow.Transformations.RowMultiplication-1.html).
- If the input and output types should use the ExpandoObject, [use the default implementation ](https://etlbox.net/api/ETLBox.DataFlow.Transformations.RowMultiplication.html).


#### Different input and output types

Instead of using the same object type for input and output, we could modify the example that we use two different types:

```C#
 public class MyString
{
    public string Text { get; set; }            
}

public class MyChar
{
    public char Char { get; set; }
}

public static void Main()
{
    var source = new MemorySource<MyString>();
    source.DataAsList.Add(new MyString() { Text = "ABC" });
    var multi = new RowMultiplication<MyString, MyChar>();
    multi.MultiplicationFunc =
        row =>
        {
            var result = new List<MyChar>();
            foreach (char c in row.Text)
                result.Add(new MyChar() { Char = c });
            return result;
        };

    var dest = new MemoryDestination<MyChar>();

    source.LinkTo<MyChar>(multi).LinkTo(dest);
    source.Execute();
    dest.Wait();

    foreach (var row in dest.Data)
        Console.WriteLine($"Char:{row.Char}");

    //Output
    /*  Char:A
        Char:B
        Char:C
    */
}
```

