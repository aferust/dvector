module dvector;

version(LDC){
    pragma(LDC_no_moduleinfo);
}

import core.stdc.stdlib;
import core.stdc.string;

private enum CAPACITY = 4;

struct Dvector(T) {
    private T* chunks;
    size_t total;
    size_t capacity;

    @property T front() @nogc nothrow {
        return chunks[0];
    }

    @property T back() @nogc nothrow {
        return chunks[length-1];
    }

    size_t length() @nogc nothrow {
        return total;
    }
    
    @property bool empty() const @nogc nothrow {
        return total == 0;
    }

    void popFront() @nogc nothrow {
        remove(0);
    }

    void popBack() @nogc nothrow {
        remove(length-1);
    }

    /** !!! WARNING !!!
    Use it carefully with the standard library.
    Be sure that the standard library functions don't implicitly copy it.
    But, it is Ok if the standard library functions return a handle of copied range
    so that you can free it manually. Otherwise, you leak memory.
    */
    Dvector!T save() const @nogc nothrow {
        T* cc_chunks = cast(T*)malloc(T.sizeof * this.capacity);
        memcpy(cc_chunks, chunks, capacity * T.sizeof);
        return Dvector!T(cc_chunks, this.total, this.capacity);
    }

    this(T* chunks, size_t total, size_t capacity) @nogc nothrow {
        this.chunks = chunks;
        this.total = total;
        this.capacity = capacity;
    }
    
    void reserve(size_t n) @nogc nothrow {
        if(chunks is null){
            chunks = cast(T*)malloc(T.sizeof * n);
            total = n;
        } else if(n > capacity){
            resize(n);
        }
    }

    void pushBack(T elem) @nogc nothrow {
        allocIfneeded();
        if (capacity == total)
            resize(capacity * 2);
        chunks[total++] = elem;
    }
    
    alias pBack = pushBack;

    ref T opIndex(size_t i) @nogc nothrow {
        return chunks[i];
    }
    
    void opIndexAssign(T elem, size_t i) @nogc nothrow {
        chunks[i] = elem;
    }
    
    void remove(size_t index) @nogc nothrow {
        for (size_t i = index; i < total - 1; i++) {
            chunks[i] = chunks[i + 1];
        }

        total--;

        if (total > 0 && total == capacity / 4){
            resize(capacity / 2);
        }
    }
    
    void remove(size_t index, size_t n) @nogc nothrow{
        memmove(&chunks[index], &chunks[index+n], length-index-n);
        total -= n;

        if (total > 0 && total == capacity / 4)
            resize(capacity / 2);
    }

    void allocIfneeded() @nogc nothrow {
        if(chunks is null){
            capacity = CAPACITY;
            T* _chunks = cast(T*)malloc(T.sizeof * CAPACITY);
            this.chunks = _chunks;
        }
    }

    void resize(size_t capacity) @nogc nothrow {
        version(Debug){
            import core.stdc.stdio;
            printf("resize: %d to %d\n", this.capacity, capacity);
        }

        T* chunks = cast(T*)realloc(this.chunks, T.sizeof * capacity);
        if (chunks) {
            this.chunks = chunks;
            this.capacity = capacity;
        }
    }

    void free() @nogc nothrow {
        total = 0;
        capacity = CAPACITY;
        core.stdc.stdlib.free(chunks);
        chunks = null;
    }

    alias freeVec = typeof(this).free;
    
    int opApply(int delegate(ref T) @nogc nothrow dg) @nogc nothrow{
        int result = 0;

        for (size_t k = 0; k < total; ++k) {
            result = dg(chunks[k]);

            if (result) {
                break;
            }
        }
        return result;
    }
    
    int opApply(int delegate(size_t i, ref T) @nogc nothrow dg) @nogc nothrow{
        int result = 0;

        for (size_t k = 0; k < total; ++k) {
            result = dg(k, chunks[k]);

            if (result) {
                break;
            }
        }
        return result;
    }
    
    // overloads for gc usages:
    int opApply(int delegate(ref T) dg){
        int result = 0;

        for (size_t k = 0; k < total; ++k) {
            result = dg(chunks[k]);

            if (result) {
                break;
            }
        }
        return result;
    }
    
    int opApply(int delegate(size_t i, ref T) dg){
        int result = 0;

        for (size_t k = 0; k < total; ++k) {
            result = dg(k, chunks[k]);

            if (result) {
                break;
            }
        }
        return result;
    }
    
    Dvector!T opBinary(string op)(ref Dvector!T rhs) @nogc nothrow{
        static if (op == "~"){
            allocIfneeded();
            foreach(elem; rhs)
                pushBack(elem);
            return this;
        } 
        else static assert(0, "Operator "~op~" not implemented");
    }
    
    Dvector!T opBinary(string op)(T rhs) @nogc nothrow {
        static if (op == "~"){
            allocIfneeded();
            pushBack(rhs);
            return this;
        } 
        else static assert(0, "Operator "~op~" not implemented");
    }

    @nogc nothrow Dvector!T opOpAssign(string op)(ref Dvector!T rhs) if (op == "~"){
        allocIfneeded();
        foreach(elem; rhs)
            pushBack(elem);
        return this;
    }

    @nogc nothrow Dvector!T opOpAssign(string op)(ref T rhs) if (op == "~"){
        allocIfneeded();
        pushBack(rhs);
        return this;
    }

    void pushFront(T elem) @nogc nothrow{
        allocIfneeded();
        pushBack(T.init);

        for(size_t i = length-1; i > 0; i--){
            chunks[i] = chunks[i - 1];
        }
        chunks[0] = elem;
    }
    
    void insert(T elem, size_t position) @nogc nothrow{
        allocIfneeded();
        pushBack(T.init);

        for (size_t k = length-1; k > position; k--)
            chunks[k] = chunks[k - 1];
        chunks[position] = elem;
    }

    void insert(ref Dvector!T other, size_t position) @nogc nothrow{
        allocIfneeded();
        const oldlen = length;
        foreach(i; 0..other.length)
            pushBack(T.init);
        memmove(&chunks[position+other.length], &chunks[position], (oldlen-position)*T.sizeof);
        memcpy(&chunks[position], other.slice.ptr, other.length*T.sizeof);
    }

    void insert(T[] other, size_t position) @nogc nothrow{
        allocIfneeded();
        const oldlen = length;
        foreach(i; 0..other.length)
            pushBack(T.init);
        memmove(&chunks[position+other.length], &chunks[position], (oldlen-position)*T.sizeof);
        memcpy(&chunks[position], other.ptr, other.length*T.sizeof);
    }

    // allocates new sub vector removes elements from the original vector. Similar to javascript.
    // instead of this it is better to use myvec.slice[start..end] without extra memory if possible.
    Dvector!T splice(size_t index, size_t n) @nogc nothrow{
        auto new_chunks = cast(T*)malloc(n*T.sizeof);
        memcpy(new_chunks, &chunks[index], n*T.sizeof);
        memmove(&chunks[index], &chunks[index+n], T.sizeof*(length-index-n));
        total -= n;

        if (total > 0 && total == capacity / 4)
            resize(capacity / 2);

        return Dvector!T(new_chunks, n, n);
    }

    // use std.range.retro if it is possible, otherwise use this and free returning vec manually 
    Dvector!T reversed_copy() @nogc nothrow{
        T* cc_chunks = cast(T*)malloc(T.sizeof * this.capacity);
        auto ret = Dvector!T(cc_chunks, this.total, this.capacity);
        
        size_t k;
        for(size_t i = length; i-- > 0; )
            ret[k++]= chunks[i];
        return ret;
    }
    
    T[] slice() @nogc nothrow{
        return chunks[0..length];
    }
}

unittest {
    import core.stdc.stdio;
    struct Person { string name; uint score;}
    
    Dvector!(Person) prs1;
    
    auto p1 = Person("ferhat", 5);
    auto p2 = Person("Mike", 3);
    auto p3 = Person("Rajneesh", 1);
    auto p4 = Person("Ce", 2);
    
    prs1 ~= p1;
    prs1 ~= p2;
    prs1 ~= p3;
    prs1 ~= p4;

    Dvector!(Person) prs2;
    auto s1 = Person("Ezgi", 15);
    auto s2 = Person("Emine", 36);
    
    prs2 ~= s1;
    prs2 ~= s2;
    
    auto comb = prs1 ~ prs2;
    
    comb.remove(2);
    
    assert(comb[2].name == "Ce");
    
    auto cn = Person("Chuck", 100);
    comb.pushFront(cn);
    
    assert(comb[0].name == "Chuck");
    
    auto srv = Person("SRV", 100);
    comb.insert(srv, 3);
    
    assert(comb[3].name == "SRV");
    
    foreach(i, p; comb){
        printf("%d: %s \n", i, p.name.ptr);
    }
    
    comb.free;
    prs2.free;
}