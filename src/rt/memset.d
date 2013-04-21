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

extern (C)
{
    // Functions from the C library.
    void *memcpy(void *, void *, size_t);
}

alias _memset!short _memset16i;
alias _memset!int _memset32i;
alias _memset!long _memset64i;

//avoids having to use void[], which was confusing and x86_64 dependent.
//does this lead to another call to this module? void[] didn't.
struct 128bits //Could use long[2] ???
{
    long a;
    long b;
}
alias _memset!128bits _memset128i;

alias _memset!float _memsetFloat;
alias _memset!double _memsetDouble;
alias _memset!real _memsetReal;
alias _memset!cfloat _memsetCfloat;
alias _memset!cdouble _memsetCdouble;
alias _memset!creal _memsetCreal;

extern (C) T* _memset(T)(T* p, T value, size_t count)
{
    T* pstart = p;
    T* ptop = p + count;

    while(p < ptop)
        *p++ = value;

    return pstart; //why are we returning anything?
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

