use std::ptr;
use std::slice;
use std::mem;
use std::io;

use std::process;

use std::ffi::{CString};

use std::ops::IndexMut;
use std::io::Write;

use libc;

// gig of memory
const SHARED_BUF_SIZE: usize = 1024 * 1024 * 1024;

fn main() {
	let shm_name: CString = CString::new("shbuf").unwrap();
	let shm_flags: libc::c_int = libc::O_CREAT | libc::O_RDWR;

	// the following cast is required fo osx only
	let shm_mode = libc::S_IRUSR as libc::c_uint | libc::S_IWUSR as libc::c_uint;

	println!("shared memory open");
	let shm_fd = unsafe { libc::shm_open(shm_name.as_ptr(), shm_flags, shm_mode) };
	if shm_fd == -1 {
		eprintln!("shared memory open failed!");
		process::exit(1);
	}

	println!("shared memory resize");
	let rsz_status = unsafe { libc::ftruncate(shm_fd, SHARED_BUF_SIZE as libc::off_t) };
	if rsz_status == -1 {
		eprintln!("shared memory resize failed!");

		unlink_shmem(&shm_name);

		process::exit(1);
	}

	println!("shared memory mapping");
	let shared_buf_ptr: *mut libc::c_void = unsafe { 
		libc::mmap(ptr::null_mut(), SHARED_BUF_SIZE, libc::PROT_READ | libc::PROT_WRITE, libc::MAP_SHARED, shm_fd, 0)
	};

	if shared_buf_ptr == libc::MAP_FAILED {
		eprintln!("shared memory mapping failed!");

		unlink_shmem(&shm_name);

		process::exit(1);
	}

	// TODO create slice from mapped memory
	let shared_buf: &mut [usize] = unsafe { 
		slice::from_raw_parts_mut(shared_buf_ptr as *mut usize, SHARED_BUF_SIZE / mem::size_of::<i64>())
	};

	println!("shared buffer can hold up tp {} unsigned integers", shared_buf.len());

	for i in 0..shared_buf.len() {
		shared_buf[i] = i;
	}

	// [] indexing is the syntactic sugar for *container.index_mut(index)
	let buf_part: &[usize] = shared_buf.index_mut(0..16);
	for n in buf_part.iter() {
		print!(" {} ", n);
	}

	println!();

	print_prompt(b"press any ENTER to exit...");

	let mut command = String::new();
	io::stdin().read_line(&mut command).expect("failed to read command!");

	unlink_shmem(&shm_name);
}

fn unlink_shmem(shm_name: &CString) {
	println!("shared memory unlink");
	let unlink_status = unsafe { libc::shm_unlink(shm_name.as_ptr()) };
	if unlink_status == -1 {
		eprintln!("shared memory unlink failed!");
		process::exit(1);
	}
}

fn print_prompt(prompt: &[u8]) {
	let stdout = io::stdout();
	let mut stdout_handle = stdout.lock();

	stdout_handle.write_all(prompt).unwrap();
	stdout_handle.flush().unwrap();
}
