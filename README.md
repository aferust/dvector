# dvector
Simple dynamic array implementation for D that fits my needs.
 * compatible with betterC.
 * don't expect much, but it does the things :)
Example:
```
import std.stdio;
import core.stdc.stdlib;

import dvector;

T* mallocOne(T, Args...)(Args args) nothrow @nogc{
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

struct Person {
    string name;
    uint score;
}

int main() nothrow @nogc
{
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
    
    foreach(p; comb){
        printf("%s \n", p.name.ptr);
    }
    
    assert(comb[2].name == "Ce");
    
    auto cn = mallocOne!Person("Chuck", 100);
    comb.pFront(cn);
    
    assert(comb[0].name == "Chuck");
    
    freeALL(comb);
    return 0;
}
```