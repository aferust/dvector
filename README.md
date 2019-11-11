# dvector
Simple dynamic array implementation for D that fits my needs.
 * compatible with betterC.
 * don't expect much, but it does the things :)

## Example:
```
import core.stdc.stdlib;
import core.stdc.stdio;

import dvector;

struct Person {
    string name;
    uint score;
}

extern (C) int main() nothrow @nogc
{
    
    Dvector!Person prs1;
    
    auto p1 = Person("ferhat", 5);
    auto p2 = Person("Mike", 3);
    auto p3 = Person("Rajneesh", 1);
    auto p4 = Person("Ce", 2);
    
    prs1 ~= p1;
    prs1 ~= p2;
    prs1 ~= p3;
    prs1 ~= p4;

    Dvector!Person prs2;
    auto s1 = Person("Ezgi", 15);
    auto s2 = Person("Emine", 36);
    
    prs2 ~= s1;
    prs2 ~= s2;
    
    auto comb = prs1 ~ prs2;
    
    comb.remove(2);
    
    assert(comb[2].name == "Ce");
    
    auto cn = Person("Chuck", 100);
    comb.pFront(cn);
    
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