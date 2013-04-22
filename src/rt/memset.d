/**
 * Contains a memset implementation used by compiler-generated code.
 *
 * Copyright: Copyright Digital Mars 2004 - 2010.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Walter Bright
 */

/*          Copyright Digital Mars 2004 - 2010.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module rt.memset;

import core.simd;

extern (C)
{
    // Functions from the C library.
    void *memcpy(void *, void *, size_t);
}

//avoids having to use void[], which was confusing and x86_64 dependent.
//does this lead to another call to this module? void[] didn't.
static assert( long.sizeof == 8 ); //perhaps? It seems bad to let this silently be wrong.
private struct _128bits //Could use long[2] ???
{
    long a;
    long b;
}

mixin(_memsetT!(short, "16i"));
mixin(_memsetT!(int, "32i"));
mixin(_memsetT!(long, "64i"));
mixin(_memsetT!(_128bits, "128i"));
mixin(_memsetT!(float, "Float"));
mixin(_memsetT!(cfloat, "Cfloat"));
mixin(_memsetT!(double, "Double"));
mixin(_memsetT!(cdouble, "Cdouble"));
mixin(_memsetT!(real, "Real"));
mixin(_memsetT!(creal, "Creal"));
mixin(_memsetT!("void16", "Vec128")); //Don't think we have to differentiate between different
                                      //base types.
version (None) //AVX types not supported by dmd currently.
{
    mixin(_memsetT!("void32", "Vec256"));
}

template _memsetT(T, string nameExt)
{
    enum _memsetT =        
        "extern(C) auto _memset" ~ nameExt ~"(" ~ T.stringof ~ "* p, "
                                                ~ T.stringof ~ " value, size_t count)
        {
            auto pstart = p;
	    auto ptop = p + count;
	    while(p < ptop)
	        *p++ = value;
            return pstart; //why are we returning anything?
        }";
}

//only exists to avoid strange vector TypeN.stringof == "cast(Type[N])(__vector(int[N]))"
template _memsetT(string typeStr, string nameExt)
{
    enum _memsetT =        
        "extern(C) auto _memset" ~ nameExt ~"(" ~ typeStr ~ "* p, "
                                                ~ typeStr ~ " value, size_t count)
        {
            auto pstart = p;
	    auto ptop = p + count;
	    while(p < ptop)
	        *p++ = value;
            return pstart;
        }";
}

void* _memsetn(void* p, void* value, size_t count, size_t sizelem)
{
    void *pstart = p;
    size_t i;

    for (i = 0; i < count; i++)
    {
        memcpy(p, value, sizelem);
        p = p + sizelem;
    }
    return pstart;
}

