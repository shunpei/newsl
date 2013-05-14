#
#全データのCSV出力を作成する。
#
sub createAllData(){
  my ($dataList,$master) = @_;

  unshift(@$dataList,"#CLASS,Race,STARTNO,ZN,NAME,CLUB,PTS,TIME,PEN,PENGATE,START,GOAL,STATUS");

  while (my ($znRace,$val)=each(%$master)){
    my $cstart = sprintf("%04d",$$val{'START'});
#    my $cstart = $$val{'START'};
    my ($zn,$race) = split(/:/,$znRace);
    my $pushdata = "$$val{'CLASS'},$race,$cstart,$zn,$$val{'NAME'},$$val{'CLUB'}";
    #calc pen
    my $pen = 0;
    my $outdata = "";
    for(my $i=1;$i<=MAXGATENUM;$i++){
      if((($i-1) % 5)==0){
        $outdata .= ' ';
      }
      if(exists $$master{$znRace}{$i}){
        $pen += $$master{$znRace}{$i};
        if($$master{$znRace}{$i} == 0){
          $outdata .= '0';
        }elsif($$master{$znRace}{$i} == 2){
          $outdata .= '2';
        }else{
          $outdata .= 'X';
        }
      }else{
        $outdata .= '-';
      }
    }
    $outdata =~ s/^\s*(.*?)(-|\s)*$/$1/;
    if($outdata eq ""){$pen = "";}
    my $pts = "";
    if(exists $$master{$znRace}{'TIME'}){
#      $pts = sprintf("%07.2f", $$master{$znRace}{'TIME'}+$pen);
      $pts = sprintf("%.2f", $$master{$znRace}{'TIME'}+$pen);
    };
    $pushdata .= ",$pts,$$master{$znRace}{'TIME'},$pen,$outdata,$$master{$znRace}{'S'},$$master{$znRace}{'G'},$$master{$znRace}{'STATUS'}";
#print "$pushdata\n";
    push(@$dataList,$pushdata);
  }
  @$dataList = sort(@$dataList);
  return 0;
}

#
#CSVからＸＭＬデータを作成する。
#
sub xmlFullOutPut(){
  my ($FILENMAME,$XSLCONFIGFILE,$DATACSV) = @_;

  my $xmldoc = new XML::DOM::Document;
  $xmldoc->setXMLDecl($xmldecl);
  my $xmldecl = $xmldoc->createXMLDecl("1.0", "UTF-8");
  $xmldoc->setXMLDecl($xmldecl);
  
  my $all = $xmldoc->createElement("all");
  $xmldoc->appendChild($all);

  my %CLASS;
  my %ZN;

  foreach my $line(@$DATACSV){
    if($line =~ /^#/){next;}
    my ($class,$race,$startno,
        $zn,$name,$club,
        $pts,$time,$pen,$pengate,$start,$goal,$status)
       = split(/,/,$line);
    #add Category
    if(!exists($CLASS{$class})){
      $CLASS{$class} =  $xmldoc->createElement("category");
      $CLASS{$class} -> setAttribute('value',$class);
      $all -> appendChild($CLASS{$class});
    }
    #add Category
    if(!exists($ZN{$zn})){
      $ZN{$zn} = $xmldoc->createElement("zn");
      $ZN{$zn} -> setAttribute('value',$zn);
      $ZN{$zn} -> setAttribute('name',encode('UTF-8',decode('Guess', $name)));
#      $ZN{$zn} -> setAttribute('name',encode('UTF-8',$name));
      $ZN{$zn} -> setAttribute('club',encode('UTF-8',$club));
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

print "$XSLCONFIGFILE\n";
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
print "xml:$xmlfilename xsl:$xslfilename\n";
    $retval =~ s/<\?xml-stylesheet (.*)?\?>/<\?xml-stylesheet type=\"text\/xsl\" href=\"$xslfilename\" \?>/;
print "$retval\n";

    open FHO,">$xmlfilename";
    print FHO $retval;
    close FHO;
  }
  close FH;
  



  return \$retval;
}





#
#配列をそのままファイルに出力
#
sub listFileOutput(){
  my ($OUTFILE,$resultdata) = @_;

  open(FH,">$OUTFILE");
  foreach my $line(@$resultdata){
    print FH "$line\n";
  print "$line\n";
  }
  close(FH);
}
#
#CSVデータのHTML出力
#
sub htmlFullOutPut(){
  my ($FILENMAME,$DATACSV) = @_;
  open(FH,">$FILENMAME");
  print FH "<HTML><BODY>\n<TABLE border=1>\n";
  foreach my $line(@$DATACSV){
    print FH "<TR>";
    my $tag = "TD";
    if($line =~ /^#/){
      $tag = "TH";
#      $line =~ s/^#(.*)/$1/;
    }
#    $line =~ s/,,/,&nbsp;,/g;
#    $line =~ s/,,/,&nbsp;,/g;
#    $line =~ s/,$/,&nbsp;/g;
$line .= ",DUMMY";
    my @list = split(/,/,$line);
#    foreach my $data (@list){
    for(my $i=0;$i < @list -1;$i++){
      my $data = @list[$i];
      if($data ne ''){
        print FH "<$tag>$data</$tag>"
      }else{
        print FH "<$tag>&nbsp;</$tag>"
      }
    }
    print FH "</TR>\n";
  }
  print FH "</BODY></HTML>\n";
  close(FH);
}



