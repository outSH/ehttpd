# Error messages used in debug messages.

# GENERIC
    ERROR_UNKNOWN: .ascii "Unknown error occured!"
    ERROR_UNKNOWN_END:
    .equ ERROR_UNKNOWN_SIZE, ERROR_UNKNOWN_END - ERROR_UNKNOWN

###############
# SOCKETS

# create
    ERROR_SOCKET_CREATE: .ascii "Create socket failed!"
    ERROR_SOCKET_CREATE_END:
    .equ ERROR_SOCKET_CREATE_SIZE, ERROR_SOCKET_CREATE_END - ERROR_SOCKET_CREATE

# setopt
    ERROR_SOCKET_SETOPT: .ascii "Setting socket option failed!"
    ERROR_SOCKET_SETOPT_END:
    .equ ERROR_SOCKET_SETOPT_SIZE, ERROR_SOCKET_SETOPT_END - ERROR_SOCKET_SETOPT

# bind
    ERROR_SOCKET_BIND: .ascii "Could not bind socket to local address!"
    ERROR_SOCKET_BIND_END:
    .equ ERROR_SOCKET_BIND_SIZE, ERROR_SOCKET_BIND_END - ERROR_SOCKET_BIND
  
# listen
    ERROR_SOCKET_LISTEN: .ascii "Could not start listen on the socket!"
    ERROR_SOCKET_LISTEN_END:
    .equ ERROR_SOCKET_LISTEN_SIZE, ERROR_SOCKET_LISTEN_END - ERROR_SOCKET_LISTEN

# accept
    ERROR_SOCKET_ACCEPT: .ascii "Could not accept new connection!"
    ERROR_SOCKET_ACCEPT_END:
    .equ ERROR_SOCKET_ACCEPT_SIZE, ERROR_SOCKET_ACCEPT_END - ERROR_SOCKET_ACCEPT

# # HANDLE
    ERROR_NEW_HANDLER_THREAD: .ascii "Could not create new handler thread!"
    ERROR_NEW_HANDLER_THREAD_END:
    .equ ERROR_NEW_HANDLER_THREAD_SIZE, ERROR_NEW_HANDLER_THREAD_END - ERROR_NEW_HANDLER_THREAD
    
###############
# REQUEST

# read_request_eof
    ERROR_REQUEST_EOF: .ascii "Reading terminated with EOF."
    ERROR_REQUEST_EOF_END:
    .equ ERROR_REQUEST_EOF_SIZE, ERROR_REQUEST_EOF_END - ERROR_REQUEST_EOF

# read_request
    ERROR_READ_REQUEST: .ascii "Could not start listen on the socket!"
    ERROR_READ_REQUEST_END:
    .equ ERROR_READ_REQUEST_SIZE, ERROR_READ_REQUEST_END - ERROR_READ_REQUEST

# bad request
    ERROR_READ_BAD_REQUEST: .ascii "Could not parse request - BAD REQUEST!"
    ERROR_READ_BAD_REQUEST_END:
    .equ ERROR_READ_BAD_REQUEST_SIZE, ERROR_READ_BAD_REQUEST_END - ERROR_READ_BAD_REQUEST

# wrong HTTP version
    ERROR_WRONG_HTTP_VERSION: .ascii "Wrong (not supported) HTTP version in request!"
    ERROR_WRONG_HTTP_VERSION_END:
    .equ ERROR_WRONG_HTTP_VERSION_SIZE, ERROR_WRONG_HTTP_VERSION_END - ERROR_WRONG_HTTP_VERSION

###############
# IO

# sednto
    ERROR_SENDTO: .ascii "sendto() - Could not send through socket"
    ERROR_SENDTO_END:
    .equ ERROR_SENDTO_SIZE, ERROR_SENDTO_END - ERROR_SENDTO

# read_file
    ERROR_READ_ERROR: .ascii "Could not read file!"
    ERROR_READ_ERROR_END:
    .equ ERROR_READ_ERROR_SIZE, ERROR_READ_ERROR_END - ERROR_READ_ERROR
    