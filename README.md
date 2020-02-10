# ehttpd
Multithreaded HTTP server written in assembler (32-bit GAS)

## Features:
- Multithreading!
- No runtime libraries dependency - just pure GNU Assembly (GAS) and syscalls.
- Binary is only **23K**
- GET / HEAD requests (icluding basic headers, like Content-Length)
- Validates requests and returns some error codes (400, 404, 405, 500, 505)
- Low memory usage (**~240 VIRT, ~12 RES on average**)
- High performance (tested with up to 255 concurrent users, 7k requests / second)
- No memory leaks.
- Tested on Fedora 31 and Ubuntu 18.04

## Build:

All resulting files are stored in bin/

#### Just httpd binary:
* make

#### httpd + copy static content for tests:
* make all

#### make all + debug messages and debug symbols:
* make debug

#### clean:
* make clean

## Usage:
- Copy ehttpd binary to location where you store your web content.
- Run ehttpd
- index.html is server by default (i.e. for request URI '/')
- **Server runs on port 7555 (so open localhost:7555)**
- Make sure port 7555 is allowed in firewall if you wish to actualy share the content.

## Tests:

Run ehttp server first with static content present.

#### Basic tests checking various errors and responses:
* test/run_test.pl <IP>

#### Simple stress test (call some requests from test content repeatedly)
* test/run_stress_test.pl <IP>

#### Performance:
- I made some tests with siege tool (https://www.joedog.org/siege-home/).
- As a content I used openconnect documentation (on my machine it was in /usr/share/doc/openconnect/)
- List of URLs is available in test/siege_open_connect_uri.txt (during tests they were called at random)
- I tested for 10 minutes and 255 concurrent users.

#### Command:
siege -c255 -t10m -i -f test/siege_open_connect_uri.txt 

**Results:**
- Transactions:             4349789 hits 
- Availability:              100.00 % 
- Elapsed time:              599.77 secs 
- Data transferred:        27067.95 MB 
- Response time:                0.03 secs 
- Transaction rate:         7252.43 trans/sec 
- Throughput:               45.13 MB/sec 
- Concurrency:              234.27 
- Successful transactions:     4349812 
- Failed transactions:               0 
- Longest transaction:           16.03 
- Shortest transaction:            0.00 

##### Adjustment tips:
To improve performance for specific content, one can:
- Change blksize used for reading files (SEND_FILE_ARG_BLKSIZE argument of send_file_content call in io_helpers.s). 
This function is called from request.s and by default equals blksize from stat syscall.
- Change socket backlog(BACKLOG_SIZE in ehttpd.s), by default its 8.
