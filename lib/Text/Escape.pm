use v6;
module Text::Escape;

sub escape($str, $how) is export {
    my $m = $how.lc;
    return $str if $m eq 'none';
    return escape_str($str, &escape_html_char) if $m eq 'html';
    return escape_str($str, &escape_uri_char ) if $m eq 'url' | 'uri';
    die "Don't know how to escape format '$how' yet";
}

sub escape_html_char($c) {
    my %escapes = (
        '<'     => '&lt;',
        '>'     => '&gt;',
        '&'     => '&amp;',
        '"'     => '&quot;',
    );
    %escapes{$c} // $c;
}

sub escape_uri_char($c) {
    my $allowed = 'abcdefghijklmnopqrstuvwxyz'
                ~ 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                ~ '0123456789'
                ~ '-_.!~*\'()';
    return $c if defined $allowed.index($c);
    return '+' if $c eq ' ';
    return sprintf('%%%x', ord($c)).uc;
}

sub escape_str($str, $callback) {
    my $result = '';
    for 0 .. ($str.chars -1 ) -> $index {
        $result ~= $callback( $str.substr: $index, 1 );
    }
    return $result;
}

# vim:ft=perl6
