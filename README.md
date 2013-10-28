# PerlPress

PerlPress is a static web content management system written in the 
programming language Perl. It can be used to build up a blog-style 
website that consists of static files. PerlPress is currently in an 
early development stage.

## Installation

PerlPress is developed using [Dist::Zilla](http://dzil.org). After 
cloning the repository make sure you have Dist::Zilla installed and 
configured. Change to the directory PerlPress/ (here you should find a 
file named dist.ini) and run `dzil install` (you may become sudo first). 
Assuming the installation process ran successfully, you have all 
libraries and executables in place.

Each PerlPress project has a source directory holding the HTML 
template and other stuff. The article content is stored in a MySQL (or 
MariaDB on newer systems) database. Therefore, you have to ensure, 
MySQL or MariaDB is running. PerlPress is capable of accessing a 
database on a remote machine.

## Setting up your project

The directory PerlPress/example holds example files. With these files 
you can set up a minimal project to play with or use them as a 
starting point for your own project.

What you need to set up the example project:

* Create a directory PerlPress/ in your home directory, e.g.:
`mkdir ~/PerlPress/`.
* Copy the sub directory example from the local PerlPress repository
into ~/PerlPress/, e.g.: `cp example/ ~/PerlPress/.`.
* Copy the file ~/PerlPress/example/perlpress.conf to ~/.perlpress.conf 
in your home directory.
* Edit ~/.perlpress.conf to suit your needs. If you have choosen other
directories, change accordingly.
* Ensure your MySQL/MariaDB is running properly. On my Fedora machine
this can be done by the command
`service mysqld status | grep "Active:"`. In the answer line you should
read something like "Active: active (running) since ...".
* Now change to the directory ~/PerlPress/example/db/. Here you find a
file named init_db.sh. Keep the MySQL root's password (may in general 
differ from that of system's root!) at hand and execute the script to
set up the database.

Now, you are finished! You have a complete little example project
defined.

## Start PerlPress

To start PerlPress simply type `perlpress` to the command line. You
should see the PerlPress prompt.

First, open a project by typing `open [project]`. Replace "project" by
the name of the project definition in the config file
~/.perlpress.conf. For the predefined example project "example" the
command would be `open example`. Now, you are asked for the database
password. For the example project type in "test_secret". Don't be
scared, there is no local echo of the password while typing in.

After successful database connection the PerlPress prompt changed an
indicates the connection by an asterisk between the brackets.

Now you can show a list of articles defined. Therefore, type in
`list articles`.

You can edit an existing article. You choose the article by it's 
article ID ("Art ID" in the list). Type in `edit article [id]` and
replace id with the id of the article you wish to edit.

You can also add new articles. Simply type in `new article` and follow
the instructions. You will end up in an editor with a skeleton of all
the article information. **Never change the structure of that file!**
The default editor is GNU nano. You can change the editor in the
system section of ~/.perlpress.conf. In nano you can end editing by
typing Ctrl+x. After editing, check your article is listed properly in
the article list by again typing `list article`.

Finally you can compile the website by typing `make`. The files are put
in a sub directory in the output file (refer to ~/.perlpress.conf). The
sub directory's name format is YYYYDDMM-HHMMSS/.

Other useful commands:

* `rm article [id]` - Delete an article entirely from the database.
Alternatively you can unpublish an article by editing the article and
change the appropriate parameter.
* `list categories` - List all categories defined
* `list tags` - List all tags defined
* `rm (category|tag) [id]` - Delete a category or tag, respectively.
* `new (category|tag) [id]` - Cretae a new category or tag,
respectively.
* `close` - Close project. After that, you can reconnect to a project.
* `quit` - Quit PerlPress.

