# Other transformation

## Sort

The sort is a simple transformation that sorts all you incoming data. You can specify the sorting method yourself by defining a Comparison function which is used for sorting.
A comparison function defines if one object is either smaller, greate or equal than another object. Based on this information your whole data set will be sort. 

```C#
Comparison<MySimpleRow> comp = new Comparison<MySimpleRow>(
        (x, y) => y.Col1 - x.Col1
    );
Sort<MySimpleRow> block = new Sort<MySimpleRow>(comp);
```

### Blocking transformation

This is a blocking transformation, because data can only be sorted when all records are available in memory.  Thus, it will always consume as much memory as needed to store all incoming rows. 
The Sort has an input and output buffer. You can't restrict the number of rows stored in the input buffer. But you can restrict the amount of records in the output buffer - set the `MaxBufferSize` property to a value greater than 0. 



