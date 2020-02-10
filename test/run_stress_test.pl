#!/usr/bin/env perl

use strict;
use warnings;
use Math::BigInt;
use LWP::UserAgent;  
use threads;

##################################
# SETUP
##################################

my $test_thread_count = 8;
my $requests_per_thread = 1000;
my $timeout_seconds = 1;

my $server_ip = "127.0.0.1";
$server_ip = $ARGV[0] if $ARGV[0];
my $server_port = "7555";
print "Testing server $server_ip:$server_port\n";

my $server = "http://$server_ip:$server_port";

##################################
# STRESS
##################################

sub send_request {
    my $request_content = shift @_ or die "send_request() - No request argument.";

    my $response_raw = `echo -e "$request_content" | nc $server_ip $server_port`;
    my $response_obj = HTTP::Response->parse($response_raw);

    return $response_obj
}

sub start_request {
    foreach (0 .. $requests_per_thread) {
        send_request("GET / HTTP/1.1");
        send_request("GET / HTTP/1.9\r\n");
        send_request("GET banana_beer.html HTTP/1.1\r\n");
        send_request("POST / HTTP/1.1\r\n");
        send_request("GET / HTTP/1.1\r\n");
        send_request("GET /osiol.png HTTP/1.1\r\n");
        send_request("GET /favicon.ico HTTP/1.1\r\n");
    }

    threads->exit()
}


my @thread_list = ();

while (1) {
    foreach (0 .. $test_thread_count) {
        print "thread started\n";
        push @thread_list, threads->create('start_request');
    }

    foreach (0 .. $test_thread_count) {
        my $thr = pop @thread_list;
        $thr->join();
        print "thread joined\n";
    }
}


