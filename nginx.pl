#!/usr/bin/env perl

use common::sense;
use Git::Wrapper;
use Data::Dump qw(dump);
use Digest::SHA;
use File::Slurp;
use Pithub;


my $homebrew_dir = './homebrew';

my $stable = {
    major  => '1',
    minor  => '2',
    patch  => '2',
    sha256 => '994ad97cbf6f7045f95ea9d6d401aad1e95766671e402c48af85aba5235a2dd7',
};
my $devel  = {
    major  => '1',
    minor  => '3',
    patch  => '2',
    sha256 => '9b30a6f67f0a9eda7db026e12d4f09656f9254cddbb66ff9c0c01d8963dc1d73',
};







my $git = Git::Wrapper->new($homebrew_dir);


unless (-d $homebrew_dir) {
#    clone_repo();
}

#update_repo();

# Changes from upstream that aren't in our master
if ($git->log('origin/master..HEAD')) {
    # push_repo();
}    

update_nginx();



sub update_nginx {
    my $nginx = "$homebrew_dir/Library/Formula/nginx.rb";

    my @lines = read_file($nginx);

    for (my $i = 0; $i < @lines; ++$i) {
        # This is the stable revision, due to the indentation
        if ($lines[$i] =~ m{^  url 'http://nginx.org/download/nginx-(\d).(\d).(\d).tar.gz'}) {
            my ($major, $minor, $patch) = ($1, $2, $3);

            if ($stable->{patch} > $patch) {
                say "Homebrew Stable has a patch. Homebrew: .$patch Stable: .$stable->{patch}";
                    
                $lines[$i]   = "  url 'http://nginx.org/download/nginx-$stable->{major}.$stable->{minor}.$stable->{patch}.tar.gz'\n";
                $lines[$i+1] = "  sha256 '$stable->{sha256}'\n";
            }

            if ($stable->{minor} > $minor) {
                say "Homebrew Stable is WAY OUT OF DATE. Homebrew: .$minor Stable: .$stable->{minor}";
                # TODO: These should be checked manually, email me or something...
            }
        }

        # And this is the devel version
        if ($lines[$i] =~ m{^    url 'http://nginx.org/download/nginx-(\d).(\d).(\d).tar.gz'}) {
            my ($major, $minor, $patch) = ($1, $2, $3);

            if ($devel->{patch} > $patch) {
                say "Homebrew Devel has a patch. Homebrew: .$patch Devel: .$devel->{patch}";

                $lines[$i]   = "    url 'http://nginx.org/download/nginx-$devel->{major}.$devel->{minor}.$devel->{patch}.tar.gz'\n";
                $lines[$i+1] = "    sha256 '$devel->{sha256}'\n";
            }

            if ($devel->{minor} > $minor) {
                say "Homebrew Devel is WAY OUT OF DATE. Homebrew: $minor Devel: $devel->{minor}";
                # TODO: These should be checked manually, email me or something...
            }

        }
    }

    write_file($nginx, @lines);
};


=cut

  url 'http://nginx.org/download/nginx-1.2.1.tar.gz'
  sha256 '994ad97cbf6f7045f95ea9d6d401aad1e95766671e402c48af85aba5235a2dd7'

  devel do
    url 'http://nginx.org/download/nginx-1.3.1.tar.gz'
    sha256 '9b30a6f67f0a9eda7db026e12d4f09656f9254cddbb66ff9c0c01d8963dc1d73'
  end

=cut


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

