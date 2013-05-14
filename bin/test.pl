#/bin/perl
use strict;
use constant SLEEPTIME => 5;
use File::Copy;

require "./bin/slcalc.pm";

#set input/output files
my %cfgd =();

getConfig(\%cfgd,"./master/sysconfig.txt");

my %masterdata = ();
readAthMasterData(\%masterdata,$cfgd{'ATHLETE'},$cfgd{'GATENUM'});
#print "name:$masterdata{'101:1'}{'NAME'}\n";

#my %calcdata = ();
readResultData(\%masterdata,$cfgd{'DATAFILE'});

#タイマーでデータロック
my $locknum = lockDataByTime(\%masterdata,300);

#marge Athdata with RaceData
#my @resultdata;
#createAllData(\@resultdata,\%masterdata,\%masterdata);

#
#XML Full ourput
#
#my $xmlMaster = xmlFullOutPut($cfgd{'XMLFULLOUT'},$cfgd{'XSLCONFIG'},\@resultdata);
my $xmlMaster = xmlFullOutPut2($cfgd{'XMLFULLOUT'},$cfgd{'XSLCONFIG'},\%masterdata);

while(-1){
  print STDERR "check e-mail file ";
  #read newdata
  opendir (DH , $cfgd{'INPUTDIR'});
  my @files = readdir(DH);
  my $filenum = 0;
  foreach my $fn (@files){
    $fn = $cfgd{'INPUTDIR'}.$fn;
    if(-f $fn) {
print "Processing:$fn\n";

      emlInputData($fn,$cfgd{'DATAFILE'},$cfgd{'MAILADDRMAP'},\%masterdata,$cfgd{'FIRSTREPORT'});
      $filenum++;

      move $fn,"datalog/$fn";

    }
  }
  closedir DH;

  #タイマーでデータロック
  my $locknum = lockDataByTime(\%masterdata,300);

  if($filenum != 0 || $locknum != 0){
  #XML Full ourput
    my $xmlMaster = xmlFullOutPut2($cfgd{'XMLFULLOUT'},$cfgd{'XSLCONFIG'},\%masterdata);
  }
  for(my $i=SLEEPTIME;$i >0;$i--){
    print STDERR "$i:";
    sleep (1);
  }
  print STDERR "0\n";
}
exit 0;
