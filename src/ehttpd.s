# ehttpd - embedded httpd, simple web server written in assembly.
#   Main entry file, handles all socket related logic.
#   Listens for incomming connection and runs new threads for each request.

.globl _start

.equ DEFALT_PORT, 0x831D # 7555 (0x1D83, reverse byte order)
.equ BACKLOG_SIZE, 8

################################################

.section .data
    HTTP_INFO_MSG: .ascii "ehttpd version 0.1"
    HTTP_INFO_MSG_END:
    .equ HTTP_INFO_MSG_SIZE, HTTP_INFO_MSG_END - HTTP_INFO_MSG

    HTTP_EXIT_MSG: .ascii "exit..." 
    HTTP_EXIT_MSG_END:
    .equ HTTP_EXIT_MSG_SIZE, HTTP_EXIT_MSG_END - HTTP_EXIT_MSG

.ifdef _DEBUG
    HTTP_NEW_THREAD_ID: .ascii ">> new request - thread id " 
    HTTP_NEW_THREAD_ID_END:
    .equ HTTP_NEW_THREAD_ID_SIZE, HTTP_NEW_THREAD_ID_END - HTTP_NEW_THREAD_ID
.endig

################################################

.section .text

##################
# ENTRY POINT
##################

# >>> _start()
# Create passive socket, wait for connections, start handling in separate thread.
.equ _START_LOCAL_VAR_SIZE, 4
.equ _START_LISTEN_SOCKET, -4
_start:
    pushl %ebp
    movl %esp, %ebp
    subl $_START_LOCAL_VAR_SIZE, %esp
    movl $-1, _START_LISTEN_SOCKET(%ebp)

    # Print init information
    pushl $HTTP_INFO_MSG_SIZE
    pushl $HTTP_INFO_MSG
    call println
    addl $8, %esp

    # signal(SIGPIPE, SIG_IGN)
    movl $SYS_SIGPIPE, %ebx
    movl $SYS_SIG_IGN, %ecx
    movl $SYS_SIGNAL, %eax
    int $INT_SYSCALL

   # signal(SIGINT, *_start_finish)
    movl $SYS_SIGINT, %ebx
    movl $_start_finish, %ecx
    movl $SYS_SIGNAL, %eax
    int $INT_SYSCALL

   # signal(SIGQUIT, *_start_finish)
    movl $SYS_SIGQUIT, %ebx
    movl $_start_finish, %ecx
    movl $SYS_SIGNAL, %eax
    int $INT_SYSCALL

   # signal(SIGHUP, *_start_cleanup)
    movl $SYS_SIGHUP, %ebx
    movl $_start_cleanup, %ecx
    movl $SYS_SIGNAL, %eax
    int $INT_SYSCALL

    # Get passive socket
    call create_listening_socket
    cmpl $0, %eax
    jl _start_finish
    movl %eax, _START_LISTEN_SOCKET(%ebp)

_start_socket_accept: # <- LOOP START
    # accept()
    movl _START_LISTEN_SOCKET(%ebp), %ebx # sockfd
    movl $0, %ecx # addr (0 - not interested)
    movl $0, %edx # addrlen (0 - not interested)
    movl $0, %esi # flags (no flags)
    movl $SYS_ACCEPT4, %eax
    int $INT_SYSCALL

    # handle error
    cmpl $0, %eax
    jge _start_socket_handle
    pushl $ERROR_SOCKET_ACCEPT_SIZE
    pushl $ERROR_SOCKET_ACCEPT
    pushl %eax
    call print_error
    addl $12, %esp
    jmp _start_socket_accept

_start_socket_handle:
    # Accepted socket is in %eax
    # Handler thread must close socket
    pushl %eax 
    call start_new_request_thread
    addl $4, %esp
    cmpl $0, %eax
    jle _start_socket_handle_error
    
    # print init thread message
.ifdef _DEBUG
    pushl %eax
    pushl $HTTP_NEW_THREAD_ID_SIZE
    pushl $HTTP_NEW_THREAD_ID
    call print
    addl $8, %esp

    # print thread id
    # stack contains thread_id from %eax here
    call print_int
    addl $4, %esp

    # print new line
    pushl $1
    pushl $IO_NEW_LINE_CHAR
    call print
    addl $8, %esp
.endif

    jmp _start_socket_accept # # <- LOOP REPEAT (OK CASE)

_start_socket_handle_error:
    pushl $ERROR_NEW_HANDLER_THREAD_SIZE
    pushl $ERROR_NEW_HANDLER_THREAD
    pushl %eax
    call print_error
    addl $12, %esp
    
    jmp _start_socket_accept # <- LOOP REPEAT (ERROR CASE)

_start_finish:
    # Print exit information
    pushl $HTTP_EXIT_MSG_SIZE
    pushl $HTTP_EXIT_MSG
    call println
    addl $8, %esp

_start_cleanup:
    # Close listening socket if valid
    cmpl $0, _START_LISTEN_SOCKET(%ebp)
    jl _start_exit
    // close()
    movl _START_LISTEN_SOCKET(%ebp), %ebx
    movl $SYS_CLOSE, %eax
    int $INT_SYSCALL

_start_exit:
    # Exit...
    movl $SYS_EXIT, %eax
    int $INT_SYSCALL
# <<< _start()

################################################

# >>> create_listening_socket()
# Return:
#   success - listening socket s >= 0
#   failure - s < 0
.type create_listening_socket, @function
.equ CLS_STACK_SIZE, 4
.equ CLS_LISTEN_SOCKET, -4
create_listening_socket:
    pushl %ebp
    movl %esp, %ebp
    subl $CLS_STACK_SIZE, %esp
    movl $-1, CLS_LISTEN_SOCKET(%ebp)

cls_socket_create:
    # socket()
    movl $PF_INET, %ebx     # domain
    movl $SOCK_STREAM, %ecx # type 
    movl $IPPROTO_TCP, %edx # protocol
    movl $SYS_SOCKET, %eax
    int $INT_SYSCALL
    
    # handle error
    cmpl $0, %eax
    jge cls_socket_setopt
    pushl $ERROR_SOCKET_CREATE_SIZE
    pushl $ERROR_SOCKET_CREATE
    pushl %eax
    call print_error
    addl $12, %esp
    jmp cls_socket_error

cls_socket_setopt:
    movl %eax, CLS_LISTEN_SOCKET(%ebp)

    # setsockopt()
    movl CLS_LISTEN_SOCKET(%ebp), %ebx # sockfd
    movl $SOL_SOCKET, %ecx             # level
    movl $SO_REUSEADDR, %edx           # optname
    movl $1, %esi                      # optval (enable)
    movl $4, %edi                      # optlen
    movl $SYS_SETSOCKOPT, %eax

    # handle error
    cmpl $0, %eax
    jge cls_socket_bind
    pushl $ERROR_SOCKET_SETOPT_SIZE
    pushl $ERROR_SOCKET_SETOPT
    pushl %eax
    call print_error
    addl $12, %esp
    jmp cls_socket_error

cls_socket_bind:
    # struct sockaddr_in
    pushl $0x0         # align 8 bytes to sizeof(struct sockaddr)
    pushl $0x0         # ...
    pushl $0x00000000  # struct in_addr (ip address 0.0.0.0)
    pushw $DEFALT_PORT # in_port_t
    pushw $PF_INET     # sa_family_t

    # bind()
    movl CLS_LISTEN_SOCKET(%ebp), %ebx # sockfd
    movl %esp, %ecx                    # *addr
    movl $16, %edx                     # addrlen - sizeof(struct sockaddr)
    movl $SYS_BIND, %eax
    int $INT_SYSCALL
    addl $16, %esp

    # handle error
    cmpl $0, %eax
    jge cls_socket_listen
    pushl $ERROR_SOCKET_BIND_SIZE
    pushl $ERROR_SOCKET_BIND
    pushl %eax
    call print_error
    addl $12, %esp
    jmp cls_socket_error

cls_socket_listen:
    # listen()
    movl CLS_LISTEN_SOCKET(%ebp), %ebx # sockfd
    movl $BACKLOG_SIZE, %ecx           # backlog
    movl $SYS_LISTEN, %eax
    int $INT_SYSCALL

    # handle error
    cmpl $0, %eax
    jge cls_socket_ok
    pushl $ERROR_SOCKET_LISTEN_SIZE
    pushl $ERROR_SOCKET_LISTEN
    pushl %eax
    call print_error
    addl $12, %esp
    jmp cls_socket_error

cls_socket_ok:
    movl CLS_LISTEN_SOCKET(%ebp), %eax
    jmp cls_socket_exit

cls_socket_error:
    # Close socket on error
    cmpl $0, CLS_LISTEN_SOCKET(%ebp)
    jl cls_socket_error_set_code
    movl $SYS_CLOSE, %eax
    movl CLS_LISTEN_SOCKET(%ebp), %ebx
    int $INT_SYSCALL

cls_socket_error_set_code:
    movl $-1, %eax

cls_socket_exit:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< create_listening_socket()
