package examples

import "core:fmt"
import gccjit ".."

int_t: ^gccjit.Type

main :: proc() {
    ctx := gccjit.acquire_context()
    assert(ctx != nil)
    
    int_t = gccjit.get_type(ctx, .Int)
    
    codegen(ctx)
    
    result := gccjit.compile(ctx)
    assert(result != nil, "compilation failed")
    defer gccjit.release_result(result)
    gccjit.release_context(ctx)
    
    code: rawptr = gccjit.result_get_code(result, "loop_test")
    assert(code != nil, "codegen failed")
    
    Proc :: #type proc "c" (int) -> int
    fn_ptr := cast(Proc)code
    
    fmt.println(fn_ptr(3)) // 5
}

codegen :: proc(ctx: ^gccjit.Context) {
    // int loop_test (int n)
    // {
    //   int sum = 0;
    //   for (int i = 0; i < n; i++)
    //     sum += i * i;
    //   return sum;
    // }

    // (simplified)
    // int loop_test (int n)
    // {
    //   int sum = 0;
    //   int i = 0;
    //   while (i < n)
    //   {
    //     sum += i * i;
    //     i++;
    //   }
    //   return sum;
    // }
    n := gccjit.new_param(ctx, nil, int_t, "n")
    func := gccjit.new_function(ctx, nil, .Exported, int_t, "loop_test", {n})
    
    // blocks
    entry := gccjit.new_block(func, "entry")
    loop_cond := gccjit.new_block(func, "loop.cond")
    loop_body := gccjit.new_block(func, "loop.body")
    loop_done := gccjit.new_block(func, "loop.done")
    
    // entry
    sum := gccjit.new_local_with_init(func, nil, int_t, "sum", entry, gccjit.new_rvalue_zero(ctx, int_t))
    i := gccjit.new_local_with_init(func, nil, int_t, "i", entry, gccjit.new_rvalue_zero(ctx, int_t))
    gccjit.block_end_with_jump(entry, nil, loop_cond)
    
    // loop condition
    cont := gccjit.new_comparison(ctx, nil, .Lt, gccjit.as_rvalue(i), gccjit.as_rvalue(n))
    gccjit.block_end_with_conditional(loop_cond, nil, cont, loop_body, loop_done)
    
    // loop body
    gccjit.block_add_assignment_op(loop_body, nil, sum, .Plus, gccjit.new_binary_op(
        ctx, nil, .Mult,
        int_t, gccjit.as_rvalue(i), gccjit.as_rvalue(i),
    ))
    gccjit.block_add_assignment_op(loop_body, nil, i, .Plus, gccjit.new_rvalue_one(ctx, int_t))
    gccjit.block_end_with_jump(loop_body, nil, loop_cond)
    
    gccjit.block_end_with_return(loop_done, nil, gccjit.as_rvalue(sum))
    gccjit.dump_to_dot(func, "loop.dot")
}
