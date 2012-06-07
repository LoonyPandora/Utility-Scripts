#!/usr/bin/env perl

# calculate histogram data from input image and write 256x100 bw image

use Image::Magick;
use warnings;
use strict;

my $err;

my $infile = shift or die "Usage: hist.pl filename\n";

# read in target image
my $src = Image::Magick->new;
$err = $src->Read($infile);
warn "$err" if "$err";

# analyze image
my @histogram;
my $w = $src->Get('width');
my $h = $src->Get('height');

# zero our array to avoid undef warnings on unincremented histogram levels
for(my $z=0; $z<256; $z++) { $histogram[$z] = 0; }

my @pixels = $src->GetPixels(map=>"I", width=>"$w", height=>"$h");
foreach my $p (@pixels) {
	$histogram[int($p*255)]++;
}

# normalize histogram data
my $norm = 0;
foreach my $lev (@histogram) {
	if($lev > $norm) { $norm = $lev; }
}

for(my $c=0; $c < @histogram; $c++) {
	# outlier: all black image, $norm is 0, div by zero!  Dodge that.
	if($norm == 0) { last; }
	$histogram[$c] = 100 * $histogram[$c] / $norm;
}

my $image = Image::Magick->new;
$image->Set(size=>'256x100');
$image->ReadImage('xc:white');

for(my $x=0; $x < 256; $x++) {
	my $height = $histogram[$x];
	for(my $y=0; $y <= $height; $y++) {
		$image->Set("pixel[$x," . (99 - $y) . "]"=>'black');
	}
}

my $outname = $infile;
$outname =~ s!^(.+)(\.\w{3})$!h_$1.png!;
$err = $image->Write("$outname");
warn "$err" if "$err";

print "Histogram printed to $outname\n";
exit;
