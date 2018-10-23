function testTupleVarRefBasic1() returns (string, int, boolean) {
    (string, (int, boolean)) (a, (b, c)) = ("Ballerina", (123, true));
    ((a, b), c) = (("UpdatedBallerina", 453), false);

    return (a, b, c);
}

function testTupleVarRefBasic2() returns (string, int, boolean) {
    var (a, (b, c)) = ("Ballerina", (123, true));
    ((a, b), c) = (("UpdatedBallerina", 453), false);

    return (a, b, c);
}

function testTupleVarRefBasic3() returns (string, int, boolean) {
    (string, (int, boolean)) t = ("Ballerina", (123, true));
    var (a, (b, c)) = t;
    ((a, b), c) = (("UpdatedBallerina", 453), false);

    return (a, b, c);
}

function testTupleVarRefAssignment1() returns (string, int, boolean) {
    var (a, (b, c)) = ("Ballerina", (123, true));
    (a, (b, c)) = foo();

    return (a, b, c);
}

function foo() returns (string, (int, boolean)) {
    return ("UpdatedBallerina", (453, false));
}

function bar() returns (Foo, (Bar, (FooObj, BarObj))) {
    Foo foo2 = {name:"TestUpdate", age:24};
    Bar bar2 = {id:35, flag:false};
    FooObj fooObj2 = new ("FoooUpdate", 4.7, 24);
    BarObj barObj2 = new (false, 66);

    return (foo2, (bar2, (fooObj2, barObj2)));
}

function testTupleVarRefAssignment2() returns (string, int, int, boolean, string, float, byte, boolean, int) {
    Foo foo1 = {name:"Test", age:23};
    Bar bar1 = {id:34, flag:true};
    FooObj fooObj1 = new ("Fooo", 3.7, 23);
    BarObj barObj1 = new (true, 56);

    var (a, (b, (c, d))) = (foo1, (bar1, (fooObj1, barObj1)));

    Foo foo2 = {name:"TestUpdate", age:24};
    Bar bar2 = {id:35, flag:false};
    FooObj fooObj2 = new ("FoooUpdate", 4.7, 24);
    BarObj barObj2 = new (false, 66);

    (a, (b, (c, d))) = (foo2, (bar2, (fooObj2, barObj2)));

    return (a.name, a.age, b.id, b.flag, c.s, c.f, c.b, d.b, d.i);
}

function testTupleVarRefAssignment3() returns (string, int, int, boolean, string, float, byte, boolean, int) {
    Foo foo1 = {name:"Test", age:23};
    Bar bar1 = {id:34, flag:true};
    FooObj fooObj1 = new ("Fooo", 3.7, 23);
    BarObj barObj1 = new (true, 56);

    var (a, (b, (c, d))) = (foo1, (bar1, (fooObj1, barObj1)));

    (a, (b, (c, d))) = bar();

    return (a.name, a.age, b.id, b.flag, c.s, c.f, c.b, d.b, d.i);
}

type Foo record {
    string name;
    int age;
};

type Bar record {
    int id;
    boolean flag;
};

type FooObj object {
    public string s;
    public float f;
    public byte b;
    public new(s, f, b){}
};

type BarObj object {
    public boolean b;
    public int i;
    public new(b, i){}
};

function testTupleVarRefWithArray1() returns (string, int[], boolean, float[]) {
    (string, (int[], (boolean, float[]))) (a, (b, (c, d))) = ("Test", ([32, 67], (false, [6.3, 4.2])));
    (a, (b, (c, d))) = ("Ballerina", ([123, 345], (true, [2.3, 4.5])));

    return (a, b, c, d);
}

function testTupleVarRefWithArray2() returns (string[], int[], boolean[], float[]) {
    (string[], (int[], (boolean[], float[]))) (a, (b, (c, d))) = (["Q", "W", "R"], ([456, 876, 56, 78], ([false, true, false], [3.5, 6.7, 9.8])));
    (a, (b, (c, d))) = (["A", "B"], ([123, 345], ([true, false], [2.3, 4.5])));

    return (a, b, c, d);
}

function testTupleVarRefWithArray3() returns (string[][], int[][], float[]) {
    (string[][], (int[][], float[])) (a, (b, c)) = ([["W", "R"], ["G", "H"]], ([[44, 66], [2, 6, 8]], [7.3, 6.7, 7.8]));
    (a, (b, c)) = ([["A", "B"], ["C", "D"]], ([[123, 345], [12, 34, 56]], [2.3, 4.5]));

    return (a, b, c);
}

function testTupleVarRefWithArray4() returns (string[][], int[][], float[]) {
    var (a, (b, c)) = ([["W", "R"], ["G", "H"]], ([[44, 66], [2, 6, 8]], [7.3, 6.7, 7.8]));
    (a, (b, c)) = ([["A", "B"], ["C", "D"]], ([[123, 345], [12, 34, 56]], [2.3, 4.5]));

    return (a, b, c);
}

function testVarRefWithUnionType1() returns (string|int|float, string|float, string) {
    (string|int|float, (string|float, string)) (a, (b, c)) = (2, (56.7, "Hello"));
    (a, (b, c)) = (34, (6.7, "Test"));
    return (a, b, c);
}

function testVarRefWithUnionType2() returns (string|int|float, string|float, string) {
    string|int|float v1 = 34;
    string|float v2 = 6.7;
    string v3 = "Test";

    (string|int|float, (string|float, string)) (a, (b, c)) = (2, (56.7, "Hello"));
    (a, (b, c)) = (v1, (v2, v3));
    return (a, b, c);
}

function testVarRefWithUnionType3() returns (string|int|float, string|float, string) {
    (string|int|float, (string|float, string)) (a, (b, c)) = (2, (56.7, "Hello"));
    (a, (b, c)) = fn2();
    return (a, b, c);
}

function fn2() returns (string|int|float, (string|float, string)) {
    (string|int|float, (string|float, string)) v = (34, (6.7, "Test"));
    return v;
}

function testVarRefWithUnionType4() returns ((string, int)|(int, boolean), float|(int, boolean), (string|float, string)) {
    ((string, int)|(int, boolean), float|(int, boolean), (string|float, string)) ((a, b), c, (d, e)) = ((12, true), (45, false), ("Hello", "World"));
    ((a, b), c, (d, e)) = (("Test", 23), 4.5, (5.7, "Foo"));
    return ((a, b), c, (d, e));
}

//not working case
function fn3() returns ((string, int)|(int, boolean), float|(int, boolean), (string|float, string)) {
    ((string, int)|(int, boolean), float|(int, boolean), (string|float, string)) ((v1, v2), v3, (v4, v5)) = (("Test", 23), 4.5, (5.7, "Foo"));
    return ((v1, v2), v3, (v4, v5));
}

function testVarRefWithUnionType5() returns ((string, int)|(int, boolean), float|(int, boolean), (string|float, string)) {
    ((string, int)|(int, boolean), float|(int, boolean), (string|float, string)) ((v1, v2), v3, (v4, v5)) = (("Test", 23), 4.5, (5.7, "Foo"));
    ((string, int)|(int, boolean), float|(int, boolean), (string|float, string)) ((a, b), c, (d, e)) = (("Test", 23), (45, false), ("Hello", "World"));
    ((a, b), c, (d, e)) = ((v1, v2), v3, (v4, v5));
    return ((a, b), c, (d, e));
}

