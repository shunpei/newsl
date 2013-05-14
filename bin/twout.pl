#!/usr/bin/perluse strict;
use warnings;
use utf8;
use Net::Twitter;
use Encode;
#use Encode::Guess;

#use Encode::Guess qw/euc-jp shift-jis/;

#################################################################
# config ########################################################
#################################################################
use constant FRDIR => "flashresult/";
use constant SLEEPTIME => 6;
my @twkeys=(
  "4lxfRN4tHU0GVOab41zg",
  "0sZQYkv1RS2aVXfIaI05mZTggmklrGckJAkPmDos",
  "278521812-KF3fnsiWJZVOatmOY7GH4FlCSCMANVmptBRvPJ2t",
  "LylluBcTiLKwhwoJEEOh6mWf1Y9mdQZCloRkzp7qw"
  );
#################################################################

while(-1){
  print STDERR "/check File/ ";

  opendir (DH , FRDIR);
  my @files = readdir(DH);
  my $i =0;
#    sleep(3); #連続で更新される場合を考慮し、ちょっと待つ
  foreach my $fn (@files){
    $fn = FRDIR.$fn;
    if(-f $fn) {
      twitteroutfile($fn,\@twkeys);
      $i++;
    }
  }
  closedir DH;

  print STDERR "$i result out\n";
  for(my $i=SLEEPTIME;$i >0;$i -= 2){
    print STDERR "$i:";
    sleep (2);
  }
  print STDERR "0 ";
}
exit 0;

#twitterout("tw1",@twkeys);
#sleep (5);
#twitterout("tw2",@twkeys);
#sleep (5);
#twitterout("tw3",@twkeys);
sub twitteroutfile(){
  my ($filename,$args) = @_;
  open(FH,"<:utf8",$filename);
  while (my $line = <FH>){
    #trim
    $line =~ s/^\s*(.*?)\s*$/$1/;
    #null行、コメント行をスキップ
    if($line eq "" || $line =~ /^#/){
      next;
    }
print STDERR encode("UTF-8","$line\n");
    twitterout($line,$args);
  }
  close FH;
  unlink($filename);
}

sub twitterout(){
  my ($twittline,$keydata) = @_;
  my ($consumer_key,$consumer_secret,$access_token,$access_token_secret) = @$keydata;
#print "$twittline:$consumer_key\n";
#return 0;
  my $twit = Net::Twitter->new(
    traits => [qw/API::REST OAuth WrapError/],
    consumer_key => "$consumer_key",
    consumer_secret => "$consumer_secret",
    ssl => 1,);

  $twit->access_token("$access_token");
  $twit->access_token_secret("$access_token_secret");

#  $twittline = encode('UTF-8',decode('Guess',$twittline));
#  my $guess = guess_encoding($twittline, qw/euc-jp shiftjis/);

#  print $guess->name."\n";
#  print "$twittline\n";

  $twit->update($twittline);
}
