package Astro::SIMBAD::Client::WSQueryInterfaceService;
# Generated by SOAP::Lite (v0.69) for Perl -- soaplite.com
# Copyright (C) 2000-2006 Paul Kulchenko, Byrne Reese
# -- generated at [Thu Aug 31 16:25:31 2006]
# -- generated from http://simweb.u-strasbg.fr/axis/services/WSQuery?wsdl

## TRW vvvv
use strict;
use warnings;

our $VERSION = '0.014_01';
## TRW ^^^^

my %methods = (
queryObjectById => {
##    endpoint => 'http://simweb.u-strasbg.fr:8080/axis/services/WSQuery',
    endpoint => 'http://%s/axis/services/WSQuery',
    soapaction => '',
    namespace => 'http://uif.simbad.cds',
    parameters => [
      SOAP::Data->new(name => 'in0', type => 'soapenc:string', attr => {}),
      SOAP::Data->new(name => 'in1', type => 'soapenc:string', attr => {}),
      SOAP::Data->new(name => 'in2', type => 'soapenc:string', attr => {}),
    ], # end parameters
  }, # end queryObjectById
queryObjectByBib => {
##    endpoint => 'http://simweb.u-strasbg.fr:8080/axis/services/WSQuery',
    endpoint => 'http://%s/axis/services/WSQuery',
    soapaction => '',
    namespace => 'http://uif.simbad.cds',
    parameters => [
      SOAP::Data->new(name => 'in0', type => 'soapenc:string', attr => {}),
      SOAP::Data->new(name => 'in1', type => 'soapenc:string', attr => {}),
      SOAP::Data->new(name => 'in2', type => 'soapenc:string', attr => {}),
    ], # end parameters
  }, # end queryObjectByBib
queryObjectByCoord => {
##    endpoint => 'http://simweb.u-strasbg.fr:8080/axis/services/WSQuery',
    endpoint => 'http://%s/axis/services/WSQuery',
    soapaction => '',
    namespace => 'http://uif.simbad.cds',
    parameters => [
      SOAP::Data->new(name => 'in0', type => 'soapenc:string', attr => {}),
      SOAP::Data->new(name => 'in1', type => 'soapenc:string', attr => {}),
      SOAP::Data->new(name => 'in2', type => 'soapenc:string', attr => {}),
      SOAP::Data->new(name => 'in3', type => 'soapenc:string', attr => {}),
    ], # end parameters
  }, # end queryObjectByCoord
); # end my %methods

use SOAP::Lite;
use Exporter;
use Carp ();
our @CARP_NOT = qw{SOAP::Lite};

use vars qw(@ISA $AUTOLOAD @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter SOAP::Lite);
@EXPORT_OK = (keys %methods);
%EXPORT_TAGS = ('all' => [@EXPORT_OK]);

sub _call {
  my ($self, $method) = (shift, shift);
  my $name = UNIVERSAL::isa($method => 'SOAP::Data') ? $method->name : $method;
  my %method = %{$methods{$name}};
  ## TRW vvvv
  my $server = shift or Carp::croak "No server specified";;
  $method{endpoint} or Carp::croak "No server address (proxy) specified";
  my $endpoint = sprintf $method{endpoint}, $server;
  ## $self->proxy($method{endpoint} || Carp::croak "No server address (proxy) specified") 
  $self->proxy ($endpoint)
    unless $self->proxy;
  ## TRW ^^^^
  my @templates = @{$method{parameters}};
  my @parameters = ();
  foreach my $param (@_) {
    if (@templates) {
      my $template = shift @templates;
      my ($prefix,$typename) = SOAP::Utils::splitqname($template->type);
      my $method = 'as_'.$typename;
      # TODO - if can('as_'.$typename) {...}
      my $result = $self->serializer->$method($param, $template->name, $template->type, $template->attr);
      push(@parameters, $template->value($result->[2]));
    } else {
      push(@parameters, $param);
    }
  }

## TRW  $self->endpoint($method{endpoint})
## TRW       ->ns($method{namespace})
## TRW      ->on_action(sub{qq!"$method{soapaction}"!});

## vvv TRW

if ($self->can ('ns')) {
    $self->endpoint($endpoint)
	->ns($method{namespace})
	->on_action (sub{$method{soapaction}});
} else {
    $self->endpoint($endpoint)
	->envprefix ('soap')
	->uri($method{namespace})
	->on_action (sub{$method{soapaction}});
}

## ^^^ TRW

if ($self->serializer->can ('register_ns')) {	## TRW
$self->serializer->register_ns("http://schemas.xmlsoap.org/wsdl/soap/","wsdlsoap");
  $self->serializer->register_ns("http://schemas.xmlsoap.org/wsdl/","wsdl");
  $self->serializer->register_ns("http://uif.simbad.cds","intf");
  $self->serializer->register_ns("http://uif.simbad.cds","impl");
  $self->serializer->register_ns("http://schemas.xmlsoap.org/soap/encoding/","soapenc");
  $self->serializer->register_ns("http://xml.apache.org/xml-soap","apachesoap");
  $self->serializer->register_ns("http://www.w3.org/2001/XMLSchema","xsd");
}	## TRW
  my $som = $self->SUPER::call($method => @parameters); 
  if ($self->want_som) {
      return $som;
  }
  UNIVERSAL::isa($som => 'SOAP::SOM') ? wantarray ? $som->paramsall : $som->result : $som;
}

sub BEGIN {
  no strict 'refs';
  for my $method (qw(want_som)) {
    my $field = '_' . $method;
    *$method = sub {
      my $self = shift->new;
      @_ ? ($self->{$field} = shift, return $self) : return $self->{$field};
    }
  }
}
no strict 'refs';
for my $method (@EXPORT_OK) {
  my %method = %{$methods{$method}};
  *$method = sub {
    my $self = UNIVERSAL::isa($_[0] => __PACKAGE__) 
      ? ref $_[0] ? shift # OBJECT
                  # CLASS, either get self or create new and assign to self
                  : (shift->self || __PACKAGE__->self(__PACKAGE__->new))
      # function call, either get self or create new and assign to self
      : (__PACKAGE__->self || __PACKAGE__->self(__PACKAGE__->new));
    $self->_call($method, @_);
  }
}

sub AUTOLOAD {
  my $method = substr($AUTOLOAD, rindex($AUTOLOAD, '::') + 2);
  return if $method eq 'DESTROY' || $method eq 'want_som';
  die "Unrecognized method '$method'. List of available method(s): @EXPORT_OK\n";
}

1;
