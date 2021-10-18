package TPS::Questionnaire::Controller::API;
use Moose;
use namespace::autoclean;

use TPS::Questionnaire::Model::Questionnaire;
use TPS::Questionnaire::Model::QuestionnaireAnswer;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => 'api');


=encoding utf-8

=head1 NAME

TPS::Questionnaire::Controller::API - REST API for TPS::Questionnaire

=head1 DESCRIPTION

Handles requests for /api/*

=head1 METHODS

=head2 post_questionnaire

Handles posts to /api/questionnaire and /api/questionnaire/{id}

Without an ID, creates a new questionnaire.
With an ID, posts a response to the questionnaire.

=cut

sub post_questionnaire :Path('questionnaire') POST CaptureArgs(1) Consumes(JSON) {
    my ($self, $c, $id) = (shift, @_);

    my $posted_body = $c->request->body_data;

    my $q = $id
        ? TPS::Questionnaire::Model::QuestionnaireAnswer->from_hashref( { %$posted_body, questionnaire_id => $id } )
        : TPS::Questionnaire::Model::Questionnaire->from_hashref( $posted_body );

    $q->save($c->schema);
    $c->stash->{'status'} = 'ok';
    $c->stash->{'result'} = $q->to_hashref;
    $c->forward('View::JSON');
    return 1;
}

=head2 put_questionnaire

Handles PUTs to /api/questionnaire/{id}.

Currently, simply looks to publish the given questionnaire.

Returns the status of the underlying publish() method.

=cut

sub put_questionnaire :Path('questionnaire') PUT CaptureArgs(1) Consumes(JSON) {
    my ($self, $c, $id) = (shift, @_);

    if (my $q = TPS::Questionnaire::Model::Questionnaire->publish($c->schema, $id)) {
        $c->stash->{'status'} = 'ok';
        $c->stash->{'result'} = $q->to_hashref;
        $c->forward('View::JSON');
        return 1;
    }
    else {
        # some kind of feedback
        return;
    }
}

=head2 get_questionnaire

Handles get requests to /api/questionnaire and /api/questionnaire/{id}

Lists existing questionnaires and shows existing questionnaires.

=cut

sub get_questionnaire :Path('questionnaire') GET CaptureArgs(1) {
    my ($self, $c, $id) = (shift, @_);

    if ($id) {
        my $q = TPS::Questionnaire::Model::Questionnaire->from_id($c->schema, $id);
        if ($q) {
            $c->stash->{'status'} = 'ok';
            $c->stash->{'result'} = $q->to_hashref;
        }
        else {
            $c->stash->{'status'} = 'error';
            $c->stash->{'error'} = 'Not found';
            $c->response->status(404);
        }
    }
    else {
        my $q = TPS::Questionnaire::Model::Questionnaire->summary_list($c->schema);
        $c->stash->{'status'} = 'ok';
        $c->stash->{'result'} = { list => $q, count => scalar(@$q) };
    }

    $c->forward('View::JSON');
}

__PACKAGE__->meta->make_immutable;

1;
