use v5.26;
use utf8;
package TPS::Questionnaire::Model::Questionnaire;

use Moose;
use namespace::autoclean;

use constant { true => !!1, false => !!0 };

use Carp qw(carp croak);
use Module::Runtime qw(use_module is_module_name);

=encoding utf-8

=head1 NAME

TPS::Questionnaire::Model::Questionnaire - represents a single questionnaire

=head1 DESCRIPTION

This class represents a single questionnaire; a titled collection of questions.

=head1 ATTRIBUTES

=head2 id

Integer ID for the questionnaire. Will not be defined if the questionnaire is
not yet stored in the database.

C<clear_id> may be used to clear an existing ID, allowing it to be re-stored
in the database with a different ID. C<has_id> indicates if this questionnaire
has an ID.

=cut

has id => (
    is => 'rw',
    isa => 'Int',
    clearer => 'clear_id',
    predicate => 'has_id',
);

=head2 title

Required string attribute; the title for the questionnaire.

=cut

has title => (
    is => 'rw',
    isa => 'Str',
    required => true,
);

=head2 is_published

Optional boolean attribute; defaults to false.

=cut

has is_published => (
    is => 'rw',
    isa => 'Bool',
    default => sub { return false; },
);

=head2 questions

Arrayref of questions, which should be objects doing the
L<TPS::Questionnaire::Model::Question> role. Defaults to the empty array.

=cut

has questions => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { return []; },
);


# Returns the question model module given the question type.
# Defaults to 'text' question type.
sub _question_module {
    my ($question_type) = @_;
    $question_type //= 'text';

    my $class = 'TPS::Questionnaire::Model::Question::'
        . join("", map { ucfirst } (split /_|\s+/, lc $question_type));

    croak "Cannot construct a valid module name for question type '$question_type'"
        unless is_module_name($class);

    return use_module($class);
}

=head1 METHODS

=head2 from_hashref(\%data)

An alternative constructor which creates a questionnaire object from a
hashref of data, formatted in the same manner the API accepts.

=cut

sub from_hashref {
    my ($class, $data) = (shift, @_);

    return $class->new(
        title => $data->{'title'},
        is_published => $data->{'is_published'},

        questions => [ map {
            my $q_data = ref $_ ? $_ : { question_text => $_ };
            my $q_class = _question_module($q_data->{question_type});
            $q_class->from_hashref($q_data);
        } $data->{questions}->@* ],
    );
}

=head2 to_hashref

Creates a hashref of data for this questionnaire and its questions, suitable
for JSON serialization.

=cut

sub to_hashref {
    my ($self) = (shift);

    return {
        title => $self->title,
        is_published => $self->is_published ? \1 : \0,
        questions => [ map $_->to_hashref, @{$self->questions} ],
    };
}

=head2 from_id($schema, $id)

Alternative constructor which creates a questionnaire object from a
L<TPS::Questionnaire::Schema> object and the questionnaire's numeric ID
in the database.

=cut

sub from_id {
    my ($class, $schema, $id) = (shift, @_);

    my $rs = $schema
        ->resultset('Questionnaire')
        ->search({ questionnaire_id => $id });
    my $result = $rs->next
        or return;

    return $class->from_db_object($schema, $result);
}

=head2 from_db_object($schema, $result)

Alternative constructor which creates a questionnaire object from a
L<TPS::Questionnaire::Schema> object and the questionnaire's
L<TPS::Questionnaire::Schema::Result::Questionnaire> object.

=cut

sub from_db_object {
    my ($class, $schema, $result) = (shift, @_);

    my $rs = $result->questionnaire_question->search(
        undef,
        { order_by => 'rank', prefetch => 'question' },
    );

    return $class->new(
        id => $result->questionnaire_id,
        title => $result->title,
        is_published => $result->is_published,

        questions => [ map {
            my $q = $_->question;
            my $q_class = _question_module($q->question_type);
            $q_class->from_db_object($schema, $q);
        } $rs->all ],
    );
}

=head2 save($schema)

Acts as a no-op if the questionnaire is already in the database (has an ID).
Otherwise, saves the questionnaire and its associated questions to the database,
updating this object's ID.

=cut

sub save {
    my ($self, $schema) = (shift, @_);

    # Even though this object has 'rw' attributes, questionnaires are
    # conceptually write-once.
    if ($self->has_id) {
        carp 'Save questionnaire which already exists';
        return $self->id;
    }

    my $result = $schema
        ->resultset('Questionnaire')
        ->create({
        title => $self->title,
        is_published => $self->is_published,
    });

    $self->id($result->questionnaire_id);

    my $rank = 0;
    for my $q (@{$self->questions}) {
        $q->_save($self, ++$rank, @_);
    }

    return $self->id;
}

=head2 summary_list($schema)

Returns a list of hashrefs, each of which have an "id" and "title" key.
This lists all questionnaires in the database. (TODO: pagnination.)

=cut

sub summary_list {
    my ($class, $schema) = (shift, @_);
    my @return;

    my $rs = $schema
        ->resultset('Questionnaire')
        ->search({ is_published => true });
    while (my $q = $rs->next) {
        push @return, {
            id => $q->questionnaire_id,
            title => $q->title,
        };
    }

    \@return;
}



=head2 update($schema)

Based on save, but expects that the ID exists.

Saves the questionnaire (title and is_published) using this object's ID.

Future improvement is to also save the associated questions to the database.

=cut

sub update {
    my ($self, $schema) = (shift, @_);

    # Even though this object has 'rw' attributes, questionnaires are
    # conceptually write-once. or not.
    unless ($self->has_id) {
        croak 'Updating questionnaire requires that one already exists', $self;
        return;
    }

    my $input = {
        title            => $self->title,
        is_published     => $self->is_published,
    };


    my $result = $schema
        ->resultset('Questionnaire')
        ->search( {questionnaire_id => $self->id} )
        ->update( $input );


    ## updated: 21 Oct 2021 by SJS
    ## comment: update() works above. need to update() the questions? am I into scope creep, yes. maybe.
    ##          so the method works for the Questionnaire, and does allow changes to the two fields, and
    ##          overall, only works for existing Qs. But it does not save/update the list of questions, which
    ##          really bugs me. But I've run out of development time. bummer.
    # my $rank = 0;
    # for my $q (@{$self->questions}) {
    #     $q->_save($self, ++$rank, @_);
    # }

    return $self->id;
}


__PACKAGE__->meta->make_immutable;

1;
