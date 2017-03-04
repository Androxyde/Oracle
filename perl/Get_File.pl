#!/usr/bin/perl

#******************************************
# Script to download a file from http
# author : Lylian Meye-Mezu
# Date : 27/11/2012
#******************************************

#importing perl LWP module
use LWP::Simple;

#===============
# Arguments test
#===============
if (scalar(@ARGV) != 3) {
  die("Usage:$0 <server> <filename> <directory> !!! \n" );
}

#=========
#variable
#=========
$nimprod_server= $ARGV[0];
$file_name = $ARGV[1];
$destination_directory = $ARGV[2];

# ----- debug -----
print "nimprod_server=$nimprod_server\n";
print "file_name=$file_name\n";
print "destination_directory=$destination_directory\n";
# -----------------

$file_name=~s/^\/apps\///;  # suppression du '/apps/' du debut
$file_name=~s/^\/+//;       # suppression des '/' du debut
$source_file="http://$nimprod_server:8080/$file_name";

# ----- debug -----
print "source_file=$source_file\n";
# -----------------

$file_name=~s/^.*\///;  # on ne garde que le nom du fichier sans le chemin absolu
$destination_file = "$destination_directory/$file_name";

# ----- debug -----
print "destination_file=$destination_file\n";
# -----------------

$status = getstore($source_file, $destination_file);
print "status=$status\n";

($_, $remote_size) = head($source_file);
$local_size = -s $destination_file;
if ($remote_size != $local_size) {
  print "files size are different; remote file size=$remote_size, downloaded file size=$local_size!!!\n";
  exit 1;
}

if (is_success($status)) {
  print "$source_file downloaded successfully  to $destination_directory !!! \n";
  exit 0;
} else {
  print "HTTP CODE:$status downloading $source_file to $destination_directory !!!\n";
  exit 1;
}
