package WWW::UPYUN::RESTAPI;
use utf8;
use Moose;
use Mojo::UserAgent;
use Digest::MD5 qw/md5_hex/;
use DateTime;
use Data::Dumper;

has bucket    => ( is => 'rw', isa => 'Str',             required => 1 );
has operator  => ( is => 'rw', isa => 'Str',             required => 1 );
has password  => ( is => 'rw', isa => 'Str',             required => 1 );
has purge_api => ( is => 'rw', isa => 'Str',             default  => 'http://purge.upyun.com/purge/' );
has ua        => ( is => 'ro', isa => 'Mojo::UserAgent', lazy     => 1, default => sub { Mojo::UserAgent->new } );

sub purge {
    my $self     = shift;
    my @url_list = shift;

    return unless scalar @url_list;
    if ( ref $url_list[0] ) {
        @url_list = @{ $url_list[0] };
    }
    return unless scalar @url_list;
    my $url_list = join( "\n", @url_list );

    my $ua     = $self->ua;
    my $date   = DateTime->now( time_zone => 'Europe/London' )->strftime('%a, %d %b %Y %T %Z');
    my $sign   = $self->sign( $url_list, $date );
    my $header = {
        Date          => $date,
        Authorization => $sign,
    };
    my $res = $ua->post( $self->purge_api => $header => form => { purge => $url_list } )->res->json;
    return 1 if $res and $res->{invalid_domain_of_url} and scalar @{ $res->{invalid_domain_of_url} } == 0;
    return unless wantarray;
    return ( 0, 'purge request failed' ) unless $res;
    return ( 0, $res->{invalid_domain_of_url} ) if $res;
}

sub sign {
    my $self    = shift;
    my $content = shift;
    my $date    = shift;

    my $sign = md5_hex join( '&', $content, $self->bucket, $date, md5_hex $self->password );
    return sprintf( 'UpYun %s:%s:%s', $self->bucket, $self->operator, $sign );
}

1;
