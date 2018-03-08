// example copied from std.bitmanip

private string myToString(ulong n)
{
    import core.internal.string : UnsignedStringBuf, unsignedToTempString;
    UnsignedStringBuf buf;
    auto s = unsignedToTempString(n, buf);
    return cast(string) s ~ (n > uint.max ? "UL" : "U");
}

// CURRENT IMPLEMENTATION
private template createReferenceAccessor(string store, T, ulong bits, string name)
{
    enum storage = "private void* " ~ store ~ "_ptr;\n";
    enum storage_accessor = "@property ref size_t " ~ store ~ "() return @trusted pure nothrow @nogc const { "
        ~ "return *cast(size_t*) &" ~ store ~ "_ptr;}\n"
        ~ "@property void " ~ store ~ "(size_t v) @trusted pure nothrow @nogc { "
        ~ "" ~ store ~ "_ptr = cast(void*) v;}\n";

    enum mask = (1UL << bits) - 1;
    // getter
    enum ref_accessor = "@property "~T.stringof~" "~name~"() @trusted pure nothrow @nogc const { auto result = "
        ~ "("~store~" & "~myToString(~mask)~"); "
        ~ "return cast("~T.stringof~") cast(void*) result;}\n"
    // setter
        ~"@property void "~name~"("~T.stringof~" v) @trusted pure nothrow @nogc { "
        ~"assert(((cast(typeof("~store~")) cast(void*) v) & "~myToString(mask)
        ~`) == 0, "Value not properly aligned for '`~name~`'"); `
        ~store~" = cast(typeof("~store~"))"
        ~" (("~store~" & (cast(typeof("~store~")) "~myToString(mask)~"))"
        ~" | ((cast(typeof("~store~")) cast(void*) v) & (cast(typeof("~store~")) "~myToString(~mask)~")));}\n";

    enum result = storage ~ storage_accessor ~ ref_accessor;
}

// IMPLEMENTATION WITH STRING INTERPOLATION
private template createReferenceAccessor(string store, T, ulong bits, string name)
{
    enum storage = text(i"private void* $(store)_ptr;\n");
    enum storage_accessor = text(iq{
        @property ref size_t $store() return @trusted pure nothrow @nogc const {
            return *cast(size_t*) & $(store)_ptr;}
        @property void $store(size_t v) @trusted pure nothrow @nogc { $(store)_ptr = cast(void*) v;}
    });

    enum mask = (1UL << bits) - 1;
    // getter
    enum ref_accessor = text(iq{
        @property $(T.stringof) $name() @trusted pure nothrow @nogc const { auto result =
            ($store & $(myToString(~mask)));
        return cast("~T.stringof~") cast(void*) result;}
    // setter
        @property void $name($(T.stringof) v) @trusted pure nothrow @nogc {
            assert(((cast(typeof($store)) cast(void*) v) & $(myToString(mask))
                ) == 0, "Value not properly aligned for '$name'");
            $store = cast(typeof($store))
            (($store & (cast(typeof($store)) $(myToString(mask))))
                | ((cast(typeof($store)) cast(void*) v) & (cast(typeof($store)) $(myToString(mask)))));}
    });

    enum result = storage ~ storage_accessor ~ ref_accessor;
}

void main()
{
    import std.stdio;
    alias a = createReferenceAccessor!("uint", ubyte, 10, "foo");
    writeln(a.result);
}