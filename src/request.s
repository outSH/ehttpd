# HTTP request handling logic

# HTTP Symbols
.equ HTTP_METHOD_UNKNOWN, 0
.equ HTTP_METHOD_GET, 1
.equ HTTP_METHOD_HEAD, 2

################################################

.section .data 
    # For reading local files
    .equ REQ_MAX_SUPPORTED_BLKSIZE, 8 * 4096 # 8 KiB

    # File name for root URI ('/')
    REQ_ROOT_URI_FILENAME: .ascii "index.html"
    REQ_ROOT_URI_FILENAME_END:
    .equ REQ_ROOT_URI_FILENAME_SIZE, REQ_ROOT_URI_FILENAME_END - REQ_ROOT_URI_FILENAME

    # DEBUG messages
.ifdef _DEBUG
    REQ_THREAD_START_MSG: .ascii "################################\nrequest handle start..."
    REQ_THREAD_START_MSG_END:
    .equ REQ_THREAD_START_MSG_SIZE, REQ_THREAD_START_MSG_END - REQ_THREAD_START_MSG

    REQ_THREAD_END_MSG: .ascii "request handle stop.\n################################"
    REQ_THREAD_END_MSG_END:
    .equ REQ_THREAD_END_MSG_SIZE, REQ_THREAD_END_MSG_END - REQ_THREAD_END_MSG

    REQ_HEAD_REQUEST_DONE_MSG: .ascii "HEAD request done - headers has been send."
    REQ_HEAD_REQUEST_DONE_MSG_END:
    .equ REQ_HEAD_REQUEST_DONE_MSG_SIZE, REQ_HEAD_REQUEST_DONE_MSG_END - REQ_HEAD_REQUEST_DONE_MSG

    REQ_START_SENDING_MSG: .ascii "GET request - start sending content..."
    REQ_START_SENDING_MSG_END:
    .equ REQ_START_SENDING_MSG_SIZE, REQ_START_SENDING_MSG_END - REQ_START_SENDING_MSG

    REQ_SENDING_DONE_MSG: .ascii "GET request - sending content done."
    REQ_SENDING_DONE_MSG_END:
    .equ REQ_SENDING_DONE_MSG_SIZE, REQ_SENDING_DONE_MSG_END - REQ_SENDING_DONE_MSG
.endif

    # HTTP METHODS
    HTTP_METHOD_STRING_GET: .ascii "GET"
    HTTP_METHOD_STRING_GET_END:
    .equ HTTP_METHOD_STRING_GET_SIZE, HTTP_METHOD_STRING_GET_END - HTTP_METHOD_STRING_GET

    HTTP_METHOD_STRING_HEAD: .ascii "HEAD"
    HTTP_METHOD_STRING_HEAD_END:
    .equ HTTP_METHOD_STRING_HEAD_SIZE, HTTP_METHOD_STRING_HEAD_END - HTTP_METHOD_STRING_HEAD

    # HTTP VERSIONS
    HTTP_VERSION_STRING_1_0: .ascii "HTTP/1.0"
    HTTP_VERSION_STRING_1_0_END:
    .equ HTTP_VERSION_STRING_1_0_SIZE, HTTP_VERSION_STRING_1_0_END - HTTP_VERSION_STRING_1_0

    HTTP_VERSION_STRING_1_1: .ascii "HTTP/1.1"
    HTTP_VERSION_STRING_1_1_END:
    .equ HTTP_VERSION_STRING_1_1_SIZE, HTTP_VERSION_STRING_1_1_END - HTTP_VERSION_STRING_1_1

#### HTTP RESPONSES ####
# Response line
    HTTP_RESPONSE_200_OK: .ascii "HTTP/1.1 200 OK\r\n"
    HTTP_RESPONSE_200_OK_END:
    .equ HTTP_RESPONSE_200_OK_SIZE, HTTP_RESPONSE_200_OK_END - HTTP_RESPONSE_200_OK

    HTTP_RESPONSE_400_BAD_REQUEST: .ascii "HTTP/1.1 400 Bad Request\r\n"
    HTTP_RESPONSE_400_BAD_REQUEST_END:
    .equ HTTP_RESPONSE_400_BAD_REQUEST_SIZE, HTTP_RESPONSE_400_BAD_REQUEST_END - HTTP_RESPONSE_400_BAD_REQUEST

    HTTP_RESPONSE_404_NOT_FOUND: .ascii "HTTP/1.1 404 Not Found\r\n"
    HTTP_RESPONSE_404_NOT_FOUND_END:
    .equ HTTP_RESPONSE_404_NOT_FOUND_SIZE, HTTP_RESPONSE_404_NOT_FOUND_END - HTTP_RESPONSE_404_NOT_FOUND

    HTTP_RESPONSE_405_NOT_ALLOWED: .ascii "HTTP/1.1 405 Method Not Allowed\r\n"
    HTTP_RESPONSE_405_NOT_ALLOWED_END:
    .equ HTTP_RESPONSE_405_NOT_ALLOWED_SIZE, HTTP_RESPONSE_405_NOT_ALLOWED_END - HTTP_RESPONSE_405_NOT_ALLOWED

    HTTP_RESPONSE_500_INTERNAL_ERROR: .ascii "HTTP/1.1 500 Internal Server Error\r\n"
    HTTP_RESPONSE_500_INTERNAL_ERROR_END:
    .equ HTTP_RESPONSE_500_INTERNAL_ERROR_SIZE, HTTP_RESPONSE_500_INTERNAL_ERROR_END - HTTP_RESPONSE_500_INTERNAL_ERROR

    HTTP_RESPONSE_505_WRONG_HTTP: .ascii "HTTP/1.1 505 HTTP Version Not Supported\r\n"
    HTTP_RESPONSE_505_WRONG_HTTP_END:
    .equ HTTP_RESPONSE_505_WRONG_HTTP_SIZE, HTTP_RESPONSE_505_WRONG_HTTP_END - HTTP_RESPONSE_505_WRONG_HTTP

# Error content
    HTTP_MSG_CONTENT_400_BAD_REQUEST: .ascii "<!DOCTYPE html>\n<html lang=en>\n<meta charset=ISO-8859-1>\n<title>Error 400</title>\n<center><h1>400 Bad Request</h1></center></html>\n"
    HTTP_MSG_CONTENT_400_BAD_REQUEST_END:
    .equ HTTP_MSG_CONTENT_400_BAD_REQUEST_SIZE, HTTP_MSG_CONTENT_400_BAD_REQUEST_END - HTTP_MSG_CONTENT_400_BAD_REQUEST

    HTTP_MSG_CONTENT_404_NOT_FOUND: .ascii "<!DOCTYPE html>\n<html lang=en>\n<meta charset=ISO-8859-1>\n<title>Error 404</title>\n<center><h1>404 - Not Found</h1></center></html>\n"
    HTTP_MSG_CONTENT_404_NOT_FOUND_END:
    .equ HTTP_MSG_CONTENT_404_NOT_FOUND_SIZE, HTTP_MSG_CONTENT_404_NOT_FOUND_END - HTTP_MSG_CONTENT_404_NOT_FOUND

    HTTP_MSG_CONTENT_405_NOT_ALLOWED: .ascii "<!DOCTYPE html>\n<html lang=en>\n<meta charset=ISO-8859-1>\n<title>Error 405</title>\n<center><h1>405 Method Not Allowed</h1></center></html>\n"
    HTTP_MSG_CONTENT_405_NOT_ALLOWED_END:
    .equ HTTP_MSG_CONTENT_405_NOT_ALLOWED_SIZE, HTTP_MSG_CONTENT_405_NOT_ALLOWED_END - HTTP_MSG_CONTENT_405_NOT_ALLOWED

    HTTP_MSG_CONTENT_500_INTERNAL_ERROR: .ascii "<!DOCTYPE html>\n<html lang=en>\n<meta charset=ISO-8859-1>\n<title>Error 500</title>\n<center><h1>500 Internal Server Error</h1></center></html>\n"
    HTTP_MSG_CONTENT_500_INTERNAL_ERROR_END:
    .equ HTTP_MSG_CONTENT_500_INTERNAL_ERROR_SIZE, HTTP_MSG_CONTENT_500_INTERNAL_ERROR_END - HTTP_MSG_CONTENT_500_INTERNAL_ERROR

    HTTP_MSG_CONTENT_505_WRONG_HTTP: .ascii "<!DOCTYPE html>\n<html lang=en>\n<meta charset=ISO-8859-1>\n<title>Error 505</title>\n<center><h1>505 HTTP Version Not Supported</h1></center></html>\n"
    HTTP_MSG_CONTENT_505_WRONG_HTTP_END:
    .equ HTTP_MSG_CONTENT_505_WRONG_HTTP_SIZE, HTTP_MSG_CONTENT_505_WRONG_HTTP_END - HTTP_MSG_CONTENT_505_WRONG_HTTP
    
# Headers
    HTTP_HEADER_CRLF: .ascii "\r\n"
    HTTP_HEADER_CRLF_END:
    .equ HTTP_HEADER_CRLF_SIZE, HTTP_HEADER_CRLF_END - HTTP_HEADER_CRLF

    HTTP_HEADER_COMMON_FINISH: .ascii "Server: ehttpd\r\nAccept-Ranges: none\r\n\r\n"
    HTTP_HEADER_COMMON_FINISH_END:
    .equ HTTP_HEADER_COMMON_FINISH_SIZE, HTTP_HEADER_COMMON_FINISH_END - HTTP_HEADER_COMMON_FINISH

    HTTP_HEADER_ALLOW_METHODS: .ascii "Allow: GET, HEAD\r\n"
    HTTP_HEADER_ALLOW_METHODS_END:
    .equ HTTP_HEADER_ALLOW_METHODS_SIZE, HTTP_HEADER_ALLOW_METHODS_END - HTTP_HEADER_ALLOW_METHODS

    HTTP_HEADER_CONTENT_TYPE_HTML_ISO: .ascii "Content-Type: text/html; charset=ISO-8859-1\r\n"
    HTTP_HEADER_CONTENT_TYPE_HTML_ISO_END:
    .equ HTTP_HEADER_CONTENT_TYPE_HTML_ISO_SIZE, HTTP_HEADER_CONTENT_TYPE_HTML_ISO_END - HTTP_HEADER_CONTENT_TYPE_HTML_ISO

    HTTP_HEADER_CONTENT_CON_CLOSE: .ascii "Connection: close\r\n"
    HTTP_HEADER_CONTENT_CON_CLOSE_END:
    .equ HTTP_HEADER_CONTENT_CON_CLOSE_SIZE, HTTP_HEADER_CONTENT_CON_CLOSE_END - HTTP_HEADER_CONTENT_CON_CLOSE

    HTTP_HEADER_CONTENT_LENGTH_INIT: .ascii "Content-Length: "
    HTTP_HEADER_CONTENT_LENGTH_INIT_END:
    .equ HTTP_HEADER_CONTENT_LENGTH_INIT_SIZE, HTTP_HEADER_CONTENT_LENGTH_INIT_END - HTTP_HEADER_CONTENT_LENGTH_INIT

################################################

.section .text

# >>> int get_http_method_id(char* method_buffer, int size)
# Returns internal method ID for HTTP method string in buffer (until size is reached).
# Returns:
#   HTTP_METHOD_* code 
#   If method not identief returns HTTP_METHOD_UNKNOWN
.type get_http_method_id, @function
.equ GHMI_ARG_BUFFER_ADDR, 8
.equ GHMI_BUFFER_SIZE, 12
get_http_method_id:
    pushl %ebp
    movl %esp, %ebp

    # GET
get_meth_id_try_get:
    cmpl $HTTP_METHOD_STRING_GET_SIZE, GHMI_BUFFER_SIZE(%ebp)
    jne get_meth_id_try_head

    movl GHMI_ARG_BUFFER_ADDR(%ebp), %esi
    movl $HTTP_METHOD_STRING_GET, %edi
    movl $HTTP_METHOD_STRING_GET_SIZE, %ecx

    cld
    repe cmpsb
    jne get_meth_id_try_head
    movl $HTTP_METHOD_GET, %eax
    jmp get_meth_id_finish

    # HEAD
get_meth_id_try_head:
    cmpl $HTTP_METHOD_STRING_HEAD_SIZE, GHMI_BUFFER_SIZE(%ebp)
    jne get_meth_id_unknown

    movl GHMI_ARG_BUFFER_ADDR(%ebp), %esi
    movl $HTTP_METHOD_STRING_HEAD, %edi
    movl $HTTP_METHOD_STRING_HEAD_SIZE, %ecx

    cld
    repe cmpsb
    jne get_meth_id_unknown
    movl $HTTP_METHOD_HEAD, %eax
    jmp get_meth_id_finish

get_meth_id_unknown:
    movl $HTTP_METHOD_UNKNOWN, %eax
    
get_meth_id_finish:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< get_http_method_id()

################################################

# >>> int check_http_version(char* buffer, int size)
# Check if HTTP version in buffer is supported.
# Returns:
#   %eax:
#       1 - true
#       0 - false
.type check_http_version, @function
.equ CHV_ARG_BUFFER_ADDR, 8
.equ CHV_BUFFER_SIZE, 12
check_http_version:
    pushl %ebp
    movl %esp, %ebp

    # HTTP/1.0
check_http_version_http_1_0:
    cmpl $HTTP_VERSION_STRING_1_0_SIZE, GHMI_BUFFER_SIZE(%ebp)
    jne check_http_version_http_1_1

    movl GHMI_ARG_BUFFER_ADDR(%ebp), %esi
    movl $HTTP_VERSION_STRING_1_0, %edi
    movl $HTTP_VERSION_STRING_1_0_SIZE, %ecx

    cld
    repe cmpsb
    jne check_http_version_http_1_1
    movl $1, %eax # ok
    jmp check_http_version_finish

    # HTTP/1.1
check_http_version_http_1_1:
    cmpl $HTTP_VERSION_STRING_1_1_SIZE, GHMI_BUFFER_SIZE(%ebp)
    jne check_http_version_not_found

    movl GHMI_ARG_BUFFER_ADDR(%ebp), %esi
    movl $HTTP_VERSION_STRING_1_1, %edi
    movl $HTTP_VERSION_STRING_1_1_SIZE, %ecx

    cld
    repe cmpsb
    jne check_http_version_not_found
    movl $2, %eax # ok
    jmp check_http_version_finish

check_http_version_not_found:
    movl $0, %eax

check_http_version_finish:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< check_http_version()

################################################
######## >>> MACROS for read_user_request()

# >>> MACRO_pim_get_first_token_from_buffer()
# Searches buffer for first no-whitespace-token, 
#  sets buffer to it's beginning and returns size of current token.
# Arguments:
#   PIM_ARG_BUFFER_ADDR(%ebp) - address of the buffer to search
#   PIM_LOCAL_ARG_BUFFER_RECVD_COUNT(%ebp) - size of the buffer
# Returns:
#   %eax - size of the current token
.macro MACRO_pim_get_first_token_from_buffer
    # Get count of whitespaces in the front of the buffer
    pushl PIM_LOCAL_ARG_BUFFER_RECVD_COUNT(%ebp)
    pushl PIM_ARG_BUFFER_ADDR(%ebp)
    call count_whitespace_chars
    addl $8, %esp

    # Shift buffer string to skip whitespace chars
    pushl %eax
    addl PIM_ARG_BUFFER_ADDR(%ebp), %eax 
    movl %eax, PIM_ARG_BUFFER_ADDR(%ebp)

    popl %eax
    subl PIM_LOCAL_ARG_BUFFER_RECVD_COUNT(%ebp), %eax
    neg %eax
    movl %eax, PIM_LOCAL_ARG_BUFFER_RECVD_COUNT(%ebp)

    # Get size of the next token
    pushl PIM_LOCAL_ARG_BUFFER_RECVD_COUNT(%ebp)
    pushl PIM_ARG_BUFFER_ADDR(%ebp)
    call count_chars_until_whitespace
    addl $8, %esp
.endm
# <<< MACRO_pim_get_first_token_from_buffer()

# >>> MACRO_pim_get_next_token_from_buffer()
#  Shift current token (size from %eax) and returns new token.
# Arguments:
#   %eax - size of the current token (to be shifted).
#   PIM_ARG_BUFFER_ADDR(%ebp) - address of the buffer to search
#   PIM_LOCAL_ARG_BUFFER_RECVD_COUNT(%ebp) - size of the buffer
# Returns:
#   %eax - size of the current token
.macro MACRO_pim_get_next_token_from_buffer
    # Shift string to skip over previous token
    pushl %eax
    addl PIM_ARG_BUFFER_ADDR(%ebp), %eax 
    movl %eax, PIM_ARG_BUFFER_ADDR(%ebp)

    popl %eax
    subl PIM_LOCAL_ARG_BUFFER_RECVD_COUNT(%ebp), %eax
    neg %eax
    movl %eax, PIM_LOCAL_ARG_BUFFER_RECVD_COUNT(%ebp)

    # Get next token
    MACRO_pim_get_first_token_from_buffer
.endm
# <<< MACRO_pim_get_next_token_from_buffer()

######## <<< MACROS END

# read_user_request() Error Codes
.equ PIM_ERROR_INTERNAL, -1
.equ PIM_ERROR_EOF, -2
.equ PIM_ERROR_BAD_REQUEST, -3
.equ PIM_ERROR_WRONG_HTTP_VERSION, -4

# >>> read_user_request(socket, *buffer, size)
# Function reads input message from the client and parses it's request line.
# Message is stored under buffer address from argument (read is limited to 'size')
# Error will be returned if request line is invalid or HTTP version is wrong.
# Return:
#   %eax - internal ID of request method (GET / HEAD etc...)
#   %esi - address inside input buffer that points to URI start.
#   %ecx - length of URI (pointed by esi)
# Error return:
#   %eax - negative error code PIM_ERROR_* indicating failure cause.
.type read_user_request, @function
.equ PIM_ARG_SOCKET, 8
.equ PIM_ARG_BUFFER_ADDR, 12
.equ PIM_ARG_BUFFER_SIZE, 16

.equ PIM_LOCAL_ARG_SIZE, 16
.equ PIM_LOCAL_ARG_BUFFER_RECVD_COUNT, -4
.equ PIM_LOCAL_ARG_RETURN_CODE, -8
.equ PIM_LOCAL_ARG_RETURN_URI, -12
.equ PIM_LOCAL_ARG_RETURN_URI_LEN, -16
read_user_request:
    pushl %ebp
    movl %esp, %ebp
    subl $PIM_LOCAL_ARG_SIZE, %esp

    movl $-1, PIM_LOCAL_ARG_RETURN_CODE(%ebp)
    movl $0, PIM_LOCAL_ARG_RETURN_URI(%ebp)
    movl $0, PIM_LOCAL_ARG_RETURN_URI_LEN(%ebp)

pim_read_message:
    movl PIM_ARG_SOCKET(%ebp), %ebx # fd
    movl PIM_ARG_BUFFER_ADDR(%ebp), %ecx # buf
    movl PIM_ARG_BUFFER_SIZE(%ebp), %edx # count
    movl $SYS_READ, %eax
    int $INT_SYSCALL  

    # Handle read errors..
    cmpl $0, %eax
    jg pim_read_ok
pim_read_error_eof:
    cmpl $0, %eax
    jne pim_read_error_internal
.ifdef _DEBUG
    pushl $ERROR_REQUEST_EOF_SIZE
    pushl $ERROR_REQUEST_EOF
    call println
    addl $8, %esp
.endif
    movl $PIM_ERROR_EOF, PIM_LOCAL_ARG_RETURN_CODE(%ebp)
    jmp get_request_finish

pim_read_error_internal:
.ifdef _DEBUG
    pushl $ERROR_READ_REQUEST_SIZE
    pushl $ERROR_READ_REQUEST
    pushl %eax
    call print_error
    addl $12, %esp
.endif
    movl $PIM_ERROR_INTERNAL, PIM_LOCAL_ARG_RETURN_CODE(%ebp)
    jmp get_request_finish

pim_read_ok:
    movl %eax, PIM_LOCAL_ARG_BUFFER_RECVD_COUNT(%ebp)

# Print input
.ifdef _DEBUG_MESSAGE_BUF
    pushl PIM_LOCAL_ARG_BUFFER_RECVD_COUNT(%ebp)
    pushl PIM_ARG_BUFFER_ADDR(%ebp)
    call println  
    addl $8, %esp
.endif

pim_get_request_line_size:
    pushl PIM_LOCAL_ARG_BUFFER_RECVD_COUNT(%ebp)
    pushl PIM_ARG_BUFFER_ADDR(%ebp)
    call find_crlf_location  
    addl $8, %esp
    movl %eax, PIM_LOCAL_ARG_BUFFER_RECVD_COUNT(%ebp)

    # Handle errors..
    cmpl $0, %eax
    jg pim_get_method_token
.ifdef _DEBUG
    pushl $ERROR_READ_BAD_REQUEST_SIZE
    pushl $ERROR_READ_BAD_REQUEST
    pushl $101
    call print_error
    addl $12, %esp
.endif
    movl $PIM_ERROR_BAD_REQUEST, PIM_LOCAL_ARG_RETURN_CODE(%ebp)
    jmp get_request_finish

pim_get_method_token:
    MACRO_pim_get_first_token_from_buffer

    pushl %eax # token size
    pushl PIM_ARG_BUFFER_ADDR(%ebp)
    call get_http_method_id
    movl %eax, PIM_LOCAL_ARG_RETURN_CODE(%ebp)
    addl $4, %esp
    popl %eax

pim_get_uri_token:
    MACRO_pim_get_next_token_from_buffer

    movl PIM_ARG_BUFFER_ADDR(%ebp), %esi
    movl %esi, PIM_LOCAL_ARG_RETURN_URI(%ebp)
    movl %eax, PIM_LOCAL_ARG_RETURN_URI_LEN(%ebp)

pim_get_http_version_token:
    MACRO_pim_get_next_token_from_buffer

    pushl %eax # token size
    pushl PIM_ARG_BUFFER_ADDR(%ebp)
    call check_http_version
    addl $8, %esp # We don't need token size in %eax anymore

    cmpl $0, %eax
    jg get_request_finish
.ifdef _DEBUG
    pushl $ERROR_WRONG_HTTP_VERSION_SIZE
    pushl $ERROR_WRONG_HTTP_VERSION
    pushl %eax
    call print_error
    addl $12, %esp
.endif
    movl $PIM_ERROR_WRONG_HTTP_VERSION, PIM_LOCAL_ARG_RETURN_CODE(%ebp)
    # jmp get_request_finish

get_request_finish:
    movl PIM_LOCAL_ARG_RETURN_CODE(%ebp), %eax
    movl PIM_LOCAL_ARG_RETURN_URI(%ebp), %esi
    movl PIM_LOCAL_ARG_RETURN_URI_LEN(%ebp), %ecx

    movl %ebp, %esp
    popl %ebp
    ret
# <<< read_user_request()

################################################

# >>> int send_500_internal_error(socket)
.type send_500_internal_error, @function
.equ SEND_500_ARG_SOCKET, 8
send_500_internal_error:
    pushl %ebp
    movl %esp, %ebp

    # Send 500 header
    pushl $HTTP_RESPONSE_500_INTERNAL_ERROR_SIZE
    pushl $HTTP_RESPONSE_500_INTERNAL_ERROR
    pushl SEND_500_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

    cmpl $0, %eax
    jl send_500_internal_error_exit

    # Send content type HTTP ISO
    pushl $HTTP_HEADER_CONTENT_TYPE_HTML_ISO_SIZE
    pushl $HTTP_HEADER_CONTENT_TYPE_HTML_ISO
    pushl SEND_500_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

    cmpl $0, %eax
    jl send_500_internal_error_exit

    # Send content len header
    pushl $HTTP_MSG_CONTENT_500_INTERNAL_ERROR_SIZE
    pushl SEND_500_ARG_SOCKET(%ebp)
    call send_content_length_header
    addl $8, %esp

    cmpl $0, %eax
    jl send_500_internal_error_exit

    # Send connection close  header
    pushl $HTTP_HEADER_CONTENT_CON_CLOSE_SIZE
    pushl $HTTP_HEADER_CONTENT_CON_CLOSE
    pushl SEND_500_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

    cmpl $0, %eax
    jl send_500_internal_error_exit

    # Send header end
    pushl SEND_500_ARG_SOCKET(%ebp)
    call send_headers_finish
    addl $4, %esp

    cmpl $0, %eax
    jl send_500_internal_error_exit

    # Send message content
    pushl $HTTP_MSG_CONTENT_500_INTERNAL_ERROR_SIZE
    pushl $HTTP_MSG_CONTENT_500_INTERNAL_ERROR
    pushl SEND_500_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

send_500_internal_error_exit:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< send_500_internal_error()

################################################

# >>> int send_400_bad_request(socket)
.type send_400_bad_request, @function
.equ SEND_400_ARG_SOCKET, 8
send_400_bad_request:
    pushl %ebp
    movl %esp, %ebp

    # Send 400 header
    pushl $HTTP_RESPONSE_400_BAD_REQUEST_SIZE
    pushl $HTTP_RESPONSE_400_BAD_REQUEST
    pushl SEND_400_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

    cmpl $0, %eax
    jl send_400_bad_request_exit

    # Send content type HTTP ISO
    pushl $HTTP_HEADER_CONTENT_TYPE_HTML_ISO_SIZE
    pushl $HTTP_HEADER_CONTENT_TYPE_HTML_ISO
    pushl SEND_400_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

    cmpl $0, %eax
    jl send_400_bad_request_exit

    # Send content len header
    pushl $HTTP_MSG_CONTENT_400_BAD_REQUEST_SIZE
    pushl SEND_400_ARG_SOCKET(%ebp)
    call send_content_length_header
    addl $8, %esp

    cmpl $0, %eax
    jl send_400_bad_request_exit

    # Send connection close  header
    pushl $HTTP_HEADER_CONTENT_CON_CLOSE_SIZE
    pushl $HTTP_HEADER_CONTENT_CON_CLOSE
    pushl SEND_400_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

    cmpl $0, %eax
    jl send_400_bad_request_exit

    # Send header end
    pushl SEND_400_ARG_SOCKET(%ebp)
    call send_headers_finish
    addl $4, %esp

    cmpl $0, %eax
    jl send_400_bad_request_exit

    # Send message content
    pushl $HTTP_MSG_CONTENT_400_BAD_REQUEST_SIZE
    pushl $HTTP_MSG_CONTENT_400_BAD_REQUEST
    pushl SEND_400_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

send_400_bad_request_exit:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< send_400_bad_request()

################################################

# >>> int send_505_wrong_http_version(socket)
.type send_505_wrong_http_version, @function
.equ SEND_505_ARG_SOCKET, 8
send_505_wrong_http_version:
    pushl %ebp
    movl %esp, %ebp

    # Send 505 header
    pushl $HTTP_RESPONSE_505_WRONG_HTTP_SIZE
    pushl $HTTP_RESPONSE_505_WRONG_HTTP
    pushl SEND_505_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

    cmpl $0, %eax
    jl send_505_wrong_http_version_exit

    # Send content type HTTP ISO
    pushl $HTTP_HEADER_CONTENT_TYPE_HTML_ISO_SIZE
    pushl $HTTP_HEADER_CONTENT_TYPE_HTML_ISO
    pushl SEND_505_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

    cmpl $0, %eax
    jl send_505_wrong_http_version_exit

    # Send content len header
    pushl $HTTP_MSG_CONTENT_505_WRONG_HTTP_SIZE
    pushl SEND_505_ARG_SOCKET(%ebp)
    call send_content_length_header
    addl $8, %esp

    cmpl $0, %eax
    jl send_505_wrong_http_version_exit

    # Send header end
    pushl SEND_505_ARG_SOCKET(%ebp)
    call send_headers_finish
    addl $4, %esp

    cmpl $0, %eax
    jl send_505_wrong_http_version_exit

    # Send message content
    pushl $HTTP_MSG_CONTENT_505_WRONG_HTTP_SIZE
    pushl $HTTP_MSG_CONTENT_505_WRONG_HTTP
    pushl SEND_505_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

send_505_wrong_http_version_exit:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< send_505_wrong_http_version()

################################################

# >>> int send_405_unknown_request(socket)
.type send_405_unknown_request, @function
.equ SEND_405_ARG_SOCKET, 8
send_405_unknown_request:
    pushl %ebp
    movl %esp, %ebp

    # Send 405 header
    pushl $HTTP_RESPONSE_405_NOT_ALLOWED_SIZE
    pushl $HTTP_RESPONSE_405_NOT_ALLOWED
    pushl SEND_405_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

    cmpl $0, %eax
    jl send_405_not_allowed_exit

    # Send content type HTTP ISO
    pushl $HTTP_HEADER_CONTENT_TYPE_HTML_ISO_SIZE
    pushl $HTTP_HEADER_CONTENT_TYPE_HTML_ISO
    pushl SEND_405_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

    cmpl $0, %eax
    jl send_405_not_allowed_exit

    # Send content len header
    pushl $HTTP_MSG_CONTENT_405_NOT_ALLOWED_SIZE
    pushl SEND_405_ARG_SOCKET(%ebp)
    call send_content_length_header
    addl $8, %esp

    cmpl $0, %eax
    jl send_405_not_allowed_exit

    # Send allowed methods header
    pushl $HTTP_HEADER_ALLOW_METHODS_SIZE
    pushl $HTTP_HEADER_ALLOW_METHODS
    pushl SEND_405_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

    cmpl $0, %eax
    jl send_405_not_allowed_exit

    # Send header end
    pushl SEND_405_ARG_SOCKET(%ebp)
    call send_headers_finish
    addl $4, %esp

    cmpl $0, %eax
    jl send_405_not_allowed_exit

    # Send message content
    pushl $HTTP_MSG_CONTENT_405_NOT_ALLOWED_SIZE
    pushl $HTTP_MSG_CONTENT_405_NOT_ALLOWED
    pushl SEND_405_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

send_405_not_allowed_exit:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< send_405_unknown_request()

################################################

# >>> int send_404_not_found(socket, error_code)
.type send_404_not_found, @function
.equ SEND_404_ARG_SOCKET, 8
.equ SEND_404_ARG_ERROR, 12
send_404_not_found:
    pushl %ebp
    movl %esp, %ebp

.ifdef _DEBUG
    pushl $HTTP_RESPONSE_404_NOT_FOUND_SIZE
    pushl $HTTP_RESPONSE_404_NOT_FOUND
    pushl SEND_404_ARG_ERROR(%ebp)
    call print_error
    addl $12, %esp
.endif

    # Send 404 header
    pushl $HTTP_RESPONSE_404_NOT_FOUND_SIZE
    pushl $HTTP_RESPONSE_404_NOT_FOUND
    pushl SEND_404_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

    cmpl $0, %eax
    jl send_404_not_found_exit

    # Send content type HTTP ISO
    pushl $HTTP_HEADER_CONTENT_TYPE_HTML_ISO_SIZE
    pushl $HTTP_HEADER_CONTENT_TYPE_HTML_ISO
    pushl SEND_404_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

    cmpl $0, %eax
    jl send_404_not_found_exit

    # Send content len header
    pushl $HTTP_MSG_CONTENT_404_NOT_FOUND_SIZE
    pushl SEND_404_ARG_SOCKET(%ebp)
    call send_content_length_header
    addl $8, %esp

    cmpl $0, %eax
    jl send_404_not_found_exit

    # Send header end
    pushl SEND_404_ARG_SOCKET(%ebp)
    call send_headers_finish
    addl $4, %esp

    cmpl $0, %eax
    jl send_404_not_found_exit

    # Send message content
    pushl $HTTP_MSG_CONTENT_404_NOT_FOUND_SIZE
    pushl $HTTP_MSG_CONTENT_404_NOT_FOUND
    pushl SEND_404_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

send_404_not_found_exit:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< send_404_not_found()

################################################

# >>> int send_200_ok_response(socket, char* uri, int uri_size)
.type send_200_ok_response, @function
.equ SEND_200_ARG_RESP_TYPE, 8
.equ SEND_200_ARG_SOCKET, 12
.equ SEND_200_ARG_URI_ADDR, 16
.equ SEND_200_ARG_URI_SIZE, 20

.equ SEND_200_LOCAL_ARG_SIZE, 12
.equ SEND_200_LOCAL_ARG_FILE_FD, -4
.equ SEND_200_LOCAL_ARG_FILE_SIZE, -8
.equ SEND_200_LOCAL_ARG_FILE_BLKSIZE, -12
send_200_ok_response:
    pushl %ebp
    movl %esp, %ebp
    subl $SEND_200_LOCAL_ARG_SIZE, %esp
    movl $-1, SEND_200_LOCAL_ARG_FILE_FD(%ebp)

    # Add '\0' after URI to make it C string.
    movl SEND_200_ARG_URI_ADDR(%ebp), %esi
    addl SEND_200_ARG_URI_SIZE(%ebp), %esi
    movl $0, (%esi)

    # open()
    movl SEND_200_ARG_URI_ADDR(%ebp), %ebx
    movl $SYS_O_RDONLY, %ecx
    xorl %edx, %edx
    movl $SYS_OPEN, %eax
    int $INT_SYSCALL

    # Handle open file errors...
    cmpl $0, %eax
    jg send_200_file_opened
    pushl %eax
    pushl SEND_200_ARG_SOCKET(%ebp)
    call send_404_not_found
    addl $8, %esp
    jmp send_200_file_exit

send_200_file_opened:
    movl %eax, SEND_200_LOCAL_ARG_FILE_FD(%ebp)

    # Get file size
    push SEND_200_LOCAL_ARG_FILE_FD(%ebp)
    call get_file_stats
    addl $4, %esp

    cmpl $0, %eax
    jg send_200_file_not_empty
    pushl $777
    pushl SEND_200_ARG_SOCKET(%ebp)
    call send_404_not_found
    addl $8, %esp
    jmp send_200_file_exit
    
send_200_file_not_empty:     
    movl %eax, SEND_200_LOCAL_ARG_FILE_SIZE(%ebp)
    movl %ebx, SEND_200_LOCAL_ARG_FILE_BLKSIZE(%ebp)
    
    # Send 200 header
    pushl $HTTP_RESPONSE_200_OK_SIZE
    pushl $HTTP_RESPONSE_200_OK
    pushl SEND_200_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

    cmpl $0, %eax
    jl send_200_file_exit

    # Send content len header
    pushl SEND_200_LOCAL_ARG_FILE_SIZE(%ebp)
    pushl SEND_200_ARG_SOCKET(%ebp)
    call send_content_length_header
    addl $8, %esp

    cmpl $0, %eax
    jl send_200_file_exit

    #pushl $HTTP_HEADER_CONTENT_TYPE_HTML_ISO_SIZE
    #pushl $HTTP_HEADER_CONTENT_TYPE_HTML_ISO
    #pushl SEND_200_ARG_SOCKET(%ebp)
    #call send_all
    #addl $12, %esp

    cmpl $0, %eax
    jl send_200_file_exit

    # Send header end
    pushl SEND_200_ARG_SOCKET(%ebp)
    call send_headers_finish
    addl $4, %esp

    cmpl $0, %eax
    jl send_200_file_exit

    cmpl $HTTP_METHOD_GET, SEND_200_ARG_RESP_TYPE(%ebp)
    je send_200_file_write_content
.ifdef _DEBUG
    pushl $REQ_HEAD_REQUEST_DONE_MSG_SIZE 
    pushl $REQ_HEAD_REQUEST_DONE_MSG
    call println
    addl $8, %esp
.endif
    jmp send_200_file_exit

send_200_file_write_content:
.ifdef _DEBUG
    pushl $REQ_START_SENDING_MSG_SIZE 
    pushl $REQ_START_SENDING_MSG
    call println
    addl $8, %esp
.endif

    # Check block size first
    movl SEND_200_LOCAL_ARG_FILE_BLKSIZE(%ebp), %ecx
    cmpl $REQ_MAX_SUPPORTED_BLKSIZE, %ecx
    jle send_200_file_call_send_function
    movl $REQ_MAX_SUPPORTED_BLKSIZE, %ecx

send_200_file_call_send_function:
    pushl %ecx # blksize
    pushl SEND_200_LOCAL_ARG_FILE_SIZE(%ebp)
    pushl SEND_200_LOCAL_ARG_FILE_FD(%ebp)
    pushl SEND_200_ARG_SOCKET(%ebp)
    call send_file_content
    addl $12, %esp

.ifdef _DEBUG
    pushl $REQ_SENDING_DONE_MSG_SIZE
    pushl $REQ_SENDING_DONE_MSG
    call println
    addl $8, %esp
.endif

send_200_file_exit:
    cmpl $0, SEND_200_LOCAL_ARG_FILE_FD(%ebp)
    jle send_200_file_done
    movl SEND_200_LOCAL_ARG_FILE_FD(%ebp), %ebx
    movl $SYS_CLOSE, %eax
    int $INT_SYSCALL  

send_200_file_done:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< send_200_ok_response()

################################################

# >>> int send_content_length_header(socket, length)
.type send_content_length_header, @function
.equ SEND_CLH_ARG_SOCKET, 8
.equ SEND_CLH_ARG_LENGTH, 12
send_content_length_header:
    pushl %ebp
    movl %esp, %ebp

    # 'Content-Length: '
    pushl $HTTP_HEADER_CONTENT_LENGTH_INIT_SIZE
    pushl $HTTP_HEADER_CONTENT_LENGTH_INIT
    pushl SEND_CLH_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

    cmpl $0, %eax
    jl send_content_length_header_exit

    # <number>
    movl SEND_CLH_ARG_LENGTH(%ebp), %eax

    MACRO_push_int_string_to_stack # int in %eax

    pushl %ecx
    pushl %esi
    pushl SEND_CLH_ARG_SOCKET(%ebp)
    call send_all
    addl $8, %esp
    popl %ecx
    addl %ecx, %esp # clean allocated numbers from stack

    cmpl $0, %eax
    jl send_content_length_header_exit

    # CRLF
    pushl $HTTP_HEADER_CRLF_SIZE
    pushl $HTTP_HEADER_CRLF
    pushl SEND_CLH_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp

send_content_length_header_exit:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< send_content_length_header()

################################################

# >>> int send_headers_finish(socket)
.type send_headers_finish, @function
.equ SEND_HEADERS_FINISH_ARG_SOCKET, 8
send_headers_finish:
    pushl %ebp
    movl %esp, %ebp

    pushl $HTTP_HEADER_COMMON_FINISH_SIZE
    pushl $HTTP_HEADER_COMMON_FINISH
    pushl SEND_HEADERS_FINISH_ARG_SOCKET(%ebp)
    call send_all
    addl $12, %esp
    
    movl %ebp, %esp
    popl %ebp
    ret
# <<< send_headers_finish()

################################################

# >>> handle_request(socket)
.type handle_request, @function
.equ HR_ARG_SOCKET, 8

# Buffer space
# Note on read buffer size:
# We only read request line from the input, thus we use limited read buffer.
# URI can be much longer than this, but this program will treat it as an
# invalid request.
.equ HR_LOCAL_READ_BUFFER_SIZE, 512
.equ HR_LOCAL_READ_BUFFER, -512
.equ HR_LOCAL_READ_BUFFER_ADDR, -516

# Local variables
.equ HR_LOCAL_ARG_SIZE, 12
.equ HR_LOCAL_ARG_READ_STATUS,  - 520
.equ HR_LOCAL_ARG_READ_URI,      -524
.equ HR_LOCAL_ARG_READ_URI_SIZE, -528
handle_request:
    pushl %ebp
    movl %esp, %ebp
    # Reserve read buffer
    subl $HR_LOCAL_READ_BUFFER_SIZE, %esp
    pushl %esp # HR_LOCAL_READ_BUFFER_ADDR(%ebp)
    # Reserve local variables
    subl $HR_LOCAL_ARG_SIZE, %esp
    
    # READ REQUEST
    pushl $HR_LOCAL_READ_BUFFER_SIZE
    pushl HR_LOCAL_READ_BUFFER_ADDR(%ebp)
    pushl HR_ARG_SOCKET(%ebp)
    call read_user_request
    addl $12, %esp

    movl %eax, HR_LOCAL_ARG_READ_STATUS(%ebp)
    movl %esi, HR_LOCAL_ARG_READ_URI(%ebp)
    movl %ecx, HR_LOCAL_ARG_READ_URI_SIZE(%ebp)

handle_request_eof:
    cmpl $PIM_ERROR_EOF, HR_LOCAL_ARG_READ_STATUS(%ebp)
    je handle_shutdown_socket

# 500
handle_internal_error:
    cmpl $PIM_ERROR_INTERNAL, HR_LOCAL_ARG_READ_STATUS(%ebp)
    jne handle_bad_request
    pushl HR_ARG_SOCKET(%ebp)
    call send_500_internal_error
    jmp handle_shutdown_socket

# 400
handle_bad_request:
    cmpl $PIM_ERROR_BAD_REQUEST, HR_LOCAL_ARG_READ_STATUS(%ebp)
    jne handle_wrong_http_version
    pushl HR_ARG_SOCKET(%ebp)
    call send_400_bad_request
    addl $4, %esp
    jmp handle_shutdown_socket

# 505
handle_wrong_http_version:
    cmpl $PIM_ERROR_WRONG_HTTP_VERSION, HR_LOCAL_ARG_READ_STATUS(%ebp)
    jne handle_unknown_request_method
    pushl HR_ARG_SOCKET(%ebp)
    call send_505_wrong_http_version
    addl $4, %esp
    jmp handle_shutdown_socket

# 405
handle_unknown_request_method:
    cmpl $HTTP_METHOD_UNKNOWN, HR_LOCAL_ARG_READ_STATUS(%ebp)
    jne handle_valid_method
    pushl HR_ARG_SOCKET(%ebp)
    call send_405_unknown_request
    addl $4, %esp
    jmp handle_shutdown_socket
    
# 200
# Only GET and HEAD supported right now.
handle_valid_method:
    cmpl $HTTP_METHOD_GET, HR_LOCAL_ARG_READ_STATUS(%ebp)
    je handle_valid_method_detect_root_uri

    cmpl $HTTP_METHOD_HEAD, HR_LOCAL_ARG_READ_STATUS(%ebp)
    je handle_valid_method_detect_root_uri

    # Unexpected error - no method matched!
    movl $HTTP_METHOD_UNKNOWN, HR_LOCAL_ARG_READ_STATUS(%ebp)
    jmp handle_unknown_request_method

handle_valid_method_detect_root_uri:
    # URI '/' has size 1
    movl HR_LOCAL_ARG_READ_URI_SIZE(%ebp), %ecx
    cmpl $1, %ecx
    jne handle_valid_method_trim_leading_slash

    # Check if its '/'
    movl HR_LOCAL_ARG_READ_URI(%ebp), %esi
    cmpb $'/', (%esi)
    jne handle_valid_method_check_uri

    # Move index.html or sth to URI
    movl %esi, %edi
    movl $REQ_ROOT_URI_FILENAME, %esi
    movl $REQ_ROOT_URI_FILENAME_SIZE, %ecx
    movl %ecx, HR_LOCAL_ARG_READ_URI_SIZE(%ebp)
    cld
    rep movsb 

    jmp handle_valid_method_verified

handle_valid_method_trim_leading_slash:
    # Trim leading '/'
    movl HR_LOCAL_ARG_READ_URI(%ebp), %esi
    cmpb $'/', (%esi)
    jne handle_valid_method_check_uri
    movl HR_LOCAL_ARG_READ_URI_SIZE(%ebp), %ecx
    subl $1, %ecx
    movl %ecx, HR_LOCAL_ARG_READ_URI_SIZE(%ebp)
    addl $1, %esi
    movl %esi, HR_LOCAL_ARG_READ_URI(%ebp)
    
handle_valid_method_check_uri:
    cmpl $0, HR_LOCAL_ARG_READ_URI_SIZE(%ebp)
    jg handle_valid_method_verified
    movl $PIM_ERROR_BAD_REQUEST, HR_LOCAL_ARG_READ_STATUS(%ebp)
    jmp handle_bad_request
    
handle_valid_method_verified: 
    pushl HR_LOCAL_ARG_READ_URI_SIZE(%ebp)
    pushl HR_LOCAL_ARG_READ_URI(%ebp)
    pushl HR_ARG_SOCKET(%ebp)
    pushl HR_LOCAL_ARG_READ_STATUS(%ebp)
    call send_200_ok_response
    addl $12, %esp
    jmp handle_shutdown_socket

handle_shutdown_socket:
    movl HR_ARG_SOCKET(%ebp), %ebx
    movl $SYS_SHUTDOWN_RDWR, %ecx
    movl $SYS_SHUTDOWN, %eax
    int $INT_SYSCALL

handle_finish:
    movl %ebp, %esp
    popl %ebp
    ret
# <<< handle_request()

################################################

# STACK SIZE = 10 KiB
#   8 = REQ_MAX_SUPPORTED_BLKSIZE
#   2 = Regular stack allocations
.equ REQUEST_THREAD_STACK_SIZE, 4096 * 10
.equ REQUEST_THREAD_RESERVED_SIZE, 8

# >>> handle_request_thread_init(socket)
.type handle_request_thread_init, @function
.equ HRT_ARG_SOCKET, -4 # Valid only after movl 4(%esp), %ebp
handle_request_thread_init:
    # Stack points to ARG1 (socket).
    # Save top of the stack in %ebp to free it later.
    leal 4(%esp), %ebp

    # THREAD START
.ifdef _DEBUG
    pushl $REQ_THREAD_START_MSG_SIZE
    pushl $REQ_THREAD_START_MSG
    call println
    addl $8, %esp
.endif

    # CALL 
    pushl HRT_ARG_SOCKET(%ebp)
    call handle_request
    addl $4, %esp
    
    # THREAD END
.ifdef _DEBUG
    pushl $REQ_THREAD_END_MSG_SIZE
    pushl $REQ_THREAD_END_MSG
    call println
    addl $8, %esp
.endif

    # THREAD CLEAUP
handle_request_thread_end:
    # Close the socket
    movl HRT_ARG_SOCKET(%ebp), %ebx
    movl $SYS_CLOSE, %eax
    int $INT_SYSCALL  

    # Unmap the stack
    movl %ebp, %ebx # thread stack addr
    subl $REQUEST_THREAD_STACK_SIZE, %ebx # Get top of the stack
    movl $REQUEST_THREAD_STACK_SIZE, %ecx # length
    movl $SYS_MUNMAP, %eax
    int $INT_SYSCALL

    # exit thread
    movl $SYS_EXIT, %eax
    int $INT_SYSCALL
# <<< handle_request_thread_init()

################################################

# >>> new_request_stack()
# Return:
#   success - pointer to the mapped area
#   failure - -errno
.type new_request_stack, @function
.equ REQUEST_THREAD_STACK_PROT, 0x1 | 0x2 # PROT_READ | PROT_WRITE
.equ REQUEST_THREAD_STACK_FLAGS, 0x0020 | 0x0002 | 0x0100 # MAP_ANONYMOUS | MAP_PRIVATE | MAP_GROWSDOWN
new_request_stack:
    pushl %ebp
    movl %esp, %ebp

    # mmap2()
    movl $0, %ebx # addr - NULL, choose any
    movl $REQUEST_THREAD_STACK_SIZE, %ecx # length
    movl $REQUEST_THREAD_STACK_PROT, %edx # prot
    movl $REQUEST_THREAD_STACK_FLAGS, %esi # flags
    xorl %edi, %edi # fd
    pushl %ebp
    xorl %ebp, %ebp # pgoffset
    movl $SYS_MMAP2, %eax
    int $INT_SYSCALL

    popl %esp
    popl %ebp
    ret
# <<< new_request_stack()

################################################

# >>> start_new_request_thread(socket)
.type start_new_request_thread, @function
#                          CLONE_VM   | CLONE_FS   | CLONE_FILES | CLONE_SIGHAND | CLONE_PARENT | CLONE_THREAD | CLONE_IO
.equ REQUEST_THREAD_FLAGS, 0x00000100 | 0x00000200 | 0x00000400  | 0x00000800    | 0x00008000   | 0x00010000   | 0x80000000
.equ START_THREAD_ARG_SOCKET, 4
start_new_request_thread:
    # Allocate stack for new thread
    call new_request_stack
    cmpl $-1, %eax
    je  rq_thread_exit

    # call clone()
    # Put ret address of new thread in new stack
    leal REQUEST_THREAD_STACK_SIZE(%eax), %ecx # leal top of the stack
	subl $4, %ecx 
    movl START_THREAD_ARG_SOCKET(%esp), %esi
    movl %esi, (%ecx)
    subl $4, %ecx 
    movl $handle_request_thread_init, (%ecx) # top of the stack holds our threaded function ptr

    movl $REQUEST_THREAD_FLAGS, %ebx # flags
    # %ecx holds child_stack
    xor %edx, %edx # parent_tid
    xor %esi, %esi # tls
    xor %edi, %edi # child_tid
    movl $SYS_CLONE, %eax
    int $INT_SYSCALL

rq_thread_exit:
    ret # parent will return, new thread will go to $handle_request_thread_init
# <<< start_new_request_thread()
    