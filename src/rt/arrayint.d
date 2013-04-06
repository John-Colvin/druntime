module rt.arrayint;

private import core.cpuid;

version (unittest)
{
    private import core.stdc.stdio : printf;
    /* This is so unit tests will test every CPU variant
     */
    uint cpuid;
    enum CPUID_MAX = 14;
    @property bool mmx()        { return cpuid == 1 && core.cpuid.mmx; }
    @property bool sse()        { return cpuid == 2 && core.cpuid.sse; }
    @property bool sse2()       { return cpuid == 3 && core.cpuid.sse2; }
    @property bool sse3()       { return cpuid == 4 && core.cpuid.sse3; }
    @property bool sse41()      { return cpuid == 5 && core.cpuid.sse41; }
    @property bool sse42()      { return cpuid == 6 && core.cpuid.sse42; }
    @property bool sse4a()      { return cpuid == 7 && core.cpuid.sse4a; }
    @property bool avx()        { return cpuid == 8 && core.cpuid.avx; }
    @property bool avx2()       { return cpuid == 9 && core.cpuid.avx2; }
    @property bool has3dnowPrefetch()   { return cpuid == 13 && core.cpuid.has3dnowPrefetch; }
}
else
{
    alias core.cpuid.mmx mmx;
    alias core.cpuid.sse sse;
    alias core.cpuid.sse2 sse2;
    alias core.cpuid.sse3 sse3;
    alias core.cpuid.sse41 sse41;
    alias core.cpuid.sse42 sse42;
    alias core.cpuid.sse4a sse4a;
    alias core.cpuid.avx avx;
    alias core.cpuid.avx2 avx2;
    alias core.cpuid.has3dnowPrefetch has3dnowPrefetch;
}

alias int T;

extern (C) @trusted nothrow:

@trusted pure nothrow
bool disjoint(T)(T[] a, T[] b) //doesn't always need to be this strict.
{
    return (a.ptr + a.length <= b.ptr || b.ptr + b.length <= a.ptr);
}

T[] _arraySliceExpAddSliceAssign_i (T[] a, T value, T[] b)
in
{
    assert(a.length == b.length);
    assert(disjoint(a, b));      //can be relaxed somewhat.
}
body
{
    auto aptr = a.ptr;
    auto aend = aptr + a.length;
    auto bptr = b.ptr;

    version (D_InlineAsm_X86_64)
    {   //In a perfect world, a lot of this would be resolvable at compile-time.
        auto aoff = cast(size_t)aptr & 15;
        auto boff = cast(size_t)bptr & 15;
        if (aoff != boff)
//        if (aoff | boff)
        {// unequal misalignment
//            printf("unequal misalignment\n");
            // run unaligned sse

            auto n = aptr + (a.length & ~31);
            asm
            {
                mov RSI, aptr;
                mov RDI, n;
                mov RAX, bptr;
                movd XMM2, value;
                pshufd XMM8, XMM8, 0;

                align 16;
            startaddsse2u:
                add RSI, 128;
                movdqu XMM0, [RAX];
                movdqu XMM1, [RAX+16];
                movdqu XMM2, [RAX+32];
                movdqu XMM3, [RAX+48];
                movdqu XMM4, [RAX+64];
                movdqu XMM5, [RAX+80];
                movdqu XMM6, [RAX+96];
                movdqu XMM7, [RAX+112];
                add RAX, 128;
                paddd XMM0, XMM8;
                paddd XMM1, XMM8;
                paddd XMM2, XMM8;
                paddd XMM3, XMM8;
                paddd XMM4, XMM8;
                paddd XMM5, XMM8;
                paddd XMM6, XMM8;
                paddd XMM7, XMM8;
                movdqu [RSI-128], XMM0;
                movdqu [RSI-112], XMM1;
                movdqu [RSI-96], XMM2;
                movdqu [RSI-80], XMM3;
                movdqu [RSI-64], XMM4;
                movdqu [RSI-48], XMM5;
                movdqu [RSI-32], XMM6;
                movdqu [RSI-16], XMM7;
                cmp RSI, RDI;
                jb startaddsse2u;

                mov aptr, RSI;
                mov bptr, RAX;
            }

        }
        else
        //approx. 2.4x faster.
        {
            T* n = aptr + (a.length & ~31);
            if (aoff != 0)
            {// both pointers are unaligned equally
//                printf("equal misalignment, fixing\n");
y                // do peel loop to align
                // (will only ever be 1, 2 or 3 iterations for int)
                // is gather and scatter sse quicker than non-sse? for 3? for 2?
                while(cast(size_t)aptr & 15)
                    *aptr++ = *bptr++ + value; //we know what aptr and bptr should be.
                                               //can that info be used to allow better
                                               //out-of-order execution? What about
                                               //hyperthreading, we're using different
                                               //parts of the core for this and sse.
                if (n - aptr - a.length < (cast(size_t)aptr & 15) >> 5)
                    n--; //fix n. Must be able to do this better.
            }
//            else { printf("aligned\n"); }
            // run aligned sse
//            printf("running aligned\n");
            asm
            {
                mov RSI, aptr;
                mov RDI, n;
                mov RAX, bptr;
                movd XMM8, value;
                pshufd XMM8, XMM8, 0;

                align 16;
            startaddsse2a:
                add RSI, 128;
                movdqa XMM0, [RAX];
                movdqa XMM1, [RAX+16];
                movdqa XMM2, [RAX+32];
                movdqa XMM3, [RAX+48];
                movdqa XMM4, [RAX+64];
                movdqa XMM5, [RAX+80];
                movdqa XMM6, [RAX+96];
                movdqa XMM7, [RAX+112];
                add RAX, 128;
                paddd XMM0, XMM8;
                paddd XMM1, XMM8;
                paddd XMM2, XMM8;
                paddd XMM3, XMM8;
                paddd XMM4, XMM8;
                paddd XMM5, XMM8;
                paddd XMM6, XMM8;
                paddd XMM7, XMM8;
                movdqa [RSI-128], XMM0;
                movdqa [RSI-112], XMM1;
                movdqa [RSI-96], XMM2;
                movdqa [RSI-80], XMM3;
                movdqa [RSI-64], XMM4;
                movdqa [RSI-48], XMM5;
                movdqa [RSI-32], XMM6;
                movdqa [RSI-16], XMM7;
                cmp RSI, RDI;
                jb startaddsse2a;

                mov aptr, RSI;
                mov bptr, RAX;
            }

        }
    }

    while (aptr < aend)
        *aptr++ = *bptr++ + value;
//   printf("\n");
    return a;
}

unittest
{
    debug(PRINTF) printf("_arraySliceExpAddSliceAssign_i unittest\n");

    for (cpuid = 0; cpuid < CPUID_MAX; cpuid++)
    {
        version (log) printf("    cpuid %d\n", cpuid);

        for (int j = 0; j < 2; j++)
        {
            const uint dim = (1 << 19) - 1;
            T[] a = new T[dim + j];     // aligned on 16 byte boundary
            a = a[j .. dim + j];        // misalign for second iteration
            T[] c = new T[dim + j];
            c = c[j .. dim + j];

            for (int i = 0; i < dim; i++)
            {
                a[i] = cast(T)(i-10);
                c[i] = cast(T)((i-10) * 2);
            }
            import std.datetime;
            StopWatch sw;
            sw.start();
            c[] = a[] + 6;
            sw.stop();
            j & 1 ? printf("unaligned\t\0") : printf("aligned\t\t\0");
            printf("%d\n", sw.peek().hnsecs);
            for (int i = 0; i < dim; i++)
            {
                if (c[i] != cast(T)(a[i] + 6))
                {
                    printf("[%d]: %d != %d + 6\n", i, c[i], a[i]);
                    assert(0);
                }
            }
        }
    }
}
