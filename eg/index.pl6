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

