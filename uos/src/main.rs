#![allow(unused_variables, dead_code)]

extern crate uos;

use std::mem;
use std::fmt;
use std::slice;
use std::thread;
use std::time::{ Duration };
use std::ptr;
use std::str;

use uos::util::RingBuf;
use uos::alloc;
use uos::vec;
use uos::lock;

static KBD_BUF: RingBuf = RingBuf::new();

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

struct Point {
	x: i32,
	y: i32
}

impl fmt::Display for Point {
	fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
		write!(f, "Point @{:p}: {{ x: {}, y: {} }}", self, self.x, self.y)
	}
}

static TASKS: lock::Mutex<vec::Vec<Process>> = lock::Mutex::new(vec::Vec::new());

fn main() {
	byte_arrays_check();
	int_arrays_check();

	test_keybord_buffer();

	unsafe {
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

		test_allocator();
	}

	test_tasks_vector();

	test_points_vector();

	println!("\n*** vector mutex test ***");

	let t1 = thread::spawn(|| {
		test_task_mutex(1);
	});

	let t2 = thread::spawn(|| {
		test_task_mutex(2);
	});

	t1.join();
	t2.join();

	println!("\n*** vector mutex test end ***");

	println!("\n*** command buffer test ***");

	// let mut cmd_buf: [u8; 16] = [0; 16];
	let mut cmd_buf: vec::Vec<u8> = vec::Vec::with_cap(64);
	console_read_line(&mut cmd_buf);

	// let lf_idx = cmd_buf.iter().enumerate().find(|&(i, &c)| c == 0);
	// here we can use str::from_utf_8 and convert byte slice to string
	// let lf_idx = cmd_buf.find(b'\n');

	/*
	if let Some((i, _)) = lf_idx {
		println!("LF index: {}", i);

		let cmd = &cmd_buf[..i];
		println!("command: '{:?}'", cmd);

		if cmd == b"ps" {
			println!("printing process table");
		}
	}
	*/
	let cmd = str::from_utf8(&cmd_buf).unwrap();
	if cmd == "ps" {
		println!("printing process table");
	}

	print_slice(&cmd_buf);

	println!("\n*** command buffer test end ***");
}

fn console_read_line(buf: &mut vec::Vec<u8>) {
	println!("buf len: {}", buf.len());
	println!("buf cap: {}", buf.cap());

	let cmd = b"ps";
	println!("command len: {}", cmd.len());

	buf.clear();

	for c in cmd.iter() {
		buf.push(*c);
	}

	// unsafe { ptr::copy_nonoverlapping(cmd.as_ptr(), buf.as_mut_ptr(), cmd.len()); }
}

fn test_keybord_buffer() {
	let writer_thread = thread::spawn(|| {
		for _ in 1..64 {
			KBD_BUF.push_back(b's');
			// giving chance to readers to complete theirs work
			thread::sleep(Duration::from_millis(50));
		}

		println!("writer thread completed");
	});

	let reader_thread = thread::spawn(|| {
		for _ in 1..1024 {
			let byte = KBD_BUF.pop_front();
			if let Some(b) = byte {
				assert_eq!(b's', b);
			}

			thread::sleep(Duration::from_millis(1));
		}

		println!("reader thread completed");
	});

	writer_thread.join();
	reader_thread.join();

	let ob = KBD_BUF.pop_front();
	print_buf_byte(&ob);

	let ob = KBD_BUF.pop_front();
	print_buf_byte(&ob);
}

fn print_buf_byte(ob: &Option<u8>) {
	if let Some(b) = ob {
		println!("byte: {:x}", b);
	} else {
		println!("buffer underflow");
	}
}

fn test_task_mutex(pid: usize) {
	// TODO may be run several threads which will add several items to vector
	let mut tasks_lock = TASKS.lock();

	tasks_lock.push(Process { pid: pid, state: ProcessState { ..NULL_PROC_STATE } });

	println!("process pid: {}", tasks_lock[0].pid);
}

fn test_tasks_vector() {
	let procs: vec::Vec<Process> = vec::Vec::with_cap(16);

	println!("\n*** tasks vector test ***");

	println!("process struct size: {}", mem::size_of::<Process>());

	println!("processes vector length: {}", procs.len());
	println!("processes vector capacity: {}", procs.cap());

	println!("\n*** tasks vector test end ***");
}

fn test_points_vector() {
	println!("\n*** points vector test ***");

	let p1 = Point { x: 11, y: 22 };
	println!("p1 = {}", p1);

	let mut points: vec::Vec<Point> = vec::Vec::with_cap(8);
	points.push(p1);

	// vector is now the owner of p1
	// println!("p1 = {}", p1);

	if let Some(p) = points.pop() {
		points.push(Point { x: 44, y: 55 });

		unsafe {
			let p_ptr: *const Point = &p;
			println!("mem @{:p} = {:?}", p_ptr, slice::from_raw_parts(p_ptr as *const u32, 4));
		}

		println!("popped p = {}", p);
	}

	println!("\n*** points vector test end");
}

unsafe fn test_allocator() {
	println!("\n*** sequential allocator test ***");
	let allocator = alloc::Allocator::new(MEM_BLOCK.as_mut_ptr(), mem::size_of_val(&MEM_BLOCK));

	let mut ring_buf1 = allocator.alloc(mem::size_of::<RingBuf>()) as *mut RingBuf;
	allocator.dealloc(ring_buf1 as *mut u8);
	
	ring_buf1 = allocator.alloc(mem::size_of::<RingBuf>()) as *mut RingBuf;
	if !ring_buf1.is_null() {
		if let Some(rbr) = ring_buf1.as_mut() {
			rbr.push_back(b'a');
		}
	}

	let ring_buf2 = allocator.alloc(mem::size_of::<RingBuf>()) as *mut RingBuf;
	if !ring_buf2.is_null() {
		if let Some(rbr) = ring_buf2.as_mut() {
			rbr.push_back(b'c');
		}
	}

	// allocating blocks of memory which are larger than others
	let proc_descr_ptr: *mut Process = allocator.alloc(mem::size_of::<Process>()) as *mut Process;
	if !proc_descr_ptr.is_null() {
		if let Some(pd) = proc_descr_ptr.as_mut() {
			pd.pid = 1;
		}
	}

	println!("mem dump: {:?}", &MEM_BLOCK[..15]);

	let proc2 = allocator.alloc(mem::size_of::<Process>()) as *mut Process;
	if !proc2.is_null() {
		(*proc2).pid = 2;
	}
	
	let ring_buf3 = allocator.alloc(mem::size_of::<RingBuf>()) as *mut RingBuf;
	if !ring_buf3.is_null() {
		if let Some(rbr) = ring_buf3.as_mut() {
			rbr.push_back(b'd');
		}
	}
	
	// out of memory condition check
	let proc3 = allocator.alloc(mem::size_of::<Process>());
	assert!(proc3.is_null());

	allocator.dealloc(ring_buf1 as *mut u8);
	allocator.dealloc(proc_descr_ptr as *mut u8);
	
	let proc4 = allocator.alloc(mem::size_of::<Process>());
	assert!(!proc4.is_null());
	
	allocator.dealloc(ring_buf2 as *mut u8);

	println!("\n*** sequential allocator test end ***");
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
