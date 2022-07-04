#!/usr/bin/perl
#       $Id: elmtag.pl,v 1.41 1999/01/07 03:22:18 cinar Exp cinar $
#
# Elmtag.pl: insert tag lines to your e-mail messages.
#
# This file and all associated files and documentation:
# 	Copyright (C) 1998,1999 Ali Onur Cinar <root@zdo.com>
#
# Latest version can be downloaded from:
#
#   ftp://hun.ece.drexel.edu/pub/cinar/elmtag*
#   ftp://ftp.cpan.org/pub/CPAN/authors/id/A/AO/AOCINAR/elmtag*
#   ftp://sunsite.unc.edu/pub/Linux/system/mail/misc/elmtag*
#  http://artemis.efes.net/cinar/elmtag
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version. And also
# please DO NOT REMOVE my name, and give me a CREDIT when you use
# whole or a part of this program in an other program.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
# Specially thanks to:
#
# Joe Doupnik		who gave tioc addresses from his Unixware system.
# Steve Cooper		who gave tioc addresses from his HP-UX system.
# W. J. Pereira		who gave tioc addresses from his AIX system.
# Robin Humble		who gave tioc addresses from his IRIX system.
# Eric Sunshine		who gave tioc addresses from his NeXT system.
# Max Waterman		who gave tioc addresses from his SGI system.
# Charles M. Orgish	who gave tioc addresses from his Ultrix system.
#
# $Log: elmtag.pl,v $
# Revision 1.41  1999/01/07 03:22:18  cinar
# *** empty log message ***
#
# Revision 1.40  1999/01/07 03:04:53  cinar
# automatic installation option included
#
# Revision 1.34  1998/12/31 02:31:41  cinar
# command line & ENV var based configuration enabled.
#
# Revision 1.33  1998/12/31 01:13:47  cinar
# .elmtagrc configuration file support.
#
# Revision 1.14  1998/12/19 12:55:06  cinar
# winsize check and calibrate modules added
#
# Revision 1.11  1998/12/14 01:36:56  cinar
# first distribution version
#

# NOTICE: The fallowing variables will be overwriten
# by the $HOME/.elmtagrc file or ENV var if one of them exists.

# location of tag database
$tag_file = '/home/cinar/personel/documents/tags';

# your prefered editor
$your_editor = 'vi';

# do you prefere an alphabeticaly ordered list? (1=on, 0=off)
$alphabetical = 1;

# centeralize taglines when appending to e-mails? (1=on, 0=off)
$centertags = 1;

# what is the max row for an e-mail?
$mailmaxrow = 80;

# no more end-user based configuration at the bottom part

# what's my version
$verraw  = '$Revision: 1.41 $'; $verraw =~ /.{11}(.{4})/g; $elmtagver = "1.$1";

@help_msg = (
	"\nElmtag.pl v$elmtagver [$^O] (c) '98-99 by Ali Onur Cinar <root\@zdo.com>\n",
	"This program is free software; you can redistribute it and/or modify it under\n",
	"the terms of the GNU General Public License as published by the Free Software\n",
	"Foundation; either version 2 of the License, or any later version.\n\n",
	"Usage: elmtag [options] filename\n\n",
	"Options:\n",
	"	-a -A	<1 or 0>  alphabetical ordering (1=on (default), 0=off)\n",
	"	-c -C	<1 or 0>  centeralize tags when writing (1=on (default), 0=off)\n",
	"	-d -D	<file>    tag database file to use\n",
	"	-e -E	<program> editor program to use\n",
	"	-m -M	<maxrow>  max number of row of an e-mail (default:80)\n",
	"	-n -N             do not use  .elmtagrc  configuration file\n",
	"	-r -R             randomly select a tag line\n\n",
	"	-i -I             automatic installation (only for ELM & PINE)\n",
	"	-h -H             this help message\n\n",
	"These command line variables overwrite .elmtagrc settings, but they can be\n",
	"also overwritten by setting shell environement variables. (see manual file)\n\n");

require "getopts.pl";
if(!&Getopts("a:A:c:C:d:D:e:E:hH:iI:m:M:nN:rR") || $opt_h || $opt_H) { print @help_msg; exit; }

undef @help_msg;	# we won't need it again

# if automatic installation requested
if ($opt_i || $opt_I)
{
	print "Installing $0...\n";

	if (!defined $elmtag_path)
	{
		print "\nChecking path for $0...";
		@lookin = split(':',$ENV{PATH});

		foreach (@lookin)
		{
			if ( -x "$_/$0" ) { $elmtag_path = "$_/$0"; break; }
		}
	}

	if (!defined $elmtag_path)
	{
		print "Checking current directory for $0...";
		undef @lookin;chomp($lookin = `pwd`);
		if ( -x "$lookin/$0" ) { $elmtag_path = "$lookin/$0"; }
	}

	if (!defined $elmtag_path)
	{
		print "\nChecking your home directory for $0...";
		open FINDP, "find $ENV{HOME} -name $0 |";

		while (<FINDP>)
		{
			next if ( /denied/ );
			$elmtag_path = $_;
		}
		close FINDP;
	}

	if (defined $elmtag_path) { print " found.\n---> Location: $elmtag_path \n"; }
	else { print " not found.\n---> Please enter the location: "; $elmtag_path = <STDIN>; }

	if (open CURCONF, "<$ENV{HOME}/.elm/elmrc")
	{
		open NEWCONF, ">$ENV{HOME}/.elm/elmrc.new";

		while (<CURCONF>)
		{
			if($_ =~ /(^editor|^### editor)/)
			{
				@line = split(/ /);

				if ($#line gt 0)
				{
					chop($prefered_editor = $line[$#line]);
				}

				print NEWCONF "editor = $elmtag_path\n";
				print "Elmtag.pl installed to your ELM configuration.\n";
			}
			else
			{
				print NEWCONF $_;
			}
		}

		close CURCONF;
		close NEWCONF;
		system("/bin/mv -f $ENV{HOME}/.elm/elmrc.new $ENV{HOME}/.elm/elmrc");
	}
	else
	{
		print "\nNo ELM configuration file found in $ENV{HOME}/.elm !\nPlease save your ELM configuration once from ELM's Options menu, and restart the installation again.\n(If you want to use Elmtag.pl from ELM ofcouse)\n\n";
	}

	if (open CURCONF, "$ENV{HOME}/.pinerc")
	{
		open NEWCONF, ">$ENV{HOME}/.pinerc.new";

		while (<CURCONF>)
		{
			if ( /^editor/ )
			{
				if (!defined $prefered_editor)
				{
					@line = split(/ /);
					chop($prefered_editor = $line[$#line]);
				}

				print NEWCONF "editor=$elmtag_path\n";
				print "Elmtag.pl installed to your PINE configuration.\n";
			}

			elsif ( (/^feature-list/) && (! /enable-alternate-editor-implicity/) )
			{
				chop;
				print NEWCONF $_;

				if ( /,/ )
				{
					print NEWCONF ",";
				}

				print NEWCONF " enable-alternate-editor-implicity\n";
			}

			else
			{
				print NEWCONF $_;
			}
		}

		close CURCONF;
		close NEWCONF;
		system("/bin/mv -f $ENV{HOME}/.pinerc.new $ENV{HOME}/.pinerc");
	}

	else
	{
		print "No PINE configuration in $ENV{HOME}.\n";
	}


	open ELMTAGCONF, ">$ENV{HOME}/.elmtagrc";
	print "Creating Elmtag.pl configuration file $ENV{HOME}/.elmtagrc...\n";

	if (($prefered_editor =~ /elmtag/) || ($prefered_editor =~ /$0/) || (!defined $prefered_editor))
	{
		$prefered_editor = "vi";
	}

	print "Your prefered editor is: $prefered_editor\n";
	print ELMTAGCONF "\$your_editor = $prefered_editor;\n";
	close ELMTAGCONF;

	print "Installation completed. Please test it from your mailer.\n";
	exit;
}

# if .elmtagrc exists in home directory get the settings
if (( -e "$ENV{HOME}/.elmtagrc" ) && !$opt_n && !$opt_N)
{
	require "$ENV{HOME}/.elmtagrc";
}

# overwrite variables if they are defined on command line or ENV var
$tag_file = $opt_d || $opt_D || $ENV{"ELMTAG_TAG_FILE"} || $tag_file;
$your_editor = $opt_e || $opt_E || $ENV{"ELMTAG_EDITOR"} || $your_editor;
$alphabetical = $opt_a || $opt_A || $ENV{"ELMTAG_ALPHABETICAL"} || $alphabetical;
$centertags = $opt_c || $opt_C || $ENV{"ELMTAG_CENTERTAGS"} || $centertags;
$mailmaxrow = $opt_m || $opt_M || $ENV{"ELMTAG_MAILMAXROW"} || $mailmaxrow;

# if elm is calling us for aliasses let's don't waste more time
if ($ARGV[0] =~ /(alias)/)
{
	exec $your_editor, $ARGV[0];
}

# User interface default coordinates
$xcord = 2;
$ycord = 4;
$uiheight = 10;
$uiweight = 76;

# define ioctl variables
%os_tiocgwinsz	= (	'aix'		=> 0x40087468,
			'freebsd'	=> 0x40087468,
			'linux'		=> 0x005413,
			'hpux'		=> 0x4008746b,
			'dec_osf'	=> 0x40087468,
			'solaris'	=> 0x005468,
			'sunos'		=> 0x005468,
			'unixware'	=> 0x005468,
			'irix'		=> 0x40087468,
			'next'		=> 0x40087468,
			'sgi'		=> 0x40087468,
			'ultrix'	=> 0x40087468);

# terminal controls
%scr = (	'f'		=> 3,
		'b'		=> 4,
		'black'		=> 0,
		'red'		=> 1,
		'green'		=> 2,
		'yellow'	=> 3,
		'blue'		=> 4,
		'magenta'	=> 5,
		'cyan'		=> 6,
		'white'		=> 7,
		'normal'	=> 0,
		'bold'		=> 1,
		'rev'		=> 7,
		'invisible'	=> 8,
		'clear'		=> '2J',
		'clrline'	=> 'K',
		'savepos'	=> 's',
		'returnpos'	=> 'r',
		'mvup'		=> 'A',
		'mvdn'		=> 'B',
		'mvfr'		=> 'C',
		'mvbk'		=> 'D');


sub svid		# clr,(f/b) or mode,x	
{
	print "\x1B[$scr{$_[1]}$scr{$_[0]}m";
}

sub sgoto		# x,y
{
	print "\x1B[$_[1];$_[0]H";
}

sub scurs		# code, num
{
	printf ("\x1B[%s$scr{$_[0]}",$_[1]);
}

sub scenter		# y, string
{
	my ($y);
	sgoto(1,$_[0]);scurs(clrline);
	$y = ($uiweight+4-length($_[1]));
	sgoto((($y-($y%2))/2),$_[0]);
	print $_[1];
}

sub strcenter		# string
{
	my ($y);
	$y = ($mailmaxrow-length($_[0]));
	return ("\n", ' ' x (($y-($y%2))/2), "$_[0]\n");
}

sub sgetwinsz
{
	my ($rep_key, $rep, @rep_decoded);

	if ($os_tiocgwinsz{$^O} && ioctl(STDIN,$os_tiocgwinsz{$^O},$rep))
	{
		$rep_key = "ssss";			# 4 short
		@rep_decoded = unpack($rep_key,$rep);	# 0 row 1 col

		if ($rep_decoded[0] >10) { $uiheight=$rep_decoded[0]-9; }
		if ($rep_decoded[1] > 3) { $uiweight=$rep_decoded[1]-2; }
	}
}

sub scbreak
{
	if ($_[0] eq 'off')
	{
		if ($BSD_STYLE)
		{
			system "stty cbreak </dev/tty >/dev/tty 2>&1";
		}
		else
		{
			system "stty", '-icanon', 'eol', "\001";
		}

		system "stty -echo";
	}
	else
	{
		if ($BSD_STYLE)
		{
			system "stty -cbreak </dev/tty >/dev/tty 2>&1";
		}
		else
		{
			system "stty", '-icanon', 'eol', '^@';
		}

		system "stty echo";
	}
}

sub BufferTags
{
	open Tags, $tag_file;
	undef @Taglines;

	while (<Tags>)
	{
		next if ( /^#/ | /^\s/);
		chomp;
		push(@Taglines, $_);
	}

	close Tags;

	if ($alphabetical == 1)
	{
		@Taglines = sort(@Taglines);
	}
}

sub ReformatTaglines
{
	undef @TaglinesS;

	foreach (@Taglines)
	{
		push(@TaglinesS, substr($_,0,$uiweight-3));
	}
}

sub ShwTag
{
	if (exists $TagedTags{$_[0]}) { print '+'; } else { print ' '; }
	print " $TaglinesS[$_[0]]", ' ' x ($uiweight-length($TaglinesS[$_[0]])-1);
}

sub ShwStaBar
{
	my(@g,$g,$k,$message);

	$k = $#Taglines + 1;

	if ($_[0])
	{
		$message = "Tagline database has $k taglines.";
	}
	else
	{
		@g = keys(%TagedTags);
		$g = $#g + 1;
		$message = "Tagline database has $k tagline. [sel:$g]";
	}

	svid(normal);scenter($ycord-2,$message);
}

sub ShowTags
{
	local($stl_line=0, $stl_pointer=0, $stl_end=$#Taglines, $m, $n, $SelectedTag, $mpat);
	undef $key;
	undef %TagedTags;

	scbreak(off);

ShowTags_action:
	while ($key !~ /(e|E|s|S|q|Q|r|R|\n)/)
	{
		$m = $stl_pointer - $stl_line;

		svid(normal);
		for ($n=0; $n<=$uiheight; $n++)
		{
			if ($n != $stl_pointer)
			{
				sgoto($xcord,$n+$ycord);
				ShwTag($m+$n);
			}
		}

		svid(rev);
		sgoto($xcord,$stl_line+$ycord);
		ShwTag($stl_pointer);

		$key = getc(STDIN);
		if ($key == 27)
		{
			$key = getc(STDIN);
			if ($key =~ /(\[|O)/)
			{
				$key = getc(STDIN);
			}
		}

# Case DN ARROW
		if (($key =~ /(B|r)/) && ($stl_pointer < $stl_end))
		{
			if ($stl_line < $uiheight)
			{
				$stl_line ++;
				$stl_pointer ++;
			}

			elsif ($stl_line == $uiheight)
			{
				$stl_pointer ++;
			}
		}

# Case UP ARROW
		elsif ($key =~ /(A|x)/)
		{
			if ($stl_line > 0)
			{
				$stl_line --;
				$stl_pointer --;
			}

			elsif (($stl_line == 0) && ($stl_pointer > 0))
			{
				$stl_pointer --;
			}
		}

# Case PG UP
		elsif ($key eq '5')
		{
			if (($stl_pointer-$uiheight) >= 0)
			{
				$stl_pointer -= $uiheight;
			}
			else
			{
				$stl_pointer = 0;
			}

			$stl_line = 0;
		}

# Case PG DOWN
		elsif ($key eq '6')
		{
			if (($stl_pointer+$uiheight) <= $stl_end)
		 	{
				$stl_pointer += $uiheight;
			}
			else
			{
				$stl_pointer = $stl_end;
			}

			$stl_line = 0;
		}

# Case (t)ag
		elsif ($key =~ /(t|T)/)
		{
			if (exists $TagedTags{$stl_pointer})
			{
				delete ($TagedTags{$stl_pointer});
			}

			else
			{
				$TagedTags{$stl_pointer} = ' ';
			}

			ShwStaBar;
		}

# Case (u)ntag
		elsif ($key =~ /(u|U)/)
		{
			undef %TagedTags;
			ShwStaBar(1);
			goto ShowTags_action;
		}

# Case /
		elsif ($key =~ /(\/)/)
		{
			svid(normal);sgoto(2,$ycord+$uiheight+1);print "Match patern: ";
			scbreak(on);chomp($mpat = <STDIN>);scbreak(off);
			sgoto(2,$ycord+$uiheight+1);scurs(clrline);
			$mpatp = -1;$mpat = lc($mpat);

			foreach (@Taglines)
			{
				$mpatp++;
				if (index(lc($_), $mpat) != -1)
				{
					$TagedTags{$mpatp} = ' ';
				}
			}

			ShwStaBar;
		}
	}
	
	svid(normal);
	print ".\n";
	scbreak(on);
}

sub DrawUI
{
	scurs(clear);
	ShwStaBar(1);
	scenter($ycord+$uiheight+2,"Use keypad to browse, (s)elect, (r)andom, (/)=search pattern,");
	scenter($ycord+$uiheight+3,"(e)dit database, (t)ag multiple, (u)ntag all or just press (q) to quit.");
	scenter($ycord+$uiheight+4,"Elmtag.pl v$elmtagver [$^O] (c) '98-99 by Ali Onur Cinar <root\@zdo.com>");

}

sub Evaluate
{
	my (@g);

	if ($key =~ /(s|S|r|R|\n)/)
	{

		if (!$ARGV[0]) { exit; } 		# if no input file, exit

		@g = keys(%TagedTags); if ($#g < 0) {$TagedTags{$stl_pointer} = '';}	
		if ($key =~ /(r|R)/) {srand (time); $stl_pointer = rand $#Taglines; undef %TagedTags; $TagedTags{$stl_pointer} = '';}

		open INFILE, ">>$ARGV[0]";
			foreach (keys(%TagedTags))
			{
				if ($centertags == 1)
				{
					print INFILE strcenter($Taglines[$_]);
				}
				else
				{
					print INFILE $Taglines[$_];
				}
			}
		close INFILE;

		exec $your_editor, $ARGV[0];
	}
	elsif ($key =~ /(e|E)/)
	{
		system $your_editor, $tag_file;
		goto main;
	}
	elsif ($key =~ /(q|Q)/)
	{
		scurs(clear);
		if ($ARGV[0])
		{
			exec $your_editor, $ARGV[0];
		}
	}
}

sub CalibWinsz
{
        sgetwinsz;
        ReformatTaglines;
        DrawUI;
	if ($_) { goto ShowTags_action; }
}

# main
main:
# signal decleration
	$SIG{'WINCH'} = \&CalibWinsz;	# calibrate UI when winsize change

# start modules
	BufferTags;		# read and buffer taglines from tag_file

	if ($opt_r || $opt_R)	# check for random mode
	{
		$key = "r";
	}
	else
	{
		CalibWinsz;		# calibrate and draw UI
		ShowTags;		# show taglines
	}

	Evaluate;		# evaluate user's answer
