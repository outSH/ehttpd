# Helper functions used for IO

# Symbols
.globl print
.globl println
.globl print_error
.globl MACRO_push_int_string_to_stack
.globl find_crlf_location
.globl count_whitespace_chars
.globl count_chars_until_whitespace
.globl get_file_stats
.globl send_file_content
.globl send_all
.globl find_char

################################################

.section .data
    IO_NEW_LINE_CHAR: .byte '\n'

    IO_ERROR_TAG: .ascii "[ERROR] - "
    IO_ERROR_TAG_END:
    .equ IO_ERROR_TAG_SIZE, IO_ERROR_TAG_END - IO_ERROR_TAG

    IO_ERROR_MESSAGE_START: .ascii " errno ("
    IO_ERROR_MESSAGE_START_END:
    .equ IO_ERROR_MESSAGE_START_SIZE, IO_ERROR_MESSAGE_START_END - IO_ERROR_MESSAGE_START

    IO_ERROR_MESSAGE_END: .ascii ")\n"
    IO_ERROR_MESSAGE_END_END:
    .equ IO_ERROR_MESSAGE_END_SIZE, IO_ERROR_MESSAGE_END_END - IO_ERROR_MESSAGE_END

    # Whitespace chars
    .equ IO_TOKEN_WHITESPACE_HTAB, 0x09
    # LF - 0x0A, VT - 0x0B, FF - 0x0C
    .equ IO_TOKEN_WHITESPACE_CR, 0x0D
    .equ IO_TOKEN_WHITESPACE_SPACE, 0x20

################################################

.section .text

# >>> int get_file_stats(int fd)
# Calls fstat for given file 'fd' and returns some values
#   in registers.
# Returns:
#   %eax - size
#   %ebx - blksize
.type get_file_stats, @function
.equ GET_FSTAT_ARG_SOCKET, 8
get_file_stats:
    pushl %ebp
    movl %esp, %ebp
    subl $SYS_STRUCT_STAT_SIZE, %esp

    # fstat()
    movl GET_FSTAT_ARG_SOCKET(%ebp), %ebx # fd
    movl %esp, %ecx # struct stat *buf
    movl $SYS_FSTAT, %eax
    int $INT_SYSCALL
    
    # Check for error

    movl SYS_STRUCT_STAT_ST_SIZE_OFF(%esp), %eax
    movl SYS_STRUCT_STAT_ST_BLKSIZE_OFF(%esp), %ebx

get_file_stats_finish:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< get_file_stats()

################################################

# >>> int send_file_content(int sockfd, int fd, int len, int blksize)
# Read file from 'fd' until 'len in blocks of 'blksize',
#   and sends them through socket 'socketfd'
# Returns:
#   Eror code from SYS_READ / sendall() or positive number
.type send_file_content, @function

.equ SEND_FILE_ARG_SOCKET, 8
.equ SEND_FILE_ARG_FD, 12
.equ SEND_FILE_ARG_BUFFER_SIZE, 16
.equ SEND_FILE_ARG_BLKSIZE, 20

send_file_content:
    pushl %ebp
    movl %esp, %ebp

    # Used registers - %edi (buffer ptr), %ecx (length remaining)

    # Reserve read buffer (store in %edi)
    subl SEND_FILE_ARG_BLKSIZE(%ebp), %esp
    movl %esp, %edi

    movl SEND_FILE_ARG_BUFFER_SIZE(%ebp), %ecx

    __send_content_loop:
        cmpl $0, %ecx
        jle send_file_content_finish

        # read()
        pushl %ecx
        movl SEND_FILE_ARG_FD(%ebp), %ebx # fd
        movl %edi, %ecx # buf
        movl SEND_FILE_ARG_BLKSIZE(%ebp), %edx # count
        movl $SYS_READ, %eax
        int $INT_SYSCALL 
        popl %ecx

        cmpl $0, %eax
        jg __send_content_read_ok

        # EOF
        cmpl $0, %eax
        je send_file_content_finish
        
        # Read error
        .ifdef _DEBUG
            pushl $ERROR_READ_ERROR_SIZE
            pushl $ERROR_READ_ERROR
            pushl %eax
            call print_error
            addl $12, %esp
        .endif
        jmp send_file_content_finish

        __send_content_read_ok:
        cmpl %ecx, %eax
        jle __send_content_write
        # Adjust write size not to exceed limit specified in argument
        movl %ecx, %eax

        __send_content_write:
        # write()
        pushl %ecx

        pushl %eax
        pushl %edi
        pushl SEND_FILE_ARG_SOCKET(%ebp)
        call send_all
        cmpl $0, %eax
        jl send_file_content_finish
        addl $4, %esp
        popl %edi
        popl %eax

        popl %ecx
        
        subl %eax, %ecx

        jmp __send_content_loop

send_file_content_finish:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< send_file_content()

################################################

# >>> int send_all(int sockfd, const void *buf, size_t len)
# Calls sendto() repeatadely until whole message in buf is send 
#   (or len is reached).
# Returns:
#   Success: numbers of chars send
#   Error: -errno from sendto()
.type send_all, @function
.equ SEND_ALL_FLAGS, 0x4000 # MSG_NOSIGNAL

.equ SEND_ALL_ARG_SOCKET, 8
.equ SEND_ALL_ARG_BUFFER, 12
.equ SEND_ALL_ARG_BUFFER_SIZE, 16
send_all:
    pushl %ebp
    movl %esp, %ebp

    # sendto()
    movl SEND_ALL_ARG_SOCKET(%ebp), %ebx # sockfd
    movl SEND_ALL_ARG_BUFFER(%ebp), %ecx # buf
    movl SEND_ALL_ARG_BUFFER_SIZE(%ebp), %edx # len
    movl $SEND_ALL_FLAGS, %esi # flags
    xorl %edi, %edi # dest_addr (NULL)

    __send_all_loop:
        # break if size <= 0
        cmpl $0, %edx
        jle send_all_finish

        pushl %ebp
        xorl %ebp, %ebp # addrlen (0)
        movl $SYS_SENDTO, %eax
        int $INT_SYSCALL
        popl %ebp

        # Handle errors...
        cmpl $0, %eax
        jge __send_all_loop_next
        
    .ifdef _DEBUG
        pushl $ERROR_SENDTO_SIZE
        pushl $ERROR_SENDTO
        pushl %eax
        call print_error
        addl $12, %esp
    .endif
        jmp send_all_finish

        __send_all_loop_next:
        subl %eax, %edx
        addl %eax, %ecx
        jmp __send_all_loop

send_all_finish:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< send_all()

################################################

# >>> int find_char(char c (in EBX), char* buffer, int size)
# Returns:
#   Success: Position of char in string. (first == 0)
#   Error: -1
.type find_char, @function
.equ FIND_CHAR_ARG_BUFFER, 8
.equ FIND_CHAR_ARG_BUFFER_SIZE, 12
find_char:
    pushl %ebp
    movl %esp, %ebp
    
    movb %bl, %al
    movl FIND_CHAR_ARG_BUFFER(%ebp), %edi
    movl FIND_CHAR_ARG_BUFFER_SIZE(%ebp), %ecx
    cld
    repne scasb
    jne find_char_not_found

    subl FIND_CHAR_ARG_BUFFER_SIZE(%ebp), %ecx
    neg %ecx
    movl %ecx, %eax
    subl $1, %eax
    jmp find_char_finish

find_char_not_found:
    movl $-1, %eax

find_char_finish:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< find_char()

################################################

# >>> find_crlf_location(buffer, size)
# Positon of CRLF (/r/n) in buffer until specified size.
# Returns:
#   Success: Position of '/r' (from CRLF) in string. (first char == 0)
#   Error: -1
.type find_crlf_location, @function
.equ FIND_CRLF_ARG_BUFFER, 8
.equ FIND_CRLF_ARG_BUFFER_SIZE, 12
find_crlf_location:
    pushl %ebp
    movl %esp, %ebp
    
    movl FIND_CRLF_ARG_BUFFER_SIZE(%ebp), %ecx
    movl FIND_CRLF_ARG_BUFFER(%ebp), %esi
    movl $0, %edi # Final position

    search_crlf:
        pushl %edi # safe edi

        pushl %ecx
        pushl %esi
        movb $'\r', %bl
        call find_char
        popl %esi
        popl %ecx

        popl %edi

        cmpl $0, %eax # Not found
        jl find_crlf_finish

        movb 1(%eax,%esi,1), %dl
        cmpb $'\n', %dl
        je find_crlf_ok

        # Shift behind found character
        addl %eax, %esi
        addl %eax, %edi
        addl $1, %esi
        addl $1, %edi

        # Decrease remaining size
        subl %eax, %ecx 

        cmpl $0, %ecx 
        jg search_crlf

find_crlf_ok:
    addl %edi, %eax
find_crlf_finish:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< find_crlf_location()

################################################

# >>> int count_whitespace_chars(char* buffer, int size)
# Counts all whitespace characters in the front of buffer (until size).
# Returns number of characters (or 0 if none was found)
.type count_whitespace_chars, @function
.equ CWC_ARG_BUFFER, 8
.equ CWC_BUFFER_SIZE, 12
count_whitespace_chars:
    pushl %ebp
    movl %esp, %ebp

    movl CWC_ARG_BUFFER(%ebp), %esi
    movl CWC_BUFFER_SIZE(%ebp), %ecx
    
    cld
    next_whitespace_count_char_loop:
        lodsb # to %al

        # Check space char
        cmpb $IO_TOKEN_WHITESPACE_SPACE, %al
        je next_whitespace_char

        # Check other whitespace (0x09 - 0x0D)
        cmpb $IO_TOKEN_WHITESPACE_HTAB, %al
        jl end_count_whitespace

        cmpb $IO_TOKEN_WHITESPACE_CR, %al
        jg end_count_whitespace

        next_whitespace_char:
            loop next_whitespace_count_char_loop

    end_count_whitespace:
        subl CWC_BUFFER_SIZE(%ebp), %ecx
        neg %ecx
        movl %ecx, %eax

count_whitespace_chars_finish:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< count_whitespace_chars()

################################################

# >>> int count_chars_until_whitespace(char* buffer, int size)
# Counts non-whitespace characters from buffer front, until size or whitespace is reached.
# Returns number of characters (or 0 if none was found)
.type count_chars_until_whitespace, @function
.equ CCUW_ARG_BUFFER, 8
.equ CCUW_BUFFER_SIZE, 12
count_chars_until_whitespace:
    pushl %ebp
    movl %esp, %ebp

    movl CCUW_ARG_BUFFER(%ebp), %esi
    movl CCUW_BUFFER_SIZE(%ebp), %ecx
    
    cld
    ccuw_next_char_loop:
        lodsb # to %al

        # Check space char
        cmpb $IO_TOKEN_WHITESPACE_SPACE, %al
        je ccuw_end

        # Check other whitespace (0x09 - 0x0D)
        cmpb $IO_TOKEN_WHITESPACE_HTAB, %al
        jl ccuw_next_char

        cmpb $IO_TOKEN_WHITESPACE_CR, %al
        jg ccuw_next_char

        jmp ccuw_end

        ccuw_next_char:
            loop ccuw_next_char_loop

    ccuw_end:
        subl CCUW_BUFFER_SIZE(%ebp), %ecx
        neg %ecx
        movl %ecx, %eax

count_chars_until_whitespace_finish:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< count_chars_until_whitespace()

################################################

# >>> print_error(error_no, string, size)
.type print_error, @function
.equ PRINT_ERROR_ARG_ERROR_NO, 8
.equ PRINT_ERROR_ARG_STRING, 12
.equ PRINT_ERROR_ARG_SIZE, 16
print_error:
    pushl %ebp
    movl %esp, %ebp    

    # 1. Print error tag
    pushl $IO_ERROR_TAG_SIZE
    pushl $IO_ERROR_TAG
    call print
    addl $8, %esp

    # 2. Print regular message
    pushl PRINT_ERROR_ARG_SIZE(%ebp)
    pushl PRINT_ERROR_ARG_STRING(%ebp)
    call print
    addl $8, %esp

    # 3. Print error number message start
    pushl $IO_ERROR_MESSAGE_START_SIZE
    pushl $IO_ERROR_MESSAGE_START
    call print
    addl $8, %esp

    # 4. Print error no
    # 4.1 Convert errno to abs value
    #movl PRINT_ERROR_ARG_ERROR_NO(%ebp), %eax
    #movl %eax, %ebx # backup int
    #negl %eax
    #cmovll %ebx, %eax

    # 4.2 Call print_int
    pushl PRINT_ERROR_ARG_ERROR_NO(%ebp)
    call print_int
    addl $4, %esp

    # 4. Print error number message end
    pushl $IO_ERROR_MESSAGE_END_SIZE
    pushl $IO_ERROR_MESSAGE_END
    call print
    addl $8, %esp

    movl %ebp, %esp
    popl %ebp
    ret
# <<< print_error()

################################################

# >>> MACRO_push_int_string_to_stack
# Pushes char representation of int into stack.
# WARNING - Invalidates %eax, %ebx, %ecx, %edx.
# WARNING - Safe and restore stack pointer after calling this macro!
#   In: 
#       %eax - integer to print
#   Out: 
#       %ecx - size of string represenation of int.
#       %esi - top of the stack holds first character of int repr.
.altmacro
.macro MACRO_push_int_string_to_stack
LOCAL __int2str_loop
    # Convert int to printable chars
    # edx:eax - int to print (edx will be 0)
    # ebx - divide by 10
    # ecx - number of digits

    movl $10, %ebx
    xor %ecx, %ecx

    __int2str_loop:
        xor %edx, %edx # divide 0000:%eax
        divl %ebx # eax=quotient, edx=remainder
        addl $48, %edx # int to char (add '0')
        subl $1, %esp
        movb %dl, (%esp)
        incl %ecx
        cmpl $0, %eax
        jne __int2str_loop

    # Pack values on the stack
    movl %esp, %esi
.endm
# <<< MACRO_push_int_string_to_stack

################################################

# >>> print_int(int)
# Print int to STDOUT
.type print_int, @function
.equ PRINT_INT_ARG_INT, 8
print_int:
    pushl %ebp
    movl %esp, %ebp

    movl PRINT_INT_ARG_INT(%ebp), %eax

    MACRO_push_int_string_to_stack

    pushl %ecx
    pushl %esi
    call print
    addl $4, %esp
    popl %ecx
    # clean allocated numbers from stack
    addl %ecx, %esp 

    movl %ebp, %esp
    popl %ebp
    ret
# <<< print_int()

################################################

# >>> println(string, size)
# Print 'string' of length 'size' to STDOUT, finish with new line.
.type println, @function
.equ PRINTLN_ARG_STRING, 8
.equ PRINTLN_ARG_SIZE, 12
println:
    pushl %ebp
    movl %esp, %ebp

    # print()
    pushl PRINTLN_ARG_SIZE(%ebp)
    pushl PRINTLN_ARG_STRING(%ebp)
    call print
    addl $8, %esp

    # print new line
    pushl $1
    pushl $IO_NEW_LINE_CHAR
    call print
    addl $8, %esp

    movl %ebp, %esp
    popl %ebp
    ret
# <<< println()

################################################

# >>> print(string, size)
# Print 'string' of length 'size' to STDOUT
.type print, @function
.equ PRINT_ARG_STRING, 8
.equ PRINT_ARG_SIZE, 12
print:
    pushl %ebp
    movl %esp, %ebp

    # write()
    movl $STDOUT, %ebx
    movl PRINT_ARG_STRING(%ebp), %ecx
    movl PRINT_ARG_SIZE(%ebp), %edx
    movl $SYS_WRITE, %eax
    int $INT_SYSCALL

    movl %ebp, %esp
    popl %ebp
    ret
# <<< print()
