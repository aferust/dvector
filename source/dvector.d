module dvector;
pragma(LDC_no_moduleinfo);

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
    
    void pushBack(T elem) @nogc nothrow {
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