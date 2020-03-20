# dvector
Dynamic array implementation for D that fits my needs.
 * compatible with betterC.
 * compatible with std.range (with empty, front, back, popFront, popBack, save).
 * supports array literals for initialization.
 * able to transfer ownership of its data to a slice.

## Example:
```
import core.stdc.stdlib;
import core.stdc.stdio;

import dvector;

extern (C) int main() nothrow @nogc
{
    Dvector!int iv = [2, 3, 24, 6, 8]; // array literals with betterC

    int[] view_iv = iv[2..$]; // [24, 6, 8]

    int[] newOwner = iv.release();
    printf("%d \n", newOwner.length);
    
    free(newOwner.ptr);

    struct Person {string name; uint score;}

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

    return 0;
}
```