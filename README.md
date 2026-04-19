# EmitFuscator
> Version 1.0.1 — Work In Progress

EmitFuscator is an Simple open source **AST-based Lua obfuscator** for Lua 5.1 / Luau. It parses your source code into an Abstract Syntax Tree, runs multiple transformation passes over it, then encodes and wraps the result in a VM runtime — making the output difficult to reverse engineer.

## Status
This project is still in active development. Expect bugs, missing features, and breaking changes between versions.

## Obfuscator Type
EmitFuscator is an **SIMPLE** **AST-based obfuscator** combined with a **VM runtime wrapper**. This means it:
- Parses source into tokens and transforms them directly
- Encodes the transformed source using byte-offset encoding
- Wraps execution inside a sandboxed VM environment
- Injects dead code noise to bloat and confuse deobfuscators

## Usage
```bash
lua main.lua Output/test.lua
