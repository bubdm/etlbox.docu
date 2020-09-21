# Text

## Text source

The text source let you read data from any text file. It will read every line from the source which can be transformed with a 
ParseLineAction - this allows you to parse the line into your data object as you like. As you need to define how a line in your
file is converted into an object yourself, this source is not as convenient as other sources, but offers the most flexibility when reading text files in a non common format. 

### Example

If your text file look like this:
1  A
2  B
3  C

You could read this file into a dataflow with:

```C#
public class MyTextRow
{
    public int Id {get;set;}
    public string Text { get; set; }
}
        
TextSource<MyTextRow> source = new TextSource<MyTextRow>();
source.Uri = "inputFile.txt";
source.ParseLineAction = (line, o) => {
    o.Id = int.Parse(line.Substring(0,1));
    o.Text = line.Substring(3,1);
};
```

Please note that you don't have to create the object yourself - a new instance of the object will be created automatically and passed into the ParseLineAction along with the current line. You just need to assign the corresponding fields into the object. 

#### Using dynamic objects

Of course the TextSource also works with dynamic objects. The default implementation uses the ExpandoObject.

```C#
 TextSource source = new TextSource();
source.Uri = "inputFile.txt";
source.ParseLineAction = (line, dynob) =>
{
    dynamic o = dynob as ExpandoObject;
    o.Id = int.Parse(line.Substring(0, 1));
    o.Text = line.Substring(3, 1);
};
```

#### Using arrays

Your input type could also be an array. If you define an array as input type, you can set the size of the array in the property `ArraySize`. Because the TextSource does the array initialization for you, this value will define the max number of elements accessable in the area. The default is 10. 

```C#
TextSource<string[]> source = new TextSource<string[]>();
source.Uri = "inputFile.txt";
source.ArraySize = 2;
source.ParseLineAction = (line, o) =>
{
    o[0] = line.Substring(0, 1);
    o[1] = line.Substring(3, 1);                
};
```

## Text destination

The text destination let you create a text file from your incoming data. It allows you to define how the incoming data object is translated into a row in your text file destination.
The text destination has a function that describe how the incoming row is converted into a string (similar to `ToString()`).

### Example

Assuming we have the same input data as above, the following code would convert this data back into a text file. 

```C#
public class MyTextRow
{
    public int Id { get; set;}
    public string Text { get; set; }
}
        
TextDestination<MyTextRow> dest = new TextDestination<MyTextRow>("outputFile.txt");
dest.WriteLineFunc = tr => $"{tr.Id}  {tr.Text}";
```

#### Using dynamic objects

Instead of an object you can use the ExandoObject with the default implementation.

```C#
TextDestination dest = new TextDestination("outputFile.txt");
    dest.WriteLineFunc =
    tr =>
    {
        dynamic r = tr as ExpandoObject;
        return $"{r.Id}  {r.Text}";
    };
```

#### Using arrays

This is the code for writing a string array input type into a file. 

```C#
TextDestination<string[]> dest = new TextDestination<string[]>("outputFile.txt");
dest.WriteLineFunc = tr => $"{tr[0]}  {tr[1]}";
```