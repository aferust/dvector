module dvector;

import core.stdc.stdlib;

struct Dvector(T) {
    private vector v;
    
    size_t length() @nogc nothrow{
        return cast(size_t)vector_total(&v);
    }
    
    void _init_() @nogc nothrow{
        vector_init(&v);
    }
    
    void pBack(T elem) @nogc nothrow{
        vector_add(&v, elem);
    }
    
    auto opCatAssign(T c) @nogc nothrow{
        pBack(c);
        return this;
    }
    
    T opIndex(int i) @nogc nothrow {
        return cast(T)vector_get(&v, i);
    }
    
    void opIndexAssign(T elem, int i) @nogc nothrow {
        vector_set(&v, i, elem);
    }
    
    void remove(int i) @nogc nothrow{
        vector_delete(&v, i);
    }
    
    void free() @nogc nothrow{
        vector_free(&v);
    }
    
    int opApply(int delegate(T) @nogc nothrow dg) @nogc nothrow{
        int result = 0;

        for (int k = 0; k < length; ++k) {
            result = dg(cast(T)vector_get(&v, k));

            if (result) {
                break;
            }
        }
        return result;
    }
    
    int opApply(int delegate(int i, T) @nogc nothrow dg) @nogc nothrow{
        int result = 0;

        for (int k = 0; k < length; ++k) {
            result = dg(k, cast(T)vector_get(&v, k));

            if (result) {
                break;
            }
        }
        return result;
    }
    
    // overloads for gc usages:
        int opApply(int delegate(T) dg){
        int result = 0;

        for (int k = 0; k < length; ++k) {
            result = dg(cast(T)vector_get(&v, k));

            if (result) {
                break;
            }
        }
        return result;
    }
    
    int opApply(int delegate(int i, T) dg){
        int result = 0;

        for (int k = 0; k < length; ++k) {
            result = dg(k, cast(T)vector_get(&v, k));

            if (result) {
                break;
            }
        }
        return result;
    }
    
    Dvector!T opBinary(string op)(Dvector!T rhs) @nogc nothrow{
        static if (op == "~"){
            foreach(elem; rhs)
                pBack(elem);
            return this;
        } 
        else static assert(0, "Operator "~op~" not implemented");
    }
    
    Dvector!T opBinary(string op)(T rhs) @nogc nothrow{
        static if (op == "~"){
            pBack(rhs);
            return this;
        } 
        else static assert(0, "Operator "~op~" not implemented");
    }
    
    void pFront(T c) @nogc nothrow{
        pBack(T.init);

        for(uint i = cast(uint)(length-1); i > 0; i--){
            vector_set(&v, i, cast(T)vector_get(&v, i-1));
        }
        vector_set(&v, 0, c);
    }
    
    void insert(T c, int position) @nogc nothrow{
        
        pBack(T.init);

        for (uint k = cast(uint)(length-1); k > position; k--)
            vector_set(&v, k, cast(T)vector_get(&v, k-1));
        vector_set(&v, position, c);
    }
    
    T[] array() @nogc nothrow{
        return cast(T[])v.items[0..length];
    }
}

unittest {
    import core.stdc.stdio;
    
    T* mallocOne(T, Args...)(Args args){
        T* p = cast(T*)malloc(T.sizeof);
        *p = T(args);
        return p;
    }
    
    void freeALL(T)(T arr) nothrow @nogc{
        foreach(elem; arr){
            free(elem);
        }
        arr.free();
    }
    
    struct Person { string name; uint score;}
    
    Dvector!(Person*) prs1; prs1._init_;
    
    auto p1 = mallocOne!Person("ferhat", 5);
    auto p2 = mallocOne!Person("Mike", 3);
    auto p3 = mallocOne!Person("Rajneesh", 1);
    auto p4 = mallocOne!Person("Ce", 2);
    
    prs1 = prs1 ~ p1;
    prs1 ~= p2;
    prs1 ~= p3;
    prs1 ~= p4;

    Dvector!(Person*) prs2; prs2._init_;
    auto s1 = mallocOne!Person("Ezgi", 15);
    auto s2 = mallocOne!Person("Emine", 36);
    
    prs2 ~= s1;
    prs2 ~= s2;
    
    auto comb = prs1 ~ prs2;
    freeALL(prs2);
    
    comb.remove(2);
    
    assert(comb[2].name == "Ce");
    
    auto cn = mallocOne!Person("Chuck", 100);
    comb.pFront(cn);
    
    assert(comb[0].name == "Chuck");
    
    auto srv = mallocOne!Person("SRV", 100);
    comb.insert(srv, 3);
    
    assert(comb[3].name == "SRV");
    
    foreach(i, p; comb){
        printf("%d: %s \n", i, p.name.ptr);
    }
    
    freeALL(comb);
    return 0;
}

// based on https://eddmann.com/posts/implementing-a-dynamic-vector-array-in-c/
// the original C implementation of the method is credited to Edd Mann
enum VECTOR_INIT_CAPACITY = 4;

private @nogc nothrow:

struct vector {
    void **items;
    int capacity;
    int total;
}

vector * vector_init(vector *v)
{
    v.capacity = VECTOR_INIT_CAPACITY;
    v.total = 0;
    v.items = cast(void**)malloc((void*).sizeof * v.capacity);
    return v;
}

int vector_total(vector *v)
{
    return v.total;
}

static void vector_resize(vector *v, int capacity)
{
    version(Debug){
        import core.stdc.stdio;
        printf("vector_resize: %d to %d\n", v.capacity, capacity);
    }

    void **items = cast(void**)realloc(v.items, (void *).sizeof * capacity);
    if (items) {
        v.items = items;
        v.capacity = capacity;
    }
}

void vector_add(vector *v, void *item)
{
    if (v.capacity == v.total)
        vector_resize(v, v.capacity * 2);
    v.items[v.total++] = item;
}

void vector_set(vector *v, int index, void *item)
{
    if (index >= 0 && index < v.total)
        v.items[index] = item;
}

void *vector_get(vector *v, int index)
{
    if (index >= 0 && index < v.total)
        return v.items[index];
    return null;
}

void vector_delete(vector *v, int index)
{
    if (index < 0 || index >= v.total)
        return;

    v.items[index] = null;

    for (int i = index; i < v.total - 1; i++) {
        v.items[i] = v.items[i + 1];
        v.items[i + 1] = null;
    }

    v.total--;

    if (v.total > 0 && v.total == v.capacity / 4)
        vector_resize(v, v.capacity / 2);
}

void vector_free(vector *v)
{
    free(v.items);
}
