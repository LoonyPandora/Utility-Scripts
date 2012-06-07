#!/usr/bin/env perl

# Rehist: alter an input image to match an input histogram, write out
# altered image.

use Image::Magick;
use warnings;
use strict;

$| = 1; # unbuffered output plz kthx

my $err;

my $sourceimage = shift;
my $targethistogram = shift or die "Usage: rehist.pl original_image target_histogram\n";

# read in original image, target histogram
print "Reading source image...";
my $src = Image::Magick->new;
$err = $src->Read($sourceimage);
warn "$err" if "$err";
print "done.\n";

print "Reading target histogram...";
my $tar = Image::Magick->new;
$err = $tar->Read($targethistogram);
warn "$err" if "$err";
print "done.\n";

my %index;
my @histogram;
my $w = $src->Get('width');
my $h = $src->Get('height');

# create histogram of source image
print "Creating histogram of source...";
my @srcpix = $src->GetPixels(map=>"I", width=>"$w", height=>"$h");
for(my $i=0; $i < @srcpix; $i++) {
	my $p = int($srcpix[$i]*255); # because normalize=>'false' is throwing errors.
	$histogram[$p]++; # add to histogram
	push(@{$index{$p}}, $i); # add to index of pixels by value;
}
print "done.\n";

# read histogram from target histogram
print "Reading target histogram...";
my @tarhistogram;
my $tarhtotal;
for(my $i = 0; $i < 256; $i++) {
	my @column = $tar->GetPixels(map=>"I", width=>1, height=>100, x=>$i, y=>0);
	$tarhistogram[$i] = 99;
	foreach my $n (@column) { $tarhistogram[$i] -= $n; }
	$tarhtotal += $tarhistogram[$i]; # total pixels in histogram
}
print "done.\n";

# normalize src histogram data
print "Normalizing source histogram data...";
my $norm = 0;
for(my $c=0; $c < 256; $c++) {
	if(defined($histogram[$c])) {
		if($histogram[$c] > $norm) { $norm = $histogram[$c];}
	}
	else {
		$histogram[$c] = 0;
	}
}
for(my $c=0; $c < @histogram; $c++) {
	# outlier: all black image, $norm is 0, div by zero!  Dodge that.
	if($norm == 0) { last; }
	$histogram[$c] = 100 * $histogram[$c] / $norm;
}
print "done.\n";
#print "Total of " . scalar(@histogram) . " values recorded.\n";

# write out source histogram
print "Writing source histogram image...";
my $srchist = Image::Magick->new;
$srchist->Set(size=>'256x100');
$srchist->ReadImage('xc:white');
for(my $x=0; $x < 256; $x++) {
	my $height = $histogram[$x];
	for(my $y = 0; $y < $height; $y++) {
		$srchist->Set("pixel[$x," . (99 - $y) . "]"=>'black');
	}
}
my $shistout = $sourceimage;
$shistout =~ s!^(.+)(\.\w{3})$!h_$1.png!;
$err = $srchist->Write("$shistout");
warn "$err" if "$err";
print "done.\n";

# diff between size of histogram and size of image, in pixelcount
my $scale = $h * $w / $tarhtotal;

# create flat sorted array of pixels from original image
my @indsort;
foreach my $k (sort {$a <=> $b} keys %index) {
	push(@indsort, @{$index{$k}});
}

# push portions of the flat array into a new index according to the
# target histogram's frequencies
my $remainder = 0;
my %targetindex;
for(my $i = 0; $i < 256; $i++) {
	my $lenraw = $tarhistogram[$i] * $scale + $remainder;
	my $len = int($lenraw);
	$remainder = $lenraw - $len;
	my @chunk = splice(@indsort, 0, $len);
	push(@{$targetindex{$i}}, @chunk);
}

print "Printing final histogram-corrected image...";
my $final = Image::Magick->new;
$final->Set(size=>$w . "x" . $h);
$final->ReadImage('xc:red');

foreach my $lev (sort {$a <=> $b} keys %targetindex) {
        my @arr = @{$targetindex{$lev}};
        my $hex = sprintf("#%2.2x%2.2x%2.2x", $lev, $lev, $lev);
        foreach my $r (@arr) {
                my $ix = $r % $w;
                my $iy = int($r / $w);
                $final->Set("pixel[$ix,$iy]"=>"$hex");
        }
}
my $finalout = $sourceimage;
$finalout =~ s!^(.+)(\.\w{3})$!out_$1.png!;

$err = $final->Write("$finalout");
warn "$err" if "$err";
print "done.\n";

