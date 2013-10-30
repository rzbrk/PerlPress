use strict;
use warnings;
package PerlPress::DBAcc;
# ABSTRACT: Database access routines of PerlPress

use DBI;
use feature qw{ switch };
use Data::UUID;

=head1 SUBROUTINES/METHODS

=head2 connect_db

Connects to database and returns the database handler. If the connection
attempt is not successfull the routine returns undef.

 my $dbh=PerlPress::DBAcc::connect_db({ host=>$host, db=>$db, usr=>$usr, pwd=>$pwd });

=cut

sub connect_db
{
  # Get a reference to a hash containing the routine's arguments
  my ($arg_ref)=@_;
  
  # Check if all necessary arguments are present
  my $host=$arg_ref->{'host'} || "127.0.0.1";
  my $db=$arg_ref->{'db'} or die "PerlPress::DBAcc::connect_db: Specify name of database!\n";
  my $usr=$arg_ref->{'usr'} or die "PerlPress::DBAcc::connect_db: Specify database user name!\n";
  my $pwd=$arg_ref->{'pwd'} || "";

  # Return database handler. If not successfull this routine should not die
  # but return undef
  my $dbh=DBI->connect("DBI:mysql:database=$db;host=$host",
    $usr, $pwd, {mysql_enable_utf8 => 1}) || undef;

  return $dbh;
}

=head2 disconnect_db

Disconnects from database.

 PerlPress::DBAcc::disconnect_db({ dbh=>$dbh });

=cut

sub disconnect_db
{
  # Get a reference to a hash containing the routine's arguments
  my ($arg_ref)=@_;
  
  # Check if all necessary arguments are present
  my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::disconnect_db: Specify database handler!\n";

  $dbh->disconnect();
}

=head2 status_db

Get the databse connection status.

=cut

sub status_db
{
  # Get a reference to a hash containing the routine's arguments
  my ($arg_ref)=@_;
  
  # Check if all necessary arguments are present
  my $dbh=$arg_ref->{'dbh'} || undef;
  
  my $status=0;
  $status=1 if ($dbh->{'Active'});
  
  return $status;
}

=head2 nav_entries

Returns an ref to an array containing all the article which go into the
navigation menu (type=page|nav).

=cut

sub nav_entries
{
  # Get a reference to a hash containing the routine's arguments
  my ($arg_ref)=@_;
  
  # Check if all necessary arguments are present
  my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::nav_entries: Specify database handler!\n";

  my $sth = $dbh->prepare("SELECT art_id FROM articles
    WHERE (status=\"published\" && (type=\"page\" || type=\"nav\"))");
  $sth->execute() or die "Couldn't execute statement: ".$dbh->errstr;

  my $nav_ids=$sth->fetchall_arrayref([0]);
  
  # $nav_ids is a array ref of array ref. Convert to array
  my @nav_ids2;
  foreach my $a (sort {$a <=> $b} @{$nav_ids})
  {
    push @nav_ids2, @{$a}[0];
  }
  
  # Return the array ref
  return \@nav_ids2;
}

=head2 get_publ_art

Returns a hash reference containing all the published articles. The type
of articles can be specified. Default is to include articles of types
"page" and "blog".

 my $pub_art=PerlPress::DBAcc::get_publ_art({ dbh=>$dbh });
 foreach my $art_id (keys $pub_art)
 {
   print "$pub_art->{$art_id}->{title}\n";
 }

=cut

sub get_publ_art
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;

	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_publ_art: Specify database handler!\n";
	my $page_only=$arg_ref->{'page_only'} || 0;
	my $blog_only=$arg_ref->{'blog_only'} || 0;

	my $type="(type=\"page\" || type=\"blog\")";

	if($page_only!=0 && $blog_only==0) { $type="type=\"page\""; }
	if($page_only==0 && $blog_only!=0) { $type="type=\"blog\""; }
	
	my $sth = $dbh->prepare("SELECT art_id, created FROM articles
	WHERE (status=\"published\" && ".$type.") ORDER BY created DESC");
	$sth->execute() or die "Couldn't execute statement: ".$dbh->errstr;

	# Loop over the results and get the article ids
	my @art_ids;
	while (my $ret=$sth->fetchrow_hashref())
	{
		push @art_ids, $ret->{'art_id'};
	}
	
	return \@art_ids
}

=head2 get_cat_list

Returns a hash ref containing all the categories defined in the
database.

 my $cat=PerlPress::DBAcc::get_cat_list({ dbh=>$dbh });
 foreach my $cat_id (keys $cat)
 {
   print "$cat_id, $cat->{$cat_id}->{cat_name}\n";
 }

=cut

sub get_cat_list
{
  # Get a reference to a hash containing the routine's arguments
  my ($arg_ref)=@_;
  
  # Check if all necessary arguments are present
  my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_cat_list: Specify database handler!\n";

  my $sth = $dbh->prepare("SELECT cat_id, cat_name, alias FROM categories");
  $sth->execute() or die "Couldn't execute statement: ".$dbh->errstr;

  my $cat=$sth->fetchall_hashref("cat_id");

  return $cat;
}

=head2 get_tag_list

Returns a hash ref containing all the tags defined in the
database.

 my $tags=PerlPress::DBAcc::get_tag_list({ dbh=>$dbh });
 foreach my $tag_id (keys $tags)
 {
   print "$tag_id, $tags->{$tag_id}->{tag_name}\n";
 }

=cut

sub get_tag_list
{
  # Get a reference to a hash containing the routine's arguments
  my ($arg_ref)=@_;
  
  # Check if all necessary arguments are present
  my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_tag_list: Specify database handler!\n";

  my $sth = $dbh->prepare("SELECT tag_id, tag_name, alias FROM tags");
  $sth->execute() or die "Couldn't execute statement: ".$dbh->errstr;

  my $tags=$sth->fetchall_hashref("tag_id");

  return $tags;
}

=head2 get_shorts_list

Returns a array ref containing all the HTML shortcuts defined in the
database as a hash ref.

 my $shorts=PerlPress::DBAcc::get_shorts_list({ dbh=>$dbh });
 foreach my $descr (keys $shorts)
 {
   print "$descr, $shorts->{$descr}->{'find'}, $shorts->{$descr}->{'repl'}\n";
 }

=cut

sub get_shorts_list
{
  # Get a reference to a hash containing the routine's arguments
  my ($arg_ref)=@_;
  
  # Check if all necessary arguments are present
  my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_shorts_list: Specify database handler!\n";

  my $sth = $dbh->prepare("SELECT * FROM html_shortcuts");
  $sth->execute() or die "Couldn't execute statement: ".$dbh->errstr;

  my $shorts=$sth->fetchall_arrayref({});

  return $shorts;
}

=head2 get_art_list

Returns a hash ref containing all ids from the article defined in the
database.

 my $art=PerlPress::DBAcc::get_art_id({ dbh=>$dbh });
 foreach my $art_id (keys $art)
 {
   print "$art_id, $art->{$art_id}->{title}\n";
 }

=cut

sub get_art_list
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;

	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_art_list: Specify database handler!\n";

	my $sth = $dbh->prepare("SELECT * FROM articles");
	$sth->execute() or die "Couldn't execute statement: ".$dbh->errstr;

	my $art=$sth->fetchall_hashref("art_id");

	return $art;
}

=head2 check_art_exist

Check if article with given art_id exists in database. Returns 1 if
true, 0 otherwise.

=cut

sub check_art_exist
{
  # Get a reference to a hash containing the routine's arguments
  my ($arg_ref)=@_;
  
  # Check if all necessary arguments are present
  my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::check_art_exist: Specify database handler!\n";
  my $art_id=$arg_ref->{'art_id'} || -1;

  # See: http://stackoverflow.com/questions/6165028/having-an-sql-select-query-how-do-i-get-number-of-items
  my $sth = $dbh->prepare("SELECT COUNT(*) FROM articles WHERE (art_id=?)");
  $sth->execute($art_id) or die "Couldn't execute statement: ".$dbh->errstr;
  
  return $sth->fetchall_arrayref()->[0][0];
}

=head2 check_cat_exist

Check if category with given cat_id exists in database. Returns 1 if
true, 0 otherwise.

=cut

sub check_cat_exist
{
  # Get a reference to a hash containing the routine's arguments
  my ($arg_ref)=@_;
  
  # Check if all necessary arguments are present
  my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::check_cat_exist: Specify database handler!\n";
  my $cat_id=$arg_ref->{'cat_id'} || -1;

  # See: http://stackoverflow.com/questions/6165028/having-an-sql-select-query-how-do-i-get-number-of-items
  my $sth = $dbh->prepare("SELECT COUNT(*) FROM categories WHERE (cat_id=?)");
  $sth->execute($cat_id) or die "Couldn't execute statement: ".$dbh->errstr;
  
  return $sth->fetchall_arrayref()->[0][0];
}

=head2 check_tag_exist

Check if tag with given tag_id exists in database. Returns 1 if
true, 0 otherwise.

=cut

sub check_tag_exist
{
  # Get a reference to a hash containing the routine's arguments
  my ($arg_ref)=@_;
  
  # Check if all necessary arguments are present
  my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::check_tag_exist: Specify database handler!\n";
  my $tag_id=$arg_ref->{'tag_id'} || -1;

  # See: http://stackoverflow.com/questions/6165028/having-an-sql-select-query-how-do-i-get-number-of-items
  my $sth = $dbh->prepare("SELECT COUNT(*) FROM tags WHERE (tag_id=?)");
  $sth->execute($tag_id) or die "Couldn't execute statement: ".$dbh->errstr;
  
  return $sth->fetchall_arrayref()->[0][0];
}

=head2 check_short_exist

Check if HTML shortcut with given tag_id exists in database. Returns 1
if true, 0 otherwise.

=cut

sub check_short_exist
{
  # Get a reference to a hash containing the routine's arguments
  my ($arg_ref)=@_;
  
  # Check if all necessary arguments are present
  my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::check_short_exist: Specify database handler!\n";
  my $short_id=$arg_ref->{'short_id'} || -1;

  # See: http://stackoverflow.com/questions/6165028/having-an-sql-select-query-how-do-i-get-number-of-items
  my $sth = $dbh->prepare("SELECT COUNT(*) FROM html_shortcuts WHERE (short_id=?)");
  $sth->execute($short_id) or die "Couldn't execute statement: ".$dbh->errstr;
  
  return $sth->fetchall_arrayref()->[0][0];
}

=head2 load_art_data

Load the article data for a single article defined by its article id
(art_id).

 my $art=PerlPress::DBAcc::load_art_data({ dbh=>$dbh, art_id=>"1" });
 print "$art->{title}\n" if defined $art;

=cut

sub load_art_data
{
  # Get a reference to a hash containing the routine's arguments
  my ($arg_ref)=@_;
  
  # Check if all necessary arguments are present
  my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::load_art_data: Specify database handler!\n";
  my $art_id=$arg_ref->{'art_id'} or die "PerlPress::DBAcc::load_art_data: Specify article id!\n";
  
  # Load the article data from table `articles` and `art_persist`
  my $sth = $dbh->prepare("SELECT * FROM articles WHERE (art_id=?)");
  $sth->execute($art_id)
    or die "Couldn't execute statement: ".$dbh->errstr;
  
  my $art=$sth->fetchrow_hashref();
  
  return $art;
}

=head2 load_short_data

Load the HTML shortcut data for a single shortcut defined by its id
(short_id).

 my $short=PerlPress::DBAcc::load_short_data({ dbh=>$dbh, short_id=>"1" });
 print "$short->{'descr'}\n" if defined $short;

=cut

sub load_short_data
{
  # Get a reference to a hash containing the routine's arguments
  my ($arg_ref)=@_;
  
  # Check if all necessary arguments are present
  my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::load_short_data: Specify database handler!\n";
  my $short_id=$arg_ref->{'short_id'} or die "PerlPress::DBAcc::load_short_data: Specify shortcut id!\n";
  
  my $sth = $dbh->prepare("SELECT * FROM html_shortcuts WHERE (short_id=?)");
  $sth->execute($short_id)
    or die "Couldn't execute statement: ".$dbh->errstr;
  
  my $short=$sth->fetchrow_hashref();
  
  return $short;
}

=head2 new_art

Create a new blank article with default entries in the database and
return its article id.

=cut

sub new_art
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::new_art: Specify database handler!\n";
		
	# Save information in table articles
	my $sth = $dbh->prepare("INSERT INTO articles (title,
												   subtitle,
												   author,
												   intr_text,
												   full_text,
												   created,
												   modified,
												   type,
												   link,
												   status,
												   notes,
												   featured)
							 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

	$sth->execute("Article title",					# title
  				  "Article subtitle",				# subtitle
  				  $ENV{'AUTHOR'},					# author
													# intr_text
  				  "<p>This text will be displayed in short view. You can use HTML.</p>",
													#  full_text
  				  "<p>This text is only visible in full view of article.</p>",
  				  PerlPress::Tools::now(),			# created
  				  PerlPress::Tools::now(),			# modified
  				  "blog",							# type
  				  "",								# link (only for type=nav !)
  				  "draft",							# status
													# notes
  				  "Insert your notes here. Will not be published.",
  				  "no"								# featured
  			     ) or die "Couldn't execute statement: ".$dbh->errstr;

	# Now, we need the article ID of the new article.
	# See: http://www.cgicorner.ch/tutor/12_mysql.shtml
	my $art_id=$dbh->{'mysql_insertid'};

	# Each article has persistent information. These information (like
	# filename or UUID) are deduced and saved to the database, when the
	# user first entered the article data. Hence, this is not done here
	# (as the new article has now only dummy data), but when the routine
	# update_art() is called the first time.
	
	return $art_id;
}

=head2 new_short

Create a new HTML shortcut with default entries in the database and
return its shortcut id.

=cut

sub new_short
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::new_art: Specify database handler!\n";
		
	# Save information in table html_shortcuts
	my $sth = $dbh->prepare("INSERT INTO html_shortcuts (descr,
												   find,
												   repl,
												   enabled)
							 VALUES (?, ?, ?, ?)");

	$sth->execute("New shortcut",					# title
  				  "",								# find pattern
  				  "",								# replace pattern
  				  "no"								# enabled
  			     ) or die "Couldn't execute statement: ".$dbh->errstr;

	# Now, we need the shortcut ID of the shortcut.
	# See: http://www.cgicorner.ch/tutor/12_mysql.shtml
	my $short_id=$dbh->{'mysql_insertid'};
	
	return $short_id;
}

=head new_cat

Creates a new category in the database.

=cut

sub new_cat
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::new_cat: Specify database handler!\n";
	my $cat_name=$arg_ref->{'cat_name'} or die "PerlPress::DBAcc::new_cat: Specify category name!\n";
	
	my $sth = $dbh->prepare("INSERT INTO categories (cat_name, alias) VALUES (?, ?)");
	$sth->execute($cat_name,
	              PerlPress::Tools::title2link({ title=>$cat_name, max_length=>$ENV{'MAX_LEN_LINK'} }))
	  or die "Couldn't execute statement: ".$dbh->errstr;
	
	# Now, we need the category ID of the new category.
	# See: http://www.cgicorner.ch/tutor/12_mysql.shtml
	my $cat_id=$dbh->{'mysql_insertid'};
	
	return $cat_id;
}

=head new_tag

Creates a new tag in the database.

=cut

sub new_tag
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::new_tag: Specify database handler!\n";
	my $tag_name=$arg_ref->{'tag_name'} or die "PerlPress::DBAcc::new_tag: Specify tag name!\n";
	
	my $sth = $dbh->prepare("INSERT INTO tags (tag_name, alias) VALUES (?, ?)");
	$sth->execute($tag_name,
				  PerlPress::Tools::title2link({ title=>$tag_name, max_length=>$ENV{'MAX_LEN_LINK'} }))
	  or die "Couldn't execute statement: ".$dbh->errstr;
	
	# Now, we need the tag ID of the new tag.
	# See: http://www.cgicorner.ch/tutor/12_mysql.shtml
	my $tag_id=$dbh->{'mysql_insertid'};
	
	return $tag_id;
}

=head2 update_art

Update article information in database.

=cut

sub update_art
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::update_art: Specify database handler!\n";
	my $art=$arg_ref->{'art'} or die "PerlPress::DBAcc::update_art: Specify article data!\n";
		
	# Update article data in table articles
	my $sth = $dbh->prepare("UPDATE LOW_PRIORITY articles
  						     SET title = ?,
						       subtitle = ?,
						       author = ?,
						       intr_text = ?,
						       full_text = ?,
						       created = ?,
						       modified = ?,
						       type = ?,
						       link = ?,
						       status = ?,
						       notes = ?
						     WHERE art_id = ?");
	
	$sth->execute($art->{'title'},
  				  $art->{'subtitle'},
  				  $art->{'author'},
  				  $art->{'intr_text'},
  				  $art->{'full_text'},
  				  $art->{'created'},
  				  $art->{'modified'},
  				  $art->{'type'},
  				  $art->{'link'},
  				  $art->{'status'},
  				  $art->{'notes'},
  				  $art->{'art_id'}
  			     ) or die "Couldn't execute statement: ".$dbh->errstr;

	# Create persistent article data (alias, filename, uuid) if not yet
	# set (=empty). Persistent data is deduced from other article data
	# (namely the id and title). If an article is newly created before
	# first user input, these data fields are left open. During first
	# "article data update" with the first user inputs, the persistent
	# data has to be created. If data is already set, leave it
	# untouched, even if title or any other data changes:
	my $sth2=$dbh->prepare("SELECT COUNT(*) FROM articles WHERE (art_id=? AND uuid=\"\")");
	$sth2->execute($art->{'art_id'})
	  or die "Couldn't execute statement: ".$dbh->errstr;
	if ($sth2->fetchall_arrayref()->[0][0])
	{
		my $alias=PerlPress::Tools::title2link({ title=>$art->{'title'},
												 max_length=>$ENV{'MAX_LEN_LINK'} });
		my $filename=$art->{'art_id'}."_".$alias.".html";
		my $ug = new Data::UUID;
		my $uuid=$ug->create_from_name_str($ENV{'BASE_URL'}, $filename);
		my $sth3=$dbh->prepare("UPDATE LOW_PRIORITY `articles` \n
		  SET alias = ?,
		    filename = ?,
		    uuid = ?
		  WHERE art_id = ?");
		$sth3->execute($alias, $filename, $uuid, $art->{'art_id'})
		  or die "Couldn't execute statement: ".$dbh->errstr;
	}

	# Categories
	$sth=$dbh->prepare("DELETE FROM art_cat WHERE art_id=?");
	$sth->execute($art->{'art_id'}) or die "Couldn't execute statement: ".$dbh->errstr;
	
	my @cat_names=@{$art->{'cat_names'}};
	my @cat_ids=@{$art->{'cat_ids'}};

	foreach my $c (0 .. $#cat_names)
	{
		if ($cat_ids[$c]==-1) # Unexisting category
		{
			# Create category
			my $cat_alias=PerlPress::Tools::title2link({ title=>$cat_names[$c], max_length=>$ENV{'MAX_LEN_LINK'} });
			$sth=$dbh->prepare("INSERT INTO categories (cat_name, alias) VALUES (?, ?)");
			$sth->execute($cat_names[$c], $cat_alias) or die "Couldn't execute statement: ".$dbh->errstr;
			# Now, we need the category ID of the new category
			# See: http://www.cgicorner.ch/tutor/12_mysql.shtml
			$cat_ids[$c]=$dbh->{'mysql_insertid'};
		}
		
		# Link the article to the category
		$sth=$dbh->prepare("INSERT INTO art_cat (art_id, cat_id) VALUES (?, ?)");
		$sth->execute($art->{'art_id'}, $cat_ids[$c]) or die "Couldn't execute statement: ".$dbh->errstr;
	}
	
	# Tags
	$sth=$dbh->prepare("DELETE FROM art_tag WHERE art_id=?");
	$sth->execute($art->{'art_id'}) or die "Couldn't execute statement: ".$dbh->errstr;
	
	my @tag_names=@{$art->{'tag_names'}};
	my @tag_ids=@{$art->{'tag_ids'}};

	foreach my $t (0 .. $#tag_names)
	{
		if ($tag_ids[$t]==-1) # Unexisting tag
		{
			# Create tag
			my $tag_alias=PerlPress::Tools::title2link({ title=>$tag_names[$t], max_length=>$ENV{'MAX_LEN_LINK'} });
			$sth=$dbh->prepare("INSERT INTO tags (tag_name, alias) VALUES (?, ?)");
			$sth->execute($tag_names[$t], $tag_alias) or die "Couldn't execute statement: ".$dbh->errstr;
			# Now, we need the tag ID of the new tag
			# See: http://www.cgicorner.ch/tutor/12_mysql.shtml
			$tag_ids[$t]=$dbh->{'mysql_insertid'};
		}
		
		# Link the article to the tag
		$sth=$dbh->prepare("INSERT INTO art_tag (art_id, tag_id) VALUES (?, ?)");
		$sth->execute($art->{'art_id'}, $tag_ids[$t]) or die "Couldn't execute statement: ".$dbh->errstr;
	}
}

=head2 update_short

Update HTML shortcut information in database.

=cut

sub update_short
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::update_short: Specify database handler!\n";
	my $short=$arg_ref->{'short'} or die "PerlPress::DBAcc::update_short: Specify shortcut data!\n";
		
	# Update HTML shortcut data in table html_shortcuts
	my $sth = $dbh->prepare("UPDATE LOW_PRIORITY html_shortcuts
  						     SET descr = ?,
						       find = ?,
						       repl = ?,
						       enabled = ?
						     WHERE short_id = ?");
	
	$sth->execute($short->{'descr'},
  				  $short->{'find'},
  				  $short->{'repl'},
  				  $short->{'enabled'},
  				  $short->{'short_id'}
  			     ) or die "Couldn't execute statement: ".$dbh->errstr;
}

=head2 update_cat

Update category information in database.

=cut

sub update_cat
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::update_cat: Specify database handler!\n";
	my $cat=$arg_ref->{'cat'} or die "PerlPress::DBAcc::update_cat: Specify category data!\n";
		
	# Update category data in table categories
	my $sth = $dbh->prepare("UPDATE LOW_PRIORITY categories
  						     SET cat_name = ?, alias = ? WHERE cat_id = ?");
	
	$sth->execute($cat->{'cat_name'},
				  PerlPress::Tools::title2link({ title=>$cat->{'cat_name'}, max_length=>$ENV{'MAX_LEN_LINK'} }),
  				  $cat->{'cat_id'}
  			     ) or die "Couldn't execute statement: ".$dbh->errstr;
}

=head2 update_tag

Update tag information in database.

=cut

sub update_tag
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::update_tag: Specify database handler!\n";
	my $tag=$arg_ref->{'tag'} or die "PerlPress::DBAcc::update_tag: Specify tag data!\n";
		
	# Update category data in table tags
	my $sth = $dbh->prepare("UPDATE LOW_PRIORITY tags
  						     SET tag_name = ?, alias = ? WHERE tag_id = ?");
	
	$sth->execute($tag->{'tag_name'},
				  PerlPress::Tools::title2link({ title=>$tag->{'tag_name'}, max_length=>$ENV{'MAX_LEN_LINK'} }),
  				  $tag->{'tag_id'}
  			     ) or die "Couldn't execute statement: ".$dbh->errstr;
}

=head2 get_art_cat_ids

Returns an ref to an array containing all the category ids of those
categories an article is linked to. The article has to be defined by
its article id (art_id).

 my @art_cat_ids=@{PerlPress::DBAcc::get_art_cat_ids({ dbh=>$dbh, art_id=>$art_id })};
 foreach my $c (@art_cat_ids)
 {
   print "$c\n";
 }

=cut

sub get_art_cat_ids
{
  # Get a reference to a hash containing the routine's arguments
  my ($arg_ref)=@_;
  
  # Check if all necessary arguments are present
  my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_art_cat_ids: Specify database handler!\n";
  my $art_id=$arg_ref->{'art_id'} or die "PerlPress::DBAcc::get_art_cat_ids: Specify article id!\n";
  
  my $sth = $dbh->prepare("SELECT cat_id FROM art_cat WHERE (art_id=?)");
  $sth->execute($art_id)
    or die "Couldn't execute statement: ".$dbh->errstr;
  
  my $cat_ids=$sth->fetchall_arrayref([0]);
  
  # $cat_ids is a array ref of array ref. Convert to array
  my @cat_ids2;
  foreach my $c (@{$cat_ids})
  {
    push @cat_ids2, @{$c}[0];
  }
  
  # Return the array ref
  return \@cat_ids2;
}

=head2 get_cat_name

Get the category name by cat_id.

=cut

sub get_cat_name
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_cat_name: Specify database handler!\n";
	my $cat_id=$arg_ref->{'cat_id'} or die "PerlPress::DBAcc::get_cat_name: Specify cat id!\n";
	
	my @cat_names;
	my $sth;
	foreach my $id (@{$cat_id})
	{
		$sth = $dbh->prepare("SELECT cat_name FROM categories WHERE (cat_id=?)");
		$sth->execute($id)
		  or die "Couldn't execute statement: ".$dbh->errstr;
		my $name=$sth->fetchrow_hashref();
		push @cat_names, $name->{'cat_name'};
	}
	return \@cat_names;
}

=head2 get_cat_alias

Get the category alias by cat_id.

=cut

sub get_cat_alias
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_cat_alias: Specify database handler!\n";
	my $cat_id=$arg_ref->{'cat_id'} or die "PerlPress::DBAcc::get_cat_alias: Specify cat id!\n";
	
	my @cat_alias;
	my $sth;
	foreach my $id (@{$cat_id})
	{
		$sth = $dbh->prepare("SELECT alias FROM categories WHERE (cat_id=?)");
		$sth->execute($id)
		  or die "Couldn't execute statement: ".$dbh->errstr;
		my $alias=$sth->fetchrow_hashref();
		push @cat_alias, $alias->{'alias'};
	}
	return \@cat_alias;
}

=head2 get_tag_alias

Get the tag alias by tag_id.

=cut

sub get_tag_alias
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_tag_alias: Specify database handler!\n";
	my $tag_id=$arg_ref->{'tag_id'} or die "PerlPress::DBAcc::get_tag_alias: Specify cat id!\n";
	
	my @tag_alias;
	my $sth;
	foreach my $id (@{$tag_id})
	{
		$sth = $dbh->prepare("SELECT alias FROM tags WHERE (tag_id=?)");
		$sth->execute($id)
		  or die "Couldn't execute statement: ".$dbh->errstr;
		my $alias=$sth->fetchrow_hashref();
		push @tag_alias, $alias->{'alias'};
	}
	return \@tag_alias;
}

=head2 get_tag_name

Get the tag name by tag_id.

=cut

sub get_tag_name
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_tag_name: Specify database handler!\n";
	my $tag_id=$arg_ref->{'tag_id'} or die "PerlPress::DBAcc::get_tag_name: Specify cat id!\n";
	
	my @tag_names;
	my $sth;
	foreach my $id (@{$tag_id})
	{
		$sth = $dbh->prepare("SELECT tag_name FROM tags WHERE (tag_id=?)");
		$sth->execute($id)
		  or die "Couldn't execute statement: ".$dbh->errstr;
		my $name=$sth->fetchrow_hashref();
		push @tag_names, $name->{'tag_name'};
	}
	return \@tag_names;
}

=head2 get_short_descr

Get the description of a HTML shortcut given by its shortcut id.

=cut

sub get_short_descr
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_short_descr: Specify database handler!\n";
	my $short_id=$arg_ref->{'short_id'} or die "PerlPress::DBAcc::get_short_descr: Specify shortcut id!\n";
	
	my $sth = $dbh->prepare("SELECT descr FROM html_shortcuts WHERE (short_id=?)");
	$sth->execute($short_id) or die "Couldn't execute statement: ".$dbh->errstr;
	$sth->fetchrow_hashref();
	return $sth->{'descr'};
}

=head2 get_cat_id

Get the category id by cat_name. If the category does not exist,
return -1.

=cut

sub get_cat_id
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_cat_id: Specify database handler!\n";
	my $cat_name=$arg_ref->{'cat_name'} or die "PerlPress::DBAcc::get_cat_id: Specify cat name!\n";
	
	my @cat_ids;
	my $sth;
	my $ex;
	foreach my $name (@{$cat_name})
	{
		# First, check if category with $name exists in database
		$sth = $dbh->prepare("SELECT COUNT(*) FROM categories WHERE (cat_name=?)");
		$sth->execute($name)
		  or die "Couldn't execute statement: ".$dbh->errstr;
		# If category exist then $ex=1, else $ex=0
		$ex=$sth->fetchall_arrayref()->[0][0];
		if ($ex)
		{
			$sth = $dbh->prepare("SELECT cat_id FROM categories WHERE (cat_name=?)");
			$sth->execute($name)
			  or die "Couldn't execute statement: ".$dbh->errstr;
			my $id=$sth->fetchrow_hashref();
			push @cat_ids, $id->{'cat_id'};
		} else
		{
			push @cat_ids, -1;
		}
	}
	return \@cat_ids;
}

=head2 get_art_tag_ids

Returns an ref to an array containing all the tag ids of those
tags an article is linked to. The article has to be defined by
its article id (art_id).

 my @art_tag_ids=@{PerlPress::DBAcc::get_art_tag_ids({ dbh=>$dbh, art_id=>$art_id })};
 foreach my $c (@art_tag_ids)
 {
   print "$c\n";
 }

=cut

sub get_art_tag_ids
{
  # Get a reference to a hash containing the routine's arguments
  my ($arg_ref)=@_;
  
  # Check if all necessary arguments are present
  my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_art_tag_ids: Specify database handler!\n";
  my $art_id=$arg_ref->{'art_id'} or die "PerlPress::DBAcc::get_art_tag_ids: Specify article id!\n";
  
  my $sth = $dbh->prepare("SELECT tag_id FROM art_tag WHERE (art_id=?)");
  $sth->execute($art_id)
    or die "Couldn't execute statement: ".$dbh->errstr;
  
  my $tag_ids=$sth->fetchall_arrayref([0]);
  
  # $tag_ids is a array ref of array ref. Convert to array
  my @tag_ids2;
  foreach my $c (@{$tag_ids})
  {
    push @tag_ids2, @{$c}[0];
  }
  
  # Return the array ref
  return \@tag_ids2;
}

#=head2 get_tag_name

#Get the tag name by tag_id.

#=cut

#sub get_tag_name
#{
	## Get a reference to a hash containing the routine's arguments
	#my ($arg_ref)=@_;
  
	## Check if all necessary arguments are present
	#my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_tag_name: Specify database handler!\n";
	#my $tag_id=$arg_ref->{'tag_id'} or die "PerlPress::DBAcc::get_tag_name: Specify tag id!\n";
	
	#my @tag_names;
	#my $sth;
	#foreach my $id (@{$tag_id})
	#{
		#$sth = $dbh->prepare("SELECT tag_name FROM tags WHERE (tag_id=?)");
		#$sth->execute($id)
		  #or die "Couldn't execute statement: ".$dbh->errstr;
		#my $name=$sth->fetchrow_hashref();
		#push @tag_names, $name->{'tag_name'};
	#}
	#return \@tag_names;
#}

=head2 get_tag_id

Get the tag id by tag_name. If the tag does not exist, return -1.

=cut

sub get_tag_id
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_tag_id: Specify database handler!\n";
	my $tag_name=$arg_ref->{'tag_name'} or die "PerlPress::DBAcc::get_tag_id: Specify tag name!\n";
	
	my @tag_ids;
	my $sth;
	my $ex;
	foreach my $name (@{$tag_name})
	{
		# First, check if tag with $name exists in database
		$sth = $dbh->prepare("SELECT COUNT(*) FROM tags WHERE (tag_name=?)");
		$sth->execute($name)
		  or die "Couldn't execute statement: ".$dbh->errstr;
		# If tag exist then $ex=1, else $ex=0
		$ex=$sth->fetchall_arrayref()->[0][0];
		if ($ex)
		{
			$sth = $dbh->prepare("SELECT tag_id FROM tags WHERE (tag_name=?)");
			$sth->execute($name)
			  or die "Couldn't execute statement: ".$dbh->errstr;
			my $id=$sth->fetchrow_hashref();
			push @tag_ids, $id->{'tag_id'};
		} else
		{
			push @tag_ids, -1;
		}
	}
	return \@tag_ids;
}

=head2 rm_cat

Delete a category from the database.

=cut

sub rm_cat
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::rm_cat: Specify database handler!\n";
	my $cat_id=$arg_ref->{'cat_id'} or die "PerlPress::DBAcc::rm_cat: Specify category id!\n";
	
	# Delete from table categories
	my $sth=$dbh->prepare("DELETE FROM categories WHERE cat_id=?");
	$sth->execute($cat_id) or die "Couldn't execute statement: ".$dbh->errstr;
	
	# Delete from table art_cat
	$sth=$dbh->prepare("DELETE FROM art_cat WHERE cat_id=?");
	$sth->execute($cat_id) or die "Couldn't execute statement: ".$dbh->errstr;
}

=head2 rm_tag

Delete a tag from the database.

=cut

sub rm_tag
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::rm_tag: Specify database handler!\n";
	my $tag_id=$arg_ref->{'tag_id'} or die "PerlPress::DBAcc::rm_tag: Specify tag id!\n";
	
	# Delete from table tags
	my $sth=$dbh->prepare("DELETE FROM tags WHERE tag_id=?");
	$sth->execute($tag_id) or die "Couldn't execute statement: ".$dbh->errstr;
	
	# Delete from table art_tag
	$sth=$dbh->prepare("DELETE FROM art_tag WHERE tag_id=?");
	$sth->execute($tag_id) or die "Couldn't execute statement: ".$dbh->errstr;
}

=head2 rm_short

Delete a HTML shortcut from the database.

=cut

sub rm_short
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::rm_short: Specify database handler!\n";
	my $short_id=$arg_ref->{'short_id'} or die "PerlPress::DBAcc::rm_short: Specify shortcut id!\n";
	
	# Delete from table html_shortcuts
	my $sth=$dbh->prepare("DELETE FROM html_shortcuts WHERE short_id=?");
	$sth->execute($short_id) or die "Couldn't execute statement: ".$dbh->errstr;
}

=head2 rm_art

Delete an article from the database.

=cut

sub rm_art
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::rm_art: Specify database handler!\n";
	my $art_id=$arg_ref->{'art_id'} or die "PerlPress::DBAcc::rm_art: Specify article id!\n";
	
	# Delete from table articles
	my $sth=$dbh->prepare("DELETE FROM articles WHERE art_id=?");
	$sth->execute($art_id) or die "Couldn't execute statement: ".$dbh->errstr;
	
	# Delete from table art_cat
	$sth=$dbh->prepare("DELETE FROM art_cat WHERE art_id=?");
	$sth->execute($art_id) or die "Couldn't execute statement: ".$dbh->errstr;
	
	# Delete from table art_tag
	$sth=$dbh->prepare("DELETE FROM art_tag WHERE art_id=?");
	$sth->execute($art_id) or die "Couldn't execute statement: ".$dbh->errstr;
}

=head2 get_art_list_by_cat


=cut

sub get_art_list_by_cat
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_art_list_by_cat: Specify database handler!\n";
	my $cat_id=$arg_ref->{'cat_id'} or die "PerlPress::DBAcc::get_art_list_by_cat: Specify category id!\n";
	
	my $sth=$dbh->prepare("SELECT t1.art_id FROM articles AS t1 INNER JOIN
		art_cat AS t2 ON t1.art_id = t2.art_id WHERE t2.cat_id
		= ? AND (t1.type='blog' OR t1.type='page') AND t1.status='published'
		ORDER BY t1.created DESC");
	$sth->execute($cat_id) or die "Couldn't execute statement: ".$dbh->errstr;
	
	my @art_ids;
	while (my $ret=$sth->fetchrow_hashref())
	{
		push @art_ids, $ret->{'art_id'};
	}
	
	return \@art_ids
}

=head2 get_art_list_by_tag


=cut

sub get_art_list_by_tag
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_art_list_by_tag: Specify database handler!\n";
	my $tag_id=$arg_ref->{'tag_id'} or die "PerlPress::DBAcc::get_art_list_by_tag: Specify tag id!\n";
	
	my $sth=$dbh->prepare("SELECT t1.art_id FROM articles AS t1 INNER JOIN
		art_tag AS t2 ON t1.art_id = t2.art_id WHERE t2.tag_id
		= ? AND (t1.type='blog' OR t1.type='page') AND t1.status='published'
		ORDER BY t1.created DESC");
	$sth->execute($tag_id) or die "Couldn't execute statement: ".$dbh->errstr;
	
	my @art_ids;
	while (my $ret=$sth->fetchrow_hashref())
	{
		push @art_ids, $ret->{'art_id'};
	}
	
	return \@art_ids
}

=head2 get_html_shortcuts

Get the HTML shortcut definitions from the database

=cut

sub get_html_shortcuts
{
	# Get a reference to a hash containing the routine's arguments
	my ($arg_ref)=@_;
  
	# Check if all necessary arguments are present
	my $dbh=$arg_ref->{'dbh'} or die "PerlPress::DBAcc::get_html_shortcuts: Specify database handler!\n";

	my $sth=$dbh->prepare("SELECT * FROM html_shortcuts");
	$sth->execute() or die "Couldn't execute statement: ".$dbh->errstr;
	
	return $sth->fetchall_hashref("descr");
}

1;
