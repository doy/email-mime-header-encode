#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use utf8;

use Email::MIME::Header::Encode 'mime_encode_header';

is(mime_encode_header('Date', 'Wed, 7 Mar 2012 23:00:10 +0100', 'utf8'),
   'Wed, 7 Mar 2012 23:00:10 +0100',
   "Date encoded correctly");

for my $header (qw(From Sender Reply-To To Cc Bcc)) {
    is(mime_encode_header($header, 'Ævar Arnfjörð Bjarmason <abcd@example.com>', 'utf8'),
        '=?UTF-8?B?w4Z2YXIgQXJuZmrDtnLDsCBCamFybWFzb24=?= <abcd@example.com>',
        "$header encoded correctly");
    is(mime_encode_header($header, 'Ricardo Signes <efgh@example.com>', 'utf8'),
        'Ricardo Signes <efgh@example.com>',
        "$header encoded correctly");
    is(mime_encode_header($header, 'Ævar Arnfjörð Bjarmason <abcd@example.com>, "Ricardo Signes" <efgh@example.com>', 'utf8'),
        '=?UTF-8?B?w4Z2YXIgQXJuZmrDtnLDsCBCamFybWFzb24=?= <abcd@example.com>, "Ricardo Signes" <efgh@example.com>',
        "$header encoded correctly");
}

for my $header (qw(Message-ID In-Reply-To References)) {
    is(mime_encode_header($header, '<CACBZZX54+QxadTb-m=j0M3DoeLo6-PQcPvLEDgYw=ZU57njMWQ@mail.gmail.com>', 'utf8'),
       '<CACBZZX54+QxadTb-m=j0M3DoeLo6-PQcPvLEDgYw=ZU57njMWQ@mail.gmail.com>',
       "$header encoded correctly");
    is(mime_encode_header($header, '<foobar=?baz?=@example.com>', 'utf8'),
       '<foobar=?baz?=@example.com>',
       "$header encoded correctly");
}

for my $header (qw(Subject Comments X-NonStandard)) {
    is(mime_encode_header($header, 'Ricardo', 'utf8'),
       'Ricardo',
       "$header encoded correctly");
    is(mime_encode_header($header, 'Julián', 'utf8'),
       '=?UTF-8?B?SnVsacOhbg==?=',
       "$header encoded correctly");
    is(mime_encode_header($header, '=?UTF-8?B?SnVsacOhbg==?=', 'utf8'),
       '=?UTF-8?B?PT9VVEYtOD9CP1NuVnNhY09oYmc9PT89?=',
       "$header encoded correctly");
    is(mime_encode_header($header, 'test test test test test test test test tést te (12 34)', 'utf8'),
       '=?UTF-8?B?dGVzdCB0ZXN0IHRlc3QgdGVzdCB0ZXN0IHRlc3QgdGVzdCB0ZXN0IHTDqXN0?= =?UTF-8?B?IHRlICgxMiAzNCk=?=',
       "$header encoded correctly");
    is(mime_encode_header($header, 'test test test test test test test test test te (12 34)', 'utf8'),
       'test test test test test test test test test te (12 34)',
       "$header encoded correctly");
}

done_testing;
