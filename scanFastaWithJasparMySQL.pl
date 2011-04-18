#!/usr/bin/perl
use strict;
use warnings;
use Bio::SeqIO;
use TFBS::DB::JASPAR5;

my $DB = 'jaspar5';
my $USR = 'mysql_dev';
my $PWD = 'riiGbs';
my $VERTEBRATE = 1;
my $THRESHOLD = '90%';
my $FASTA = 'cnes_rostral_group.fa';

my $db = TFBS::DB::JASPAR5->connect("dbi:mysql:$DB",$USR,$PWD);

my $file = $FASTA;
$file =~ s/\.fasta$//;
$file =~ s/\.fa$//;

my $matrixset;
if($VERTEBRATE == 1) {
  $matrixset = $db->get_MatrixSet(-tax_group => ['vertebrates'], -collection => ['core']);
  $file .= '_jaspar_core_vert.txt'
}
else {
  $matrixset = $db->get_MatrixSet(-collection => ['core']);
  $file .= '_jaspar_core.txt'
}

open(OUT,">$file");
print OUT join("\t",(qw(seqid tfid tfname score strand start end),"\n"));

my $fasta = Bio::SeqIO->new(-file => $FASTA,
                            -format => 'fasta');

while(my $seq = $fasta->next_seq()) {

  my $iterator = $matrixset->Iterator();

  while (my $matrix_object = $iterator->next) {

    my $matrix = $matrix_object->to_PWM();

    my $site_set = $matrix->search_seq(-seqobj => $seq,
                                       -threshold => $THRESHOLD);

    # To retrieve individual sites from $site_set, create an iterator obj:
    my $site_iterator = $site_set->Iterator(-sort_by => "score");

    while (my $site = $site_iterator->next())  {
      my $pattern = $site->pattern;
      my $percent_score = $site->rel_score() * 100;
      $percent_score = sprintf("%.0f", $percent_score);
      print OUT join("\t",($seq->id,$pattern->ID,$pattern->name,$percent_score,$site->strand,$site->start,$site->end,"\n"));
    }
  }
}

__END__

mysql> SELECT DISTINCT VAL, COUNT(*) FROM MATRIX_ANNOTATION WHERE TAG = 'tax_group' GROUP BY VAL;
+--------------+----------+
| VAL          | COUNT(*) |
+--------------+----------+
| fungi        |      177 |
| insects      |      126 |
| mammals      |      174 |
| nematodes    |       24 |
| plants       |       21 |
| urochordates |        1 |
| vertebrates  |      530 |
+--------------+----------+
7 rows in set (0.00 sec)

   get_MatrixSet
        Title   : get_MatrixSet
        Usage   : my $matrixset = $db->get_MatrixSet(%args);
        Function: fetches matrix data under for all matrices in the database
                  matching criteria defined by the named arguments
                  and returns a TFBS::MatrixSet object
        Returns : a TFBS::MatrixSet object
        Args    : This method accepts named arguments, corresponding to arbitrary tags, and also some utility functions
                  Note that this is different from JASPAR2 and to some extent JASPAR4. As any tag is supported for
                  database storage, any tag can be used for information retrieval.
                  Additionally, arguments as 'name','class','collection' can be used (even though
                  they are not tags.
                  Per default, only the last version of the matrix is given. The only way to get older matrices out of this
                  to use an array of IDs with actual versions like MA0001.1, or set the argyment -all_versions=>1, in which  case you get all versions for each stable ID




                 Examples include:
        Fundamental matrix features
               -all # gives absolutely all matrix entry, regardless of versin and collection. Only useful for backup situations and sanity checks. Takes precedence over everything else

               -ID        # a reference to an array of stable IDs (strings), with or without version, as above. tyically something like "MA0001.2" . Takes precedence over everything salve -all
        -name      # a reference to an array of
                              #  transcription factor names (string). Will only take latest version. NOT a preferred way to access since names change over time
                  -collection # a string corresponding to a JASPAR collection. Per default CORE
                  -all_versions # gives all matrix versions that fit with rest of criteria, including obsolete ones.Is off per default.
                                # Typical usage is in combiation with a stable IDs withou versions to get all versinos of a particular matrix
                 Typical tag queries:
               These can be either a string or a reference to an array of strings. If it is an arrau it will be interpreted as as an "or"s statement
                  -class    # a reference to an array of
                              #  structural class names (strings)
                  -species    # a reference to an array of
                              #   NCBI Taxonomy IDs (integers)
                  -taxgroup  # a reference to an array of
                              #  higher taxonomic categories (string)

       Computed features of the matrices           -min_ic     # float, minimum total information content                  #   of the matrix.       -matrixtype    #string describing type of matrix to retrieve. If left out, the
       format
                               will revert to the database format, which is PFM.

       The arguments that expect list references are used in database query formulation: elements within lists are combined with 'OR' operators, and the lists of different types with 'AND'. For example,

           my $matrixset = $db->(-class => ['TRP_CLUSTER', 'FORKHEAD'],
                                 -species => ['Homo sapiens', 'Mus musculus'],
                                 );

       gives a set of TFBS::Matrix::PFM objects (given that the matrix models are stored as such)
        whose (structural clas is 'TRP_CLUSTER' OR'FORKHEAD') AND (the species they are derived
        from is 'Homo sapiens'OR 'Mus musculus').

       As above, unless IDs with version numbers are used, only one matrix per stable ID wil be returned: the matrix with the highest version number

       The -min_ic filter is applied after the query in the sense that the matrices profiles with total information content less than specified are not included in the set.


