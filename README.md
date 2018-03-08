# Interpolated Strings

## Examples

A great use case where interpolated strings shines is code generation. Let's assume we want to write "function generator" that takes some parameters and returns a string of D source code for the function definition, i.e.

```D
string generateFunc(string returnType, string name, string type, string op)
{
    return
        returnType ~ ` ` ~ name ~ `(` ~ type ~ ` left, ` ~ type ~ ` right)
        {
            return cast(` ~ returnType ~ `)(left ` ~ op ~ ` right);
        }
    `;
}
```

This code is hard very hard to follow and see what the final result looks like.  This is where interpolated strings can help.  The same function could be written as an interpolated string like this:

```D
string generateFunc(string returnType, string name, string type, string op)
{
    return text(iq{
        $returnType $name($type left, $type right)
        {
            return cast($returnType)(left $op right);
        }
    });
}
```

Note that in the second example, we are able to make use of the `q{}` string because we don't have to end the string by closing all curly-braces in order to insert dynamic values.

In "normal source code mode", characters are interpreted as syntax with meaningful semantics and strings are entered and exited with some form of quotes. Interpolated strings are great when most of the code is meant for a string because it makes "string" the default behavior and meaningful syntax is entered/exited with the `$` escape character.

This is also good for very long strings. Generating a web page is a good example:
```D
string generatePage(string title, string background, string name)
{
    return iq{
<html>
<head>
<title>$title</title>
<style type="text/css">
body {background:$background;}
</style>
</head>
<body>
       <h1>Hello $(name.capitalize)</h1>
</body>
</html>
    };
}
```

## Implementation

In other languages interpolated strings simply allocate a new string on the heap at runtime and return it.  With D we can have more flexibility by making use of tuples. In D the proposal is to have interpolated strings represent tuples, i.e.
```D

i"$a + 100 = $(a + 100)"

// SAME THING AS

tuple!(a, " + 100 = ", 1 + 100)

```

you can create a runtime string by using the `text` function , i.e.

```D
int a = 20;
assert("20 + 100 = 120" == text(i"$a + 100 = $(a + 100)"));
```

or you could pass it to a function like this
```D
int a = 20;
write(i"$a + 100 = $(a + 100)"));
```
