#!/usr/bin/env perl

use common::sense;
use Git::Wrapper;
use Data::Dump qw(dump);
use File::Slurp;
use Pithub;


my $homebrew_dir = './homebrew';
my $stable = {major => 1, minor => 2, patch => 2};
my $devel  = {major => 1, minor => 3, patch => 2};







my $git = Git::Wrapper->new($homebrew_dir);


unless (-d $homebrew_dir) {
    # clone_repo();
}

# update_repo();

# Changes from upstream that aren't in our master
if ($git->log('origin/master..HEAD')) {
    # push_repo();
}    

open_nginx();



sub open_nginx {
    my $nginx = "$homebrew_dir/Library/Formula/nginx.rb";

    my @lines = read_file($nginx);

    for (my $i = 0; $i < @lines; ++$i) {
        if ($lines[$i] =~ m{^  url 'http://nginx.org/download/nginx-(\d).(\d).(\d).tar.gz'}) {
            my ($major, $minor, $patch) = ($1, $2, $3);

            say "$major, $minor, $patch";

            say $lines[$i+1];

            # Ignore the major for now, we don't know whether a major version will be
            # Devel or Stable yet (until major 2.0 is released - not for a LONG time)

            
            # Nginx works off the linux-style "even is stable, odd is devel" method
            if ($minor % 2) {
                if ($devel->{patch} > $patch) {
                    say "Homebrew Devel has a patch. Homebrew: $patch Devel: $devel->{patch}";
                }

                if ($devel->{minor} > $minor) {
                    say "Homebrew Stable is WAY OUT OF DATE. Homebrew: $minor Devel: $devel->{minor}";
                }
            } else {    
                if ($stable->{patch} > $patch) {
                    say "Homebrew Stable has a patch. Homebrew: $patch Devel: $stable->{patch}";
                    
                    $lines[$i] = "  url 'http://nginx.org/download/nginx-$stable->{major}.$stable->{minor}.$stable->{patch}.tar.gz\n";
                }

                if ($stable->{minor} > $minor) {
                    say "Homebrew Stable is WAY OUT OF DATE. Homebrew: $minor Devel: $stable->{minor}";
                }

            }
        }
    }

    die @lines[1..15];
};



sub clone_repo {
    say "Cloning Homebrew...";
    $git->clone('git@github.com:LoonyPandora/homebrew.git');

    say "Adding Upstream...";
    $git->remote('add', 'upstream', 'git://github.com/mxcl/homebrew.git');
}


sub update_repo {
    say "Fetching Upstream...";
    $git->fetch('upstream');

    say "Merging Changes...";
    $git->merge('upstream/master');
}



sub push_repo {
    say "Pushing to my GitHub...";
    $git->push('origin', 'master');

}

