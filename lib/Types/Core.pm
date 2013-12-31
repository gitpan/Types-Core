#!/usr/bin/perl 
use warnings; use strict;
# vim=:SetNumberAndWidth
=encoding utf-8

=head1 NAME

Types::Core - Core types defined as tests and literals (ease of use)

=head1 VERSION

Version "0.1.2";

=cut



{	package Types::Core;
	use 5.12.0;
	use strict;
	use mem;
	our $VERSION='0.1.2';

#{{{

# 0.1.2 - Write tests to verify solo string equality, returning $var on true,
# 				capturing undef and returning false;
# 			- doc updates
# 0.1.1 - move to using Xporter so EXPORT_OK works w/o deleting defaults
# 			- narrow focus of module -- Default to: Basic types, Ehv &
# 				possible addon of "blessed", "typ"
#	0.1.0 - regularized some naming (Type->type cf. ref; Ref->ref, cf ref) in
#	        function names; modularized/functionized type checks
#	      - Made previous True/False values return the original value for True
#
#	TODO: - conditionalize usage of P::P as we are not "Using it" it won't
#	        flag a 'compile-time' error and late runtime is not best time
#	        to rely on something not there
#
# 0.0.6 - Add ability to use Scalar::Util 'reftype' to determine which
# 				of the base types something is (sans classes).  Fall back
# 				to pattern matching if it isn't available.
# 		  - Add IO & GLOB to fill out basic type representation
# 		  - remove obsolute function calls prior to publishing;
# 0.0.5	-	Added type_check function
# 0.0.4 - add RefInit 
# 0.0.3 - add SCALAR test
# 			- code simplification
# 0.0.2 - Export EhV by default (EXPORT_OK doesn't work reliably)
#}}}	

	our (@TYPES, %TYPES, @EXPORT, @EXPORT_OK);
	use mem(@TYPES=qw(ARRAY CODE GLOB HASH IO REF SCALAR));
	use mem(%TYPES=&{sub () { map { ($_, $_) } @TYPES }});
	use mem(@EXPORT=(@TYPES,qw(EhV )), 
					@EXPORT_OK=qw(typ blessed));

	#use P;
	#use Dbg(1,1,1);
	#TPe "types::EXPORT=%s",\@EXPORT;


	# NOTE: this module should not "use P" (literally _use_) 
	#       or "P" can't "use" this mod.
	#				but this mod makes use of P via direct call later on
	#	eval 'use P;';  # this module should not "use P", or P can't use this mod.
	
	# see if we have this short-cut available
	#
	eval { require Scalar::Util };
	my $scalar_util_available = !$@;

	sub subProto($) { my $subref = $_[0];
		use B ();
		CODE($subref) or die "subProto: expected CODE ref, not " . 
													(ref $subref) // "(undef)";
		B::svref_2object($subref)->GV->PV;
	}

	use constant shortest_type		=> 'REF';
	use constant last_let_offset	=> length(shortest_type)-1;

	BEGIN {
		if ($scalar_util_available) {
			Scalar::Util->import('reftype') or die "Unexpected problem w/import: $@";

			eval '# line ' . __LINE__ .' '. __FILE__ .' 
			sub _type ($) { reftype $_[0] }
			sub _isatype ($$) { (typ($_[0])//"") eq ($_[1]//"") ? $_[0] : undef }';

			$@ && die "_isatype eval(1): $@";

		} else {
				#old _type-> ($_[0] =~ m{^(?:[\w+]=)?([A-Z]+)\(})[0] }
			eval '# line ' . __LINE__ .' '. __FILE__ .' 
				sub _type ($) { 
					my $end = index $_[0], "(";
					$end > '.last_let_offset.' || return undef;			#shortest type=REF)
					substr $_[0], (rindex $_[0], "=", $end) + 1, $end 
				}
					
				sub _isatype($$) {
					my ($var, $type) = @_;
					ref $var && (1 + index($var, $type)) ? $var : undef;
				}';		#end of eval
			$@ && die "_isatype eval(2): $@";
		}
	}

	sub isatype($$) {goto &_isatype}
	sub typ($) {goto &_type}
	sub type($) {goto &_type}

	
=head1 SYNOPSIS


  my @ref_types = (ARRAY CODE GLOB HASH IO REF SCALAR);
  my $ref = $_[0];
  P "Error: expected %s", HASH unless HASH $ref;

Syntax symplifier for type checking.

Allows easy, non-quoted usage of types as literals, and
allows the standard type names to be used as true/false
check routines of references.


=head1 USAGE

=over

B<C<TYPE <Ref>>>  -  Check if I<Ref> has underlying type, I<TYPE>

B<C<TYPE>>  -  Literal usage equal to itself


=back

=head1 Example

  printf "type = %s\n", HASH if HASH $var;

Same as:

  printf "type = %s\n", 'HASH' if ref $var eq 'HASH';)

=head1 DESCRIPTION

For the most basic functions listed in the Synopsis, they take
either 0 or 1 arguments.  If 1 parameter, then they test it
to see if the C<ref> is of the given I<type> (blessed or not) & returns
true or false.

For no args, they return literals of themselves, allowing the 
named strings to be used as Literals w/o quotes.


=cut 

BEGIN {     # create the type functions...
	eval '# line ' . __LINE__ .' '. __FILE__ .'
		sub ' . $_ . ' (;*) {	@_ ? isatype($_[0], '.$_.') : '.$_.' } '
		for @TYPES;
}


=head1 Helper/Useful shorthand Functions 


     EhV $hashref, FIELDNAME;     # Exist[in]hash? Value : undef

=over

If fieldname exists in the HASH pointed to by hashref, return the value,
else returns undef.

=back

     typ REF;                     #return underlying type of REF

=over

Just as c<ref> returns the name of the package or class of a reference,
it had to start out with a reference to one of the basic types.
That's the value returned by C<typ>.  Note: use of this function
violates object integrity by "peeking under the hood" at how class
is implemented.  

=back

    blessed REF;                #is REF blessed or not?

=over

Included for it's usefulness in type checking.  Similar functionality
as implemented in L<Scalar::Util> (uses C<Scalar::Util> if available,
though it is not needed).

=back


=head1 EhV Example

In order to prevent automatic creation of variables, when accessed
or tested for C<undef>, (autovivification), one must test
for existence first, before attempting to read the value.

This results in a 2 step process to retrive a value:

  exists $name{$testname} ? $name{testname}:undef;

If you have multiple levels of hash tables say retrieving SSN's
via {$lastname}{$firstname} in object member 'name2ssns' but
don't know if the object member is valid or not, you could have
nested code:

  my $p=$this;
  if (exists $p->{name2ssns}) {
    $p=$p->{name2ssns};
    if (exists $p->{$lastname}) {
      $p=$p->{$lastname};
      if (exists $p->{$firstname}) {
        return $p->{$firstname};
      }
    }
  }
  return undef;

Instead EhV saves 1 step.  Instead of having to test then
reference the value to return it, it returns the value if 
it exists, else it returns C<undef>.  Thus, the above could
be written:

  my $p=$this;
  return $p = EhV $p, name2ssns      and
             $p = EhV $p, $lastname  and 
                  EhV $p, $firstname;

This not only saves coding space & time, but allows faster
comprehension of what is going on (presuming familiarity 
with C<EhV>).  
      
=cut

	sub EhV($*) {	my ($arg, $field) = @_;
		HASH $arg && defined $field && exists $arg->{$field} ? $arg->{$field} : undef
	}


	sub blessed (*) { my $arg = $_[0];
		ref $arg && ! exists $TYPES{ref $arg} ? $arg : undef
	}
	use Xporter;

1}

# vim: ts=2 sw=2
