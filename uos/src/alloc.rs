pub struct Allocator {
	mem_block: *mut u32
}

// TODO simplest possible sequential fit allocator with header structure

impl Allocator {
	pub const fn new(mem_blk: *mut u32) -> Allocator {
		Allocator { mem_block: mem_blk }
	}
}
