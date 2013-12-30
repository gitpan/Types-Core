#!/usr/bin/perl 
# vim=:SetNumberAndWidth
=encoding utf-8

=head1 NAME

Types::Core - Basic types defined as tests and literals (ease of use)

=head1 VERSION

Version "0.1.0";

=cut



{	package Types::Core;
	use warnings;use strict;
	use mem;
	our $VERSION='0.1.1';

# 0.1.1 - move to using Xportr so EXPORT_OK works w/o deleting defaults
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
	

	our (@TYPES, %TYPES, @EXPORT, @EXPORT_OK);
	use mem(@TYPES=qw(ARRAY CODE GLOB HASH IO REF SCALAR));
	use mem(%TYPES=&{sub () { map { ($_, $_) } @TYPES }});
	use mem(@EXPORT=(@TYPES,qw(EhV )), 
					@EXPORT_OK=qw(typ blessed));


	# see if we have this short-cut available
	eval { require Scalar::Util };
	my $scalar_util_available = !$@;

	# NOTE: this module should not "use P" (literally _use_) 
	#       or "P" can't "use" this mod.
	#				but this mod makes use of P via direct call later on
	#	eval 'use P;';  # this module should not "use P", or P can't use this mod.
	
	sub subProto($) {
		use B ();
		CODE $_[0] or die "subProto: expected CODE ref, not " . 
											(ref $_[0])//"(undef)";
		B::svref_2object($_[0])->GV->PV;
	}


	BEGIN {
		if ($scalar_util_available) {
			Scalar::Util->import('reftype') and die "Unexpected problem w/import: $@";

			eval '# line ' . __LINE__ .' '. __FILE__ .' 
			sub _type ($) { reftype $_[0] }
			sub _isatype ($$) { (typ($_[0])//"") eq ($_[1]//"") ? $_[0] : undef }';

			$@ && die "_isatype eval(1): $@";

		} else {
				#old _type-> ($_[0] =~ m{^(?:[\w+]=)?([A-Z]+)\(})[0] }
			eval '# line ' . __LINE__ .' '. __FILE__ .' 
			sub _type ($) { 
				my $end = index $_[0], "(";
				$end > 2 || return undef;			#>2 (shortest type=REF)
				substr $_[0], (rindex $_[0], "=", $end) + 1, $end }
				
			sub _isatype($$) {
				my ($var, $type) = @_;
				ref $var && (1+index($var, $type)) ? 1 : 0;
			}';
			$@ && die "_isatype eval(2): $@";
		}
	}

	sub isatype($$) {goto &_isatype}
	sub typ($) {goto &_type}
	sub type($) {goto &_type}

	
=head1 SYNOPSIS


  my @ref_types = (ARRAY CODE GLOB HASH IO REF SCALAR);
  my $ref       = $_[0];
  P "Error: expected %s", HASH unless HASH $ref;

	# pkg->{p1} gets a _copy_ of array in 1st param if "safe"
  $ref  = ARRAY $_[0] and $pkg->{p1} = [@$ref];

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
		sub ' . $_ . ' (;*) {	
			return @_ ? isatype($_[0], '.$_.') : '.$_.' } '
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

#  typIs($ref, TYPE)  - returns $ref if same TYPE else undef
#
#  refIs($ref, REF)   - return $ref if same REF else undef
#
#  typSame($t1, $2)   - return $t1 if $t1 == $t2, else undef
#
#  refSame($r1, $r2)  - return $r1 if $r1 == $r2 else undef


	
	sub EhV($*) {my ($_, $field)=@_;
		HASH $_ or return undef; 
		exists $_->{$_[1]} ? $_->{$_[1]} : undef
	}


	sub blessed (*) {
		my $arg = $_[0];
		ref $arg && ! exists $TYPES{ref $arg} && return $arg;
		undef;
	}



#	sub typIs ($$) {
#		defined($_[0]) && defined($_[1]) && 
#			((typ $_[0])//"") eq (typ $_[1])//""  ?  $_[0]	:	undef }
#
#	sub refIs ($*) {
#		defined($_[0]) && defined($_[1]) && 
#			((ref $_[0])//"") eq $_[1]//""		? $_[0]	:	undef }
#
#
#	sub typSame ($$) {
#		defined($_[0]) && defined($_[1]) && 
#			((typ $_[0])//"") eq (typ $_[1])//""  ?  $_[0]	:	undef }
#
#	sub refSame ($$) {
#		defined($_[0]) && defined($_[1]) && 
#			((ref $_[0])//"") eq (ref $_[1])//""		? $_[0]	:	undef }
#

#=over
#
#
#typCheck($reference, TYPE) -- verifies $reference is of TYPE or dies
#
#refCheck($reference, CLASSNAME) - checks if reference is of CLASSNAME or
#dies
#
#=back
#
#=cut

#	sub typCheck ($$) {
#		my $pp=\&P::P;
#		my ($ref, $typ, $msg) = @_;
#		my ($pkg, $fn, $ln, $sub) = caller(0);
#		if (typ($ref) ne $typ) {
#			die $pp->("Type Mismatch.  Expected %s, got '%s' @ %s line %s.", $typ,
#					ref $ref, $fn, $ln);
#		}
#	}

#=over
#
#refCheck($ref1, $ref1)  - dies if not same ref(CLASS)
#
#=back
#
#=cut
#
#	sub refCheck ($*) {
#		my $pp=\&P::P;
#		my ($obj, $ref, $msg) = @_;
#		die $pp->("Ref-Class Mismatch: expected %s, got '%s' @ %s line %s.", $ref,
#				ref $obj, (caller 0)[1,2]) if ref $obj ne $ref;
#	}


#=over

#refInit(\$pointer, $value)   - assign value to pointer unless it's a ref

#=back

#=cut


#	sub refInit (\$$) { my ($pp, $val) = @_;
#		$$pp = $val unless ref $$pp }



#	sub import () { my $p = shift; my $caller = (caller)[0];
#    my ($as, $alias);
#    @_=grep { $as and ($alias=$_), undef;
#              /^as$/i and ($as=1), undef } @_;
#
#    if ($alias) { no strict q(refs);
#      *{$alias.'::'} = *{__PACKAGE__.'::'}; }
#
#		foreach my $f (@EXPORT, @_) {
#			$f or next;
#			next unless grep("$f", @EXPORT) && grep("$f", @EXPORT_OK);
#			my $proto = (prototype $f) // "";
#			no strict 'refs';
#			eval "# line ". __LINE__ ." ". __FILE__ ." \n".
#				"sub ".$caller."::".$f." (".$proto.") {
#					goto &". __PACKAGE__ ."::".$f."};"; 
#			$@ and warn "$@";
#		}
#	}
#
	use Xportr;

	1;
}

{	package main;
	unless ((caller 0)[0]) {
    local $_=do{ $/=undef, <Types::Core::DATA>};
		close Types::Core::Data;
		eval $_;
    die "self-test failed: $@" if $@;
		1;
	} else { 
		close $Types::Core::DATA;
	}
1}

package Types::Core;
__DATA__


# line __LINE__    __FILE__ 
foreach (qw{STDERR STDOUT}) {select *$_; $|=1};
#use strict; use warnings; 
use P;
my %tests;
my $MAXCASES=0;
use Types::Core;

my $format="#%-2d %-25s: ";
{
  my $case=0;
  sub newcase() {++$case}
  sub caseno() {$case};
  sub iter(){"Test ${\(0+&caseno)}"}
}

sub case ($) {
  &newcase;
  if (!@ARGV || $tests{&caseno}) {
	  $_=P (\*STDOUT, $format,  &caseno, "(".$_[0].")");
    1
  } else {
    0;
  }
}

my @base_types=qw(ARRAY CODE GLOB HASH IO REF SCALAR);
my @std_funcs=qw(EhV typ blessed);
my @opt_funcs=qw(RefInit);

no warnings;
no strict;

sub findtype($) {
	my $v=$_[0];
	foreach (@base_types) {
		no strict 'refs';
		no warnings;
		return $_ if  $_->($_[0]) ;
	}
}

my @sigils=qw(@ & * % \\$ $ ); 
use vars qw($all @all &all *all %all  );

sub print_type($) { my $ref = $_[0];
	my $t = findtype($ref);
	P "For ref to \"%-15s\", type=%s", $ref, $t;
}

for my $sig  (@sigils) {
	my $ref=eval '\\'.$sig.'all';
	print_type($ref);
}

# vim: ts=2 sw=2
