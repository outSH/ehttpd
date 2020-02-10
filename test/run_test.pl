#!/usr/bin/env perl

use strict;
use warnings;
use HTTP::Response;  
use Test::More;

##################################
# SETUP
##################################
my $content_dir = "web-content";

my $server_ip = "127.0.0.1";
$server_ip = $ARGV[0] if $ARGV[0];
my $server_port = "7555";
print "Testing server $server_ip:$server_port\n";


##################################
# Helpers
##################################

sub print_http_response {
    my $response = shift @_ or die "check_response() - No response argument.";

    if ($response->is_success) {
        print "\tHTTP call OK!\n"
    }
    else {
        print "\tHTTP call NOT OK!\n"
    }
    
    print "\t", $response->code, " ", $response->message, "\n";
    print "\tMessage length: ", length($response->as_string), "\n";
    print "\tContent length: ", length($response->content), "\n";
    my %headers_hash = $response->headers->flatten;
    print "\tHeaders: ", join ' | ', keys %headers_hash, "\n";
}

sub send_request {
    my $request_content = shift @_ or die "send_request() - No request argument.";

    print "\n>>> SENDING REQUEST $request_content\n";

    my $response_raw = `echo -e "$request_content" | nc $server_ip $server_port`;
    my $response_obj = HTTP::Response->parse($response_raw);

    print_http_response($response_obj);

    return $response_obj
}

sub test_content_header {
    my $response = shift @_ or die "test_content_header() - No response ARG.";
    my $file_content = shift @_ or die "test_content_header() - No file_content ARG.";

    cmp_ok($response->header("Content-Length"), '>', 0, "Content-Length not 0.");
    is($response->header("Content-Length"), $file_content->{"len"}, 
        "Content-Length is the same as original.");
}

sub test_content_body {
    my $response = shift @_ or die "test_content_body() - No response ARG.";
    my $file_content = shift @_ or die "test_content_body() - No file_content ARG.";

    cmp_ok(length($response->content), '>', 0, "Response content not empty.");
    is(length($response->content), $file_content->{"len"}, 
        "Response content length is the same as original.");
    is($response->content, $file_content->{"content"}, 
        "Response content is the same as original.");
}

##################################
# INIT
##################################

my $resp       = undef;
my %test_files = ();

# Read test web-content files
opendir (my $cdir, $content_dir) || die "Could not open DIR '$content_dir': $!\n";

print "Processing test content files in '$content_dir'\n";

while (readdir $cdir) {
    if ($_ eq "." || $_ eq "..") {
        next;
    }

    print "Read $_\n";

    open my $fh, '<', "$content_dir/$_" or die "Could not open FILE '$content_dir/$_' : $!\n";

    my $file_content = do { local $/; <$fh> };

    $test_files{"$_"} = {
                            "len" => length($file_content),
                            "content"  => $file_content,
                        };

    close $fh
}

closedir $cdir;

######################
# ERROR TESTS
######################

$resp = send_request("xxxxxxxxxxxxx");
is($resp->code, 400, "Garbage request.");

$resp = send_request("GET / HTTP/1.1");
is($resp->code, 400, "Missing CRLF in request header.");
cmp_ok(length($resp->content), '>', 0, "Response content present.");
like($resp->content, qr/<title>.*400.*<\/title>/, "Correct 400 title HTML tag.");

$resp = send_request("GET / HTTP/1.9\r\n");
is($resp->code, 505, "Wrong HTTP version.");
cmp_ok(length($resp->content), '>', 0, "Response content present.");
like($resp->content, qr/<title>.*505.*<\/title>/, "Correct 505 title HTML tag.");

$resp = send_request("GET banana_beer.html HTTP/1.1\r\n");
is($resp->code, 404, "Not existing file.");
cmp_ok(length($resp->content), '>', 0, "Response content present.");
like($resp->content, qr/<title>.*404.*<\/title>/, "Correct 404 title HTML tag.");

$resp = send_request("GET empty.html HTTP/1.1\r\n");
is($resp->code, 404, "Empty html file.");

# Check common headers
ok($resp->header("server"), "server header is available in error response.");
is($resp->header("server"), "ehttpd", "server header contains correct name.");
ok($resp->header("Accept-Ranges"), "Accept-Ranges header is available in error response.");
is($resp->header("Accept-Ranges"), "none", "Accept-Ranges are disabled.");

$resp = send_request("POST / HTTP/1.1\r\n");
is($resp->code, 405, "Not supported http method");
ok($resp->header("Allow"), "When 405 is returned, Allow header is present.");
is($resp->header("Allow"), "GET, HEAD", "Allow header in 405 response should specify GET, HEAD only.");
cmp_ok(length($resp->content), '>', 0, "Response content present.");
like($resp->content, qr/<title>.*405.*<\/title>/, "Correct 405 title HTML tag.");

######################
# HEAD / GET TESTS
######################

# Simple request tests
my $simple_text_file = "simple.txt";

# HEAD/GET simple.txt
$resp = send_request("HEAD $simple_text_file HTTP/1.1\r\n");
is($resp->code, 200, "HEAD successfully.");
test_content_header($resp, $test_files{$simple_text_file});
cmp_ok(length($resp->content), '==', 0, "HEAD does not return body content.");

$resp = send_request("GET $simple_text_file HTTP/1.1\r\n");
is($resp->code, 200, "GET successfully.");
test_content_header($resp, $test_files{$simple_text_file});
test_content_body($resp, $test_files{$simple_text_file});

# HEAD/GET /simple.txt
$resp = send_request("HEAD /$simple_text_file HTTP/1.1\r\n");
is($resp->code, 200, "HEAD successfully.");
test_content_header($resp, $test_files{$simple_text_file});
cmp_ok(length($resp->content), '==', 0, "HEAD does not return body content.");

$resp = send_request("GET /$simple_text_file HTTP/1.1\r\n");
is($resp->code, 200, "GET successfully.");
test_content_header($resp, $test_files{$simple_text_file});
test_content_body($resp, $test_files{$simple_text_file});

# HEAD/GET /
my $index_file = "index.html";
$resp = send_request("HEAD / HTTP/1.1\r\n");
is($resp->code, 200, "HEAD successfully.");
test_content_header($resp, $test_files{$index_file});
cmp_ok(length($resp->content), '==', 0, "HEAD does not return body content.");

$resp = send_request("GET / HTTP/1.1\r\n");
is($resp->code, 200, "GET successfully.");
test_content_header($resp, $test_files{$index_file});
test_content_body($resp, $test_files{$index_file});

# HEAD/GET large.txt
my $large_text_file = "large.txt";
$resp = send_request("HEAD /$large_text_file HTTP/1.1\r\n");
is($resp->code, 200, "HEAD successfully.");
test_content_header($resp, $test_files{$large_text_file});
cmp_ok(length($resp->content), '==', 0, "HEAD does not return body content.");

$resp = send_request("GET /$large_text_file HTTP/1.1\r\n");
is($resp->code, 200, "GET successfully.");
test_content_header($resp, $test_files{$large_text_file});
test_content_body($resp, $test_files{$large_text_file});

### IMAGES
# HEAD/GET favicon.ico
my $img_icon_file = "favicon.ico";
$resp = send_request("HEAD /$img_icon_file HTTP/1.1\r\n");
is($resp->code, 200, "HEAD successfully.");
test_content_header($resp, $test_files{$img_icon_file});

$resp = send_request("GET /$img_icon_file HTTP/1.1\r\n");
is($resp->code, 200, "GET successfully.");
test_content_header($resp, $test_files{$img_icon_file});
test_content_body($resp, $test_files{$img_icon_file});

# HEAD/GET osiol.png
my $img_png_file = "osiol.png";
$resp = send_request("HEAD /$img_png_file HTTP/1.1\r\n");
is($resp->code, 200, "HEAD successfully.");
test_content_header($resp, $test_files{$img_png_file});

$resp = send_request("GET /$img_png_file HTTP/1.1\r\n");
is($resp->code, 200, "GET successfully.");
test_content_header($resp, $test_files{$img_png_file});
test_content_body($resp, $test_files{$img_png_file});

# HEAD/GET stuff.gif
my $img_gif_file = "stuff.gif";
$resp = send_request("HEAD /$img_gif_file HTTP/1.1\r\n");
is($resp->code, 200, "HEAD successfully.");
test_content_header($resp, $test_files{$img_gif_file});

$resp = send_request("GET /$img_gif_file HTTP/1.1\r\n");
is($resp->code, 200, "GET successfully.");
test_content_header($resp, $test_files{$img_gif_file});
test_content_body($resp, $test_files{$img_gif_file});

done_testing();