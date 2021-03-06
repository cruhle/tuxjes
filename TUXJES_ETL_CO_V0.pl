#TUXJES_ETL_CO_V0.pl

#2019-05-09
#
#faz 2 leituras ao fcheiro de log
#a 1 eh para saber quais os numeros de job com erro > 4
#na 2 retira todas as linhas dos numeros de job retirados na 1 leitura
#noutra fase será em copiar os ficheiros com os erros e enviar p/email
#

#/PRD/EXE_COBOL/PROD/CO/tux/JESROOT/jessyslog

#/PRD/EXE_COBOL/PROD/CO/tux/JESROOT/00251663
#/PRD/EXE_COBOL/PROD/CO/tux/JESROOT/00251663.bak
#/PRD/EXE_COBOL/PROD/CO/tux/JESROOT_BCK/00251663.bak

#/PRD/EXE_COBOL/PROD/CO/tux/JESROOT/%s
#/PRD/EXE_COBOL/PROD/CO/tux/JESROOT/%s.bak
#/PRD/EXE_COBOL/PROD/CO/tux/JESROOT_BCK/%s.bak

#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT

use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;
use constant	START_TIME	=>	6;
use constant	END_TIME	=>	7;
use constant	RETURN_CODE	=>	11;

use strict;
use warnings;
use integer;

my ($area, $parm) =  @ARGV; 

if($#ARGV!=1) {
	printf("\nPARAMETROS\tERRO\tERRO\tERRO\t");
	printf("Faltam parametros: area ficheiro\n");
	exit;
}

if (not defined $area) {
  die "Falta a AREA OPERACIONAL [CO|FO|RP].\n";
}

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my @ins;
my $start_time=0;
my $end_time=0;
my $work;

my $code;

my %rcodes;

$area = uc($area);

#------------------------------------------------------
#FIRST READ
#------------------------------------------------------
open my $fp,'<',$parm or die "ERROR $!\n";
while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@ins = split(/\t/);
		
	next if(scalar @ins != 12);
	next if($ins[STEP_NAME] eq '-');
			
	$code = $ins[RETURN_CODE];
	$code =~ tr/0-9//cd;	
	if($code > 4) {
		$rcodes{$ins[JOB_NUMBER]} += 1;		
	}
					
}
close $fp;

#foreach(sort keys %rcodes) {
#	printf("%10s\t%d\n",$_, $rcodes{$_});
#}

#------------------------------------------------------
#SECOND READ
#------------------------------------------------------
open $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@ins = split(/\t/);
		
	next if(scalar @ins != 12);
	next if($ins[STEP_NAME] eq '-');
			
	$start_time = time_2_seconds(substr($ins[START_TIME],1));
	$end_time = time_2_seconds(substr($ins[END_TIME],1));
	$work = valida_tempos($start_time, $end_time);
	
	#############$code = $ins[RETURN_CODE];
	#############$code =~ tr/0-9//cd;	
	#############if($code < 5) {
	#############	#if($code == 4) { print  $ins[RETURN_CODE],"\t"; }
	#############	next;
	#############}
			
	if(!exists($rcodes{$ins[JOB_NUMBER]})) {
		next;
	}
			
	printf("%s;%s;%s;%s;%s;%d;%s\n",
		data_hora($ins[DATA_HORA]),
		$area,
		$ins[JOB_NUMBER],
		$ins[JOB_NAME],
		$ins[STEP_NAME],
		valida_tempos($start_time, $end_time),
		$ins[RETURN_CODE]
		);	

#	$rcodes{$ins[RETURN_CODE]} += 1;
		
}
close $fp;

#falta o job number!
#e o respectivo ficheiro
my @locais=();
push @locais,'/PRD/EXE_COBOL/PROD/CO/tux/JESROOT/%s';
push @locais,'/PRD/EXE_COBOL/PROD/CO/tux/JESROOT/%s.bak';
push @locais,'/PRD/EXE_COBOL/PROD/CO/tux/JESROOT_BCK/%s.bak';


#------------------------------------------------------

#foreach(sort keys %rcodes) {
#	printf("%10s\t%d\n",$_, $rcodes{$_});
#}

#------------------------------------------------------
#SUB-ROTINAS
#------------------------------------------------------

sub data_hora {

	my $in = shift;
	
	my ($d , $h) = split(/\s/,$in);	
	
	return (
		substr($d,0,4)
		.'-'.
		substr($d,4,2)
		.'-'.
		substr($d,6,2)
		.';'.
		substr($h,0,5)
	);
	
	
}

sub time_2_seconds {

	my $in = shift;
	
	my ($h, $m, $s) = split(/:/,$in);
			
	return (($h*3600)+($m*60)+$s);
	
}

sub seconds_2_time {

	my $in = shift;
	
	return (sprintf("%02d:%02d:%02d", $in/3600, $in/60%60, $in%60));
	
}

sub valida_tempos {

	my ($t1, $t2) = @_;
	my $rv = 0;
	
	if($t1 > $t2) {
		$rv = (86400-$t1) + $t2;
	} else {
		$rv = $t2 - $t1;
	}
	
	return $rv;
}


##########	# Create the data for the chart.
##########	v <- c(0003,
##########	0024,
##########	0087,
##########	0108,
##########	0002
##########	)
##########	
##########	labelsm <- c('a','b','c','d','a1')
##########	# Give the chart file a name.
##########	png(file = "line_chart.jpg")
##########	
##########	# Plot the bar chart. 
##########	plot(v,type = "o",axes=FALSE,ann=FALSE)
##########	axis(1, at=1:5, lab=c("Mon","Tue","Wed","Thu","Fri"))
##########	box()
##########	
##########	# Save the file.
##########	dev.off()