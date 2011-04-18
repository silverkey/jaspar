#!/usr/bin/perl
use strict;
use warnings;
use DBI;
use LWP;
use HTTP::Request;
use lib '/home/remo/src/TFBS/';
use TFBS::DB::JASPAR5;

# JASPAR DB download from:
# http://jaspar.genereg.net/html/DOWNLOAD/Archive.zip
# to download and install TFBS perl library:
# svn co http://www.ii.uib.no/svn/lenhard/TFBS/
# You need to download the last version from the svn
# because it is more updated than the archive
# You also need to have it installed with make install
# otherwise the code will notbe able to find some modules....

# -------------------------------------------------------
# Database specific settings
# -------------------------------------------------------
my $DB = 'jaspar5'; my $USR = 'mysql_dev'; my $PWD = 'riiGbs'; 

# -------------------------------------------------------
# Download jaspar database using LWP
# SQL tables will be in jaspar5/all_data/sql_tables/
# -------------------------------------------------------
# Create the agent
my $ua = LWP::UserAgent->new;
# Create a request
my $req = HTTP::Request->new(GET => 'http://jaspar.genereg.net/html/DOWNLOAD/Archive.zip');
$req->content_type('application/x-www-form-urlencoded');
$req->content('query=libwww-perl&mode=dist');
# Pass request to the user agent and get a response back
my $res = $ua->request($req);
# Check the outcome of the response
if ($res->is_success) {
  open(OUT,">Archive.zip");
  print OUT $res->content;
  mkdir('jaspar5');
  system('unzip -d jaspar5 Archive.zip');
  chdir('jaspar5/all_data/sql_tables');
}
else {
  die 'ERROR: Cannot download Jaspar: '. $res->status_line, "\n";
}

# -------------------------------------------------------
# Create and populate the jaspar database
# -------------------------------------------------------
my $jaspar = TFBS::DB::JASPAR5->create("dbi:mysql:$DB",$USR,$PWD);
my $dbh = connect_to_db($DB,$USR,$PWD);

my @table = glob('*.txt');
populate_jaspar_table($_,$dbh) foreach @table;

sub populate_jaspar_table {
  my $file = shift;
  my $dbh = shift;
  my $table = "$file";
  $table =~ s/\.txt//;
  my $load = "LOAD DATA LOCAL INFILE '$file' INTO TABLE $table";
  $dbh->do($load);
}

sub connect_to_db {
  my $db = shift;
  my $usr = shift;
  my $pwd = shift;
  my $host = shift;
  my $dsn = 'dbi:mysql:'.$db;
  $dsn .= ':'.$host if $host; # IN THE CURRENT DBI POD VERSION THERE IS THE '@' IN THE PLACE OF ':'
  my $dbh = DBI->connect($dsn,$usr,$pwd,{PrintWarn=>1,PrintError=>1,RaiseError=>1}) or die $DBI::errstr;
  return $dbh;
}
