import std.stdio;
import std.string : indexOf;

//
// Example of interpolated strings if they used a nice syntax!
//
int main(string[] args)
{
    foreach(item; i"hello\n")
    {
        write(item);
    }
    int a = 42;
    foreach(item; i"$(a)\n")
    {
        write(item);
    }
    foreach(item; i"a is $(a)\n")
    {
        write(item);
    }
    foreach(item; i"1 + 2 is $(1 + 2)\n")
    {
        write(item);
    }

    writeInterpolatedString(i"hello\n");
    writeInterpolatedString(i"$(a)\n");
    writeInterpolatedString(i"a is $(a)\n");
    writeInterpolatedString(i"1 + 2 is $(1 + 2)\n");

    //
    // Example of code generation
    //
    {
        string functionName = "foo";
        string operation = "+";
        writeInterpolatedString(iq{
            int $(functionName)(int x, int y)
            {
                return x $(operation) y;
            }
        }));
    }
    
    // Example of passing an interpolated string to writefln
    writefln("here is an interpolated string \"%s\"",
        formatter(i"hello")));
    writefln("here is an interpolated string \"%s\"",
        formatter(i"1 + 2 is $(1 + 2)")));
    

    return 0;
}