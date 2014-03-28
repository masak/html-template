class HTML::Template;

use Text::Escape;
use HTML::Template::Grammar;

=begin pod

=head1 NAME

HTML::Template - A simple templating system based on the HTML::Template of Perl 5

=head1 SYNOPSIS

eg/index.pl6 looks like this:

  use v6;

  use HTML::Template;

  my %params = (
    title => 'Hello Perl 6 world',
    authors => Array.new(
      { name => 'Ilya'   },
      { name => 'Moritz' },
      { name => 'Lyle'   },
      { name => 'Carl'   },
      { name => 'Johan'  },
    ),
  );

  my $ht = HTML::Template.from_file("templates/index.tmpl");
  $ht.with_params(%params);
  print $ht.output;

eg/templates/index.tmpl looks like this:

  <html><head><title><TMPL_VAR title></head>
  <body>
  <h1><TMPL_VAR title>

   <ul>
  <TMPL_LOOP authors>
    <li><TMPL_VAR name></li>
  </TMPL_LOOP>
  </ul>

  <TMPL_IF error>
   <div id="error">Some error happened</div>
  </TMPL_IF>

  </body>
  </html>


=head1 AUTHOR

Carl Masak

=end pod

has $.in;
has %!params;
has %!meta;
has $.file;

method from_string( Str $in ) {
    return self.new(in => $in);
}

method from_file($file_path) {
    return self.new(in => slurp($file_path), file => $file_path);
}

method param( Pair $param ) {
    %!params{$param.key} = $param.value;
}

method with_params( %params ) {
    %!params = %params;
    return self;
}

method output() {
    return self.substitute( self.parse, %!params );
}

method parse( $in? ) {
    my $match := HTML::Template::Grammar.parse($in || $!in);
    die "Failed to parse the template" unless $match;
    CATCH {
        default {
            my $err = $_;
            die $err ~ ($.file ?? " in file $.file" !! "");
        }
    }
    #die "Failed to parse the template" ~ ($.file ?? " in file $.file" !! "") unless $match;
    return $match<contents>;
}

method substitute( $contents, %params ) {
    my $output = ~$contents<plaintext>;

    for $contents<chunk>.list -> $chunk {

        if $chunk<directive><insertion> -> $i {
            my $key = ~$i<attributes><name><val>;

            my $value;
            if (defined %params{$key}) {
                $value = %params{$key};
            } else {
                $value = %!params{$key};
            }

            # RAKUDO: Scalar type not implemented yet
            if defined $value {
                warn "Param $key is a { $value.WHAT }" unless $value ~~ Str | Int;
            } else {
                warn  "Param $key is a undef";
                $value = '';
            }

            if $i<attributes><escape> {
                my $et = ~$i<attributes><escape>;
                $value = escape($value, $et);
            }
            $output ~= ~$value;
        }
        elsif $chunk<directive><if_statement> -> $if {
            my $cond;
            if $if<attributes><name><lctrls> -> $lc {
                if %!meta<loops><current> -> $c {
                    if $lc<lc_last> {
                        $cond = ?($c<elems> == $c<iteration>);
                    }
                    elsif $lc<lc_first> {
                        $cond = ?($c<iteration> == 1);
                    }
                }
            }
            else {
                $cond = %params{~$if<attributes><name><val>};
            }

            if $cond {
                $output ~= self.substitute(
                                $if<contents>[0],
                                %params
                            );
            }
            elsif $if<else> {
                $output ~= self.substitute(
                                $if<else>,
                                %params
                            );
            }
        }
        elsif $chunk<directive><for_statement> -> $for {
            my $key = ~$for<attributes><name><val>;

            my $iterations = %params{$key};

            # RAKUDO: Rakudo doesn't understand autovivification of multiple
            # hash indices %!meta<loops><current> = $key; [perl #61740]
            %!meta<loops> = {} unless defined %!meta<loops>;

            # that will fail on nested same-named loops... hm
            %!meta<loops>{$key} = {elems => $iterations.elems, iteration => 0};
            %!meta<loops><current> = %!meta<loops>{$key};

            for $iterations.values -> $iteration {
                %!meta<loops>{$key}<iteration>++;
                $output ~= self.substitute(
                                $for<contents>,
                                $iteration
                            );
            }
        }
        elsif $chunk<directive><include> {
            my $file = ~$chunk<directive><include><attributes><name><val>;
            %params<TMPL_PATH> = '' if not defined %params<TMPL_PATH>;
            $file = %params<TMPL_PATH> ~ $file;
            # TODO: check for file existance
            #if $file ~~ :e  {
                $output ~= self.substitute(
                                self.parse( slurp($file) ),
                                %params
                            );
            #}
        }

        $output ~= ~$chunk<plaintext>;
    }
    return $output;
}

# vim:ft=perl6
