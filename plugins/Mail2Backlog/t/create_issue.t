use strict;
use warnings;
use utf8;

use Test::More;
use WebService::Backlog;
use Encode;

$RPC::XML::ENCODING = 'utf-8';

my $backlog = new_ok( 'WebService::Backlog' => [
    space => '',
    username => '',
    password => '',
] );

my $create_issue = new_ok('WebService::Backlog::CreateIssue' => [{
    projectId   => 1234567890,
    summary     => Encode::encode_utf8( '課題の件名' ),
    description => Encode::encode_utf8( '課題の内容' ),
}]);

my $issue = $backlog->createIssue( $create_issue );

isa_ok( $issue, 'WebService::Backlog::Issue' );

done_testing;
