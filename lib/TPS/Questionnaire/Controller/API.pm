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

    if ($id) {
        my %posted = %{$c->request->body_data};
        $posted{questionnaire_id} = $id;
        my $qa = 'TPS::Questionnaire::Model::QuestionnaireAnswer'->from_hashref(\%posted);
        $qa->save($c->schema);
        $c->stash->{'status'} = 'ok';
        $c->stash->{'result'} = $qa->to_hashref;
        $c->forward('View::JSON');
    }
    else {
        my $q = 'TPS::Questionnaire::Model::Questionnaire'->from_hashref($c->request->body_data);
        $q->save($c->schema);
        $c->stash->{'status'} = 'ok';
        $c->stash->{'result'} = $q->to_hashref;
        $c->forward('View::JSON');
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


=head2 put_questionnaire

Handles PUT action to /api/questionnaire/{id}

The ID is required, this is an "update" action to edit existing data on an unpublished questionnaire.
That is, you can edit the title (and in the future, the questions) associated with an unpublished questionnaire,
or you can publish a questionnaire.

Once a questionnaire is published it can accept responses, but none of its questions or metadata can be further modified.

Once published, a questionnaire cannot be unpublished. (In the future, we may want to be able to unpublish a
questionnaire. For example, if you want to revise an existing questionnaire, you'd publish a revised version and
unpublish the old version. But this would have to be done in such a way that no previously published questionnaires
could be modified. Previous responses to old questionnaires would be preserved.)

=cut

sub put_questionnaire :Path('questionnaire') PUT CaptureArgs(1) Consumes(JSON) {
    my ($self, $c, $id) = (shift, @_);

    ## input validation?
    ## a. is the id valid, i.e., does it exist in the DB
    ## b. is this item (id) in an unpublished state?
    ##
    my (%posted, $q, $qa, );

    # %posted = %{$c->request->body_data};

    if ($id) {
        $q = TPS::Questionnaire::Model::Questionnaire->from_id($c->schema, $id);

        if ( $q->is_published() ) {
            $c->stash->{'status'} = 'error';
            $c->stash->{'error'}  = 'Not allowed to update an already published questionnaire.';
            $c->response->status(400);
        }
        else {
            $q = 'TPS::Questionnaire::Model::Questionnaire'->from_hashref($c->request->body_data);
            $q->id( $id );
            $q->update($c->schema);

            $c->stash->{'status'} = 'ok';
            $c->stash->{'result'} = $q->to_hashref;
            $c->forward('View::JSON');
        }
    }
    else {
        ## if $id not provided, should we do a "create" like POST does?
        ##
        my $q = 'TPS::Questionnaire::Model::Questionnaire'->from_hashref($c->request->body_data);
        $q->save($c->schema);
        $c->stash->{'status'} = 'ok';
        $c->stash->{'result'} = $q->to_hashref;
        $c->forward('View::JSON');
    }

}# end put_questionnaire




__PACKAGE__->meta->make_immutable;

1;
