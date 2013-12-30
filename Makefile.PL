

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Types::Core',
		BUILD_REQUIRES => { mem => '0.3.2' , Xporter => '0.0.4',
                     'Test::Simple' => 0.44,
		},
    VERSION_FROM => 'lib/Types/Core.pm', # finds \$VERSION
    AUTHOR       => 'LAWALSH (LAWALSH@cpan.org)',
    ABSTRACT     => 'Ease-of-use functions for perl core Types',
    PREREQ_PM    => {
										 'mem'	=> '0.3.2',Xporter => '0.0.4',
                    },
);
