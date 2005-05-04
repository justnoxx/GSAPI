package GSAPI;

use 5.008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

use Tie::Handle;

our @ISA = qw(Exporter Tie::Handle);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use GSAPI ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.4';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&GSAPI::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('GSAPI', $VERSION);

# Preloaded methods go here.

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

GSAPI - Perl extension for accessing GNU Ghostscript

=head1 SYNOPSIS

  use GSAPI;
  my $inst = GSAPI::new_instance();
  GSAPI::init_with_args($inst);
  GSAPI::run_string($inst, "12345679 9 mul pstack quit\n");
  GSAPI::exit($inst);
  GSAPI::delete_instance $inst;

=head1 ABSTRACT

GSAPI is an interface to GNU Ghostscript.
It's mainly written to provide a simply interface to ghostscript
that works under Win32 and Unix.

=head1 DESCRIPTION

=over 4

=item ($prod, $cpy, $rev, $revd) = revision()

   Returns Product name, Copyright, Revision and Revision Date
   of the ghostscript release.

=item $inst = new_instance()

   Returns the instance handle.

=item delete_instance($inst)

   Destroys the instance.

=item set_stdio($inst, &stdin, &stdout, &stderr)

   Sets the callbacks for ghostscript I/O
   stdin gets the maximum number of bytes to return on input and should
   return a string up to that length.
   stdout/stderr gets the string passed and they should return the number
   of bytes written.
   Example:

   set_stdio $inst,
             sub { "\n" },
             sub { print STDOUT $_[0]; length $_[0] },
             sub { print STDERR $_[0]; lenngth $_[0] };

=item $rc = init_with_args($inst, ...)

   initializes the ghostscript stuff.

=item $rc = exit($inst)

   calls gsapi_exit

=item $rc = run_string($inst, $string, [$user_errors ])

   calls gsapi_run_string_with_length

=item $rc = run_file($inst, $filename, [$user_errors])

   calls gsapi_run_file

=item $rc = run_string_begin($inst, [$user_errors])

   calls gs_run_string_begin

=item $rc = run_string_end($inst, [$user_errors])

   calls gs_run_string_end
   
=item $rc = run_string_continue($inst, $string, [$user_errors])

   calls gsapi_run_string_continue
  
   =item TIEHANDLE $class, [ stdin => sub { getc STDIN }, ]
                        [ stdout => &stdout, ]
                        [ stderr => stderr, ]
                        [ args => [ arg1, arg2, ...], ]
                        [ user_errors => 0|1, ]

=cut

sub TIEHANDLE {
   my ($class,%args) = @_;
   my $inst = new_instance();
   $args{stdin} ||= sub { getc STDIN };
   $args{stdout} ||= sub { print STDOUT $_[0]; length $_[0] };
   $args{stderr} ||= sub { print STDERR $_[0]; length $_[0] };
   $args{args} ||= [];
   $args{user_errors} ||= 0;
   $args{inst} = $inst;
   set_stdio($inst, $args{stdin}, $args{stdout}, $args{stderr});
   delete @args{qw/stdin stdout stderr/};
   init_with_args($inst, @{$args{args}});
   run_string_begin($inst, $args{user_errors});
   bless \%args, $class;
}

sub WRITE ($$$$) {
   my ($ref, $buf, $len, $offs) = @_;
   run_string_continue($ref->{inst}, substr($buf, 0, $len), $ref->{user_errors});
}

sub DESTROY ($) {
   my $inst = $_[0]->{inst};
   run_string_end($inst, $_[0]->{user_errors});
   GSAPI::exit($inst);
   delete_instance($inst);
}

=back

=head2 EXPORT

None by default.

=head1 AUTHOR

Stefan Traby, E<lt>stefan@hello-penguin.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003,2005 by Stefan Traby <stefan@hello-penguin.com>
Copyright (C) 2003,2005 by KW-Computer Ges.m.b.H Graz, Austria.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License 2.0 or any later version.

The main reason why this module is not available under dual license (Artistic/GPL)
is simply the fact that GNU Gostscript is only available under GPL and not
under Artistic License.

=cut

1;
__END__
