package Mail2Backlog::Plugin;
use strict;
use Encode;
use WebService::Backlog;

$RPC::XML::ENCODING = 'UTF-8';

sub create_issue {
    my $cb = shift;
    my ( %params ) = @_;
    my $plugin = MT->component( 'Mail2Backlog' );
    my $app = MT->instance();
    my $scope = 'system';
    if ( ref ( $app ) =~ /^MT::App::/ ) {
        if ( my $blog = $app->blog ) {
            if (! $plugin->get_config_value( 'backlog_use_system_settings',
                                             'blog:' . $blog->id ) ) {
                $scope = 'blog:' . $blog->id;
            }
        }
    }
    my $backlog_space = $plugin->get_config_value( 'backlog_space', $scope );
    my $backlog_username = $plugin->get_config_value( 'backlog_username', $scope );
    my $backlog_password = $plugin->get_config_value( 'backlog_password', $scope );
    my $backlog_projectId = $plugin->get_config_value( 'backlog_projectId', $scope );
    my $backlog_token = $plugin->get_config_value( 'backlog_token', $scope );
    my $backlog_issueTypeId = $plugin->get_config_value( 'backlog_issueTypeId', $scope );
    my $backlog_issueComponentId = $plugin->get_config_value( 'backlog_issueComponentId', $scope );
    my $backlog_assignerId = $plugin->get_config_value( 'backlog_assignerId', $scope );
    my $backlog_issueMilestoneId = $plugin->get_config_value( 'backlog_issueMilestoneId', $scope );
    my $backlog_priorityId = $plugin->get_config_value( 'backlog_priorityId', $scope );
    my $headers = $params{ headers };
    my $body = $params{ body };
    my $subject = $headers->{ Subject };
    $subject = encode_utf8( decode( 'MIME-Header', $subject ) );
    $body = encode_utf8( decode( 'iso-2022-jp', $$body ) );
    if ( $backlog_token ) {
        $backlog_token = quotemeta( $backlog_token );
        if ( $body !~ /$backlog_token/ ) {
            return 1;
        }
    }
    my $backlog = WebService::Backlog->new(
        space    => $backlog_space,
        username => $backlog_username,
        password => $backlog_password,
    );
    my $params = {
        projectId   => $backlog_projectId,
        summary     => $subject,
        description => $body,
    };
    $params->{ issueTypeId } = $backlog_issueTypeId if $backlog_issueTypeId;
    $params->{ componentId } = $backlog_issueComponentId if $backlog_issueComponentId;
    $params->{ assignerId }  = $backlog_assignerId if $backlog_assignerId;
    $params->{ milestoneId } = $backlog_issueMilestoneId if $backlog_issueMilestoneId;
    $params->{ priorityId }  = $backlog_priorityId;
    if ( $app->run_callbacks( 'backlog_pre_create_issue', $app, $params ) ) {
        my $issue = WebService::Backlog::CreateIssue->new( $params );
        my $created_issue = $backlog->createIssue( $issue );
        if ( (! $created_issue ) || (! $created_issue->{ id } ) ) {
            $app->log( {
                message => $plugin->translate( 'Error while creating Issue of Backlog.' ),
                class => 'backlog',
                level => 4,
            } );
        }
        if (! $app->run_callbacks( 'backlog_post_create_issue', $app, $params, $created_issue ) ) {
            return 0;
        }
    }
    return 1;
}

1;