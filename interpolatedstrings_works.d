import std.stdio;
import std.string : indexOf;

//
// Example of Interpolated Strings
//
int main(string[] args)
{
    foreach(item; mixin(interpolatedTupleMixin("hello\n")))
    {
        write(item);
    }
    int a = 42;
    foreach(item; mixin(interpolatedTupleMixin("$(a)\n")))
    {
        write(item);
    }
    foreach(item; mixin(interpolatedTupleMixin("a is $(a)\n")))
    {
        write(item);
    }
    foreach(item; mixin(interpolatedTupleMixin("1 + 2 is $(1 + 2)\n")))
    {
        write(item);
    }

    writeInterpolatedString(mixin(interpolatedTupleMixin("hello\n")));
    writeInterpolatedString(mixin(interpolatedTupleMixin("$(a)\n")));
    writeInterpolatedString(mixin(interpolatedTupleMixin("a is $(a)\n")));
    writeInterpolatedString(mixin(interpolatedTupleMixin("1 + 2 is $(1 + 2)\n")));

    //
    // Example of code generation
    //
    {
        string functionName = "foo";
        string operation = "+";
        writeInterpolatedString(mixin(interpolatedTupleMixin(q{
            int $(functionName)(int x, int y)
            {
                return x $(operation) y;
            }
        })));
    }

    // Example of passing an interpolated string to writefln
    writefln("here is an interpolated string \"%s\"",
        formatter(mixin(interpolatedTupleMixin("hello"))));
    writefln("here is an interpolated string \"%s\"",
        formatter(mixin(interpolatedTupleMixin("1 + 2 is $(1 + 2)"))));

    mixin(generateFunc("int", "add2Ints", "int", "+"));
    add2Ints(10, 20);

    return 0;
}

//
// Implementation of interpolated strings
//

template tuple(T...)
{
    alias tuple = T;
}
string interpolatedTupleMixin(string str) pure
{
    return "tuple!(" ~ interpolatedMixinHelper1(str) ~ ")";
}
private string interpolatedMixinHelper1(string str) pure
{
    auto dollarIndex = str.indexOf("$");
    if(dollarIndex < 0)
    {
        return "\"" ~ str ~ "\"";
    }
    if(dollarIndex == 0)
    {
        return interpolatedMixinHelper2(str[1..$]);
    }
    return "\"" ~ str[0..dollarIndex] ~ "\", " ~ interpolatedMixinHelper2(str[dollarIndex + 1..$]);
}
// star of str is a dollar expression
private string interpolatedMixinHelper2(string str) pure
{
    if(str[0] == '(')
    {
        auto endParensIndex = str.indexOf(')');
        if(endParensIndex < 0)
        {
            assert(0, "interpolated string has mismatch parens");
        }
        if(endParensIndex + 1 == str.length)
        {
            return str[1..endParensIndex];
        }
        return str[1..endParensIndex] ~ ", " ~ interpolatedMixinHelper1(str[endParensIndex + 1 .. $]);
    }
    assert(0, "interpolated expression not surrounded by '()' is not supported yet (expression is \"" ~ str ~ "\")");
}
void writeInterpolatedString(T...)(T interpolatedString)
{
    foreach(part; interpolatedString)
    {
        write(part);
    }
}
auto formatter(T...)(T interpolatedString)
{
    struct Formatter
    {
        T interpolatedString;
        void toString(scope void delegate(const(char)[]) sink) const
        {
            foreach(part; interpolatedString)
            {
                static if(__traits(compiles, sink(part)))
                {
                    sink(part);
                }
                else
                {
                    import std.format : formattedWrite;
                    formattedWrite(sink, "%s", part);
                }
            }
        }
    }
    return Formatter(interpolatedString);
}


// NOTE:
// This doesn't work because the tuple does not have access to the variables/
// scope of the caller who is instantiating the template.
// For now this has to be a mixin.
//
template interpolate(string str)
{
    enum interpolate = mixin(interpolatedTupleMixin(str));
}
string generateFunc(string returnType, string name, string type, string op)
{
/*
    DOESN'T WORK: interpolate template can't see the local variables
    import std.conv : text;
    return text(interpolate!q{
        $(returnType) $(name)($(type) left, $(type) right)
        {
            return cast($(returnType))(left $(op) right);
        }
    });
*/
    import std.conv : text;
    return text(mixin(interpolatedTupleMixin(q{
        $(returnType) $(name)($(type) left, $(type) right)
        {
            return cast($(returnType))(left $(op) right);
        }
    })));
}


