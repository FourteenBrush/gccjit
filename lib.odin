package gccjit

import "core:c"
import "base:runtime"
import "core:strings"

when ODIN_OS == .Windows {
    foreign import gccjit "gccjit.lib"
} else {
    foreign import gccjit "system:gccjit"
}

// Opaque typedefs
Context  :: distinct struct {}
Timer    :: distinct struct {}
Type     :: distinct struct {}
Object   :: distinct struct {}
Param    :: distinct struct {}
Location :: distinct struct {}
Function :: distinct struct {}
Block    :: distinct struct {}
LValue   :: distinct struct {}
RValue   :: distinct struct {}
Field    :: distinct struct {}
Struct   :: distinct struct {}
Result   :: distinct struct {}

SwitchCase   :: distinct struct {}
FunctionType :: distinct struct {}
VectorType   :: distinct struct {}
ExtendedAsm  :: distinct struct {}

// for places where an int is used as a bool
#assert(size_of(c.int) == size_of(b32))
#assert(size_of(c.uint) == size_of(u32))
#assert(size_of(c.size_t) == size_of(uint))
#assert(size_of(c.ssize_t) == size_of(int))
#assert(size_of(c.double) == size_of(f64))

@(link_prefix="gcc_jit_")
foreign gccjit {
    version_major :: proc() -> i32 ---
    version_minor :: proc() -> i32 ---
    @(link_name="gcc_jit_version_patchlevel")
    version_patch :: proc() -> i32 ---
    
    @(link_name="gcc_jit_context_acquire")
    acquire_context :: proc() -> ^Context ---
    @(link_name="gcc_jit_context_release")
    release_context :: proc(ctx: ^Context) ---
    
    // Timing API
    @(link_name="gcc_jit_timer_new")
    new_timer :: proc() -> ^Timer ---
    @(link_name="gcc_jit_timer_release")
    release_timer :: proc(^Timer) ---
    @(link_name="gcc_jit_timer_push")
    push_timer :: proc(timer: ^Timer, item_name: cstring) ---
    @(link_name="gcc_kit_timer_pop")
    pop_timer :: proc(timer: ^Timer, item_name: cstring) ---
    @(link_name="gcc_jit_timer_print")
    print_timer :: proc(timer: ^Timer, f_out: ^c.FILE) ---
    
    // Upcasts, see relevant proc groups
    param_as_lvalue :: proc(param: ^Param) -> ^LValue ---
    param_as_rvalue :: proc(param: ^Param) -> ^RValue ---
    param_as_object :: proc(param: ^Param) -> ^Object ---
    case_as_object :: proc(case_: ^SwitchCase) -> ^Object ---
    field_as_object :: proc(field: ^Field) -> ^Object ---
    
    @(link_name="gcc_jit_object_get_debug_string")
    object_debug_string :: proc(obj: ^Object) -> cstring ---
    
    type_as_object :: proc(type: ^Type) -> ^Object ---
    type_get_pointer :: proc(type: ^Type) -> ^Type ---
    type_get_const :: proc(type: ^Type) -> ^Type ---
    type_get_volatile :: proc(type: ^Type) -> ^Type ---
    type_get_aligned :: proc(type: ^Type, align_bytes: uint) -> ^Type ---
    type_get_vector :: proc(type: ^Type, num_units: uint) -> ^Type ---
    
    // Globals
    @(link_name="gcc_jit_global_set_initializer")
    _global_set_initializer :: proc(ctx: ^Context, blob: rawptr, nbytes: uint) -> ^LValue ---
    global_set_initializer_rvalue :: proc(global: ^LValue, init_value: ^RValue) -> ^LValue ---
    global_set_readonly :: proc(global: ^LValue) ---
    
    // Lvalues
    lvalue_as_object :: proc(lval: ^LValue) -> ^Object ---
    lvalue_as_rvalue :: proc(lval: ^LValue) -> ^RValue ---
    lvalue_get_address :: proc(lval: ^LValue, loc: ^Location) -> ^RValue ---
    lvalue_set_tls_model :: proc(lval: ^LValue, model: TlsModel) ---
    lvalue_set_link_section :: proc(lval: ^LValue, section_name: cstring) ---
    lvalue_set_register_name :: proc(lval: ^LValue, reg_name: cstring) ---
    lvalue_set_alignment :: proc(lval: ^LValue, bytes: u32) ---
    lvalue_get_alignment :: proc(lval: ^LValue) -> u32 ---
    @(link_name="gcc_jit_lvalue_add_string_attribute")
    lvalue_add_str_attribute :: proc(lval: ^LValue, attrib: VariableAttribute, value: cstring) ---
    
    // Working with pointers, structs and unions
    rvalue_dereference :: proc(rval: ^RValue, loc: ^Location) -> ^LValue ---
    lvalue_access_field :: proc(struct_: ^LValue, loc: ^Location, field: ^Field) -> ^LValue ---
    rvalue_access_field :: proc(struct_: ^RValue, loc: ^Location, field: ^Field) -> ^RValue ---
    rvalue_dereference_field :: proc(ptr: ^RValue, loc: ^Location, field: ^Field) -> ^RValue ---
    
    // Rvalues
    rvalue_get_type :: proc(rval: ^RValue) -> ^Type ---
    rvalue_as_object :: proc(rvalue: ^RValue) -> ^Object ---
    
    // Functions
    function_as_object :: proc(func: ^Function) -> ^Object ---
    // TODO: proc group
    function_add_attribute :: proc(func: ^Function, attrib: FunctionAttribute) ---
    @(link_name="gcc_jit_function_add_string_attribute")
    function_add_str_attribute :: proc(func: ^Function, attrib: FunctionAttribute, value: cstring) ---
    @(link_name="gcc_jit_function_add_integer_array_attribute")
    function_add_int_array_attribute :: proc(func: ^Function, attrib: FunctionAttribute, len: uint) ---
    
    // Function pointers
    function_get_addr :: proc(func: ^Function, loc: ^Location) -> ^RValue ---
    
    // Structs
    struct_as_type :: proc(s: ^Struct) -> ^Type ---
    @(link_name="gcc_jit_struct_set_fields")
    _struct_set_fields :: proc(s: ^Struct, loc: ^Location, nfields: i32, fields: [^]^Field) ---
    
    result_get_code :: proc(res: ^Result, func_name: cstring) -> rawptr ---
    result_get_global :: proc(res: ^Result, name: cstring) -> rawptr ---
    @(link_name="gcc_jit_result_release")
    release_result :: proc(res: ^Result) ---

    // Blocks
    block_as_object :: proc(block: ^Block) -> ^Object ---
    block_get_function :: proc(block: ^Block) -> ^Function ---
    block_add_eval :: proc(block: ^Block, loc: ^Location, rval: ^RValue) ---
    block_add_assignment :: proc(block: ^Block, loc: ^Location, lval: ^LValue, rval: ^RValue) ---
    block_add_assignment_op :: proc(block: ^Block, loc: ^Location, lval: ^LValue, op: BinaryOp, rval: ^RValue) ---
    block_add_comment :: proc(block: ^Block, loc: ^Location, text: cstring) ---
    block_end_with_conditional :: proc(block: ^Block, loc: ^Location, boolval: ^RValue, on_true, on_false: ^Block) ---
    block_end_with_jump :: proc(block: ^Block, loc: ^Location, target: ^Block) ---
    block_end_with_return :: proc(block: ^Block, loc: ^Location, rval: ^RValue) ---
    block_end_with_void_return :: proc(block: ^Block, loc: ^Location) ---
    @(link_name="gcc_jit_block_end_with_switch")
    _block_end_with_switch :: proc(block: ^Block, loc: ^Location, expr: ^RValue, default: ^Block, ncases: i32, cases: [^]^SwitchCase) ---
    
    // Assembly support
    block_add_extended_asm :: proc(block: ^Block, loc: ^Location, asm_template: cstring) -> ^ExtendedAsm ---
    @(link_name="gcc_jit_block_end_with_extended_asm_goto")
    _block_end_with_extended_asm_goto :: proc(block: ^Block, loc: ^Location, asm_template: cstring, ngoto_blocks: i32, goto_blocks: [^]^Block, fallthrough_block: ^Block) -> ^ExtendedAsm ---
    @(link_name="gcc_jit_extended_asm_set_volatile_flag")
    extended_asm_set_volatile :: proc(asm_: ^ExtendedAsm, val: b32) ---
    extended_asm_set_inline :: proc(asm_: ^ExtendedAsm, val: b32) ---
    extended_asm_add_output_operand :: proc(asm_: ^ExtendedAsm, asm_symbolic_name, constraint: cstring, dest: ^LValue) ---
    extended_asm_add_input_operand :: proc(asm_: ^ExtendedAsm, asm_symbolic_name, constraint: cstring, src: ^RValue) ---
    extended_asm_add_clobber :: proc(asm_: ^ExtendedAsm, victim: cstring) ---
    extended_asm_as_object :: proc(asm_: ^ExtendedAsm) -> ^Object ---
    @(link_name="gcc_jit_context_add_top_level_asm")
    add_top_level_asm :: proc(ctx: ^Context, loc: ^Location, asm_stmts: cstring) ---
    
    // Reflection
    type_dyncast_array :: proc(^Type) -> ^Type ---
    type_is_bool :: proc(^Type) -> b32 ---
    type_dyncast_function_ptr_type :: proc(^Type) -> ^FunctionType ---
    function_type_get_return_type :: proc(^FunctionType) -> ^Type ---
    function_type_get_param_count :: proc(^FunctionType) -> uint ---
    function_type_get_param_type :: proc(fn_type: ^FunctionType, idx: uint) -> ^Type ---
    type_is_integral :: proc(^Type) -> b32 ---
    type_is_pointer :: proc(^Type) -> b32 ---
    type_dyncast_vector :: proc(^Type) -> ^VectorType ---
    type_is_struct :: proc(^Type) -> ^Struct ---
    vector_type_get_num_units :: proc(^VectorType) -> uint ---
    vector_type_get_element_type :: proc(^VectorType) -> ^Type ---
    type_unqualified :: proc(^Type) -> ^Type ---
    struct_get_field :: proc(s: ^Struct, idx: uint) -> ^Field ---
    struct_get_field_count :: proc(^Struct) -> uint ---
    compatible_types :: proc(ltype, rtype: ^Type) -> b32 ---
    type_get_size :: proc(^Type) -> int ---
    type_get_restrict :: proc(^Type) -> ^Type ---
}

@(link_prefix="gcc_jit_context_")
foreign gccjit {
    new_child_context :: proc(parent: ^Context) -> ^Context ---
    
    // Options
    set_str_option :: proc(ctx: ^Context, option: StringOption, value: cstring) ---
    set_bool_option :: proc(ctx: ^Context, option: BoolOption, val: b32) ---
    set_int_option :: proc(ctx: ^Context, option: IntOption, val: i32) ---
    @(link_name="gcc_jit_context_set_bool_allow_unreachable_blocks")
    allow_unreachable_blocks :: proc(ctx: ^Context, value: b32) ---
    @(link_name="gcc_jit_context_set_bool_use_external_driver")
    use_external_driver :: proc(ctx: ^Context, val: b32) ---
    @(link_name="gcc_jit_context_set_bool_print_errors_to_stderr")
    print_errors_to_stderr :: proc(ctx: ^Context, val: b32) ---
    add_command_line_option :: proc(ctx: ^Context, optname: cstring) ---
    add_driver_option :: proc(ctx: ^Context, optname: cstring) ---
    set_output_ident :: proc(ctx: ^Context, ident: cstring) ---
    
    get_first_error :: proc(ctx: ^Context) -> cstring ---
    get_last_error :: proc(ctx: ^Context) -> cstring ---
    
    compile :: proc(ctx: ^Context) -> ^Result ---
    compile_to_file :: proc(ctx: ^Context, output: OutputKind, output_path: cstring) ---
    
    // Debugging
    dump_to_file :: proc(ctx: ^Context, path: cstring, update_locations: b32) ---
    // FIXME: pass some odin type instead of a ^FILE
    set_logfile :: proc(ctx: ^Context, logfile: ^c.FILE, flags := i32(0), verbosity := i32(0)) ---
    dump_reproducer_to_file :: proc(ctx: ^Context, path: cstring) ---
    enable_dump :: proc(ctx: ^Context, dump_name: cstring, dest: ^cstring) ---
    
    // Timing API
    get_timer :: proc(ctx: ^Context) -> ^Timer ---
    set_timer :: proc(ctx: ^Context, timer: ^Timer) ---
    
    new_global :: proc(ctx: ^Context, loc: ^Location, kind: GlobalKind, type: ^Type, name: cstring) -> ^LValue ---
    new_array_access :: proc(ctx: ^Context, loc: ^Location, ptr: ^RValue, idx: ^RValue) -> ^LValue ---
    new_vector_access :: proc(ctx: ^Context, loc: ^Location, vec: ^RValue, idx: ^RValue) -> ^RValue ---
    
    new_location :: proc(ctx: ^Context, filename: cstring, line, col: i32) -> ^Location ---
    
    // Rvalues
    new_rvalue_from_int :: proc(ctx: ^Context, numeric_type: ^Type, value: i32) -> ^RValue ---
    new_rvalue_from_long :: proc(ctx: ^Context, numeric_type: ^Type, value: c.long) -> ^RValue ---
    new_rvalue_from_double :: proc(ctx: ^Context, numeric_type: ^Type, value: c.double) -> ^RValue ---
    new_rvalue_from_ptr :: proc(ctx: ^Context, ptr_type: ^Type, value: rawptr) -> ^RValue ---
    @(link_name="gcc_jit_context_new_rvalue_from_vector")
    _new_rvalue_from_vector :: proc(ctx: ^Context, loc: ^Location, vec_type: ^Type, nelements: uint, elements: [^]^RValue) -> ^RValue ---
    new_rvalue_vector_perm :: proc(ctx: ^Context, loc: ^Location, elements1, elements2: [^]^RValue, mask: ^RValue) -> ^RValue ---
    // Function pointers
    @(link_name="gcc_jit_context_new_function_ptr_type")
    _new_fn_ptr_type :: proc(ctx: ^Context, loc: ^Location, ret_type: ^Type, nparams: i32, param_types: [^]^Type, variadic := b32(false)) -> ^Type ---
    
    new_string_literal :: proc(ctx: ^Context, value: cstring) -> ^RValue ---
    new_sizeof :: proc(ctx: ^Context, type: ^Type) -> ^RValue ---
    new_alignof :: proc(ctx: ^Context, type: ^Type) -> ^RValue ---
    
    @(link_name="gcc_jit_context_new_array_constructor")
    _new_array_constructor :: proc(ctx: ^Context, loc: ^Location, type: ^Type, nvalues: uint, values: [^]^RValue) -> ^RValue ---
    @(link_name="gcc_jit_context_new_struct_constructor")
    _new_struct_constructor :: proc(ctx: ^Context, loc: ^Location, type: ^Type, nvalues: uint, fields: [^]^Field) -> ^RValue ---
    new_union_constructor :: proc(ctx: ^Context, loc: ^Location, type: ^Type, field: ^Field, value: ^RValue) -> ^RValue ---
    new_cast :: proc(ctx: ^Context, loc: ^Location, rvalue: ^RValue, type: ^Type) -> ^RValue ---
    new_bitcast :: proc(ctx: ^Context, loc: ^Location, rvalue: ^RValue, type: ^Type) -> ^RValue ---
    
    @(link_name="gcc_jit_context_null")
    new_rvalue_null :: proc(ctx: ^Context, ptr_type: ^Type) -> ^RValue ---
    @(link_name="gcc_jit_context_zero")
    new_rvalue_zero :: proc(ctx: ^Context, numeric_type: ^Type) -> ^RValue ---
    @(link_name="gcc_jit_context_one")
    new_rvalue_one :: proc(ctx: ^Context, numeric_type: ^Type) -> ^RValue ---
    
    get_type :: proc(ctx: ^Context, type: JitType) -> ^Type ---
    new_array_type :: proc(ctx: ^Context, loc: ^Location, elem_type: ^Type, nelements: i32) -> ^Type ---
    new_param :: proc(ctx: ^Context, loc: ^Location, type: ^Type, name: cstring) -> ^Param ---
    
    // Functions
    @(link_name="gcc_jit_context_new_function")
    _new_function :: proc(ctx: ^Context, loc: ^Location, kind: FunctionKind, ret_type: ^Type, name: cstring, nparams: i32, params: [^]^Param, variadic := b32(false)) -> ^Function ---
    get_builtin_function :: proc(ctx: ^Context, name: cstring) -> ^Function ---
    get_target_builtin_function :: proc(ctx: ^Context, name: cstring) -> ^Function ---
    
    // Structs
    @(link_name="gcc_jit_context_new_struct_type")
    _new_struct_type :: proc(ctx: ^Context, loc: ^Location, name: cstring, nfields: i32, fields: [^]^Field) -> ^Struct ---
    new_opaque_struct :: proc(ctx: ^Context, loc: ^Location, name: cstring) -> ^Struct ---
    @(link_name="gcc_jit_context_new_union_type")
    _new_union_type :: proc(ctx: ^Context, loc: ^Location, name: cstring, nfields: i32, fields: [^]^Field) -> ^Type ---
    
    // Fields
    new_field :: proc(ctx: ^Context, loc: ^Location, type: ^Type, name: cstring) -> ^Field ---
    new_bitfield :: proc(ctx: ^Context, loc: ^Location, type: ^Type, name: cstring) -> ^Field ---
    
    new_unary_op :: proc(ctx: ^Context, loc: ^Location, op: UnaryOp, res_type: ^Type, rvalue: ^RValue) -> ^RValue ---
    new_binary_op :: proc(ctx: ^Context, loc: ^Location, op: BinaryOp, res_type: ^Type, a, b: ^RValue) -> ^RValue ---
    new_comparison :: proc(ctx: ^Context, loc: ^Location, op: Comparison, a, b: ^RValue) -> ^RValue ---
    @(link_name="gcc_jit_context_new_call")
    _new_call :: proc(ctx: ^Context, loc: ^Location, func: ^Function, nargs: i32, args: [^]^RValue) -> ^RValue ---
    @(link_name="gcc_jut_context_new_call_through_ptr")
    _new_call_through_ptr :: proc(ctx: ^Context, loc: ^Location, fn_ptr: ^RValue, nargs: i32, args: [^]^RValue) -> ^RValue ---
    
    @(link_name="gcc_jit_rvalue_set_bool_require_tail_call")
    rvalue_require_tailcall :: proc(call: ^RValue, val: b32) ---
    
    // Switch cases
    new_case :: proc(ctx: ^Context, min_value, max_value: ^RValue, dest_block: ^Block) -> ^SwitchCase ---
}

@(link_prefix="gcc_jit_function_")
foreign gccjit {
    get_param :: proc(func: ^Function, idx: i32) -> ^Param ---
    get_param_count :: proc(func: ^Function) -> uint ---
    get_return_type :: proc(func: ^Function) -> ^Type ---
    new_local :: proc(func: ^Function, loc: ^Location, type: ^Type, name: cstring) -> ^LValue ---
    new_temp :: proc(func: ^Function, loc: ^Location, name: cstring)  -> ^LValue ---
    dump_to_dot :: proc(func: ^Function, path: cstring) ---
    
    // Blocks
    new_block :: proc(func: ^Function, name: cstring) -> ^Block ---
}

set_optimization_level :: proc "contextless" (ctx: ^Context, l: OptimizationLevel) {
    set_int_option(ctx, .OptimizationLevel, cast(i32)l)
}

new_location_from :: proc(ctx: ^Context, loc: runtime.Source_Code_Location) -> ^Location {
    filepath := strings.clone_to_cstring(loc.file_path, context.temp_allocator)
    return new_location(ctx, filepath, line=loc.line, col=loc.column)
}

as_rvalue :: proc { param_as_rvalue, lvalue_as_rvalue }

as_object :: proc {
    param_as_object,
    case_as_object,
    field_as_object,
    type_as_object,
    lvalue_as_object,
    rvalue_as_object,
    function_as_object,
    block_as_object,
    extended_asm_as_object,
}

new_rvalue_from :: proc {
    new_rvalue_from_int,
    new_rvalue_from_long,
    new_rvalue_from_double,
    new_rvalue_from_ptr,
    new_rvalue_from_vector,
}

new_function :: proc "contextless" (ctx: ^Context, loc: ^Location, kind: FunctionKind, ret_type: ^Type, name: cstring, params: []^Param, variadic := b32(false)) -> ^Function {
    return _new_function(ctx, loc, kind, ret_type, name, cast(i32)len(params), raw_data(params), variadic)
}

new_array_constructor :: proc "contextless" (ctx: ^Context, loc: ^Location, type: ^Type, values: []^RValue) -> ^RValue {
    return _new_array_constructor(ctx, loc, type, len(values), raw_data(values))
}

new_struct_constructor :: proc "contextless" (ctx: ^Context, loc: ^Location, type: ^Type, fields: []^Field) -> ^RValue {
    return _new_struct_constructor(ctx, loc, type, len(fields), raw_data(fields))
}

new_rvalue_from_vector :: proc "contextless" (ctx: ^Context, loc: ^Location, vec_type: ^Type, elements: []^RValue) -> ^RValue {
    return _new_rvalue_from_vector(ctx, loc, vec_type, len(elements), raw_data(elements))
}

new_call :: proc "contextless" (ctx: ^Context, loc: ^Location, func: ^Function, args: []^RValue) -> ^RValue {
    return _new_call(ctx, loc, func, cast(i32)len(args), raw_data(args))
}

new_call_through_ptr :: proc "contextless" (ctx: ^Context, loc: ^Location, fn_ptr: ^RValue, args: []^RValue) -> ^RValue {
    return _new_call_through_ptr(ctx, loc, fn_ptr, cast(i32)len(args), raw_data(args))
}

new_fn_ptr_type :: proc "contextless" (ctx: ^Context, loc: ^Location, ret_type: ^Type, param_types: []^Type, variadic := b32(false)) -> ^Type {
    return _new_fn_ptr_type(ctx, loc, ret_type, cast(i32)len(param_types), raw_data(param_types))
}

global_set_initializer :: proc "contextless" (ctx: ^Context, blob: []u8) -> ^LValue {
    return _global_set_initializer(ctx, raw_data(blob), len(blob))
}

block_end_with_switch :: proc "contextless" (block: ^Block, loc: ^Location, expr: ^RValue, default: ^Block, cases: []^SwitchCase) {
    _block_end_with_switch(block, loc, expr, default, cast(i32)len(cases), raw_data(cases))
}

struct_set_fields :: proc "contextless" (s: ^Struct, loc: ^Location, fields: []^Field) {
    _struct_set_fields(s, loc, cast(i32)len(fields), raw_data(fields))
}

new_union_type :: proc "contextless" (ctx: ^Context, loc: ^Location, name: cstring, fields: []^Field) -> ^Type {
    return _new_union_type(ctx, loc, name, cast(i32)len(fields), raw_data(fields))
}

block_end_with_extended_asm_goto :: proc "contextless" (block: ^Block, loc: ^Location, asm_template: cstring, goto_blocks: []^Block, fallthrough_block: ^Block) -> ^ExtendedAsm {
    return _block_end_with_extended_asm_goto(block, loc, asm_template, cast(i32)len(goto_blocks), raw_data(goto_blocks), fallthrough_block)
}

// Creates a new local with initializer, the source code location is shared for both the local and the assignment.
// If you need different locations, call the individual procs instead.
new_local_with_init :: proc "contextless" (func: ^Function, loc: ^Location, type: ^Type, name: cstring, block: ^Block, init: ^RValue) -> ^LValue {
    local := new_local(func, loc, type, name)
    block_add_assignment(block, loc, local, init)
    return local
}
