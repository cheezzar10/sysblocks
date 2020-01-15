#![allow(unused_variables, dead_code)]

extern crate uos;

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
static mut MEM_BLOCK: [u32; 1024] = [0; 1024];

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
		println!("another  task: {}", PROCS[CUR_TASK_IDX - 1].pid);
		// match running process 

		let alloc = alloc::Allocator::new(MEM_BLOCK.as_mut_ptr());
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
