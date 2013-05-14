#/bin/perl
use utf8;

use XML::Simple;
use XML::DOM;
#use Encode;
#use Encode::Guess;
#use Encode::Guess qw/euc-jp shift-jis /;
#use Net::POP3;
use MIME::Parser;
use HTTP::Date; 
use Jcode;


use constant MAXGATENUM => 30;

sub getConfig(){
  my ($dahaHash,$filename)= @_;

  #set default
  $$dahaHash{'ATHLETE'}='master/ath_config.txt';
  $$dahaHash{'MAILADDRMAP'}='master/mailmap.txt';
  $$dahaHash{'DATAFILE'}='result/resultdata.txt';
  $$dahaHash{'CSVFULLOUT'}='output/calcdata.out.csv';
  $$dahaHash{'HTMLFULLOUT'}='output/calcdata.out.html';
  $$dahaHash{'XMLFULLOUT'}='output/calcdata.out.xml';
  $$dahaHash{'XSLCONFIG'}='master/xslconfig.txt';
  $$dahaHash{'INPUTDIR'}='inputdata/';
  $$dahaHash{'GATENUM'}='25';

  open (FH,$filename);
  while (my $line = <FH>){
    #trim
    $line =~ s/^\s*(.*?)\s*$/$1/;
    #null行、コメント行をスキップ
    if($line eq "" || $line =~ /^#/){
      next;
    }
    my @list = split(/,/,$line);
    #csvからダブルクォートを削除
    foreach my $data(@list){
      $data =~ s/^\"(.*)\"$/$1/;
    }
    my $key = @list[0];
    $$dahaHash{"$key"} = "@list[1]";
  }
  close (FH);

  return 0;
}

#
#出場者情報の読み込み
#
sub readAthMasterData(){
  my ($dataHash,$filename,$gatenum)= @_;

  my $pengate = "";
#print STDERR "G:$gatenum\n";
  for($i=0;$i < $gatenum;$i++){
    my $astr = ($i % 5 == 0)?" -":"-";
    $pengate = "$pengate$astr";
  }
  $pengate =~ s/^\s//;

  open (FH,$filename);
  while (my $line = <FH>){
    #trim
    $line =~ s/^\s*(.*?)\s*$/$1/;
    #null行、コメント行をスキップ
    if($line eq "" || $line =~ /^#/){
      next;
    }
print STDERR "DEF:$line\n";
    my @list = split(/,/,$line);
    #csvからダブルクォートを削除
    foreach my $data(@list){
      $data =~ s/^\"(.*)\"$/$1/;
    }
    my $zn = "@list[1]:@list[5]";
    $$dataHash{$zn}{'START'} = @list[0];
    $$dataHash{$zn}{'NAME'}  = @list[2];
    $$dataHash{$zn}{'CLUB'}  = @list[3];
    $$dataHash{$zn}{'CLASS'} = @list[4];
    $$dataHash{$zn}{'PENGATE'} = $pengate;
  }
  close (FH);
  return 0;
}

#
#既存のリザルトデータを読み込む。
#
sub readResultData(){
  my ($dataHash,$filename) = @_;

  my $flgs = 0;
  my $flgg = 0;

  open (FH,$filename);
  while (my $line = <FH>){
    #trim
    $line =~ s/^\s*(.*?)\s*$/$1/;
    #null行、コメント行をスキップ
    if($line eq "" || $line =~ /^#/){
      next;
    }
    if(setResultLine($line,$dataHash) <0 ){
      print STDERR "$line\n";
    }
  }
  close (FH);
  return 0;
}
#
#eml形式のファイルデータを追加する。
#
sub emlInputData{
  my ($emlfilename,$datafilename,$mailmapfilename,$resHash,$firstreportfolder) = @_;

  my $tmpdir = "./tmp";
#print "file:'$emlfilename'\n";
  my $parser = MIME::Parser->new;
  if( !(-d $tmpdir )){
    mkdir $tmpdir;
  }
  $parser->output_dir($tmpdir);

  open FH,$emlfilename;
  my $entity = $parser->parse(*FH);
  close FH;

  my %mailmap;
#print "mailfile:$mailmapfilename\n";
  open FH,$mailmapfilename;
  while (my $line = <FH>){
#print "line:$line\n";
    #trim
    $line = jcode($line)->tr('Ａ-Ｚａ-ｚ０-９＠?','A-Za-z0-9@-');
    $line =~ s/^\s*(.*?)\s*$/$1/;
    $line =~ s/^\s\s$/\s/g;
    #null行、コメント行をスキップ
    if($line eq "" || $line =~ /^#/){
      next;
    }
    my ($mailaddr,$target,$datalength) = split(/,/,$line);
    $mailmap{$mailaddr}{'TARGET'} = $target;
    $mailmap{$mailaddr}{'DATALENGTH'} = $datalength;
#print "$mailaddr - $mailmap{$mailaddr}{'TARGET'}\n";
  }
  close FH;

  my $header = $entity->head;

  my $from = $header->get('From');
  $from =~ s/^\s*(.*?)\s*$/$1/;
  if($from =~ m/^(.*)\<(.*)\>\s*$/){
    $from =~ s/^(.*)\<(.*)\>\s*$/$2/;
  }
  my $subject = $header->get('Subject');
  $subject =~ s/\s$//;
  my $race = $subject;
  $race =~ s/(.*):(.*)/$1/;
  my $datestr = $header->get('Date');
  $datestr =~ s/^\s*(.*?)\s*$/$1/;
  my $datetime = str2time($datestr);
#  $datetime =~ s/\s*$//;
#  $datetime = str2time($datetime);

#  my $body = $entity->bodyhandle->as_string;
  my $body_entity = ($entity->is_multipart) ? $entity->parts(0) : $entity;
  my $body = $body_entity->bodyhandle->as_string;

#print "from:'$from'\n";
#print "Sbj :'$race'\n";
#print "Date:'$datetime'\n";
#print "Body:'$body'\n";
print "maildata:$datestr\n";
print "maildata:$from/$race/$datestr\n";
  
  my @bodyline = split('\n',$body);
  foreach $line (@bodyline){

    $line =~ s/^\s*(.*?)\s*$/$1/;
    #null行、コメント行をスキップ
    if($line eq "" || $line =~ /^#/){
      next;
    }

    my @dataline;
    my @data = split(/ /,$line);

    if($line =~ /^E/i){
      #E(ND) で読み込み終了
      last;
    }elsif(@data == 2){
      #データ数が２の場合は、mailMAPを参照して、追加。
      if(exists $mailmap{$from}){
        unshift(@data, $mailmap{$from}{'TARGET'});
      }else{
        next;
      }
    }
    unless(@data == 3){
      print "DataNUMerr:@data $line\n";
      next;
    }else{
      $data[0] = uc $data[0];
      if($data[0] eq "M" && @data[2] =~ m/^(L|C|F|UL)$/i){
        $data[2] = uc $data[2];
        push(@dataline , "$datetime,$data[1],$race,$data[0],$data[2],$from");
      }elsif($data[0] =~ m/^(S|G)$/ && $data[2] =~ m/^[0-5]\d[0-5]\d{3}$/){
        #start or goal の登録
        push(@dataline , "$datetime,$data[1],$race,$data[0],$data[2],$from");
      }elsif($data[0] =~ m/^P(\d+)$/){
        #ゲートペナルティの登録
        $data[0] =~ s/^P//;
        my @penall = split(//, $data[2]);
        foreach my $pen (@penall){
        my $penval= ($pen eq 5)?"50":"$pen";
        push(@dataline , "$datetime,$data[1],$race,$data[0],$penval,$from");
          $data[0]++;
        }
      }else{
        print "DataFMTerr:$line\n";
        next;
      }
      foreach $data (@dataline){
        my $lret = setResultLine($data,$resHash);

        #速報書き込み
print STDERR "$lret:$data\n";
        if($lret >= 0){
#result書き込み
          open FH,">>$datafilename";
          print FH "$data\n";
          close FH;
          if($lret > 0){
             makeFRout($data,$resHash,$firstreportfolder)
          }
        }
      }
    }
  }
#  unlink $emlfilename;
#  move $emlfilename,"$tmpdir/backup/
  unlink glob ("$tmpdir/*");
}


sub makeFRout{
   my ($dataline,$resHash,$outdir) = @_;

   my ($ts,$zn,$race) = split(/,/,$dataline);
   my $key = "$zn:$race";
   my $class = $$resHash{$key}{'CLASS'};
   my $name = $$resHash{$key}{'NAME'};
   my $pts = $$resHash{$key}{'PTS'};
   my $time = $$resHash{$key}{'TIME'};
   my $pen = $$resHash{$key}{'PEN'};
   my $pengate = $$resHash{$key}{'PENGATE'};

   my $FRoutfilename = "$outdir$class-$race-$zn";
#   my $FRoutdata = "$class,$zn,$name,$pts,$time,$pen";
   my $FRoutdata = "$class $zn $name race:$race Point:$pts(time:$time / $pengate)";

   open FH,">$FRoutfilename";
   print FH $FRoutdata;
   close FH;
}
#
#時間でデータをロックする。
#
sub lockDataByTime()
{
  my ($datahash,$locktime) = @_;
  my $retval=0;
#print "check lock($locktime $$datahash{'101:1'}{'NAME'})\n";


  while (my ($znRace,$val) =each( %$datahash)){
    if(exists $$datahash{$znRace}{'STATUS'}){next;}
    #仮データ作成から５分でLOCK
#print "$znRace -> $$datahash{$znRace}{'DATATIME'}{'PTS'}\n";
    if(exists $$datahash{$znRace}{'DATATIME'}{'PTS'}){
      if( time - $$datahash{$znRace}{'DATATIME'}{'PTS'} > $locktime){
        my ($zn,$race)=split(/:/,$znRace);
        my $dataline="$znRace,$zn,$race,M,L,SYSTEM";
        print STDERR "DATA FIXED($locktime $$datahash{$znRace}{'DATATIME'}{'PTS'}):$znRace\n";
        $$datahash{$znRace}{'STATUS'} = "L";
        $retval++;
      }
    }
  }
  return $retval;
}

sub setResultLine{
  my ($line,$datahash) = @_;
#print "$line\n";

  my @list = split(/,/,$line);
  #csvからダブルクォートを削除
  foreach my $data(@list){
    $data =~ s/^\"(.*)\"$/$1/;
  }
  my $zn = "@list[1]:@list[2]";

  unless(exists $$datahash{$zn}{'START'}){
    print STDERR "#unmatch athlete data/$zn/$line\n";
    retuen -1;
  }
  #
  #ロックステータスの処理
  #
  if(@list[3] eq "M"){
    #ステータスの更新
    if(@list[4] eq "UL"){
       $$datahash{$zn}{'DATATIME'}{'PTS'} = @list[0];
       delete $$datahash{$zn}{'STATUS'};
    }else{
       $$datahash{$zn}{'STATUS'} = @list[4];
    }
    return 0;
  }

  #ロックステータスのチェック(LOCK/CHECK/FIXED)
  if(exists $$datahash{$zn}{'STATUS'}){
    if($$datahash{$zn}{'STATUS'} =~ m/[LCF]/i){
      print STDERR "#DATA FIXED($$datahash{$zn}{'STATUS'}):";
      return -1;
    }
  }

  #データが登録済みの場合は、登録時間をチェック
  if(exists $$datahash{$zn}{@list[3]}){
    if($$datahash{$zn}{'DATATIME'}{@list[3]} >= @list[0]){
      print STDERR "#timedata error:";
      return -1;
    }
  }
  #データ登録
  my $orgdata = $$datahash{$zn}{@list[3]};
  $$datahash{$zn}{'DATATIME'}{@list[3]} = @list[0];
  $$datahash{$zn}{@list[3]} = @list[4];
  #スタートとゴール、両方が揃ったらタイムを計算
  if(@list[3] eq 'S' || @list[3] eq 'G'){
    if((exists $$datahash{$zn}{'S'}) && (exists $$datahash{$zn}{'G'})){
      $$datahash{$zn}{'TIME'} = 
        CalcGoalTime( $$datahash{$zn}{'S'} , $$datahash{$zn}{'G'} );
    }
  }else{

    #出力用文字列データのポインタ計算
    my $strptr = @list[3] - 1 + int((@list[3]-1) / 5);
    my @spdata = split (//,$$datahash{$zn}{'PENGATE'});

    #文字列データを使って、ゲート番号が最大を超えていないかチェック
    if(@spdata < $strptr){
      print STDERR "Over MaxGate::$line\n";
      delete  $$datahash{$zn}{@list[3]};
      return -1;
    }
    unless(@list[4] == 0 ||@list[4] == 2 ||@list[4] == 50){
      print STDERR "Penalty Pts Error:$line\n";
      delete  $$datahash{$zn}{@list[3]};
      return -1;
    }
    #ペナルティの合計値を更新。
    $$datahash{$zn}{'PEN'} += @list[4] - $orgdata;

    my $setval= (@list[4] == 50)?"X":"@list[4]";
#print "@list[3] p:$strptr\n";
    @spdata[$strptr] = "$setval";
    $$datahash{$zn}{'PENGATE'} = join("",@spdata);
#print "a:$$datahash{$zn}{'PENGATE'}\n\n";
  }
  if(exists $$datahash{$zn}{'TIME'} && index($$datahash{$zn}{'PENGATE'},"-") == -1){
# && @list[4] != $orgdata){
    #仮データ作成完了！
    my $retcode = (exists $$datahash{$zn}{'PTS'})?2:1;
    $$datahash{$zn}{'PTS'} =   my $t = sprintf("%.2f",$$datahash{$zn}{'TIME'} + $$datahash{$zn}{'PEN'});
    $$datahash{$zn}{'DATATIME'}{'PTS'} = @list[0];
    return $retcode;
  }
  return 0;
}

#
#スタートタイムのデータとゴールタイムのデータから、タイムを計算する。
#
sub CalcGoalTime(){
  my ($startdata,$goaldata) = @_;

  my $st = int($startdata/10000) * 6000  + $startdata % 10000;
  my $gt = int($goaldata /10000) * 6000  + $goaldata  % 10000;
  my $t = sprintf("%.2f",(($gt - $st + 360000) % 360000) / 100);
  return $t;
}


#
#MasterDataから直接ＸＭＬファイルを作成する。
#
sub xmlFullOutPut2(){
  my ($FILENMAME,$XSLCONFIGFILE,$master) = @_;

  my $xmldoc = new XML::DOM::Document;
  $xmldoc->setXMLDecl($xmldecl);
  my $xmldecl = $xmldoc->createXMLDecl("1.0", "UTF-8");
  $xmldoc->setXMLDecl($xmldecl);
  
  my $all = $xmldoc->createElement("all");
  $xmldoc->appendChild($all);

  my %CLASS;
  my %ZN;

  while (my ($znRace,$val)=each(%$master)){
    my ($zn,$race) = split(/:/,$znRace);
    my $class   = $$master{$znRace}{'CLASS'};
    my $startno = $$master{$znRace}{'START'};
    my $name    = $$master{$znRace}{'NAME'};
    my $club    = $$master{$znRace}{'CLUB'};
    my $pts     = $$master{$znRace}{'PTS'};
    my $time    = $$master{$znRace}{'TIME'};
    my $pen     = $$master{$znRace}{'PEN'};
    my $pengate = $$master{$znRace}{'PENGATE'};
    my $start   = $$master{$znRace}{'S'};
    my $goal    = $$master{$znRace}{'G'};
    my $status  = $$master{$znRace}{'STATUS'};
    #add Category
    
    if(!exists($CLASS{$class})){
      $CLASS{$class} =  $xmldoc->createElement("category");
      $CLASS{$class} -> setAttribute('value',$class);
      $all -> appendChild($CLASS{$class});
    }
    #add Athlete Infomation 
    if(!exists($ZN{$zn})){
      $ZN{$zn} = $xmldoc->createElement("zn");
      $ZN{$zn} -> setAttribute('value',$zn);

#      $ZN{$zn} -> setAttribute('name',encode('UTF-8',decode('shiftjis', $name)));
#      $ZN{$zn} -> setAttribute('name',encode('UTF-8',decode('Guess', $name)));
#      $ZN{$zn} -> setAttribute('name',encode('UTF-8',$name));
#      $ZN{$zn} -> setAttribute('name',from_to($_, 'Guess', 'UTF-8'));
#      $ZN{$zn} -> setAttribute('name', Encode::from_to($name, 'shiftjis', 'utf8')); 
      $ZN{$zn} -> setAttribute('name',$name);

#      $ZN{$zn} -> setAttribute('club',encode('UTF-8',$club));
      $ZN{$zn} -> setAttribute('club',$club);

      if($pts ne ''){
        $ZN{$zn} -> setAttribute('bestpts',$pts);
      }else{
        $ZN{$zn} -> setAttribute('bestpts','9999.99');
      }
      $CLASS{$class} -> appendChild($ZN{$zn});
    }else{
      if($pts ne ''){
        if($ZN{$zn} -> getAttribute('bestpts') > $pts){
          $ZN{$zn} -> setAttribute('bestpts',$pts);
        }
      }
    }
    #add Race Infomation
    my $RACE = $xmldoc->createElement("race");
    $RACE -> setAttribute('value',$race);
    $RACE -> setAttribute('pts',$pts);
    $RACE -> setAttribute('time',$time);
    $RACE -> setAttribute('pen',$pen);
    $RACE -> setAttribute('pengate',$pengate);
    $RACE -> setAttribute('start',$start);
    $RACE -> setAttribute('goal',$goal);
    $RACE -> setAttribute('status',$status);
    $RACE -> setAttribute('startno',$startno);
    $ZN{$zn} -> appendChild($RACE);
  }
  my $retval = $xmldoc->toString;
  $retval =~ s/<all(>|\s)/<\?xml-stylesheet \?><all$1/;
  $retval =~ s/>/>\n/g;
  $retval =~ s/>\n\n/>\n/g;
# type="text/xsl" href="result.xsl"

  open(FH,">$FILENMAME");
  print FH $retval;
  close FH;

#Data Output

  my $retval = $xmldoc->toString;
  $retval =~ s/<all(>|\s)/<\?xml-stylesheet \?><all$1/;
  $retval =~ s/>/>\n/g;
  $retval =~ s/>\n\n/>\n/g;
# type="text/xsl" href="result.xsl"

  open(FH,">$FILENMAME");
  print FH $retval;
  close FH;

#print "$XSLCONFIGFILE\n";
  open FH,$XSLCONFIGFILE;
  while (my $line = <FH>){
    #trim
    $line =~ s/^\s*(.*?)\s*$/$1/;
    #null行、コメント行をスキップ
    if($line eq "" || $line =~ /^#/){
      next;
    }
print "$line\n";
    ($xmlfilename,$xslfilename) = split(/,/,$line);
    $xmlfilename =~ s/^\"(.*)\"$/$1/;
    $xslfilename =~ s/^\"(.*)\"$/$1/;
#print "xml:$xmlfilename xsl:$xslfilename\n";
    $retval =~ s/<\?xml-stylesheet (.*)?\?>/<\?xml-stylesheet type=\"text\/xsl\" href=\"$xslfilename\" \?>/;
#print "$retval\n";

    open FHO,">$xmlfilename";
    print FHO $retval;
    close FHO;
  }
  close FH;
  return \$retval;
}


sub emlInputData2{
  my ($emlfilename,$datafilename,$mailmapfilename,$resHash,$firstreportfolder) = @_;

  my $tmpdir = "./tmp";
#print "file:'$emlfilename'\n";
  my $parser = MIME::Parser->new;
  if( !(-d $tmpdir )){
    mkdir $tmpdir;
  }
  $parser->output_dir($tmpdir);

  open FH,$emlfilename;
  my @bodyline = <FH>;
  my $entity = $parser->parse(*FH);
  close FH;

  my %mailmap;
#print "mailfile:$mailmapfilename\n";
  open FH,$mailmapfilename;
  while (my $line = <FH>){
#print "line:$line\n";
    #trim
    $line = jcode($line)->tr('Ａ-Ｚａ-ｚ０-９＠?','A-Za-z0-9@-');
    $line =~ s/^\s*(.*?)\s*$/$1/;
    $line =~ s/^\s\s$/\s/g;
    #null行、コメント行をスキップ
    if($line eq "" || $line =~ /^#/){
      next;
    }
    my ($mailaddr,$target,$datalength) = split(/,/,$line);
    $mailmap{$mailaddr}{'TARGET'} = $target;
    $mailmap{$mailaddr}{'DATALENGTH'} = $datalength;
#print "$mailaddr - $mailmap{$mailaddr}{'TARGET'}\n";
  }
  close FH;

  my $header = $entity->head;

  my $from = $header->get('From');
  $from =~ s/^\s*(.*?)\s*$/$1/;
  if($from =~ m/^(.*)\<(.*)\>\s*$/){
    $from =~ s/^(.*)\<(.*)\>\s*$/$2/;
  }
  my $subject = $header->get('Subject');
  $subject =~ s/\s$//;
  my $race = $subject;
#  $race =~ s/(.*):(.*)/$1/;
  $race = '1';
  my $datestr = $header->get('Date');
  $datestr =~ s/^\s*(.*?)\s*$/$1/;
#  my $datetime = str2time($datestr);
  my $datetime = time();
#  $datetime =~ s/\s*$//;
#  $datetime = str2time($datetime);

#  my $body = $entity->bodyhandle->as_string;
  my $body_entity = ($entity->is_multipart) ? $entity->parts(0) : $entity;
  my $body = $body_entity->bodyhandle->as_string;

#print "from:'$from'\n";
print "Sbj :'$race'\n";
print "Date:'$datetime'\n";
print "Body:'$body'\n";
print "maildata:$datestr\n";
print "maildata:$from/$race/$datestr\n";
  
#  my @bodyline = split('\n',$body);
  foreach $line (@bodyline){

    $line =~ s/^\s*(.*?)\s*$/$1/;
    #null行、コメント行をスキップ
    if($line eq "" || $line =~ /^#/){
      next;
    }

    my @dataline;
    my @data = split(/ /,$line);

    $from = $data[3];
    splice(@data,3,1);
    $race = $data[4];
    splice(@data,3,1);


    if($line =~ /^E/i){
      #E(ND) で読み込み終了
      last;
    }elsif(@data == 2){
      #データ数が２の場合は、mailMAPを参照して、追加。
      if(exists $mailmap{$from}){
        unshift(@data, $mailmap{$from}{'TARGET'});
      }else{
        next;
      }
    }
    unless(@data == 3){
      print "DataNUMerr:@data $line\n";
      next;
    }else{
      $data[0] = uc $data[0];
      if($data[0] eq "M" && @data[2] =~ m/^(L|C|F|UL)$/i){
        $data[2] = uc $data[2];
        push(@dataline , "$datetime,$data[1],$race,$data[0],$data[2],$from");
      }elsif($data[0] =~ m/^(S|G)$/ && $data[2] =~ m/^[0-5]\d[0-5]\d{3}$/){
        #start or goal の登録
        push(@dataline , "$datetime,$data[1],$race,$data[0],$data[2],$from");
      }elsif($data[0] =~ m/^P(\d+)$/){
        #ゲートペナルティの登録
        $data[0] =~ s/^P//;
        my @penall = split(//, $data[2]);
        foreach my $pen (@penall){
        my $penval= ($pen eq 5)?"50":"$pen";
        push(@dataline , "$datetime,$data[1],$race,$data[0],$penval,$from");
          $data[0]++;
        }
      }else{
        print "DataFMTerr:$line\n";
        next;
      }

      foreach $data (@dataline){
        my $lret = setResultLine($data,$resHash);

        #速報書き込み
print STDERR "$lret:$data\n";
        if($lret >= 0){
#result書き込み
          open FH,">>$datafilename";
          print FH "$data\n";
          close FH;
          if($lret > 0){
             makeFRout($data,$resHash,$firstreportfolder)
          }
        }
      }

    }
  }
  unlink $emlfilename;
  move $emlfilename,"$tmpdir/backup/";
  unlink glob ("$tmpdir/*");
}


#モジュール終了！
1;
