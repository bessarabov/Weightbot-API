package Weightbot::API;

use warnings;
use strict;

use WWW::Mechanize;
use Class::Date qw(date);

=head1 NAME

Weightbot::API - Get Weightbot iPhone app data from weightbot.com

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

There is a great iPhone weight tracking app
http://tapbots.com/software/weightbot/. It backups it's data to the site
https://weightbot.com/ where everybody who uses that app can login and
download the file with the records.

This module gets that data and shows it as a pretty data structure.

    use Weightbot::API;
    use Data::Dumper;

    my $wi = Weightbot::API->new({
        email    => 'user@example.com',
        password => '******',
    }); 

    say $wi->raw_data;
    say Dumper $wi->data;

The object does not send requests to site until data is needed to be
retrieved. The first executed method data() or raw_data() will get data from
the site and the data will be stored in the object, so you can use raw_data()
and data() many times without unnecessary requests.

Site https://weightbot.com/ does not have real API, this module behaves as a
browser.

=head1 SUBROUTINES/METHODS

=head2 new

Creates new object. It has to get parameters 'email' and 'password'.
Optionally you can specify 'site' with some custom site url (default is
'https://weightbot.com'). The other optional thing is to specify 'raw_data'.

    my $wi = Weightbot::API->new({
        email    => 'user@example.com',
        password => '******',
    }); 

=cut

sub new {
    my ($class, $self) = @_;

    die 'No email specified, stopped' unless $self->{email};
    die 'No password specified, stopped' unless $self->{password};

    $self->{site} ||= 'https://weightbot.com';

    bless($self, $class);
    return $self;
}

=head2 raw_data

Returns the weight records in the format as they are stored on the site.
Here is an example:

    date, kilograms, pounds
    2008-12-04, 80.9, 178.4
    2008-12-05, 82.6, 182.1
    2008-12-06, 81.9, 180.6
    2008-12-08, 82.6, 182.1

You can run this method many times but only the first run will get data from
the site.

=cut

sub raw_data {
    my ($self) = @_;

    $self->_get_data_if_needed;

    return $self->{raw_data};
}

=head2 data

Returns the weight data in a structure. In that data some dates can be
skipped. In this structure all the dates are present, but if there is no
weight for that date the empty sting is used. 

An example for the data show in raw_data() method:

    $VAR1 = [
              {
                'n' => 1,
                'date' => '2008-12-04',
                'kg' => '80.9',
                'lb' => '178.4'
              },
              {
                'n' => 2,
                'date' => '2008-12-05',
                'kg' => '82.6',
                'lb' => '182.1'
              },
              {
                'n' => 3,
                'date' => '2008-12-06',
                'kg' => '81.9',
                'lb' => '180.6'
              },
              {
                'n' => 4,
                'date' => '2008-12-07',
                'kg' => '',
                'lb' => ''
              },
              {
                'n' => 5,
                'date' => '2008-12-08',
                'kg' => '82.6',
                'lb' => '182.1'
              }
            ];

=cut

sub data {
    my ($self) = @_;

    $self->_get_data_if_needed;

    unless ($self->{data}) {
        my $result;

        my $n = 1;
        my $prev_date;

        local $Class::Date::DATE_FORMAT="%Y-%m-%d";

        foreach my $line (split '\n', $self->{raw_data}) {
            next if $line =~ /^date, kilograms, pounds$/;
            my ($d, $k, $p) = split /\s*,\s*/, $line;

            $d = date($d);

            if ($prev_date) {
                if ($d < $prev_date) {
                    die "Date '$d' is earlier than '$prev_date', stopped";
                }

                my $expected_date = $prev_date + '1D';
                while ($d != $expected_date) {
                    push @$result, {
                        date => "$expected_date",
                        kg => '', 
                        lb => '', 
                        n => $n, 
                    };  
                    $expected_date += '1D';
                    $n++;
                }

            }   
            
            push @$result, {
                date => "$d",
                kg => $k, 
                lb => $p, 
                n => $n, 
            };  
            $prev_date = $d; 
            $n++;
        }
        $self->{data} = $result;
    }

    return $self->{data};
}

=begin comment _get_data_if_needed

This is a private method that is executed in raw_data() and data(). It checks
if the object already has the data from the site. If not the site is asked
for the data, witch is stored in the object.

=end comment

=cut

sub _get_data_if_needed {
    my ($self) = @_;

    unless ($self->{raw_data}) {
        my $mech = WWW::Mechanize->new(
            agent => "Weightbot::API/$VERSION"
        );

        $mech->get( $self->{site} . '/account/login');

        $mech->submit_form(
            form_number => 1,
            fields      => {
                email     => $self->{email},
                password  => $self->{password},
            }
        );

        $mech->submit_form(
            form_number => 1,
        );

        if ($mech->content !~ /^date, kilograms, pounds\n/) {
            die "Recieved incorrect data, stopped"
        }

        $self->{raw_data} = $mech->content;
    }
}

=head1 AUTHOR

Ivan Bessarabov, C<< <ivan@bessarabov.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-weightbot-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Weightbot-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.
You can also submit a bug or a feature request on GitHub.

=head1 SOURCE CODE 

The source code for this module is hosted on GitHub http://github.com/bessarabov/Weightbot-API

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Weightbot::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Weightbot-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Weightbot-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Weightbot-API>

=item * Search CPAN

L<http://search.cpan.org/dist/Weightbot-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Ivan Bessarabov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Weightbot::API
