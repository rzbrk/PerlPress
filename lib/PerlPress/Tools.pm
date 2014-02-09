use strict;
use warnings;
package PerlPress::Tools;
# ABSTRACT: Tools of PerlPress

use Carp;
use Cwd;
use URI::Escape;
use utf8;
use Time::Local;
#use Switch;
use feature qw{ switch };
use Path::Class qw(dir file);
use HTML::Strip;
use Encode qw(encode decode);
use Text::Unidecode;

=head1 SUBROUTINES/METHODS

=head2 now

Returns actual date and time as formatted string "YYYY-MM-DD HH:MM:SS".
Optionally an offset in seconds can be spcified.

 my $now_str = PerlPress::Tools::now();
 my $timeout = PerlPress::Tools::now({ offset=>86400 });

=cut

sub now
{
    # Get a reference to a hash containing the routine's arguments
    my ($arg_ref) = @_;
    
    # Check if all necessary arguments are present
    my $offset=$arg_ref->{'offset'} || 0; # Offset in seconds

    my @now   = localtime time + $offset;
    my $year  = sprintf "%04d", $now[5]+1900;
    my $month = sprintf "%02d", $now[4]+1;
    my $day   = sprintf "%02d", $now[3];
    my $hour  = sprintf "%02d", $now[2];
    my $min   = sprintf "%02d", $now[1];
    my $sec   = sprintf "%02d", $now[0];

    return "$year-$month-$day $hour:$min:$sec";
}

=head2 now_dir

Returns actual date and time as formatted string "YYYY-MM-DD_HHMMSS".
Optionally an offset in seconds can be spcified.

 my $now_str = PerlPress::Tools::now_dir();
 my $timeout = PerlPress::Tools::now_dir({ offset=>86400 });

=cut

sub now_dir
{
    # Get a reference to a hash containing the routine's arguments
    my ($arg_ref) = @_;
  
    # Check if all necessary arguments are present
    my $offset = $arg_ref->{'offset'} || 0; # Offset in seconds

    my @now   = localtime time + $offset;
    my $year  = sprintf "%04d", $now[5]+1900;
    my $month = sprintf "%02d", $now[4]+1;
    my $day   = sprintf "%02d", $now[3];
    my $hour  = sprintf "%02d", $now[2];
    my $min   = sprintf "%02d", $now[1];
    my $sec   = sprintf "%02d", $now[0];

    return "$year$month$day"."_"."$hour$min$sec";
}

=head2 create_output_dir_tree

Creates the directory tree for the HTML output and outputs a hash reference
containing key/value pairs for the directories

 my $dir = PerlPress::Tools::create_output_dir_tree({ outdir=>$outdir });
 my $base_dir = $dir->{'base'};
 my $icons_dir_rel = $dir->{'icons'}->relative($dir->{'art'});

=cut

sub create_output_dir_tree
{
    # Get a reference to a hash containing the routine's arguments
    my ($arg_ref) = @_;

    # Check if all necessary arguments are present
    my $dbh = $arg_ref->{'dbh'} or croak "Specify database handler!\n";
    my $outdir = $arg_ref->{'outdir'} or croak "Specify output directory!\n";

    # Remove trailing / from $outdir if present
    $outdir =~s/\/$//;

    # Hash holding the directory structure
    my $dirs;
    $dirs->{'base'}    = dir($outdir, PerlPress::Tools::now_dir());
    $dirs->{'art'}     = $dirs->{'base'}->subdir("art");
    $dirs->{'cat'}     = $dirs->{'base'}->subdir("cat");
    $dirs->{'tag'}     = $dirs->{'base'}->subdir("tag");
    $dirs->{'img'}     = $dirs->{'base'}->subdir("img");
    $dirs->{'files'}   = $dirs->{'base'}->subdir("files");
    $dirs->{'icons'}   = $dirs->{'base'}->subdir("icons");
    $dirs->{'css'}     = $dirs->{'base'}->subdir("css");
    $dirs->{'sitemap'} = $dirs->{'base'}->file("sitemap.xml"); # Sitemap file
    
    # Get a list of all defined categories and tags
    my $cats = PerlPress::DBAcc::get_cat_list({ dbh=>$dbh });
    foreach my $cat_id (keys $cats)
    {
        $dirs->{"cat_".$cat_id}=$dirs->{'cat'}->subdir($cat_id."_".$cats->{$cat_id}->{'alias'});
    }

    my $tags = PerlPress::DBAcc::get_tag_list({ dbh=>$dbh });
    foreach my $tag_id (keys $tags)
    {
        $dirs->{"tag_".$tag_id}=$dirs->{'tag'}->subdir($tag_id."_".$tags->{$tag_id}->{'alias'});
    }

    # Create all the directories
    foreach my $d (keys $dirs)
    {
        $dirs->{$d}->mkpath() if ($dirs->{$d}->is_dir);
    }

    return $dirs;
}

=head2 clearstr

Converts a given string to a string removed from critical characters.
An optional second parameter is the maximum length of the output string.
Default is 30 characters. 

  my $link = PerlPress::Tools::clearstr({ str=>$str, max_len=>$len });

=cut

sub clearstr
{
    # Get a reference to a hash containing the routine's arguments
    my ($arg_ref) = @_;

    # Check if all necessary arguments are present
    my $str = $arg_ref->{'str'} or croak "Specify title!\n";
    my $len = $arg_ref->{'max_len'} || 30;
    
    # Convert to lower case characters
    $str = lc $str;

    # Define special characters and replacements, which are not handled
    # by Text::Unidecode as we want (e.g. "ä" -> "a" not "ae")
    my %map = (
        "[ä]"  => "ae",
        "[ö]"  => "oe",
        "[ü]"  => "ue",
        "[ ]+" => "_",
        "€"    => "euro",
    );
    foreach my $c (keys %map) { $str =~s/$c/$map{$c}/g; };

    # Normalize string using Text::Unidecode
    $str = Text::Unidecode::unidecode($str);
	
    # Remove remaining "special characters" like brackets and so on
    $str =~s/[^-0-9_a-z]//g;

    $str =~s/_+/_/g;
    $str =~s/^_//;

    # Reduce length of string $link
    $str = substr($str, 0, $len);

    # Remove trailing "_" if exist
    $str =~s/_$//;

    return $str;
}

=head2 date_str2epoch

Calculate the epoch time from a given time string with format
"YYYY-MM-DD hh:mm:ss" or "YYYY-MM-DDThh:mm:ss". The epoch time is the
number of seconds after 1970-01-01T00:00:00.

=cut

sub date_str2epoch
{
    # Get a reference to a hash containing the routine's arguments
    my ($arg_ref) = @_;
  
    # Check if all necessary arguments are present
    my $date = $arg_ref->{'date'} or croak "Specify date string!\n";

    # Initialize return value
    my $ret = 0;

    if ($date =~m/^([\d]{4,4})-([\d]{2,2})-([\d]{2,2})[\sT]{1,1}([\d]{2,2}):([\d]{2,2}):([\d]{2,2})$/)
    {
        # We have to substract 1 from the month value ($2)
        my $month = $2-1;
        $ret = timegm($6, $5, $4, $3, $month, $1);
    }

    return $ret;
}

=head2 epoch2date_str

Create a date string from a given epoch time. A couple of different
output formats are suppported:

"YYYY-MM-DDThh:mm:ss"
"YYYY-MM-DD hh:mm:ss"
"DD.MM.YYYY"

The epoch time is the number of seconds after 1970-01-01T00:00:00.

=cut

sub epoch2date_str
{
    # Get a reference to a hash containing the routine's arguments
    my ($arg_ref) = @_;
  
    # Check if all necessary arguments are present
    my $date = $arg_ref->{'date'} or croak "Specify date string!\n";
    my $format = $arg_ref->{'format'} or croak "Specify format!\n";
    # Timezone offset to GMT in hours
    my $tz_offset = $arg_ref->{'tz_offset'} || 0;
  
    my (
        $sec,
        $min,
        $hour,
        $mday,
        $mon,
        $year,
        $wday,
        $yday,
        $isdst
    ) = gmtime($date);

    # Preformat the data
    $year      = $year+1900;
    $mon++;                                     # January = 0 !
    $mon       = sprintf "%02d", $mon;
    $mday      = sprintf "%02d", $mday;
    $hour      = sprintf "%02d", $hour;
    $min       = sprintf "%02d", $min;
    $sec       = sprintf "%02d", $sec;
    $tz_offset = sprintf "%+03d:00", $tz_offset;

    my $date_str;
    given($format)
    {
        when("YYYY-MM-DDThh:mm:ss")
        {
            $date_str = $year."-".$mon."-".$mday."T".$hour.":".$min.":".$sec;
        }
        when("YYYY-MM-DDThh:mm:ssTZD")
        {
            $date_str = $year."-".$mon."-".$mday."T".$hour.":".$min.":"
                .$sec.$tz_offset;
        }
        when("YYYY-MM-DD hh:mm:ss")
        {
            $date_str = $year."-".$mon."-".$mday." ".$hour.":".$min.":".$sec;
        }
        when("DD.MM.YYYY")
        {
	        $date_str = $mday.".".$mon.".".$year;
        }
        when("YYYY-MM-DD")
        {
            $date_str=$year."-".$mon."-".$mday;
        }
        default
        {
            croak "Unrecognized date format!\n";
	    }
    }

    return $date_str;
}

=head2 striphtml

Strips HTML markup from text string using HTML::Strip and reduces length
of text string, if specified.

=cut

sub striphtml
{
    # Get a reference to a hash containing the routine's arguments
    my ($arg_ref) = @_;

    # Check if all necessary arguments are present
    my $html = $arg_ref->{'html'} or croak "Specify input string!\n";
    my $len = $arg_ref->{'max_len'} || 0;

    my $hs = HTML::Strip->new();
	
    # Bug #42834 for HTML-Strip: HTML::Strip breaks UTF-8
    # See: https://rt.cpan.org/Public/Bug/Display.html?id=42834
    my $clean;
    if ($HTML::Strip::VERSION <= 1.06)
    {
        $html = encode("utf8", $html);
        $clean = $hs->parse( $html );
        $hs->eof;
        $clean = decode("utf8", $clean) if (! utf8::is_utf8($clean));
    } else
    {
        $clean = $hs->parse( $html );
        $hs->eof;
    }

    # Trim whitespace
    $clean =~s/\s+/ /g;

    # Remove " if present
    $clean =~s/\"//g;

    $clean = substr($clean,0,$len) if ($len > 0);

    return $clean;
}

=head2 check_dir_exist_writable

In case the given directory exists and is writable, the function returns
1 (true), else 0 (false).

=cut

sub check_dir_exist_writable
{
    # Get a reference to a hash containing the routine's arguments
    my ($arg_ref) = @_;

    # Check if all necessary arguments are present
    my $dir = $arg_ref->{'dir'} or croak "Specify directory!\n";

    my $ret = 0;
    $ret = 1 if (-d $dir && -w $dir);

    return $ret;
}

=head2 repl_with_home

Replaces the substring "~/" in a file path with "$ENV{'HOME'}/".

=cut

sub repl_with_home
{
    my $path = shift;
    $path =~s/~\//$ENV{'HOME'}\//;
    $path =~s/\/$//; # Remove trailing / if exist
    return $path;
}

1;
