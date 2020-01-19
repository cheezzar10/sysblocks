#![allow(unused_variables, dead_code)]

extern crate uos;

use std::mem;

use uos::util::RingBuf;
use uos::alloc;

static mut KBD_BUF: RingBuf = RingBuf::new();

struct Process {
	pid: usize,
	state: ProcessState
}

// saved process state
struct ProcessState {
	eip: usize,
	eflags: usize,
	eax: usize,
	ecx: usize,
	edx: usize,
	ebx: usize,
	esp: usize,
	ebp: usize,
	esi: usize,
	edi: usize,
	cs: usize,
	ds: usize,
	pdbr: usize
}

static NULL_PROC_STATE: ProcessState = ProcessState { eip: 0, eflags: 0, eax: 0, ecx: 0, edx: 0, ebx: 0, esp: 0, ebp: 0, esi: 0, edi: 0, cs: 0, ds: 0, pdbr: 0 };

static mut PROCS: [Process; 2] = [ 
	Process { pid: 0, state: ProcessState { ..NULL_PROC_STATE } }, 
	Process { pid: 0, state: ProcessState { ..NULL_PROC_STATE } }
];

static mut CUR_TASK_IDX: usize = 1;

// emulating memory page, in real world we will point to the block of hw memory
static mut MEM_BLOCK: [u8; 256] = [0; 256];

// should be defined as extern
// static CUR_TASK_PTR: *mut Process = &mut PROCS[0];

fn main() {
	byte_arrays_check();
	int_arrays_check();

	unsafe {
		KBD_BUF.push_back(b'a');

		let ob = KBD_BUF.pop_front();
		print_buf_byte(&ob);

		let ob = KBD_BUF.pop_front();
		print_buf_byte(&ob);

		let mut proc_ref: &mut Process = &mut PROCS[0];
		proc_ref.pid = 1;

		proc_ref = &mut PROCS[1];
		proc_ref.pid = 2;

		let next_proc = &PROCS
			.iter()
			.find(|p| p.pid != 1);

		match next_proc {
			Some(p) => {
				println!("next proc pid: {}", p.pid);
			}
			_ => ()
		}

		println!("current task: {}", PROCS[CUR_TASK_IDX].pid);
		println!("another task: {}", PROCS[CUR_TASK_IDX - 1].pid);
		// match running process 

		println!("\n*** sequential allocator test ***");
		let alloc = alloc::Allocator::new(MEM_BLOCK.as_mut_ptr(), mem::size_of_val(&MEM_BLOCK));
		let proc_descr_ptr: *mut Process = alloc.alloc(mem::size_of::<Process>()) as *mut Process;

		// better use as_ref and match returned Option
		if !proc_descr_ptr.is_null() {
			if let Some(pd) = proc_descr_ptr.as_mut() {
				pd.pid = 1;
			}
		}

		println!("mem dump: {:?}", &MEM_BLOCK[..15]);

		let proc2 = alloc.alloc(mem::size_of::<Process>()) as *mut Process;
		if !proc2.is_null() {
			(*proc2).pid = 2;
		}

		alloc.dealloc(proc_descr_ptr as *mut u8);

		println!("ring buf mem size: {}", mem::size_of::<RingBuf>());
	}
}

fn print_buf_byte(ob: &Option<u8>) {
	if let Some(b) = ob {
		println!("byte: {:x}", b);
	} else {
		println!("buffer underflow");
	}
}

fn byte_arrays_check() {
	println!("checking arrays");

	let a1: [u8; 2] = [1; 2];
	let a2 = [1u8, 1u8];

	assert_eq!(a1, a2);
	println!("same types");

	print_slice(&a1);
}

fn print_slice<T: std::fmt::Debug>(a: &[T]) {
	println!("{:?}", a);
}

fn int_arrays_check() {
	let a: [u32; 4] = [ 0x4, 0xff, 0x8, 0x12 ];
	print_slice(&a);
}