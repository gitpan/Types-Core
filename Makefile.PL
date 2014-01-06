

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Types::Core',
    VERSION_FROM => 'lib/Types/Core.pm', # finds \$VERSION
    AUTHOR       => 'LAWALSH (LAWALSH@cpan.org)',
    ABSTRACT     => 'Ease-of-use functions for perl core Types',
    BUILD_REQUIRES=> { 'ExtUtils::MakeMaker' => '6.8.2', },
    PREREQ_PM    => {
										 'mem'	=> '0.4.3',Xporter => '0.0.7',
                    },
);
