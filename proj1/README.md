# Project1 - Lexical Definition
The project is to write a scanner for the Scala language in **lex**.

## Install flex
```
$ sudo apt install flex bison
```

## How to build
```
make
./scanner < input.scala
```

## Example
Given the input:
```
/* Hello World Example */
object HelloWorld {
    def main ( ) {
        // Print text to the console
        println ("Hello World");
    }
}
```
The scanner should output:
```
1: /* Hello World Example */
<OBJECT>
<id: HelloWorld>
<'{'>
2: object HelloWorld {
<DEF>
<id: main>
<'('>
<')'>
<'{'>
3: def main ( ) {
4: // Print text to the console
<PRINTLN>
<'('>
<string:Hello World>
<')'>
<';'>
5: println ("Hello World");
<'}'>
6: }
<'}'>
7: }

Symbol Table:
HelloWorld
main
```