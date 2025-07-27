package gccjit

import "core:c"

BoolOption :: enum c.int {
    DebugInfo         = 0,
    DumpInitialTree   = 1,
    DumpInitialGimple = 2,
    DumpGeneratedCode = 3,
    DumpSummary       = 4,
    DumpEverything    = 5,
    SelfcheckGC       = 6,
    KeepIntermediates = 7,
}

StringOption :: enum c.int {
    ProgramName = 0,
    SpecialCharsInFuncNames = 1,
}

IntOption :: enum c.int {
    OptimizationLevel = 0,
}

OptimizationLevel :: enum c.int {
    Unoptimized = 0,
    Limited     = 1,
    Standard    = 2,
    Aggressive  = 3,
}

OutputKind :: enum c.int {
    Assembler      = 0,
    ObjectFile     = 1,
    DynamicLibrary = 2,
    Executable     = 3,
}

JitType :: enum c.int {
    Void              = 0,
    VoidPtr           = 1,
    Bool              = 2,
    Char              = 3,
    SignedChar        = 4,
    UnsignedChar      = 5,
    Short             = 6,
    UnsignedShort     = 7,
    Int               = 8,
    UnsignedInt       = 9,
    Long              = 10,
    UnsignedLong      = 11,
    LongLong          = 12,
    UnsignedLongLong  = 13,
    Float             = 14,
    Double            = 15,
    LongDouble        = 16,
    ConstCharPtr      = 17,
    SizeT             = 18,
    FilePtr           = 19,
    ComplexFloat      = 20,
    ComplexDouble     = 21,
    ComplexLongDouble = 22,
}

FunctionKind :: enum c.int {
    Exported     = 0,
    Internal     = 1,
    Imported     = 2,
    AlwaysInline = 3,
}

UnaryOp :: enum c.int {
    Minus         = 0,
    BitwiseNegate = 1,
    LogicalNegate = 2,
    Abs           = 3,
}

BinaryOp :: enum c.int {
    Plus       = 0,
    Minus      = 1,
    Mult       = 2,
    Divide     = 3,
    Modulo     = 4,
    BitwiseAnd = 5,
    BitwiseXor = 6,
    BitwiseOr  = 7,
    LogicalAnd = 8,
    LogicalOr  = 9,
    Lshift     = 10,
    Rshift     = 11,
}

Comparison :: enum c.int {
    Eq = 0,
    Ne = 1,
    Lt = 2,
    Le = 3,
    Gt = 4,
    Ge = 5,
}

TlsModel :: enum c.int {
    None          = 0,
    GlobalDynamic = 1,
    LocalDynamic  = 2,
    InitialExec   = 3,
    LocalExec     = 4,
}

GlobalKind :: enum c.int {
    Exported = 0,
    Internal = 1,
    Imported = 2,
}

VariableAttribute :: enum c.int {
    Visibility = 0,
}

FunctionAttribute :: enum c.int {
    Alias        = 0,
    AlwaysInline = 1,
    Inline       = 2,
    NoInline     = 3,
    Target       = 4,
    Used         = 5,
    Visibility   = 6,
    Cold         = 7,
    ReturnsTwice = 8,
    Pure         = 9,
    Const        = 10,
    Weak         = 11,
    NonNull      = 11,
}
