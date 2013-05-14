#/bin/perl
use strict;
use Net::POP3;
use IO::Handle;


#################################################################
# config ########################################################
#################################################################
use constant EMLOUTDIR => "inputdata/";
my @mailcfg=("pop.parkcity.ne.jp","wsn_calc_sys","CanoeSlalome");
use constant SLEEPTIME => 5;
#################################################################

while(-1){
  print "check mail - ";
  mailtofile(EMLOUTDIR,@mailcfg);
  for(my $i=SLEEPTIME;$i >0;$i-=2){
    print STDERR "$i:";
    sleep (2);
  }
  print "0";

}
exit 0;

sub mailtofile(){
  my ($outdir,$server_name,$user_name,$user_pass)=@_;

  # connect pop3 server
  my $objPop3 = eval{ Net::POP3->new($server_name) or die "ERR"; };
  if( !$objPop3 ) {
    if (substr($@,0,3) eq 'ERR') {
      print STDERR "pop3 access error\n";
    } else {
      print STDERR $@;
    }
    exit();
  }

  #login and get message num
  my $mailnum = $objPop3->login($user_name,$user_pass);

  print STDERR "$mailnum message\n";

  if($mailnum == 0){
    $objPop3->quit();
    return 0;
  }

  my $msglist = $objPop3->list();

  foreach my $msgid  ( keys %$msglist  ) {
#    print "ID:$msgid\n";
#  open FH,">$$msgid{$key}";
    my $inFH = $objPop3->getfh($msgid);
    my $ts = time;
    my $i=0;
    while(-e "$outdir$ts.$msgid.$i.eml"){
      $i++;
    }
    my $filename = "$outdir$ts.$msgid.$i.eml";
print "outfile:$filename\n";
    open(OFH,">$filename");
    while ( my $line = <$inFH>) {
      print OFH $line;
    }
    close OFH;
    close $inFH;
    $objPop3->delete($msgid);
  }
  $objPop3->quit();

  return $mailnum;
}
