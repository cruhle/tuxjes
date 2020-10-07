#TUXJES_ETL_DIARY.pl

#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog
#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT_BCK/01318783.bak

#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT

use strict;
use warnings;
use File::Basename;

use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;
use constant	START_TIME	=>	6;
use constant	END_TIME	=>	7;

my @ins;
my $key;
my %jobs;

my ($start_time, $end_time, $work_time) = (0, 0, 0);

my ($area, $parm) = @ARGV;

if(!defined $area) {
	die "FALTA AREA\n";
}

if(!defined $parm) {
	die "FALTA FICHEIRO\n";
}

if(!-e $parm) {
	printf("FILE [%s] NOT FOUND.\n",$parm);
	exit ;
}

my $filename = basename($parm);

$filename =~ s/log/$area/;
$filename =~ s/\./_/g;
$filename.='_day.csv';
$filename = '/tmp/pkis/'. $filename;

open my $fp,'<',$parm or die "ERROR $!\n";
my $linhas=0;
my $escrita=0;

while(<$fp>) {

	$linhas++;
	next if(length $_ < 20);
	
	chomp;
	@ins = split(/\t/);
		
	next if(scalar @ins != 12);
	next if($ins[STEP_NAME] eq '-');
			
	$key = data_hora_DATA($ins[DATA_HORA]) 
		.';'. $area;
	
	if(length($ins[START_TIME])==9 and length($ins[END_TIME])==9) {
		$start_time = time_2_seconds(substr($ins[START_TIME],1));
		$end_time = time_2_seconds(substr($ins[END_TIME],1));
		$work_time = valida_tempos($start_time, $end_time);
	} else {
		$work_time = 0;
	}
		
	if(exists($jobs{$key})) {		
		$jobs{$key}{'work'} += $work_time;				
		
		if($jobs{$key}{'end'} < $ins[JOB_NUMBER]) {
			#print $key,"\t",$ins[JOB_NUMBER],"\t",$jobs{$key}{'start'},"\t",$jobs{$key}{'end'},"\t",$jobs{$key}{'counter'},"\n";
			$jobs{$key}{'counter'} += 1;				
			$jobs{$key}{'end'} = $ins[JOB_NUMBER];				
		}
		#print $key,"\t",$ins[JOB_NUMBER],"\t",$jobs{$key}{'start'},"\t",$jobs{$key}{'end'},"\t",$jobs{$key}{'counter'},"\n";
		
	} else {
		$jobs{$key} = {		
			'work' => $work_time,
			'start' => $ins[JOB_NUMBER],
			'end' => $ins[JOB_NUMBER],
			'counter' => 1
		};
		#print $key,"\t",$ins[JOB_NUMBER],"\n";
		$escrita++;
	}
							
}
close $fp;

printf("%s [%6d] [%6d]\n", $parm, $linhas, $escrita);

#foreach(sort keys %jobs) {
#	printf("%s:%s:%d\n", $parm, $_, $jobs{$_}{'work'});
#}

open $fp,'>',$filename;
printf($fp "%s\n",$0);
foreach(sort keys %jobs) {
	printf($fp "%s;%d;%d;%s\n", 
		$_, 
		$jobs{$_}{'counter'},
		$jobs{$_}{'work'},
		seconds_2_time($jobs{$_}{'work'})
		);	
	#printf($fp "%s;%d;%d;%s;%s;%d\n", 
	#	$_, 
	#	($jobs{$_}{'end'} - $jobs{$_}{'start'}), 
	#	$jobs{$_}{'work'}
	#	,$jobs{$_}{'start'}
	#	,$jobs{$_}{'end'}
	#	,$jobs{$_}{'counter'}
	#	);			
}
close $fp;

#----------ROTINAS-----------------

sub data_hora_DATA {

	my $in = shift;
	
	my ($d , $h) = split(/\s/,$in);	
	
	return (
		substr($d,0,4)
		.'-'.
		substr($d,4,2)
		.'-'.
		substr($d,6,2)		
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


