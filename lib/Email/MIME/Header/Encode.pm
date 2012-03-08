package Email::MIME::Header::Encode;
use strict;
use warnings;

use Email::Address;
use Encode ();
use MIME::Base64();

use Sub::Exporter -setup => {
    exports => [ 'mime_encode_header' ],
};

my %encoders = (
    'Date'        => \&_date_time_encode,
    'From'        => \&_mailbox_list_encode,
    'Sender'      => \&_mailbox_encode,
    'Reply-To'    => \&_address_list_encode,
    'To'          => \&_address_list_encode,
    'Cc'          => \&_address_list_encode,
    'Bcc'         => \&_address_list_encode,
    'Message-ID'  => \&_msg_id_encode,
    'In-Reply-To' => \&_msg_id_encode,
    'References'  => \&_msg_id_encode,
    'Subject'     => \&_unstructured_encode,
    'Comments'    => \&_unstructured_encode,
);

sub mime_encode_header {
    my ($header, $body, $charset, $encoding) = @_;

    return $body unless $body =~ /\P{ASCII}/
                     || $body =~ /=\?/;

    $header =~ s/^Resent-//;

    return $encoders{$header}->($body, $charset, $encoding)
        if exists $encoders{$header};

    return _unstructured_encode($body, $charset, $encoding);
}

sub _date_time_encode {
    my ($val, $charset, $encoding) = @_;
    return $val;
}

sub _mailbox_encode {
    my ($val, $charset, $encoding) = @_;
    return _mailbox_list_encode($val, $charset);
}

sub _mailbox_list_encode {
    my ($val, $charset, $encoding) = @_;
    my @addrs = Email::Address->parse($val);

    @addrs = map {
        my $phrase = $_->phrase;
        $_->phrase(_mime_encode($phrase, $charset, $encoding))
            if $phrase =~ /\P{ASCII}/;
        my $comment = $_->comment;
        $_->comment(_mime_encode($comment, $charset, $encoding))
            if $comment =~ /\P{ASCII}/;
        $_;
    } @addrs;

    return join(', ', map { $_->format } @addrs);
}

sub _address_encode {
    my ($val, $charset, $encoding) = @_;
    return _address_list_encode($val, $charset, $encoding);
}

sub _address_list_encode {
    my ($val, $charset, $encoding) = @_;
    return _mailbox_list_encode($val, $charset, $encoding); # XXX is this right?
}

sub _msg_id_encode {
    my ($val, $charset, $encoding) = @_;
    return $val;
}

sub _unstructured_encode {
    my ($val, $charset, $encoding) = @_;
    return _mime_encode($val, $charset, $encoding);
}

sub _mime_encode {
    my ($val, $charset, $encoding) = @_;

    $encoding = $encoding || 'base64';

    if ($encoding eq 'base64') {
        return _mime_encode_base64($val, $charset);
    }
    else {
        # TODO: write an encoder for quoted-printable? the tricky part there is
        # the folding whitespace
        die "Encoding $encoding is not supported";
    }
}

sub _mime_encode_base64 {
    my $text    = shift;
    my $charset = Encode::find_encoding(shift)->mime_name();

    my $head = '=?' . $charset . '?B?';
    my $tail = '?=';

    my $base_length = 75 - ( length($head) + length($tail) );

    # This code is copied from Mail::Message::Field::Full in the Mail-Box
    # distro.
    my $real_length = int( $base_length / 4 ) * 3;

    my @result;
    my $chunk = q{};
    while ( length( my $chr = substr( $text, 0, 1, '' ) ) ) {
        my $chr = Encode::encode( $charset, $chr, 0 );

        if ( length($chunk) + length($chr) > $real_length ) {
            push @result, $head . MIME::Base64::encode_base64( $chunk, q{} ) . $tail;
            $chunk = q{};
        }

        $chunk .= $chr;
    }

    push @result, $head . MIME::Base64::encode_base64( $chunk, q{} ) . $tail
        if length $chunk;

    return join q{ }, @result;
}

1;
