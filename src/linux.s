# x86 (32-bit) Linux specific definitions

# Interrupt
    .equ INT_SYSCALL, 0x80

# Standard File Descriptors
    .equ STDIN, 0
    .equ STDOUT, 1
    .equ STDERR, 2

# Basic SYSCALLS
    #  void exit(int status);
    .equ SYS_EXIT, 1

    # ssize_t read(int fd, void *buf, size_t count);
    .equ SYS_READ, 3

    # ssize_t write(int fd, const void *buf, size_t count); 
    .equ SYS_WRITE, 4

    # int open(const char *pathname, int flags, mode_t mode)
    .equ SYS_OPEN, 5

        # flags
        .equ SYS_O_RDONLY, 0
        .equ SYS_O_WRONLY, 1
        .equ SYS_OO_RDWR, 2

    # int close(int fd);
    .equ SYS_CLOSE, 6

    # int fstat(int fd, struct stat *buf);
    .equ SYS_FSTAT, 108
        # Structure works on:
        # * Linux 5.3.15-300.fc31.x86_64
        .equ SYS_STRUCT_STAT_SIZE, 64
        .equ SYS_STRUCT_STAT_ST_SIZE_OFF, 20
        .equ SYS_STRUCT_STAT_ST_BLKSIZE_OFF, 24
        # struct stat
        # 0: st_dev (+4)		    /* Device.  +4 */
        # 4: st_ino; (+4)		    /* File serial number.	*/
        # 8: st_mode; (+2)		/* File mode.  */
        # 10: st_nlink (+2)		/* Link count.  */
        # 12: st_uid;	(+2)	    /* User ID of the file's owner.	*/
        # 14 st_gid; (+2)		    /* Group ID of the file's group.*/
        # 16: st_rdev (+4)		/* Device number, if device.  */
        # 20: st_size; (+4)		/* Size of file, in bytes.  */
        # 24: st_blksize; (+4)	/* Optimal block size for I/O.  */
        # 28: st_blocks; (+4)		/* Number 512-byte blocks allocated. */
        # 32: st_atime; (+4)		/* Time of last modification.  */
        # 36: PAD (+4)
        # 40: st_mtime (+4)
        # 44: PAD (+4)
        # 48: st_ctime (+4)
        # 52: PAD (+4)
        # 56: PAD (+4)
        # 60: PAD (+4)
        # 64: END


# Sockets
    # socket
    .equ PF_INET, 2     # socket domain
    .equ SOCK_STREAM, 1 # socket type
    .equ IPPROTO_TCP, 6 # socket protocol
    
    # socket option
    .equ SOL_SOCKET, 1
    .equ SO_REUSEADDR, 2

    # SYSCALLS
    # int socket(int domain, int type, int protocol);
    .equ SYS_SOCKET, 359

    # int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
    .equ SYS_BIND, 361

    # int listen(int sockfd, int backlog);
    .equ SYS_LISTEN, 363

    # int accept4(int sockfd, struct sockaddr *addr, socklen_t *addrlen, int flags); 
    .equ SYS_ACCEPT4, 364

    # int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen);
    .equ SYS_SETSOCKOPT, 366

    # ssize_t sendto(int sockfd, const void *buf, size_t len, int flags, const struct sockaddr *dest_addr, socklen_t addrlen);
    .equ SYS_SENDTO, 369

    # int shutdown(int sockfd, int how);
    .equ SYS_SHUTDOWN, 373
    .equ SYS_SHUTDOWN_RD, 0x0
    .equ SYS_SHUTDOWN_WR, 0x1
    .equ SYS_SHUTDOWN_RDWR, 0x2

# Threads
    # void *mmap2(void *addr, size_t length, int prot, int flags, int fd, off_t pgoffset);
    .equ SYS_MMAP2, 192

    # int munmap(void *addr, size_t length);
    .equ SYS_MUNMAP, 91
    
    # long clone(unsigned long flags, void *stack, int *parent_tid, unsigned long tls, int *child_tid);
    .equ SYS_CLONE, 120

# Signals
    # sighandler_t signal(int signum, sighandler_t handler);
    .equ SYS_SIGNAL, 48

    # signal args
    .equ SYS_SIGHUP, 1
    .equ SYS_SIGINT, 2
    .equ SYS_SIGQUIT, 3
    .equ SYS_SIGPIPE, 13

    .equ SYS_SIG_IGN, 1
