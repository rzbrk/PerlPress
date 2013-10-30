use strict;
use warnings;
package PerlPress::Compiler;
# ABSTRACT: HTML Compiler routines of PerlPress

use HTML::Template;
use feature qw{ switch };
use XML::Smart;

=head1 SUBROUTINES/METHODS

=head2 list_cat

Returns a hash ref containing all the categories along with the path
for the category files

 my $cat=PerlPress::Compiler::list_cat({ dbh=>$dbh, cat_dir=>"../foo/bar" });
 foreach my $c (keys $cat)
 {
   print "$cat->{$c}->{cat_name}, $cat->{$c}->{path}\n";
 }

=cut

sub list_cat
{
  # Get a reference to a hash containing the routine's arguments
  my ($arg_ref)=@_;
  
  # Check if all necessary arguments are present
  my $dbh=$arg_ref->{'dbh'} or die "PerlPress::Compiler::list_cat: Specify database handler!\n";
  my $cat_dir=$arg_ref->{'cat_dir'} or die "PerlPress::Compiler::list_cat: Specify local base directory for category files!\n";

  # Get all categories
  my $cat=PerlPress::DBAcc::get_cat({ dbh=>$dbh });
  
  # Foreach category generate the corresponding path
  foreach my $cat_id (keys $cat)
  {
    $cat->{$cat_id}->{path}=$cat_dir."/".
      PerlPress::Tools::title2link({ title=>$cat->{$cat_id}->{cat_name} });
  }
  
  return $cat;
}

=head2 nav_menu



=cut

sub nav_menu
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::Compiler::nav_menu: Specify database handler!\n";
	my $dirs=$arg_ref->{'dirs'} or die "PerlPress::Compiler::nav_menu: Specify directories!\n";
	my $refdir=$arg_ref->{'refdir'} or die "PerlPress::Compiler::nav_menu: Specify reference directory!\n";

	# Get array ref with ids of articles which go into the navigation
	# menu
	my $nav_entries=PerlPress::DBAcc::nav_entries({ dbh=>$dbh });

	# Initialize variable
	my @menu=();
	
	# Default entry in the menu is the link to the start page
	push @menu, { NAV_NAME => "Home", NAV_LINK => $dirs->{'base'}->file("index.html")->relative($refdir) };

	# Loop through the entries of the navigation menu and build up an
	# array with template variable definitions
	foreach my $art_id (sort {$a <=> $b } @{$nav_entries})
	{
		# Load the article data that also contain link information
		my $art=PerlPress::DBAcc::load_art_data({ dbh=>$dbh, art_id=>$art_id });
		
		if ($art->{type}=~m/nav/i)
		{
			push @menu, { NAV_NAME => $art->{'title'},
						  NAV_LINK => $art->{'link'} };
		} else # type=page
		{
			push @menu, { NAV_NAME => $art->{'title'},
						  #NAV_LINK => $dirs->{'art'}->relative($refdir)."/".$art_id."_".$art->{'alias'}.".html" };
						  NAV_LINK => $dirs->{'art'}->file($art->{'filename'})->relative($refdir) };
		}
	}

	return \@menu;
}

=head2 html_art



=cut

sub html_art
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
	  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::Compiler::html_art: Specify database handler!\n";
	my $art_id=$arg_ref->{'art_id'} or die "PerlPress::Compiler::html_art: Specify article id!\n";
	my $dirs=$arg_ref->{'dirs'} or die "PerlPress::Compiler::html_art: Specify directory information!\n";
	my $templ=$arg_ref->{'templ'} or die "PerlPress::Compiler::html_art: Specify template!\n";

	# Define the reference directory. All pathes in links in the
	# output file will be given relativ to this path
	my $refdir=$dirs->{'art'};

	# Get the article data
	my $art=PerlPress::DBAcc::load_art_data({ dbh=>$dbh, dirs=>$dirs, art_id=>$art_id });

	# The file name of the article HTML file
	#my $filename=$art_id."_".$art->{'alias'}.".html";
	
	# Calculate some additional data
	$art->{'created_epoch'}=PerlPress::Tools::date_str2epoch({ date=>$art->{created} });
	$art->{'modified_epoch'}=PerlPress::Tools::date_str2epoch({ date=>$art->{modified} });
	
	$art->{'recomm'}="#";
	$art->{'twitter'}="#";
	
	# Get the categories the article is linked to
	my @art_cat_ids=@{PerlPress::DBAcc::get_art_cat_ids({ dbh=>$dbh, art_id=>$art_id })};
	my @art_cat_names=@{PerlPress::DBAcc::get_cat_name({ dbh=>$dbh, cat_id=>\@art_cat_ids })};
	my @art_cat_alias=@{PerlPress::DBAcc::get_cat_alias({ dbh=>$dbh, cat_id=>\@art_cat_ids })};
	my @art_cats=();
	foreach my $c (0 .. $#art_cat_names)
	{
		push @art_cats, { ART_CAT_LINK => $dirs->{"cat_".$art_cat_ids[$c]}->file("index.html")->relative($refdir),
						  ART_CAT_NAME => $art_cat_names[$c] };
	}
	
	my @art_tag_ids=@{PerlPress::DBAcc::get_art_tag_ids({ dbh=>$dbh, art_id=>$art_id })};
	my @art_tag_names=@{PerlPress::DBAcc::get_tag_name({ dbh=>$dbh, tag_id=>\@art_tag_ids })};
	my @art_tag_alias=@{PerlPress::DBAcc::get_tag_alias({ dbh=>$dbh, tag_id=>\@art_tag_ids })};
	my @art_tags=();
	foreach my $t (0 .. $#art_tag_names)
	{
		push @art_tags, { ART_TAG_LINK => $dirs->{"tag_".$art_tag_ids[$t]}->file("index.html")->relative($refdir),
						  ART_TAG_NAME => $art_tag_names[$t] };
	}
	
	# Get the code for the navigation menu
	my @nav_menu=@{PerlPress::Compiler::nav_menu({ dbh=>$dbh, dirs=>$dirs, refdir=>$refdir })};

	# Find HTML shortcuts in intr_text and full_text of articles
	my @html_shortcuts;
	my @shorts=@{PerlPress::DBAcc::get_shorts_list({ dbh=>$dbh })};
	foreach my $s (@shorts)
	{
		push @html_shortcuts,
		  eval("{find=>\"$s->{'find'}\", repl=>sub{\"$s->{'repl'}\"}}")
		  if ($s->{'enabled'}=~m/yes/i);
		warn $@ if $@;
	}
	
	# This is a pre-defined shortcut to resolve internal article links
	push @html_shortcuts, {find=>"\{article id=\"(?<id>.*)\"\}(?<txt>[^\{]*)\{\/article\}",
	  repl=>sub{PerlPress::Compiler::art_link({ dbh=>$dbh, dirs=>$dirs, refdir=>$refdir, art_id=>$+{id}, text=>$+{txt} })}};
	
	foreach my $s (@html_shortcuts)
	{
		$art->{'intr_text'}=~s/$s->{'find'}/$s->{'repl'}->()/eg;
		$art->{'full_text'}=~s/$s->{'find'}/$s->{'repl'}->()/eg;
	}

	# Open the html template file
	my $html = HTML::Template->new(filename => $templ,
								   global_vars => 1,
								   loop_context_vars => 1,
								   utf8 => 1)
			   or die "PerlPress::Compiler::html_art: Cannot open the template file $templ, $!\n";

	$html->param(CHARSET => "utf-8",
				 META_AUTHOR => $art->{'author'},
				 META_DESCR => PerlPress::Tools::strip_html({ html=>$art->{'intr_text'}, maxlen=>150 }),
				 META_KEYWORDS => join(", ", @art_tag_names),
				 META_DATE => PerlPress::Tools::epoch2date_str({ date=>$art->{'created_epoch'}, format=>"YYYY-MM-DDThh:mm:ss" }),
				 HEAD_TITLE => $art->{'title'},
				 CSS => $dirs->{'css'}->file("default.css")->relative($refdir),
				 LINK_HOME => $dirs->{'base'}->file("index.html")->relative($refdir),
				 ICON_DIR => $dirs->{'icons'}->relative($refdir),
				 NAV_MENU => \@nav_menu,
				 ART_PAGE => 1,
				 ART_LIST => [ { ART_FULL_LINK => $dirs->{'art'}->file($art->{'filename'})->relative($refdir),
								 ART_TITLE => $art->{'title'},
								 ART_INFO_SHOW => 1,
								 ART_DATE => PerlPress::Tools::epoch2date_str({ date=>$art->{'created_epoch'}, format=>"DD.MM.YYYY" }),
								 ART_CATEGORIES => \@art_cats,
								 ART_COMM_LINK => "#",
								 ART_RECOMM_LINK => $art->{'recomm'},
								 ART_TWTTR_LINK => $art->{'twitter'},
								 ART_TXT_INTRO => $art->{'intr_text'},
								 ART_TXT_FULL => $art->{'full_text'},
								 ART_TAGS => \@art_tags,
							   } ]
				);

	# Output the HTML code to a file
	my $file=$dirs->{'art'}->file($art->{'filename'});
	open my $filehandle, ">", $file
		or die "Could not open $file: $!";
	binmode $filehandle, ':encoding(UTF-8)';
	print {$filehandle} $html->output();
	close $filehandle;
}

=head2 html_list


=cut

sub html_list
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
	  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::Compiler::html_list: Specify database handler!\n";
	my $type=$arg_ref->{'type'} or die "PerlPress::Compiler::html_list: Specify type (cat|tag|blog)!\n";
	my $dirs=$arg_ref->{'dirs'} or die "PerlPress::Compiler::html_list: Specify directory information!\n";
	my $templ=$arg_ref->{'templ'} or die "PerlPress::Compiler::html_list: Specify template!\n";
	
	# Intialiaze some variables
	my $refdir;			# Reference dir. All pathes in links in the
						# output file will be given relativ to this
						# path.
	my $cat_page=0;		# Indicator, if category page
	my $tag_page=0;		# Indicator, if tag page
	my $cattag_name="";	# Name of cat/tag
	my @art_ids;		# IDs of articles linked to cat/tag
	
	
	# See, if we need to create category, tag or blog pages
	given($type)
	{
		when(m/(cat|category)/i)
		{
			$type="cat";
			$cat_page=1;
			
			my $id=$arg_ref->{'id'} or die "PerlPress::Compiler::html_list: Specify category id!\n";
			$refdir=$dirs->{"cat_".$id};
			
			$cattag_name=${PerlPress::DBAcc::get_cat_name({ dbh=>$dbh, cat_id=>[$id] })}[0];
			@art_ids=@{PerlPress::DBAcc::get_art_list_by_cat({ dbh=>$dbh, cat_id=>$id })};
		}
		when(m/tag/i)
		{
			$type="tag";
			$tag_page=1;
			
			my $id=$arg_ref->{'id'} or die "PerlPress::Compiler::html_list: Specify tag id!\n";
			$refdir=$dirs->{"tag_".$id};
			
			$cattag_name=${PerlPress::DBAcc::get_tag_name({ dbh=>$dbh, tag_id=>[$id] })}[0];
			@art_ids=@{PerlPress::DBAcc::get_art_list_by_tag({ dbh=>$dbh, tag_id=>$id })};
		}
		when(m/blog/i)
		{
			$type="blog";
			$refdir=$dirs->{'base'};
			
			$cattag_name="Blog"; # For window title
			@art_ids=@{PerlPress::DBAcc::get_publ_art({ dbh=>$dbh, blog_only=>1 })};
		}
		default
		{
			die "html_list: Invalid type argument (not \"cat\", \"tag\" or \"blog\")";
		}
	}
	
	# Get the code for the navigation menu
	my @nav_menu=@{PerlPress::Compiler::nav_menu({ dbh=>$dbh, dirs=>$dirs, refdir=>$refdir })};
	
	# A defined number of articles are put on one page
	# ($ENV{'ART_PER_PAGE'}. Hence, a category will have multiple HTML
	# pages in which the articles fit in. Loop over the HTML files
	# (pages) of the category
	my $n_page=0; # page counter
	my $page_last=0; # indicates, if last page
	while($#art_ids >= 0)
	{
		$n_page++; # increment file counter
		my @art_ids_page;
		if ($#art_ids >= $ENV{'ART_PER_PAGE'})
		{
			$page_last=1 if ($#art_ids == $ENV{'ART_PER_PAGE'});
			@art_ids_page=splice(@art_ids,0,$ENV{'ART_PER_PAGE'});
		} else
		{
			$page_last=1;
			@art_ids_page=splice(@art_ids,0,$#art_ids+1);
		}
		
		# Load the articles that have to be put in the page
		my @art_list;	# This array holds the articles for the page
		for my $art_id (@art_ids_page)
		{
			my $art=PerlPress::DBAcc::load_art_data({ dbh=>$dbh,
													  dirs=>$dirs,
													  art_id=>$art_id });
			
			# Calculate some additional data
			$art->{'created_epoch'}=PerlPress::Tools::date_str2epoch({ date=>$art->{created} });
			$art->{'modified_epoch'}=PerlPress::Tools::date_str2epoch({ date=>$art->{modified} });
			
			$art->{'filename'}=$art_id."_".$art->{'alias'}.".html";
			
			$art->{'recomm'}="#";
			$art->{'twitter'}="#";
			
			# Get the categories the article is linked to
			my @art_cat_ids=@{PerlPress::DBAcc::get_art_cat_ids({ dbh=>$dbh, art_id=>$art_id })};
			my @art_cat_names=@{PerlPress::DBAcc::get_cat_name({ dbh=>$dbh, cat_id=>\@art_cat_ids })};
			my @art_cat_alias=@{PerlPress::DBAcc::get_cat_alias({ dbh=>$dbh, cat_id=>\@art_cat_ids })};
			my @art_cats=();
			foreach my $c (0 .. $#art_cat_names)
			{
				push @art_cats, { ART_CAT_LINK => $dirs->{"cat_".$art_cat_ids[$c]}->file("index.html")->relative($refdir),
								  ART_CAT_NAME => $art_cat_names[$c] };
			}
			
			my @art_tag_ids=@{PerlPress::DBAcc::get_art_tag_ids({ dbh=>$dbh, art_id=>$art_id })};
			my @art_tag_names=@{PerlPress::DBAcc::get_tag_name({ dbh=>$dbh, tag_id=>\@art_tag_ids })};
			my @art_tag_alias=@{PerlPress::DBAcc::get_tag_alias({ dbh=>$dbh, tag_id=>\@art_tag_ids })};
			my @art_tags=();
			foreach my $t (0 .. $#art_tag_names)
			{
				push @art_tags, { ART_TAG_LINK => $dirs->{"tag_".$art_tag_ids[$t]}->file("index.html")->relative($refdir),
								  ART_TAG_NAME => $art_tag_names[$t] };
			}
			
			# Find HTML shortcuts in intr_text
			my @html_shortcuts;
			my @shorts=@{PerlPress::DBAcc::get_shorts_list({ dbh=>$dbh })};
			foreach my $s (@shorts)
			{
				push @html_shortcuts,
				  eval("{find=>\"$s->{'find'}\", repl=>sub{\"$s->{'repl'}\"}}")
				  if ($s->{'enabled'}=~m/yes/i);
				warn $@ if $@;
			}
			
			# This is a pre-defined shortcut to resolve internal article links
			push @html_shortcuts, {find=>"\{article id=\"(?<id>.*)\"\}(?<txt>[^\{]*)\{\/article\}",
			  repl=>sub{PerlPress::Compiler::art_link({ dbh=>$dbh, dirs=>$dirs, refdir=>$refdir, art_id=>$+{id}, text=>$+{txt} })}};
			
			foreach my $s (@html_shortcuts)
			{
				$art->{'intr_text'}=~s/$s->{'find'}/$s->{'repl'}->()/eg;
			}
			
			# If article has full_text then set appropriate template
			# variable to show "read more" link.
			my $read_more=0;
			$read_more=1 if (! ($art->{'full_text'}=~ m/^\s+$/));
			
			push @art_list,
				 { ART_FULL_LINK => $dirs->{'art'}->file($art->{'filename'})->relative($refdir),
				   ART_TITLE => $art->{'title'},
				   ART_INFO_SHOW => 1,
				   ART_DATE => PerlPress::Tools::epoch2date_str({ date=>$art->{'created_epoch'}, format=>"DD.MM.YYYY" }),
				   ART_CATEGORIES => \@art_cats,
				   ART_COMM_LINK => "#",
				   ART_RECOMM_LINK => $art->{'recomm'},
				   ART_TWTTR_LINK => $art->{'twitter'},
				   ART_TXT_INTRO => $art->{'intr_text'},
				   ART_MORE => $read_more,
				   ART_TAGS => \@art_tags,
				 };
		}
		
		# Now create the HTML page
	
		# First, middle or last page? The name of the first file is
		# always "index.html". The following are page2.html and so on.
		my $nav_page_first=0;
		my $nav_page_middle=0;
		my $nav_page_last=0;
		my $page_prev_link="";
		my $page_next_link="";
		my $filename="";
		if ($n_page==1 && $page_last==0)
		{
			$nav_page_first=1;
			$page_next_link=$refdir->file("page2.html")->relative($refdir);
			$filename="index.html";
		}
		if ($n_page==1 && $page_last==1)
		{
			# This is the case, when there is only one page.
			# Hide all navigation buttons.
			$filename="index.html";
		}
		if ($n_page==2 && $page_last==0)
		{
			$nav_page_middle=1;
			$page_prev_link=$refdir->file("index.html")->relative($refdir);
			$page_next_link=$refdir->file("page3.html")->relative($refdir);
			$filename="page".$n_page.".html";
		}
		if ($n_page==2 && $page_last==1)
		{
			$nav_page_last=1;
			$page_prev_link=$refdir->file("index.html")->relative($refdir);
			$filename="page".$n_page.".html";
		}
		if ($n_page>2 && $page_last==0)
		{
			$nav_page_middle=1;
			$page_prev_link=$refdir->file("page".($n_page-1).".html")->relative($refdir);
			$page_next_link=$refdir->file("page".($n_page+1).".html")->relative($refdir);
			$filename="page".$n_page.".html";
		}
		if ($n_page>2 && $page_last==1)
		{
			$nav_page_last=1;
			$page_prev_link=$refdir->file("page".($n_page-1).".html")->relative($refdir);
			$filename="page".$n_page.".html";
		}
		
		# Open the html template file
		my $html = HTML::Template->new(filename => $templ,
									   global_vars => 1,
									   loop_context_vars => 1,
									   utf8 => 1)
				   or die "PerlPress::Compiler::html_cat: Cannot open the template file $templ, $!\n";
		
		$html->param(CHARSET => "utf-8",
					 META_AUTHOR => $ENV{'AUTHOR'},
					 META_DESCR => "",
					 META_KEYWORDS => "",
					 META_DATE => PerlPress::Tools::epoch2date_str({ date=>time, format=>"YYYY-MM-DDThh:mm:ss" }),
					 HEAD_TITLE => $cattag_name,
					 CSS => $dirs->{'css'}->file("default.css")->relative($refdir),
					 LINK_HOME => $dirs->{'base'}->file("index.html")->relative($refdir),
					 ICON_DIR => $dirs->{'icons'}->relative($refdir),
					 NAV_MENU => \@nav_menu,
					 CAT_PAGE => $cat_page,
					 TAG_PAGE => $tag_page,
					 CAT_LINK => $refdir->file("index.html")->relative($refdir),
					 CAT_NAME => $cattag_name,
					 TAG_LINK => $refdir->file("index.html")->relative($refdir),
					 TAG_NAME => $cattag_name,
					 ART_LIST => \@art_list,
					 NAV_PAGE_FIRST => $nav_page_first,
					 NAV_PAGE_MIDDLE => $nav_page_middle,
					 NAV_PAGE_LAST => $nav_page_last,
					 PAGE_NEXT_LINK => $page_next_link,
					 PAGE_PREV_LINK => $page_prev_link
					);
					
		# Output the HTML code to a file
		my $file=$refdir->file($filename);
		open my $filehandle, ">", $file
			or die "Could not open $file: $!";
		binmode $filehandle, ':encoding(UTF-8)';
		print {$filehandle} $html->output();
		close $filehandle;
	}

	return $n_page;
}

=head2 sitemap

Create a sitemap.

=cut

sub sitemap
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
	  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::Compiler::sitemap: Specify database handler!\n";
	my $dirs=$arg_ref->{'dirs'} or die "PerlPress::Compiler::sitemap: Specify directory information!\n";
	my $ch_freq=$arg_ref->{'changefreq'} || 'weekly'; # change frequency
	
	# Base URL from environmental variables
	my $base_url=$ENV{'BASE_URL'};
	
	# Initialize sitemap XML
	# See: http://de.wikipedia.org/wiki/Sitemaps-Protokoll#Beispiel
	my $sitemap = XML::Smart->new(q`<?xml version="1.0" encoding="UTF-8" ?>
	<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9
	http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
	</urlset>`);
	$sitemap=$sitemap->{'urlset'};
	
	# Get all published articles with type=(blog|page)
	my @publ=@{PerlPress::DBAcc::get_publ_art({ dbh=>$dbh })};
	foreach my $art_id (@publ)
	{
		# Get the article data
		my $art=PerlPress::DBAcc::load_art_data({ dbh=>$dbh, dirs=>$dirs, art_id=>$art_id });
		$art->{'created_epoch'}=PerlPress::Tools::date_str2epoch({ date=>$art->{created} });
		my $lastmod=PerlPress::Tools::epoch2date_str({ date=>$art->{'created_epoch'},
													   format=>"YYYY-MM-DDThh:mm:ss" });
		
		my $url={loc=>$base_url."/art/".$art_id."_".$art->{'alias'}.".html",
				 lastmod=>$lastmod,
				 changefreq=>$ch_freq
				};
				
		push(@{$sitemap->{'url'}} , $url);
	}
	
	# Save to file
	$sitemap->save($dirs->{'sitemap'});
}

=head2 art_link

Returns the link to an article given by its art_id. If the article does
not exist, return the string #.

=cut

sub art_link
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
	  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::Compiler::art_link: Specify database handler!\n";
	my $dirs=$arg_ref->{'dirs'} or die "PerlPress::Compiler::art_link: Specify directory information!\n";
	my $refdir=$arg_ref->{'refdir'} or die "PerlPress::Compiler::art_link: Specify reference directory!\n";
	my $art_id=$arg_ref->{'art_id'} or die "PerlPress::Compiler::art_link: Specify article id!\n";
	my $text=$arg_ref->{'text'} || "Article $art_id";
	
	my $link="#";
	if (PerlPress::DBAcc::check_art_exist({ dbh=>$dbh, art_id=>$art_id }))
	{
		my $art=PerlPress::DBAcc::load_art_data({ dbh=>$dbh, art_id=>$art_id });
		#$link=$dirs->{'art'}->file($art_id."_".$art->{'alias'}.".html")->relative($refdir);
		$link=$dirs->{'art'}->file($art->{'filename'})->relative($refdir);
	}
	return "<a href=\"$link\">$text</a>";
}

1;
